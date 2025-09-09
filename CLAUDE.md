# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Underworld Tycoon** is a dual-economy city management simulation built in Godot 4.4+ where players act as a corrupt mayor managing both legitimate city services and illegal business operations. The core gameplay involves balancing public approval through city services while building a criminal empire and laundering money.

## Development Commands

### Running the Game
```bash
# Open project in Godot Editor
godot -e project.godot

# Run the game directly
godot project.godot

# Run in headless mode for testing
godot --headless --quit project.godot
```

### Git Workflow
```bash
# Development uses conventional commits with specific format
git commit -m "Add comprehensive mission system

- Created MissionSystem.gd with 5 mission types
- Missions track progress automatically
- Integration with existing game events

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to remote
git push origin main
```

### Save/Load Testing
```bash
# Save files are located at:
# user://saves/save_1.save through save_5.save
# Auto-save at user://saves/auto_save.save

# In-game shortcuts:
# F5 - Quick save
# F9 - Load menu
# Ctrl+S - Save menu
```

## Architecture Overview

### Singleton-Based Core Systems

The game uses Godot's autoload system for 7 core singletons that manage global state:

1. **GameManager** - Overall game state, pause/resume, game speed
2. **Economy** - Dual money system (clean/dirty), laundering, income multipliers
3. **CitySim** - City services, districts, approval ratings, service quality effects
4. **ShadowOps** - Illegal businesses, production chains, business types
5. **RiskSystem** - Heat accumulation, raids, investigations, police pressure
6. **EventBus** - Signal routing between systems, UI notifications
7. **TimeManager** - Day/night cycles, time progression, scheduled events

### Signal-Driven Communication

All systems communicate through EventBus signals rather than direct references:

```gdscript
# Emit events through EventBus
EventBus.building_placed.emit(building_data)
EventBus.notify_success("Building constructed!")

# Systems connect to relevant signals in _ready()
EventBus.building_placed.connect(_on_building_placed)
```

### Key System Interactions

- **Economy ↔ CitySim**: Service investments affect income multipliers
- **ShadowOps ↔ RiskSystem**: Business operations generate heat
- **CitySim ↔ RiskSystem**: Police investment reduces heat accumulation
- **All Systems ↔ EventBus**: Centralized event communication

### Building System Architecture

Buildings use a data-driven approach with three layers:

1. **Business Data** (ShadowOps): Type definitions, costs, income, heat generation
2. **Plot System** (BuildingPlots): 48 predefined locations across 4 districts with validation
3. **Visual Layer** (Main.gd): Creates Node2D representations with click handling

### Mission System

Dynamic mission generation with 5 types:
- **Build**: "Construct X buildings of type Y"
- **Money**: "Accumulate $X in dirty money"  
- **Heat**: "Keep heat below X% for Y days"
- **Survive**: "Survive X days without raids"
- **Diversify**: "Own one of each building type"

Missions auto-track progress and generate new objectives upon completion.

### Save System

Complete game state preservation including:
- All singleton data (economy, districts, services, heat)
- Building locations and metadata
- Mission progress and completion history  
- Plot occupation status
- 5 save slots with metadata (timestamp, playtime, game progress)

## Code Conventions

### Null Safety Pattern
The codebase uses defensive programming to avoid @onready null references:

```gdscript
# Instead of @onready var label: Label = $Path/To/Label
# Use dynamic finding with null checks:
var label = find_node_by_path("Path/To/Label") 
if label:
    label.text = "Safe update"
```

### Event Handling Priority
Building plots use Area2D with specific collision layers and priorities:

```gdscript
area.collision_layer = 2  # Buildings layer
area.priority = 10        # Higher than grid/world areas
area.set_pickable(true)   # Enable input
```

### Money Formatting
Consistent money display across UI:

```gdscript
func format_money(amount: float) -> String:
    if amount >= 1000000: return str(snapped(amount / 1000000.0, 0.1)) + "M"
    elif amount >= 1000: return str(snapped(amount / 1000.0, 0.1)) + "K"
    else: return str(int(amount))
```

### Service Investment Effects
Municipal services have real gameplay effects:

- **Transport**: Multiplies business income (up to +15%)
- **Police**: Reduces heat accumulation (up to -50%)  
- **Public Works**: Boosts city approval (up to +20)
- **Garbage**: Increases district prosperity (up to +20%)

### Building Types
8 business types with strategic tradeoffs:

| Type | Cost | Income | Heat | Special Effect |
|------|------|--------|------|----------------|
| Bar | 8K | 800 | +1.0 | Basic income |
| Club | 18K | 2000 | +3.0 | 2x income at night |
| Workshop | 15K | 800 | +2.0 | Produces illegal goods |
| NGO | 30K | 0 | -1.0 | Money laundering |
| Casino | 45K | 4500 | +5.0 | High risk/reward |
| Pawnshop | 12K | 900 | +2.0 | Steady medium income |
| Restaurant | 25K | 1200 | -0.5 | Legal front business |
| Garage | 18K | 1800 | +3.5 | Produces contraband |

## Current Development Status

**Progress: 19% Complete (10/53 roadmap tasks)**

### Phase 1 - Critical Mechanics (27% complete)
- ✅ Save/Load System (5/5 tasks)
- ✅ Mission System (4/4 tasks)  
- ⏳ Raids System (0/6 tasks)

### Phase 2 - Strategic Depth (30% complete)
- ✅ Municipal Investment Effects (6/6 tasks)
- ⏳ Electoral System (0/8 tasks)
- ⏳ Advanced Economy (0/6 tasks)

The next major implementation priority is the **Raids System** to provide meaningful consequences for high heat levels.

## Keyboard Shortcuts

- **WASD/Arrows**: Camera movement
- **Mouse Wheel**: Zoom in/out
- **Left Click**: Select building plots, place buildings
- **Right Click**: Cancel construction
- **Tab**: Switch between Legal/Illegal panels
- **Space**: Pause/Resume
- **H**: Toggle notification history
- **G**: Toggle enhanced grid overlay
- **F5**: Quick save
- **F9**: Load game menu
- **Ctrl+S**: Save game menu
- **ESC**: Cancel current action

## File Structure Patterns

```
src/scripts/
├── singletons/     # Global systems (autoloaded)
├── systems/        # Game mechanics (instantiated)
├── ui/            # User interface controllers
├── buildings/     # Building-specific logic
└── Main.gd        # Scene controller and game coordinator
```

Scene files (.tscn) are minimal - most logic lives in associated .gd scripts for easier version control and debugging.