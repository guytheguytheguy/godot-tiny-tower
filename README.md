# Tiny Tower - Godot Edition

This is a port of the Tiny Tower game from React/Three.js to Godot Engine using GDScript. The original web-based game has been fully reimplemented as a native application while preserving all the core gameplay mechanics and features.

## About the Port

### Why Godot?

Godot Engine offers several advantages for a physics-based game like Tiny Tower:

1. **Native Physics Engine**: Godot's built-in 3D physics engine provides more stable and consistent physics simulation compared to the web-based Cannon.js used in the original React version.

2. **Performance**: As a native application, the Godot version can deliver better performance, especially on lower-end devices.

3. **Cross-Platform**: Godot makes it easy to build for multiple platforms (Windows, macOS, Linux, mobile) from a single codebase.

4. **Simplified Development**: The port eliminates the TypeScript complexities and React component lifecycle issues that were causing blocks to unmount/remount unexpectedly in the original version.

### What Was Preserved

- Complete game mechanics and physics
- Level progression system with stars
- Block types with different physical properties
- Visual design and UI layout
- Sound effects and music

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
- **LevelManager**: Loads and manages level data
- **SoundManager**: Manages sound effects and music
- **DataManager**: Handles saving/loading game progress

### Game Objects

- **Block**: The core physics object that players stack to build towers
  - Different block types (wood, stone, metal, ice, glass, rubber)
  - Physics properties (mass, friction, restitution)
  - Visual appearance (colors, textures)

### Scenes

- **Main Menu**: Starting point with options to play, adjust settings, etc.
- **Level Select**: Browse and select levels to play
- **Game Screen**: Main gameplay where blocks are stacked
- **Level Complete**: Shows results after completing a level

## How to Open in Godot

1. Download and install [Godot Engine 4.2](https://godotengine.org/)
2. Open Godot Engine
3. Click "Import" and select the `project.godot` file in this directory
4. Click "Open"
5. Press F5 or click the "Play" button to run the game

## Development Notes

- The port uses Godot's built-in physics engine instead of Cannon.js
- Block rendering uses Godot's mesh rendering system instead of Three.js
- Game state is managed through Godot's signals (similar to events in React)
- Level data is stored in JSON format similar to the original game

## Comparison to Original React Version

This Godot port resolves several key issues from the original React/Three.js implementation:

1. **Stable Physics**: No more issues with blocks disappearing or physics objects being unmounted incorrectly
2. **No TypeScript Errors**: The original had various TypeScript integration issues with React Three Fiber
3. **Better Performance**: Native rendering and physics simulation instead of web-based
4. **Simplified Code Structure**: More direct game logic without React component lifecycle complications

## Future Enhancements

- Additional block types and level mechanics
- More advanced visual effects
- Mobile touch controls
- Multiplayer capabilities

---

Developed by: [Your Name]  
Original React version created by: [Original Author]
