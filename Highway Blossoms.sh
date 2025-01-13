#!/bin/bash
# PORTMASTER: highwayblossoms.zip, Highway Blossoms.sh


# Prelude
XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt

# Variables 

PORTEXEC="HighwayBlossoms.sh"
GAMEDIR="/$directory/ports/highwayblossoms"
GL4ES_LIBS="$GAMEDIR/gl4es"
OTHER_LIBS="$GAMEDIR/libs"
export LD_LIBRARY_PATH="$GL4ES_LIBS:$OTHER_LIBS:$LD_LIBRARY_PATH"

export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

cd "$GAMEDIR"

# this step isn't required, though it will make
# the game more playable. The file being checked
# for is created in the downscale_assets.sh script
if [ ! -f "$GAMEDIR/has_been_patched" ]; then
	export PATCHER_FILE="$GAMEDIR/downscale_assets.sh"
	export PATCHER_GAME="Highway Blossoms"
	export PATCHER_TIME="15 to 20 minutes"
	export PATCHDIR="$GAMEDIR"
  export LOVE_GRAPHICS_USE_OPENGLES=1

	# This will take a WHILE if this is the first run!
	source "$controlfolder/utils/patcher.txt"
fi

# these interfere with the patcher, so the are below it
if [ "$CFW_NAME" = "muOS" ]; then
  export SDL_VIDEO_GL_DRIVER="$GL4ES_LIBS/libGL.so.1"
  export SDL_VIDEO_EGL_DRIVER="$GL4ES_LIBS/libEGL.so.1"
fi

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# If using gl4es
if [ -f "${controlfolder}/libgl_${CFW_NAME}.txt" ]; then 
  source "${controlfolder}/libgl_${CFW_NAME}.txt"
else
  source "${controlfolder}/libgl_default.txt"
fi

# not a required command, just shows a splash while the
# game loads
mpv "$GAMEDIR/cover.png"

cd ./gamefiles

# setup default settings so that text is legible
SETTINGS_FOLDER="$GAMEDIR/gamefiles/game/saves/"
if [ ! -f "$SETTINGS_FOLDER" ]; then
  mkdir -p "$SETTINGS_FOLDER"
  cp "$GAMEDIR/text_settings" "$SETTINGS_FOLDER/persistent"
fi

pm_platform_helper "$GAMEDIR/gamefiles/lib/py3-linux-aarch64/HighwayBlossoms"
$GPTOKEYB "HighwayBlossoms" -c "$GAMEDIR/highwayblossoms.gptk" &

bash "./$PORTEXEC"

pm_finish
$ESUDO kill -9 $(pidof gptokeyb)
