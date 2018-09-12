--#include constants
--#include globals
--#include config

--#include oo
--#include v2
--#include bbox
--#include camera

--#include helpers
--#include tween
--#include coroutines
--#include queues
--#include gfx

--#include actors
--#include button
--#include room
--#include smoke
--#include particle
--#include player
--#include spring
--#include spawn
--#include spikes
--#include moving_platform
--#include teleporter
--#include power-ups
--#include mine

--[[

interactables:
- x spring
- spikes
- tele_enter
- powerup
- mine

standalone
- gore
- x smoke
- spawn
- tele exit

]]

-- split into actors / particles / interactables
-- x gravity
-- x downward collision
-- x wall slide
-- x add wall slide smoko
-- x fall down faster
-- x wall jump
-- x variable jump time
-- x test controller input
-- x add ice
-- x springs
-- x wall sliding on ice
-- x player spawn points
-- x spikes
-- x respawn player after death
-- x add ease in for spawn point
-- x add coroutine for spawn point
-- x slippage when changing directions
-- x flip smoke correctly when wall sliding
-- x particles with sprites
-- x add gore particles and gored up tiles
-- x add gore on vertical surfaces
-- x make gore slippery
-- x add gore when dying
-- moving platforms
-- laser beam
-- add water
-- add butterflies
-- add flies
-- vanishing platforms
-- lookup / lookdown sprites
-- go through right and come back left (?)
-- x add second player
-- add trailing smoke particles when springing up
-- x add multiple players / spawn points
-- x add death mechanics
-- x add score
-- x camera shake
-- x doppelgangers
-- x remove typ code
-- x bullet time on kill
-- better kill animations
-- restore ghosts / particles on player
-- decrease score when dying on spikes

-- fades

-- number of player selector menu
-- title screen
-- game end screen (kills or timer)
-- prettier score display
-- pretty pass

-- powerups - item dropper
-- x invincibility
-- visualize power ups
-- different sprites for different players
-- bomb
-- blast mine
-- x superspeed
-- x superjump
-- x gravity tweak
-- balloon pulling upwards
-- double jump
-- dash
-- x invisibility
-- meteors
-- flamethrower
-- bullet time
-- whip
-- jetpack
-- moving platforms
-- vanishing platforms
-- miniature mode
-- lasers
-- gun
-- rope
-- selfbomber (on a timer)
-- level design

-- x multiple players
-- x random player spawns
-- x player collision
-- x player kill
-- x player colors

--#include main
