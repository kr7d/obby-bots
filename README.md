# Obby Bots

[![Play on Roblox](https://img.shields.io/badge/Roblox-Play%20Now-00A2FF?logo=roblox&logoColor=white)](https://www.roblox.com/games/110009073548190/Obby-Bots)
[![Built with Rojo](https://img.shields.io/badge/Built%20with-Rojo-e93450)](https://rojo.space/)

<img src="https://tr.rbxcdn.com/180DAY-2d7b6f597e5b88954424e55b64d38d7c/150/150/Image/Webp/noFilterg" alt="Obby Bots icon" width="128" />

A Roblox idle/obby hybrid: players race through short obstacle courses, then send a **replay bot** off to run that recording forever for passive credits. Built in collaboration with [a987a](https://www.roblox.com/users/283053707/profile).

This repo is the full source for the game, synced with [Rojo](https://rojo.space/) so it can be version-controlled and edited outside of Roblox Studio.

## Table of Contents

- [Gameplay](#gameplay)
- [Bots: Unlocking & Upgrading](#bots-unlocking--upgrading)
- [Rebirth](#rebirth)
- [Other Systems](#other-systems)
- [Project Structure](#project-structure)
- [Setup](#setup)
- [Roadmap](#roadmap)
- [Notes](#notes)

## Gameplay Loop

**Step 1:** A player completes one of many short (~10-30 second) obbies.\
<img src="https://i.imgur.com/d54SxzR.gif" width="500" alt="Player recording themselves completing an obby">

**Step 2:** Their run is recorded into one of their recording slots. The player then assigns a **replay bot** to that recording slot.\
<img src="https://i.imgur.com/N3rJzgO.gif" width="500" alt="Player setting starter bot to Slot 1">

**Step 3:** That replay bot spawns and automatically re-runs that recording forever, earning credits on each completed loop.\
<img src="https://i.imgur.com/0tbmgKT.gif" width="500" alt="Bot replaying the player's recording">

> Players can keep re-attempting an obby to shave down their personal best — a faster recorded time makes the bot complete its loop quicker, increasing credit throughput.

### Recording Slot Logic

- If a player has an empty slot available, the new run is recorded to the first empty slot.
- If all of the player's slots are full:
  - If one of the slots already holds a recording for the same obby, the new run replaces it, but only if it's faster than the time currently stored there.
  - Otherwise, if no slot holds a recording for that obby, the run isn't recorded.

> Players can also manually delete a slot's recording to free it up.


## Bots: Unlocking & Upgrading

Bots are obtained through a chest system (parallel to Clash Royale):

- Each chest type has its own pool of possible bots and drop rates.
- Opening a chest awards 3 bots (duplicates possible), with a 10% chance of an extra bonus bot.
- Duplicate bots upgrade an existing bot to a higher tier (max **Tier 10**), each tier multiplying the bot's credit output by 1.5x.
- Higher-rarity bots require fewer duplicates to max out.

| Rarity | Cumulative Copies Required for Tier 10 |
|---|---|
| Common | 96 |
| Uncommon | 64 |
| Rare | 48 |
| Epic | 32 |
| Legendary | 24 |

## Rebirth

A prestige loop for players who've hit a wall on credit income:

- Rebirthing costs credits — the requirement starts at 1,000,000¢ and scales 9x with each rebirth.
- Rebirthing resets your progress: credits back to 0, all bots removed (back down to the default `Starter` bot), extra bot slots revoked, and all obbies re-locked except the default `Obby Lobby`.
- In exchange, every rebirth doubles all future credit earnings permanently (multiplicative, so 2 rebirths = 4x, 3 = 8x, and so on).
- A progress bar toward the next rebirth is always visible in the UI, which lights up once the player can afford to cash in.

## Other Systems

- **Spectate** — watch your bots run their loops in real time.
- **Chests & Inventory** — chest-opening UI, bot collection, and duplicate-upgrade flow.
- **Leaderboards** — global stat leaderboards (e.g. Most Credits), backed by ordered Datastores.
- **Tutorial** — a scripted onboarding flow (recording a run, opening the inventory, spectating a bot).
- **Gamepasses** — purchasable perks (e.g. a 4th bot slot).
- **Race Bot** — *(not implemented yet)* pauses a bot's replay loop while racing is enabled; the bot resumes replaying the moment the player leaves the StartZone, effectively "racing" alongside a ghost of their own best run.

## Project Structure

Rojo maps Roblox's instance hierarchy to these folders so the project can live in Git:

```
src/
  client/          -> StarterPlayer.StarterPlayerScripts
  server/          -> ServerScriptService
    Data/            data loading/saving (Datastore wrapper)
    Main/            core game logic (bots, leaderboards, admin, robux)
  shared/          -> ReplicatedStorage
    Game Settings/   tunable values, tiers, feature flags
    Modules/         shared logic used by both client & server (playback, tutorial, UI helpers)
  serverstorage/   -> ServerStorage
  startergui/      -> StarterGui (top-level only; see below)
default.project.json
```

Some scripts live deeply nested inside `StarterGui`'s UI hierarchy (e.g. handlers attached to specific Frames/Buttons rather than sitting in `StarterPlayerScripts`). These are declared explicitly in `default.project.json` with their real paths, alongside `$ignoreUnknownInstances` flags (or sidecar `.meta.json` files) to protect their non-script children — like UI templates and cloneable models — from being deleted on sync.

## Setup

1. Install [Rojo](https://rojo.space/docs/latest/getting-started/installation/) (CLI + the Roblox Studio plugin). This repo pins tool versions with [Rokit](https://github.com/rojo-rbx/rokit); if you have Rokit installed, `rokit install` picks up the right Rojo version automatically.
2. Clone this repo and run `rojo serve` from the project root.
3. Open the place in Roblox Studio, open the Rojo plugin, and connect.
4. Review the diff before accepting — it should be empty or match only your intended changes.

## Notes

Some larger, unmodified library scripts (e.g. collision group utilities) are intentionally left untracked and live only in the `.rbxl` place file, not in this repo.
