#!/bin/bash
# run in this directory automatically by the main game script 
set -e

# by what factor image and video sizes are reduced
# and what scale is used for reducing png quality
SCALE_FACTOR=3
# what quality are jpgs reduced to? higher is worse up to 30
JPG_QUALITY=10
# what fps are videos reduced to
LOWER_FPS=30
# what quality are scaled down videos reduced to? higher is worse
LOW_SCALE_VIDEO_QUALITY=15
# what quality are non scaled down videos reduced to? higher is worse
HIGH_SCALE_VIDEO_QUALITY=20


FFMPEG="$(pwd)/ffmpeg"
chmod +x $FFMPEG

check_marker() {
  marker="$1.lowres"
  if [ -f "$marker" ]; then
    echo "already downscaled $original"
    return 1; 
  fi
  return 0; 
}

put_marker() {
  marker="$1.lowres"
  touch "$marker"
}

# takes video at path and downscales it to be lower res, quality, and fps
downscale_video() {
  original=$1
  lowres="./lowres.mkv"

  # return early if this video has already been downscaled
  check_marker "$original" || return 0

  rm -f $lowres # clean up interupted run

  echo "$original"

  $FFMPEG -nostdin -v error -i "$original" \
    -vf "scale=iw/$SCALE_FACTOR:ih/$SCALE_FACTOR,fps=$LOWER_FPS" \
    -crf "$LOW_SCALE_VIDEO_QUALITY" \
    -c:a aac -b:a 128k \
    "$lowres" 

  mv "$lowres" "$original"
  put_marker "$original"
}

# takes a video and lowers quality and fps but not resolution!
# some videos have to stay the same size for things to look right
downsample_video() {
  original=$1
  lowres="./lowres.mkv"

  # return early if this video has already been downscaled
  check_marker "$original" || return 0

  rm -f $lowres # clean up interupted run

  echo "$original"

  $FFMPEG -nostdin -v error -i "$original" \
    -crf "$HIGH_SCALE_VIDEO_QUALITY" \
    -c:a aac \
    -b:a 128k \
    "$lowres" 

  mv "$lowres" "$original"
  put_marker "$original"
}



downscale_all_pngs_recursively() {

  temp_file="./image.png"

  find . -iname "*.png" -print0 |  while IFS= read -r -d '' file; do
    echo "$file"

    # due to the expected image resolutions, we need to scale down
    # then scale back up using nearest neighbor to get same size pngs
    # with a disk size reduction
    $FFMPEG -nostdin -v error -i "$file" \
      -vf "scale=iw/${SCALE_FACTOR}:ih/${SCALE_FACTOR}" \
      "$temp_file"

    rm "$file"

    $FFMPEG -nostdin -v error -nostdin -v error -i "$temp_file" \
      -sws_flags neighbor \
      -vf "scale=iw*${SCALE_FACTOR}:ih*${SCALE_FACTOR}" \
      "$file"

    rm "$temp_file"
  done

}

downscale_all_jpgs_recursively() {
  temp_file="./image.jpg"

  find . -iname "*.jpg" -print0 | while IFS= read -r -d '' file; do
    echo "$file"

    # on the other hand jpgs are easy
    $FFMPEG -nostdin -v error -nostdin -v error -i "$file" -q:v $JPG_QUALITY "$temp_file"

    mv "$temp_file" "$file"
  done
}

downscale_renpy_archive() {
  original=$1
  temp_folder="./dearchived"
  lowres="./new-archive.rpa"
  # might as well keep things invariant across systems and 
  # use the shipped python
  renpy_python="./gamefiles/lib/py3-linux-aarch64/python"

  check_marker "$original" || return 0

  rm -rf "$temp_folder" # clean up interupted run
  $renpy_python rpatool -x "$original" -o "$temp_folder"
  cd "$temp_folder"

  downscale_all_pngs_recursively
  downscale_all_jpgs_recursively

  "../$renpy_python" ../rpatool -c "$lowres" *
  mv "$lowres" "../$original"
  cd ..

  rm -r "$temp_folder"
  put_marker "$original"
}

maybe_downscale_renpy_archive() {
  if [ -f "$1" ]; then
    downscale_renpy_archive "$1"
  fi
}

# renpy doens't make this video fill the screen when its downscaled,
# So instead downsample
downsample_video ./gamefiles/game/media/NamiTools-ElanBootLogo-HBlossoms-Akemi-1080p60.mkv

downscale_video ./gamefiles/game/media/op.mkv
downscale_video ./gamefiles/game/media/ed.mkv

downscale_renpy_archive ./gamefiles/game/archive.rpa
maybe_downscale_renpy_archive ./gamefiles/game/adult.rpa
maybe_downscale_renpy_archive ./gamefiles/game/nextexit.rpa

# Remove uneeded large game files
rm -rf ./gamefiles/lib/py3-linux-armv7l
rm -rf ./gamefiles/lib/py3-linux-i686
rm -rf ./gamefiles/lib/py3-windows-i686
rm -rf ./gamefiles/lib/py3-mac-universal
rm -rf ./gamefiles/lib/py3-windows-x86_64/
rm -rf ./gamefiles/HighwayBlossoms.app

# indicates that this file finished running
touch has_been_patched
