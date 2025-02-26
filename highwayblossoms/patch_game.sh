#!/bin/bash
# run in this directory automatically by the main game script 

set -e

# webm quality lower is worse
WEBP_QUALITY=10
# what fps are videos reduced to
LOWER_FPS=30
#
VORBIS_COMPATIBLE_AUDIO_SAMPLE_RATE=48000
# 
AUDIO_BIT_RATE=32k
# 
VIDEO_BIT_RATE=200k
# what quality are scaled down videos reduced to? higher is worse
LOW_SCALE_VIDEO_QUALITY=15
# what quality are non scaled down videos reduced to? higher is worse
HIGH_SCALE_VIDEO_QUALITY=20
# by what factor video sizes are reduced?
SCALE_FACTOR=3

FFMPEG="$PWD/ffmpeg"
PYTHON="$PWD/renpy/lib/py3-linux-aarch64/python"
chmod +x $FFMPEG

check_marker() {
  marker="$1.lowres"
  if [ -f "$marker" ]; then
    echo "already downscaled $1"
    return 1; 
  fi
  return 0; 
}

put_marker() {
  marker="$1.lowres"
  touch "$marker"
}

remove_markers() {
  find . -type f -name '*.lowres' -exec rm {} +
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
    -vf "scale=iw/${SCALE_FACTOR}:ih/${SCALE_FACTOR},fps=${LOWER_FPS}" \
    -crf "${LOW_SCALE_VIDEO_QUALITY}" \
    -c:a aac \
    -b:a "${AUDIO_BIT_RATE}" \
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
    -b:a "${AUDIO_BIT_RATE}" \
    "$lowres" 

  mv "$lowres" "$original"
  put_marker "$original"
}

recursive_downscale_x_into_y_with_options() {
  temp_file="./out.$2"

  find . -iname "*.$1" -print0 |  while IFS= read -r -d '' file; do
  if check_marker "$file"; then
    echo "$file"
    rm -f "$temp_file"
    eval "$FFMPEG -nostdin -v error -i '$file' $3 '$temp_file'"
    mv "$temp_file" "$file"
    put_marker "$file"
  fi
done
}

recursive_downscale_x_with_options() {
  recursive_downscale_x_into_y_with_options "$1" "$1" "$2"
}

# OOps, all webp
downscale_pngs() {
  recursive_downscale_x_into_y_with_options "png" "webp" "-c:v libwebp -quality ${WEBP_QUALITY}"
}

downscale_jpgs() {
  recursive_downscale_x_into_y_with_options "jpg"  "webp" "-c:v libwebp -quality ${WEBP_QUALITY}"
  recursive_downscale_x_into_y_with_options "jpeg" "webp" "-c:v libwebp -quality ${WEBP_QUALITY}"
}

downscale_oggs() {
  recursive_downscale_x_into_y_with_options "ogg" "opus" "-ar ${VORBIS_COMPATIBLE_AUDIO_SAMPLE_RATE} -b:a ${AUDIO_BIT_RATE} -c:a libopus"
}

downscale_wavs() {
  recursive_downscale_x_into_y_with_options "wav" "opus" "-ar ${VORBIS_COMPATIBLE_AUDIO_SAMPLE_RATE} -b:a ${AUDIO_BIT_RATE} -c:a libopus"
}

downscale_flacs() {
  recursive_downscale_x_into_y_with_options "wav" "opus" "-ar ${VORBIS_COMPATIBLE_AUDIO_SAMPLE_RATE} -b:a ${AUDIO_BIT_RATE} -c:a libopus"
}

downscale_webms() {
  recursive_downscale_x_with_options "webm" "-ar ${VORBIS_COMPATIBLE_AUDIO_SAMPLE_RATE} -ac 1 -b:a ${AUDIO_BIT_RATE} -c:v libvpx -r ${LOWER_FPS} -b:v ${VIDEO_BIT_RATE}"
}

downscale_mkvs() {
  recursive_downscale_x_with_options "mkv" "-ar ${VORBIS_COMPATIBLE_AUDIO_SAMPLE_RATE} -ac 1 -b:a ${AUDIO_BIT_RATE} -r ${LOWER_FPS} -b:v ${VIDEO_BIT_RATE}"
}


# extract all assets
for RPA in ./gamefiles/*rpa; do
  if [ -f "$RPA" ]; then
    echo "Extracting $RPA"
    $PYTHON rpatool -x $RPA -o ./gamefiles
    rm $RPA
  fi
done

# downscale all assets
cd gamefiles

downscale_jpgs
downscale_pngs
# downscale_flacs
# downscale_oggs # downsampling audio doesn't seem to help much; removing.
downscale_wavs
# downscale_mkvs # Takes waaay to long. Instead doing only the needed ones
downsample_video ./media/NamiTools-ElanBootLogo-HBlossoms-Akemi-1080p60.mkv
downscale_video  ./media/op.mkv
downscale_video  ./media/ed.mkv
downscale_webms

remove_markers
cd ..

# up until here the script is fail safe; you could quit it and nothing bad would happen.
# The rest of the script should run quickly though, so hopefully this doesn't matter.

# apply game file patches
cp patches/* gamefiles/

# setup default settings so that text is legible
mkdir -p "gamefiles/saves"
cp "text_settings" "gamefiles/saves/persistent"

# indicates that this file finished running and shouldn't be run again
touch has_been_patched
