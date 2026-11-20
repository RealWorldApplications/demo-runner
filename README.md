# Gulf Stream Mini-Sub 🌊🚢

**GDG Tampa Bay — Dive into Game Development: Building 2D Web Games with Flutter & Flame**

A lightweight, zero-asset-dependency 2D endless ocean runner built from scratch with **Flutter** and the **Flame engine**. Everything you see and hear—the animated 4-frame yellow mini-submarine, deep ocean sunbeams, bioluminescent jellyfish, coral spires, particle bubble bursts, and retro hydro-thruster sound effects—is generated procedurally in Dart at runtime.

---

## Git Branch Structure

This repository is structured into two branches so attendees can code along smoothly during the live session:

| Branch | Purpose |
| :--- | :--- |
| `main` (alias: `starter`) | **Attendee Starter Project.** Dependencies, procedural audio synth, Mini-Sub sprite generator, and Flutter UI overlays are wired up, with guided `// TODO (Stage X)` markers where we code live together. |
| `completed` | **Full Working Solution.** Complete game code, particles, audio hooks, and passing widget tests. |

To switch between branches:
```bash
# Code along with the workshop
git checkout main

# Jump to the completed solution at any time
git checkout completed
```

---

## Quick Start

1. **Install dependencies**
   ```bash
   flutter pub get
   ```
2. **Run in Chrome**
   ```bash
   flutter run -d chrome
   ```
3. **Run tests**
   ```bash
   flutter test
   ```

---

## Controls

- **Tap / Click / `Space` / `↑` / `W`**: Fire hydro-thruster (swim upward)
- **`D`**: Toggle Flame hitbox debug outlines live (`debugMode`)
- **`M`**: Mute / unmute synthesized procedural sound effects

---

## Presenter & Attendee Step-by-Step Guide

Follow the full 60-minute step-by-step live coding script, speaker notes, and web optimization guide in [WORKSHOP_GUIDE.md](WORKSHOP_GUIDE.md).
