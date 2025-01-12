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
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
PORTEXEC="HighwayBlossoms.sh"
PORTLOC="/$directory/ports/highwayblossoms"
GL4ES_LIBS="$PORTLOC/gl4es"

# Exports
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export SDL_VIDEO_GL_DRIVER="$GL4ES_LIBS/libGL.so.1"
export SDL_VIDEO_EGL_DRIVER="$GL4ES_LIBS/libEGL.so.1"

cd $PORTLOC

set -e

> "$PORTLOC/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# If using gl4es
if [ -f "${controlfolder}/libgl_${CFW_NAME}.txt" ]; then 
  source "${controlfolder}/libgl_${CFW_NAME}.txt"
else
  source "${controlfolder}/libgl_default.txt"
fi

echo "Downscaling assets" > /dev/tty0
echo "This will take a WHILE (15 minutes) if this is the first run!" > /dev/tty0

./downscale_assets.sh
cd gamefiles

pm_platform_helper "$PORTLOC/gamefiles/lib/py3-linux-aarch64/HighwayBlossoms"
$GPTOKEYB "HighwayBlossoms" -c "$PORTLOC/highwayblossoms.gptk" &

bash "./$PORTEXEC"

pm_finish
$ESUDO kill -9 $(pidof gptokeyb)
