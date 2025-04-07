# Tiny Tower - Godot Edition

This is a port of the Tiny Tower game from React/Three.js to Godot Engine using GDScript, with a twist - now transformed into a Jenga-style block removal game. Instead of building towers, players must carefully remove blocks from pre-built structures without causing them to collapse.

## About the Port & Gameplay Revamp

### Why Godot?

Godot Engine offers several advantages for a physics-based game like Tiny Tower:

1. **Native Physics Engine**: Godot's built-in 3D physics engine provides more stable and consistent physics simulation compared to the web-based Cannon.js used in the original React version.

2. **Performance**: As a native application, the Godot version can deliver better performance, especially on lower-end devices.

3. **Cross-Platform**: Godot makes it easy to build for multiple platforms (Windows, macOS, Linux, mobile) from a single codebase.

4. **Simplified Development**: The port eliminates the TypeScript complexities and React component lifecycle issues that were causing blocks to unmount/remount unexpectedly in the original version.

### New Gameplay Mechanics

The game now focuses on strategic block removal rather than tower building:

- **Pre-built Towers**: Each level starts with a pre-built tower structure
- **Block Selection**: Players select which blocks to remove from the structure
- **Physics Challenges**: Removing blocks affects the tower's stability in realistic ways
- **Risk vs. Reward**: Players must balance removing more blocks (higher score) with the risk of tower collapse
- **Strategic Thinking**: Different block materials and positions present unique challenges

## Project Structure

```
godot-tiny-tower/
├── assets/
│   ├── levels/          # JSON level definitions
│   ├── music/           # Background music tracks
│   ├── sounds/          # Sound effects
│   └── textures/        # Block and UI textures
├── scenes/
│   ├── main_menu.tscn   # Main menu scene
│   ├── level_select.tscn # Level selection scene
│   ├── game_screen.tscn # Main gameplay scene
│   └── ui/              # UI component scenes
├── scripts/
│   ├── managers/        # Game management scripts
│   ├── objects/         # Physics objects (blocks, etc.)
│   ├── scenes/          # Scene controllers
│   ├── screens/         # Screen controllers
│   └── ui/              # UI components scripts
└── project.godot        # Godot project file
```

## Key Components

### Manager Singletons

- **GameManager**: Handles game state, scoring, and level progression
- **LevelManager**: Loads and manages level data including tower configurations
- **SoundManager**: Manages sound effects and music
- **DataManager**: Handles saving/loading game progress

### Game Objects

- **Block**: The core physics object that players remove from towers
  - Different block types (wood, stone, metal, ice, glass, rubber)
  - Physics properties (mass, friction, restitution)
  - Visual appearance (colors, textures)

### Scenes

- **Main Menu**: Starting point with options to play, adjust settings, etc.
- **Level Select**: Browse and select levels to play
- **Game Screen**: Main gameplay where players remove blocks from towers
- **Level Complete**: Shows results after completing a level

## How to Open in Godot

1. Download and install [Godot Engine 4.2](https://godotengine.org/)
2. Open Godot Engine
3. Click "Import" and select the `project.godot` file in this directory
4. Click "Open"
5. Press F5 or click the "Play" button to run the game

## Development Notes

- The game uses Godot's built-in physics engine for realistic block interactions
- Tower configurations are defined in the level data, allowing for various tower designs
- Block selection and removal is handled through raycasting and physics interactions
- Game state is managed through Godot's signals (similar to events in React)

## Gameplay Mechanics

1. **Selection**: Click on a block to select it for removal
2. **Removal**: Confirm removal of the selected block
3. **Physics**: The tower will react realistically based on structural integrity
4. **Scoring**: Points are awarded based on how many blocks are successfully removed
5. **Stars**: Earn up to three stars based on blocks removed and tower height maintained

## Future Enhancements

- Additional tower configurations and block types
- Special blocks with unique properties (magnetic, explosive, etc.)
- Time-based challenges
- Mobile touch controls optimization
- Multiplayer competitive mode

---

Developed by: [Your Name]  
Original React version created by: [Original Author]
