# [Noctura](https://noctura-lovat.vercel.app/)

A Roblox script hub built around a clean loader system. Detects your current game, pulls the matching script automatically, and presents it through a polished GUI — no manual script hunting needed.

---

## How It Works

Paste the loader into your executor. It fetches `scripts.json` from this repo, checks your current `PlaceId`, and if there's a supported script for the game you're in, it launches the Noctura GUI. From there you can load the script or tweak settings.

If the game isn't supported, you'll still get the GUI — it'll just let you know.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Nocturra/Noctura/refs/heads/main/important/loader.lua"))()
```

## UI Libraries Used

- [Rayfield](https://docs.sirius.menu/rayfield/) — the entire UI library for all scripts :D
