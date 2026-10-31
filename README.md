# The Wars Mobile

**Build smart, command precisely, and adapt before the next round breaks you.**

The Wars Mobile is a concept for an original, touch-first tactical strategy game. Players command a champion, develop a defence, manage limited resources, and adapt between timed combat rounds. The target is a readable, competitive mobile experience built around matches of roughly 10–20 minutes.

> **Project status:** Concept and pre-production. This repository does not yet contain a playable game or installation instructions.

## The Game

The Wars Mobile combines arena defence, base-building decisions, and direct champion control in a compact match:

1. Enter an arena with a champion, a core base, and limited resources.
2. Move and command the champion, place or upgrade defences, and use abilities.
3. Decide how to spend resources across defence, economy, and champion power.
4. Choose an upgrade between rounds as enemy pressure increases.
5. Finish the match and work toward a competitive ranked ladder.

Touch-first controls are planned: tap to select or target, tap terrain to move, and pinch to zoom. The interface aims to keep the essential strategy visible on a phone screen.

## Product Direction

- **Genre:** Tactical strategy / arena defence / champion command
- **Platform:** Android first; iOS considered after Android validation
- **Match target:** 10–20 minutes
- **Initial opponents:** AI opponents to test the core loop, pacing, and hero balance
- **Competitive direction:** PvP matchmaking and ranked progression after gameplay validation
- **Match sizes planned:** 1v1 through 4v4, with bots filling open slots where appropriate
- **Monetisation direction:** Cosmetic-focused; no in-match power sales planned

These are design goals, not features currently implemented.

## First Playable Goals

The planned vertical slice is intentionally small:

- One original arena and one controllable champion
- One player base, a barracks/defence building, and upgrade choices
- A small roster of allied and enemy units
- Resources, timed rounds, abilities, and AI opponents
- Mobile HUD, onboarding, local save data, and Android device testing
- Early balance telemetry and a networked 1v1 prototype

Live PvP matchmaking, ranked seasons, guilds, global chat, user-generated maps, and a large live-service backend are outside the first playable scope.

## Technology

- **Engine:** Godot 4
- **Game logic:** GDScript; C# only if later shown to be necessary
- **Target:** Android-first, using Godot's mobile or compatibility rendering path as appropriate
- **Tools planned:** Godot editor, VS Code, Git, and Android SDK tooling

## Development Roadmap

1. Discovery and pre-production
2. Core prototype with AI opponents
3. Original-content vertical slice
4. Alpha testing, balance work, and network load testing
5. Closed beta and player feedback
6. Android soft-launch candidate
7. Consider PvP matchmaking, ranked play, and additional platforms after validation

The sequence and scope may change based on playtest results and technical validation.

## Originality and Asset Provenance

The project is intended to be an original intellectual property. It may draw on high-level strategy-game ideas, but it must not use another game's code, maps, art, UI, audio, characters, names, or other proprietary materials. Shipped assets should have documented sources, licences, and approvals.

## Reference

The design brief cites [a Warcraft III custom-map gameplay video](https://www.youtube.com/watch?v=zK5bsGxLxic&list=PLFugRJGpmJHt8SaGfvce6VId4tURO9eK1) as a high-level gameplay reference. It is not a source of assets or implementation material.

## Repository Contents

This repository is being set up from a concept and planning document. Game code, production assets, and build instructions will be added as development begins.
