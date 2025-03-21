# Port of Highway Blossoms
## Controls

| Button | Action |
|--|--| 
|A|Confirm/Next|
|B|Cancel|
|X|Toggle Auto|
|Y|Toggle Overlay|
|D-Pad|Navigation|
|Start|Toggle Menu|
|L1|Back|
|R1/L2|Skip|

## What is this?
This is a port of the game [Highway Blossoms](https://vnstudioelan.itch.io/highway-blossoms) 
using the framework [Portmaster](https://portmaster.games/). This does not include
any game files, but with them you should be able to play the game on some handheld devices
such as the RG35XXSP and other aarch64 architecture devices.

## How do I use it? 
Drop the entire contents of the `Highway\ Blossoms\ 1.2.5\ -\ Unified/game` folder
into the `gamefiles` folder and then run the `./Highway Blossoms.sh` script to start it.

## Things to note!
* The first time you run the game, it will take a while to start, like 15 minutes.
This is because the first thing it does is downsample all the assets so that
the videos don't play like slide shows and the images don't take up quite as much
RAM

* The menu interaction is a little weird in the base game with just keyboard,
so similarly it is a little wonky on the gamepad navigating some of the menus,
but it does work. I recommend filling your save slots for easier navigation on 
those screens

* DLC files should work, though the next exit dlc will double the time for the first
launch to actually start due to the increased number of files to downscale

## Thanks To;
* [Studio Elan](https://vnstudioelan.com/) for making awesome visual novels, please check them out
* [Portmaster](https://portmaster.games/) and their framework and community
* [renpy](https://www.renpy.org/) for being a great visual novel engine
* [gl4es](https://github.com/ptitSeb/gl4es) for being an essential library
* [rpatool](https://github.com/shizmob/rpatool) for allowing unpacking and repacking of assets for downsampling
* [ffmpeg](https://ffmpeg.org/) for being the most useful multimedia tool
