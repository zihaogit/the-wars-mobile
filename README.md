# The Wars Mobile

**Build smart, command precisely, and adapt before the next round breaks you.**

The Wars Mobile is a concept for an original, touch-first tactical strategy game. Players command a champion, develop a defence, manage limited resources, and adapt between timed combat rounds. The target is a readable, competitive mobile experience built around matches of roughly 10–20 minutes.

> **Project status:** The local Godot prototype now has a winding arena, touch build/upgrade commands, three original structures, resource costs and income, food capacity, and tower combat. Production character art, complete AI base-building, the planned vertical slice, and online play are not implemented.

## The Game

The game combines arena defence, base-building decisions, and champion command in a compact match:

1. Use the command grid to queue a champion, or choose a structure and tap one of your marked build plots.
2. Spend gold and wood to build or upgrade a Sentinel Spire, Timber Camp, or Harveststead.
3. Manage food capacity, income, and the headquarters supply limit as rounds progress.
4. Defend the original winding lane while commanding a hero with touch selection and movement orders.
5. Keep the command interface usable on a phone without relying on a mouse.

This prototype implements an initial version of that loop with original map geometry, legal player-side plots, three placeable/upgradable structures, and a basic economy. Rival structure-building, detailed headquarters rules, deeper hero abilities, and final production art remain unfinished.

## Product Direction

- **Genre:** Tactical strategy / arena defence / champion command
- **Platform:** Android first; iOS considered after Android validation
- **Match target:** 10–20 minutes
- **Initial opponents:** AI opponents to test the core loop, pacing, and hero balance
- **Competitive direction:** PvP matchmaking and ranked progression after gameplay validation
- **Match sizes planned:** 1v1 through 4v4, with bots filling open slots where appropriate
- **Monetisation direction:** Cosmetic-focused; no in-match power sales planned

These are design goals; online PvP and the full progression system are not implemented.

## First Playable Goals

The planned vertical slice is intentionally small:

- One original arena and one controllable champion
- One player base, a barracks/defence building, and upgrade choices
- Gold-funded recruit queues with multiple allied and enemy units
- Timed rounds, readable hero roles, abilities, upgrades, and adaptive AI opponents
- Mobile HUD, onboarding, local save data, and Android device testing
- Early balance telemetry and a networked 1v1 prototype

Live PvP matchmaking, ranked seasons, guilds, global chat, user-generated maps, and a large live-service backend are outside the first playable scope.

## Technology

- **Engine:** Godot 4
- **Game logic:** GDScript; C# only if later shown to be necessary
- **Target:** Android-first, using Godot's mobile or compatibility rendering path as appropriate
- **Tools planned:** Godot editor, VS Code, Git, and Android SDK tooling

## Run the 1v1 Prototype

1. Install Godot 4.7.2 or a compatible Godot 4 release.
2. Open `game/project.godot` in Godot and run the project.
3. Use the recruit cards to queue units for the next round. Choose a structure in the lower command grid, then tap an empty blue plot to place it; tap one of your buildings and choose **Upgrade** to improve it. Spires attack nearby rivals, Timber Camps increase wood income, and farms increase food capacity. Tap a friendly unit, then tap the battlefield to issue a movement order. Each side earns 75 gold per round, with additional wood from your economy. This is an original-content strategy prototype, not a Warcraft III port or asset recreation.

The original hero roster and portrait artwork are in `game/heroes/`. Hero definitions are data-driven in `hero_roster.json`.

The Android SDK and phone export workflow are described in the local development start guide, which is intentionally excluded from Git.

Run the match-flow checks from a terminal with:

```powershell
godot --headless --path .\game --script res://tests/test_match_flow.gd
```

The Word reference compares our original heroes with the Warcraft map's complete build, recruit, and upgrade catalog, including map-defined evolution paths: [Hero Roster & Reference Comparison](./docs/Hero_Roster_Reference_Comparison.docx).

## Development Roadmap

1. Extend the original arena with more map-defined build restrictions and tactical routes.
2. Expand the touch command grid and test resource, supply, and placement edge cases.
3. Add rival construction decisions, hero abilities, and deeper combat feedback.
4. Replace procedural placeholders with polished original models, animation, and audio.
5. Validate landscape layout, readability, and performance on a real Android phone.
6. Alpha testing, balance work, and network load testing.
7. Consider PvP matchmaking, ranked play, and additional platforms after validation.

The sequence and scope may change based on playtest results and technical validation.

## Originality and Asset Provenance

The project is intended to be an original intellectual property. It may draw on high-level strategy-game ideas, but it must not use another game's code, maps, art, UI, audio, characters, names, or other proprietary materials. Shipped assets should have documented sources, licences, and approvals.

## Reference

The design brief cites [a Warcraft III custom-map gameplay video](https://www.youtube.com/watch?v=zK5bsGxLxic&list=PLFugRJGpmJHt8SaGfvce6VId4tURO9eK1) as a high-level gameplay reference. It is not a source of assets or implementation material.

## Repository Contents

The `game/` directory contains a Godot 4 3D 1v1 prototype with a gold-funded recruit queue, touch unit selection/movement, eight mirrored construction plots, three upgradeable structures, gold/wood/food rules, adaptive AI counter-picks, automatic waves, and King-only victory. Match flow lives in `game/scripts/main.gd`, 3D scene construction in `game/scripts/arena_view.gd`, and the interface in `game/scripts/battle_hud.gd`. Hero profiles and portraits in `game/heroes/` are original SVG artwork; battlefield units and buildings are procedural original 3D models and still need production-quality art.
