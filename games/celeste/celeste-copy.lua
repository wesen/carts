-- ~celeste~
-- matt thorson + noel berry

k_left=0
k_right=1
k_up=2
k_down=3
k_jump=4
k_dash=5

-- x first, drawing of the current room
-- x draw terrain
-- x draw player
-- x draw player hair
-- x animate player
-- x move player
-- x draw hair
-- x jump
-- x solidity checks
-- x objects
-- x multijumps
-- x smoke
-- x dash
-- x camera shake and freeze
-- x wall slide
-- x walljumps
-- x title screen
-- clouds
-- particles
-- spawn player
-- platforms
-- ice
-- spikes
-- flash bg with chests
-- kill player
-- fall floor
-- fake wall
-- music

max_djump=1
frames=0
seconds=0
minutes=0

shake=0
-- used to stop the game loop
freeze=0

sfx_timer=0
music_timer=0

start_game=false
start_game_flash=0

flash_bg=false

-- levels
room={x=0,y=0}
types={}

--#include title
--#include room
--#include game

--#include player
--#include hair
--#include smoke
--#include clouds

--#include objects

--#include main-functions
--#include helpers