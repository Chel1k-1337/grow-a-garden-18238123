# Roblox AutoBuy Script

An intelligent AutoBuy script for Roblox that automatically targets, teleports, and purchases items from shop menus.

## Features

- **Smart UI Interaction**: Automatically finds and interacts with Shop NPCs and stands using proximity prompts and click detectors.
- **Dynamic Element Tracking**: Tracks items by name, automatically finding the correct item cards, prices, and buy buttons even if the UI structure changes or scales.
- **VirtualInputManager Simulation**: Simulates physical mouse clicks and key presses to bypass standard exploit detection and ensure 100% accuracy on complex UI layouts (like scrolling frames and inset topbars).
- **Anti-Spam & Reliability**: Smart waits and validations ensure the script doesn't spam click, double-purchase, or get stuck if items are out of stock.

## How to Use

1. Load the script into your executor (e.g., Xeno, Synapse, Krnl).
2. Attach to the game.
3. Run the script. The script will automatically loop, handle the UI, and return to base when finished.

## Notes

- This script was specifically optimized to handle complex Roblox GUI offsets and custom ImageLabel button layouts.
- It includes automatic compensation for `GuiService` TopBar insets to ensure perfect pixel-accurate clicks.
