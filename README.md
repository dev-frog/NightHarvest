# NightHarvest 🌙

A cozy 2D farming game made with **LÖVE2D** (Lua).

Grow crops, harvest under the moonlight, save progress to your own cloud backend via REST API.

## Features (current)
- 8×8 farm grid
- Plant / harvest crops with growth stages
- Player movement (WASD / arrows)
- Username registration screen
- Cloud save/load via your REST API (no local JSON anymore)
- Placeholder rectangle graphics (ready for pixel art replacement)

## Controls
- **WASD / Arrow keys** → Move character
- **Left mouse click** on tile → Plant seed (if soil) or Harvest (if ready)
- Saves automatically happen on harvest (or you can add manual save later)

## Tech Stack
- **Frontend**: Lua + LÖVE2D[](https://love2d.org)
- **Backend**: Your own REST API (e.g. Node.js/Express + MongoDB, PocketBase, Supabase…)
- **HTTP client**: lua-https (or fetch-lua for async in future)

## Folder Structure