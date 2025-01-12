#!/bin/bash
# run in this directory automatically by the main game script 
set -e

# by what factor image and video sizes are reduced
# and what scale is used for reducing png quality
SCALE_FACTOR=3
# what fps are videos reduced to
LOWER_FPS=30
# what quality are jpgs reduced to? higher is worse up to 30
JPG_QUALITY=10

# takes video at path and downscales it to be 
# 1/4 the size and 30fps
downscale_video() {
  original=$1
  lowres="./lowres.mkv"

  # return early if this video has already been downscaled
  marker="$original.downscaled"
  if [ -f "$marker" ]; then
    echo "already downscaled $original"
    return 0; 
  fi

  rm -f $lowres # clean up interupted run

  ffmpeg  -i "$original" \
    -vf "scale=iw/$SCALE_FACTOR:ih/$SCALE_FACTOR,fps=$LOWER_FPS" \
    -preset medium \
    -crf 23 \
    -c:a aac -b:a 128k \
    "$lowres" 

  mv "$lowres" "$original"
  touch "$marker"
}



downscale_all_images_recursively() {

  temp_file="./image.png"

  find . -iname "*.png" -print0 | while IFS= read -r -d '' file; do
    echo "$file"

    # due to the expected image resolutions, we need to scale down
    # then scale back up using nearest neighbor to get same size pngs
    # with a disk size reduction
    ffmpeg -nostdin -v error -i "$file" \
      -vf "scale=iw/${SCALE_FACTOR}:ih/${SCALE_FACTOR}" \
      "$temp_file"

    rm "$file"

    ffmpeg -nostdin -v error -i "$temp_file" \
      -sws_flags neighbor \
      -vf "scale=iw*${SCALE_FACTOR}:ih*${SCALE_FACTOR}" \
      "$file"

    rm "$temp_file"
  done

  temp_file="./image.jpg"

  find . -iname "*.jpg" -print0 | while IFS= read -r -d '' file; do
    echo "$file"

    # on the other hand jpgs are easy
    ffmpeg -nostdin -v error -i "$file" -q:v $JPG_QUALITY "$temp_file"

    mv "$temp_file" "$file"
  done
}

downscale_renpy_image_archive() {
  original=$1
  temp_folder="./dearchived"
  lowres="./new-archive.rpa"
  # might as well keep things invariant across systems and 
  # use the shipped python
  renpy_python="./gamefiles/lib/py3-linux-aarch64/python" 

  marker="$original.downscaled"
  if [ -f "$marker" ]; then
    echo "already downscaled $original"
    return 0; 
  fi

  rm -rf "$temp_folder" # clean up interupted run
  $renpy_python rpatool -x "$original" -o "$temp_folder"
  cd "$temp_folder"

  downscale_all_images_recursively

  "../$renpy_python" ../rpatool -c "$lowres" *
  mv "$lowres" "../$original"
  cd ..

  rm -r "$temp_folder"
  touch "$marker"
}

downscale_video ./gamefiles/game/media/NamiTools-ElanBootLogo-HBlossoms-Akemi-1080p60.mkv
downscale_video ./gamefiles/game/media/op.mkv
downscale_video ./gamefiles/game/media/ed.mkv

downscale_renpy_image_archive ./gamefiles/game/archive.rpa

# Remove uneeded large game files
rm -rf ./gamefiles/lib/py3-linux-armv7l
rm -rf ./gamefiles/lib/py3-linux-i686
rm -rf ./gamefiles/lib/py3-windows-i686
rm -rf ./gamefiles/lib/py3-mac-universal
