# Obby Bots

<img src="https://tr.rbxcdn.com/180DAY-2d7b6f597e5b88954424e55b64d38d7c/150/150/Image/Webp/noFilterg" alt="Obby Bots icon" width="128" />

A Roblox game where players race through short obstacle courses (obbies), then watch "replay bots" complete them forever to earn credits. Covers gameplay systems, a chest/rarity progression loop, and a full Rojo + Git tooling setup for version control. Built in collaboration with [a987a](https://www.roblox.com/users/283053707/profile).

## Gameplay

1. A player completes one of many short (~10-30 second) obbies.
2. Their run is recorded into one of their bot recording slots (3 by default, 4 with the relevant gamepass).
3. A **replay bot** spawns and automatically re-runs that recording forever, earning credits on each completed loop.
4. Players can keep re-attempting an obby to shave down their personal best, as a faster recorded time makes the bot complete its loop quicker, increasing credit throughput.

### Recording Slot Logic
 
- If a player has an empty slot available, the new run is recorded to the first empty slot.
- If all of the player's slots are full:
    - If one of the slots already holds a recording for the same obby, the new run replaces it, but only if it's faster than the time currently stored there.
    - Otherwise, if no slot holds a recording for that obby, the run isn't recorded.

> Players can also manually delete a slot's recording to free it up.

## Credits & Multipliers

Each bot's credits-per-win is calculated as:

```
Credits = Obby Base Credits × Bot Multiplier × Completion Time Multiplier
```

- **Obby Base Credits** — a flat value per obby (e.g. a starter obby might award 10 credits per win, an advanced obby up to 10,000).
- **Bot Multiplier** — determined by the bot's rarity and tier; rarer/higher-tier bots multiply earnings more.
- **Completion Time Multiplier** — rewards faster completion times, calculated as:

  ```
  min(3, 100^-(x - y) + 1)
  ```

  where `x` is the bot's completion time and `y` is a hand-tuned "good time" benchmark set per obby. This caps the bonus at 3x and scales down as completion time gets further from the target.

## Bots: Unlocking & Upgrading

Bots are obtained through a chest system (parallel to Clash Royale):

- Each chest type has its own pool of possible bots and drop rates.
- Opening a chest awards 3 bots (duplicates possible), with a 10% chance of an extra bonus bot.
- Duplicate bots upgrade an existing bot to a higher tier (max **Tier 10**), increasing its multiplier.
- Higher-rarity bots require fewer duplicates to max out.

  | Rarity | Cumulative Copies Required for Tier 10 |
  |---|---|
  | Common | 96 |
  | Uncommon | 64 |
  | Rare | 48 |
  | Epic | 32 |
  | Legendary | 24 |

## Gamepasses

- **+1 Extra Bot Recording Slot** — raises the cap from 3 to 4 recording slots.
- **Extra Luck** — doubles the chance of pulling rarer bots from chests.

## Misc. Features

- **Spectate** — watch your bots in action.
- **Race Bot** — (Not implemented yet) pauses a bot's replay loop while racing is enabled; the bot resumes replaying the moment the player leaves the StartZone, effectively "racing" alongside a ghost of their own best run.

## Project Structure

This repo is synced with [Rojo](https://rojo.space/), mapping Roblox's instance hierarchy to real files so it can be tracked in Git.

```
src/
  client/          -> StarterPlayer.StarterPlayerScripts
  server/          -> ServerScriptService
  shared/          -> ReplicatedStorage
  serverstorage/   -> ServerStorage
  startergui/      -> StarterGui (top-level only; see below)
default.project.json
```

Some scripts live deeply nested inside `StarterGui`'s UI hierarchy (e.g. handlers attached to specific Frames/Buttons rather than sitting in `StarterPlayerScripts`). These are declared explicitly in `default.project.json` with their real paths, alongside `$ignoreUnknownInstances` flags (or sidecar `.meta.json` files) to protect their non-script children — like UI templates and cloneable models — from being deleted on sync.

### Setup

1. Install [Rojo](https://rojo.space/docs/latest/getting-started/installation/) (CLI + the Roblox Studio plugin).
2. Clone this repo and run `rojo serve` from the project root.
3. Open the place in Roblox Studio, open the Rojo plugin, and connect.
4. Review the diff before accepting — it should be empty or match only your intended changes.

## Notes

Some larger, unmodified library scripts (e.g. collision group utilities) are intentionally left untracked and live only in the `.rbxl` place file, not in this repo.