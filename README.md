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
- **Backend**: Your own REST API (Node.js/HonoJS + MongoDB, PocketBase)
- **HTTP client**: lua-https (or fetch-lua for async in future)

## Folder Structure

```text
.
├── assets
│   ├── fonts
│   ├── images
│   ├── sounds
│   └── Sunnyside_World_ASSET_PACK_V2.1/
│       └── Sunnyside_World_Gamemaker/
├── conf.lua
├── lib
├── main.lua
├── README.md
└── src
```

### Note on `Sunnyside_World_Gamemaker`


The `Sunnyside_World_Gamemaker` folder is a **GameMaker Studio 2 project** included with the asset pack. While you are using **LÖVE2D**, this folder is useful for:
- **Reference for Animations:** Folder names (e.g., `base_idle_strip9`) indicate the number of frames in each animation.
- **Raw Assets:** Individual frames are stored as `.png` files.
- **Metadata:** `.yy` files contain project settings that can be opened as text for reference.

**Recommendation:** Do not import this entire folder into your LÖVE2D project to avoid bloating the game size. Instead, use the consolidated spritesheets in `assets/images`.
