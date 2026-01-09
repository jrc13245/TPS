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
- Configurable scale (0.3x - 2.0x)
- Toggle individual display elements on/off
- Option to hide frame when no target
- Position saved between sessions
- Customizable colors for all text elements
- Adjustable transparency/alpha for all elements
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
| `/tps scale <0.3-2.0>` | Set frame scale |
| `/tps show` | Show the frame |
| `/tps hide` | Hide the frame |
| `/tps config` | Show current settings |

### Display Toggles

| Command | Description |
|---------|-------------|
| `/tps title` | Toggle target name display |
| `/tps distance` | Toggle distance display |
| `/tps position` | Toggle behind/front display |
| `/tps los` | Toggle line of sight display |
| `/tps range` | Toggle melee/ranged display |
| `/tps hidenotarget` | Toggle auto-hide when no target |

### Color Customization

| Command | Description |
|---------|-------------|
| `/tps colors` | Show current color settings |
| `/tps color <element> <color>` | Set element color |

**Elements:** `title`, `distance`, `behind`, `front`, `los`, `nolos`, `melee`, `ranged`

**Available Colors:**
- Neutrals: `white`, `gray`, `black`, `brown`
- Warm: `red`, `coral`, `salmon`, `orange`, `peach`, `gold`, `yellow`
- Cool: `lime`, `mint`, `green`, `teal`, `cyan`, `sky`, `blue`
- Purple/Pink: `indigo`, `purple`, `violet`, `lavender`, `magenta`, `pink`

Use `default` or `reset` to restore the original color.

**Examples:**
```
/tps color behind cyan
/tps color front red
/tps color title white
/tps color melee default
```

### Alpha/Opacity Settings

| Command | Description |
|---------|-------------|
| `/tps alpha` | Show current alpha settings |
| `/tps alpha <element> <0-1>` | Set element opacity |

**Elements:** `background`, `border`, `title`, `distance`, `behind`, `front`, `los`, `nolos`, `melee`, `ranged`

Values range from `0` (invisible) to `1` (fully opaque).

**Examples:**
```
/tps alpha background 0.5
/tps alpha border 0.8
/tps alpha title 1.0
```

## Distance Notes

- Distance shown matches ranged spell tooltip ranges
- Melee range threshold: ≤2.00 yds = MELEE, >2.00 yds = RANGED
- This corresponds to the game's 5-yard melee range (different measurement methods)

## Default Colors

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
│      X.XX yds       │
│       BEHIND        │
│       IN LOS        │
│       MELEE       U │
└─────────────────────┘
```

- The `U` indicator appears when the frame is unlocked (draggable)
- The frame automatically resizes when display elements are toggled off

## License

Free to use and modify.
