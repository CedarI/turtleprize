# Turtle Mining System

Advanced Minecraft ComputerCraft turtle mining system with multiple strategies and remote monitoring for ATM10 modpack.

## Features
- **Multiple Mining Strategies**: Branch mining (most efficient), Hybrid, and Shaft mining
- **Smart Fuel Management**: Supports coal, charcoal, coal blocks, lava buckets, wood items
- **Remote Monitoring**: Real-time status updates and remote recall capability
- **Inventory Management**: Automatic junk disposal, ender chest support, essential item protection
- **Ore Vein Following**: Intelligent ore detection and thorough mining of entire veins
- **Safety Features**: Critical fuel handling, pre-flight checks, emergency base return
- **Statistics Tracking**: Blocks mined, ores found, distance traveled

## Quick Start

### Base Setup
```
[Fuel Chest] ← [Turtle] → [ ]
                   ↓
              [Main Chest]
```

1. Place turtle at desired (0,0,0) coordinate
2. Place **main chest** behind turtle (south) for mined items
3. Place **fuel chest** to left of turtle (west) for coal/charcoal
4. Run monitor on a computer: `monitor`
5. Start mining: `miner <width> <length> [strategy]`

### Example Commands
```bash
miner 32 64 branch    # 32x64 area with branch mining (recommended)
miner 16 32 hybrid    # Smaller area with hybrid approach
miner 24 48 shaft     # Traditional shaft mining
```

## Mining Strategies

### Branch Mining (Recommended)
- Mines horizontal tunnels at optimal Y-levels (-54, -50, -46, etc.)
- Most efficient for ore discovery (3-4x better than shaft mining)
- Stays underground, minimizing travel time
- Best for large-scale operations

### Hybrid Mining  
- Combines vertical shafts with horizontal branches at key levels
- Good balance between coverage and efficiency
- Creates access shafts every 8 blocks with 6-block branches

### Shaft Mining
- Traditional surface-to-bedrock mining
- Improved spacing pattern covers more area
- Good for smaller areas or when you need complete coverage

## Fuel Management

The turtle intelligently handles multiple fuel types:
- **Coal & Charcoal**: 80 fuel units each (completely interchangeable)
- **Coal Blocks**: 800 fuel units (most efficient)  
- **Lava Buckets**: 1000 fuel units (excellent for long operations)
- **Wood Items**: 5–15 fuel units (emergency backup)

### Critical Fuel Handling
When fuel drops below 100 units:
1. Turtle automatically returns to base
2. Waits at base checking fuel chest every 5 seconds
3. Auto-resumes mining when fuel reaches 500+ units
4. Never gets stranded underground

## Requirements

### Hardware
- ComputerCraft turtle with wireless modem
- Computer with wireless modem (for monitoring)
- 2 chests (main storage + fuel storage)

### Supplies
- Fuel: coal, charcoal, coal blocks, or lava buckets
- Empty bucket (recommended for lava refueling)
- Optional: Ender chest (for remote inventory management)

### Software Setup
1. Set the `HOME_BASE_ID` in `miner.lua` to match your monitor computer's ID
2. Both turtle and monitor computer need wireless modems
3. Ensure computers are within wireless range

## Advanced Features

### Pre-Flight Check
Automatically verifies before starting:
- Adequate fuel levels (recommends 1000+ units)
- Fuel available in inventory
- Essential items present (buckets, ender chests)
- Shows detailed fuel inventory breakdown

### Remote Monitoring
- Real-time position, fuel, and inventory tracking
- Progress monitoring with completion percentages
- Remote recall capability (press 'r' on monitor)
- Statistics display (ores found, blocks mined, distance traveled)

### Inventory Management  
- **Smart Junk Disposal**: Automatically drops stone, dirt, gravel, etc.
- **Essential Item Protection**: Never drops buckets, ender chests, or fuel
- **Ender Chest Support**: Uses ender chests for remote item storage
- **Inventory Consolidation**: Automatically stacks similar items

### Ore Detection
- **6-Direction Scanning**: Checks up, down, and all horizontal directions
- **Vein Following**: Intelligently follows ore veins to mine completely  
- **Thorough Mining**: Mines blocks above and below ore deposits
- **ATM10 Ore Support**: Includes all common modded ores

## Troubleshooting

### Common Issues
- **"No wireless modem found"**: Ensure both turtle and monitor have wireless modems
- **"WAITING FOR FUEL"**: Add coal/charcoal to the fuel chest (left of turtle)
- **Turtle gets stuck**: Use remote recall ('r' on monitor) to bring it home
- **No status updates**: Check HOME_BASE_ID matches monitor computer ID

### Performance Tips
- Use coal blocks instead of individual coal for 10x efficiency
- Keep ender chest in inventory for long mining sessions
- Branch mining strategy is most efficient for ore discovery
- Monitor fuel levels - turtle returns automatically when low

## File Structure
- `miner.lua` - Main turtle mining program
- `monitor.lua` - Remote monitoring and control system

## License
MIT License - See LICENSE file for details