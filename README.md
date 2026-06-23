# Noctura

A Roblox script hub built around a clean loader system. Detects your current game, pulls the matching script automatically, and presents it through a polished GUI — no manual script hunting needed.

---

## How It Works

Paste the loader into your executor. It fetches `scripts.json` from this repo, checks your current `PlaceId`, and if there's a supported script for the game you're in, it launches the Noctura GUI via the [Mercury UI library](https://github.com/deeeity/mercury-lib). From there you can load the script or tweak settings.

If the game isn't supported, you'll still get the GUI — it'll just let you know.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Nocturra/Noctura/refs/heads/main/important/loader.lua"))()
```

---

## Supported Games

| Game | Script | Features |
|------|--------|----------|
| Surf for Lucky Blocks | `SurfForLuckyBlocks/script.lua` | Auto surf, lucky block targeting, rarity filtering, rainbow accent, config save/load |
| Money Clicker Incremental | `MoneyIncremental/script.lua` | Auto click money/gems, auto prestige, auto upgrade, auto daily reward, auto crate open, config system, theme switcher |
| Sell Lemons | `SellLemons/script.lua` | Auto farm (purchase, upgrade, collect, cash drop, fruit), auto phone offer, tycoon detection |

---

## Features

- **Auto game detection** — matches your PlaceId to the right script on load
- **Mercury UI** — clean dark-themed hub GUI with tabs for loading and settings
- **Anonymize toggle** — spoofs your username and face texture in-game
- **Config system** — save/load your settings per script (where supported)
- **Modular scripts** — each game gets its own self-contained script file.

---

## UI Libraries Used

- [Mercury](https://github.com/deeeity/mercury-lib) — main hub loader GUI
- [Vynixius](https://github.com/RegularVynixu/UI-Libraries) — Surf for Lucky Blocks
- [Visual UI Library](https://github.com/VisualRoblox/Roblox) — Money Clicker Incremental
- [IreXion](https://github.com/GhostDuckyy/UI-Libraries) — Sell Lemons
