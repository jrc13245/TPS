# TPS - Target Position Status

A World of Warcraft 1.12.1 addon that displays real-time target information including distance, position (behind/front), line of sight, and melee range status.

## Requirements

- **UnitXP_SP3** - Required for distance, LOS, and behind detection functions

## Features

- **Target Name** - Shows current target name
- **Distance** - Real-time distance to target (accurate for ranged spell ranges)
- **Position** - BEHIND (green) / FRONT (orange) indicator
- **Line of Sight** - IN LOS (light blue) / NO LOS (red) indicator
- **Range** - MELEE (yellow) / RANGED (purple) indicator

### Additional Features

- Movable and lockable frame
- Configurable scale (0.5x - 2.0x)
- Toggle individual display elements on/off
- Option to hide frame when no target
- Position saved between sessions
- Semi-transparent grey background

## Installation

1. Extract the `TPS` folder to `Interface/AddOns/`
2. Ensure `UnitXP_SP3_Addon` is also installed
3. Restart WoW or `/reload`

## Slash Commands

| Command | Description |
|---------|-------------|
| `/tps` | Show help |
| `/tps lock` | Lock the frame |
| `/tps unlock` | Unlock the frame (allows dragging) |
| `/tps toggle` | Toggle lock state |
| `/tps reset` | Reset position to center |
| `/tps scale <0.5-2.0>` | Set frame scale |
| `/tps show` | Show the frame |
| `/tps hide` | Hide the frame |
| `/tps config` | Show current settings |

### Display Toggles

| Command | Description |
|---------|-------------|
| `/tps distance` | Toggle distance display |
| `/tps position` | Toggle behind/front display |
| `/tps los` | Toggle line of sight display |
| `/tps range` | Toggle melee/ranged display |
| `/tps hidenotarget` | Toggle auto-hide when no target |

## Distance Notes

- Distance shown matches ranged spell tooltip ranges
- Melee range threshold: ≤2.00 yds = MELEE, >2.00 yds = RANGED
- This corresponds to the game's 5-yard melee range (different measurement methods)

## Colors

| Status | Color |
|--------|-------|
| Target Name | Gold |
| Distance | White |
| BEHIND | Green |
| FRONT | Orange |
| IN LOS | Light Blue |
| NO LOS | Red |
| MELEE | Yellow |
| RANGED | Purple |
| No Target (---) | Grey |

## Frame Layout

```
┌─────────────────────┐
│  Target: <name>     │
│  Distance: X.XX yds │
│       BEHIND        │
│       IN LOS        │
│       MELEE         │
│                   L │
└─────────────────────┘
```

The frame automatically resizes when display elements are toggled off.

## License

Free to use and modify.
