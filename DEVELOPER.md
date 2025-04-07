# Tiny Tower - Developer Documentation

This document provides comprehensive information for developers working on the Godot version of Tiny Tower. It covers the project architecture, code organization, and implementation details to help you understand and extend the codebase.

## Project Architecture

### Overview

Tiny Tower is built using Godot 4.2 and is structured as a 3D physics-based puzzle game. The architecture follows Godot's scene-based approach with the following key components:

1. **Managers**: Singleton autoload scripts that handle global game state and functionality
2. **Scenes**: Modular game screens and UI components
3. **Objects**: Physics-based entities (blocks, etc.)
4. **UI Components**: User interface elements

### Directory Structure

```
godot-tiny-tower/
├── assets/
│   ├── fonts/              # Game fonts
│   ├── icons/              # App icons
│   ├── levels/             # Level definition JSON files
│   ├── music/              # Background music tracks
│   ├── sounds/
│   │   ├── game/           # Gameplay sound effects
│   │   └── ui/             # UI sound effects
│   └── textures/
│       ├── blocks/         # Block textures and materials
│       ├── environment/    # Environment textures
│       └── ui/             # UI elements and icons
├── scenes/
│   ├── environment.tres    # Default environment resource
│   ├── game_screen.tscn    # Main gameplay scene
│   ├── level_complete.tscn # Level completion screen
│   ├── level_select.tscn   # Level selection screen 
│   ├── main_menu.tscn      # Main menu scene
│   ├── objects/            # Reusable game object scenes
│   │   └── block.tscn      # Block scene
│   └── ui/                 # UI component scenes
│       ├── block_button.tscn  # Block selection button
│       ├── level_button.tscn  # Level selection button
│       └── settings_panel.tscn # Settings panel
├── scripts/
│   ├── managers/           # Global singleton scripts
│   │   ├── data_manager.gd   # Save/load functionality
│   │   ├── game_manager.gd   # Game state management
│   │   ├── level_manager.gd  # Level loading/progression
│   │   └── sound_manager.gd  # Audio management
│   ├── objects/            # Game object scripts
│   │   └── block.gd          # Block physics and behavior
│   ├── scenes/             # Scene controller scripts
│   │   ├── game_screen.gd    # Main gameplay controller
│   │   ├── level_select.gd   # Level selection logic
│   │   └── main_menu.gd      # Main menu controller
│   ├── screens/            # Full-screen UI controllers
│   │   └── level_complete.gd # Level completion controller
│   └── ui/                 # UI component scripts
│       ├── block_button.gd   # Block selection button
│       ├── game_hud.gd       # In-game HUD
│       └── level_button.gd   # Level selection button
└── project.godot           # Godot project file
```

## Core Systems

### Game State Management

The game state is managed through the `GameManager` singleton which handles:

- Game states (menu, playing, paused, game over, level complete)
- Scoring and move counting
- Timer functionality
- Level completion logic

```gdscript
# Example of state management in GameManager
func set_state(new_state: int) -> void:
    if current_state != new_state:
        current_state = new_state
        emit_signal("game_state_changed", current_state)
        
        # Handle state-specific actions
        match current_state:
            GameState.PLAYING:
                Engine.time_scale = config.game_speed
                timer_running = true
            GameState.PAUSED:
                Engine.time_scale = 0.0
                timer_running = false
```

### Level System

Levels are defined in JSON files located in `assets/levels/`. Each level specifies:

- Level metadata (ID, name, description)
- Star requirements
- Block configurations
- Win conditions
- Physics properties

The `LevelManager` handles loading these files and tracking player progress.

```json
{
  "id": "level-1",
  "name": "Tutorial",
  "description": "Learn how to stack blocks to build a tower",
  "min_score": 100,
  "time_limit": 120,
  "star_requirements": [100, 200, 300],
  "blocks": [
    {
      "id": "ground",
      "type": "stone",
      "position": [0, 0, 0],
      "rotation": [0, 0, 0],
      "size": [10, 0.5, 10],
      "is_static": true
    }
  ],
  "available_blocks": ["wood", "stone"],
  "win_condition": {
    "type": "height",
    "value": 5
  },
  "physics": {
    "gravity": 25.0,
    "friction": 0.8,
    "restitution": 0.1
  }
}
```

### Physics System

The physics system is built on Godot's physics engine. The `Block` class (`scripts/objects/block.gd`) is the core physics entity:

- Implements different material types (wood, stone, metal, ice, etc.)
- Handles collision detection and response
- Manages block stability detection
- Controls visual appearance based on block type

```gdscript
# Block types with their properties
const BLOCK_TYPES = {
    "wood": {
        "mass": 2.0,
        "friction": 0.7,
        "restitution": 0.3,
        "color": Color(0xa0, 0x6d, 0x43),
        "emissive": false,
        "texture": "res://assets/textures/blocks/wood.png",
        "sound_type": "wood"
    },
    "stone": {
        "mass": 5.0,
        "friction": 0.8,
        "restitution": 0.2,
        "color": Color(0x8c, 0x8c, 0x8c),
        "emissive": false,
        "texture": "res://assets/textures/blocks/stone.png",
        "sound_type": "stone"
    },
    // Other block types...
}
```

### Save System

Game progress is saved using Godot's `FileAccess` system:

- Level completion status
- Star ratings
- High scores
- Settings

The `DataManager` singleton handles saving and loading this data.

## Game Flow

1. **Game Startup**:
   - `project.godot` defines autoloaded singletons
   - Main menu scene is loaded as the starting scene

2. **Level Selection**:
   - Player selects a level from the level select screen
   - `LevelManager` loads the corresponding level data
   - Game screen is loaded and initialized with level data

3. **Gameplay**:
   - Player places blocks to build a tower
   - Physics simulation runs continuously
   - Game checks win conditions based on level data
   - UI updates with score, moves, and time

4. **Level Completion**:
   - Win condition is detected by game screen
   - `GameManager` handles level completion logic
   - Level results are displayed (score, stars, etc.)
   - Progress is saved via `DataManager`

## Signal Communication

Godot's signal system is used extensively for decoupled communication between components:

```gdscript
# In GameManager
signal game_state_changed(state)
signal score_updated(score)

# In a UI component that listens for these signals
func _ready():
    GameManager.game_state_changed.connect(_on_game_state_changed)
    GameManager.score_updated.connect(_on_score_updated)
```

## Key Implementations

### Block Placement

The block placement system works as follows:

1. Preview block follows mouse cursor using raycasting
2. Player clicks to place the block
3. Physical block is created at the position of the preview
4. Block becomes affected by physics
5. Stability is checked after a delay to see if the tower remains standing

```gdscript
# Place the current block in the world
func place_current_block():
    # Create a new physical block at the position of the preview
    current_block = BlockScene.instantiate()
    current_block.block_type = preview_block.block_type
    current_block.custom_size = preview_block.custom_size
    current_block.global_position = preview_block.global_position
    current_block.global_rotation = preview_block.global_rotation
    
    # Place the block and make it physical
    current_block.place()
    
    # Add score based on height
    var height_score = int(current_block.global_position.y * 10.0)
    GameManager.add_score(height_score)
```

### Block Stability Detection

Blocks need to detect when they've stabilized:

```gdscript
# Check if block has settled (stopped moving)
func is_settled() -> bool:
    return linear_velocity.length() < velocity_threshold and angular_velocity.length() < angular_velocity_threshold

# Called every physics frame
func _physics_process(_delta):
    if not is_preview and not is_static and is_placed and not is_stable:
        if is_settled():
            if not stable_timer.is_started():
                stable_timer.start()
        else:
            if stable_timer.is_started():
                stable_timer.stop()
```

## Custom UI Framework

The game uses custom UI components created with Godot's Control nodes. Key components include:

- `level_button.gd`: Displays level information and handles selection
- `block_button.gd`: Allows selection of different block types during gameplay
- `game_hud.gd`: In-game UI showing score, time, and controls

## Testing

### Testing Levels

To test a specific level directly, you can:

1. Open `game_screen.tscn`
2. Run the scene directly
3. In the debugger, call:
   ```gdscript
   var level_data = LevelManager.load_level("level-1")
   get_node("/root/GameScreen").load_level(level_data)
   ```

### Physics Debugging

For debugging physics issues:

1. Enable "Visible Collision Shapes" in the Debug menu
2. Use Godot's built-in physics debugging tools
3. Add print statements to track velocities and collisions

## Adding New Features

### Adding New Block Types

To add a new block type:

1. Add its properties to the `BLOCK_TYPES` dictionary in `block.gd`
2. Create corresponding textures in `assets/textures/blocks/`
3. Update UI to include the new block type

### Creating New Levels

To create a new level:

1. Create a new JSON file in `assets/levels/` (e.g., `level-4.json`)
2. Define level properties following the established format
3. Test the level by loading it in the game

### Adding New Win Conditions

To add a new win condition type:

1. Extend the `check_win_condition()` function in `game_screen.gd`
2. Add the new condition type to the match statement
3. Implement the condition checking logic

## Performance Considerations

- Limit the number of active physics objects (blocks) to maintain performance
- Use LOD (Level of Detail) for blocks far from the camera
- Consider freezing blocks that have been stable for extended periods

## Common Issues and Solutions

### Physics Glitches

If blocks behave erratically:
- Check collision shapes for proper sizing
- Adjust physics parameters (gravity, friction)
- Increase physics steps in project settings

### Memory Management

For larger levels with many blocks:
- Implement object pooling for blocks
- Consider removing blocks that fall below a certain threshold

## Tools and Utilities

### Debug Console

The game includes a hidden debug console (press <kbd>~</kbd> to open):
- Run commands to modify game state
- Spawn objects for testing
- Toggle debug visualization

### Level Editor

A future update will include a level editor:
- Create and edit levels visually
- Test levels directly
- Export levels to JSON format

## Contribution Guidelines

1. Use consistent code formatting (follow existing style)
2. Document new functions and classes
3. Add comments for complex logic
4. Test changes thoroughly before submitting
5. Update this documentation for significant changes

---

## Appendix A: Block Properties Reference

| Block Type | Mass | Friction | Restitution | Special Properties |
|------------|------|----------|-------------|-------------------|
| Wood       | 2.0  | 0.7      | 0.3         | None              |
| Stone      | 5.0  | 0.8      | 0.2         | None              |
| Metal      | 8.0  | 0.6      | 0.5         | None              |
| Ice        | 1.5  | 0.1      | 0.8         | Slippery surface  |
| Glass      | 1.8  | 0.5      | 0.6         | Semi-transparent  |
| Rubber     | 1.0  | 0.9      | 0.9         | High bounce       |

## Appendix B: Signal Reference

| Source Object    | Signal               | Parameters          | Description                            |
|------------------|----------------------|---------------------|----------------------------------------|
| GameManager      | game_state_changed   | state               | Emitted when game state changes        |
|                  | score_updated        | score               | Emitted when score changes             |
|                  | moves_updated        | moves               | Emitted when moves count changes       |
|                  | timer_updated        | time                | Emitted when timer updates             |
| LevelManager     | levels_loaded        | levels              | Emitted when all levels are loaded     |
|                  | level_loaded         | level_data          | Emitted when a specific level is loaded|
| Block            | block_placed         |                     | Emitted when a block is placed         |
|                  | block_hit            | other_block         | Emitted when blocks collide            |
|                  | block_settled        | is_stable           | Emitted when a block stabilizes        |
| GameScreen       | game_over            |                     | Emitted on game over                   |
|                  | level_complete       | score, moves, time, stars | Emitted when level is completed  |
