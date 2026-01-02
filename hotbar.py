"""
hotbar.py - Block Selection Hotbar UI

Displays a row of block slots at the bottom of the screen.
Player can select blocks using number keys 1-9.
"""

from ursina import Entity, camera, color, Text, Quad
from voxel import BlockType


# List of placeable block types for the hotbar (excludes AIR)
HOTBAR_BLOCKS = [
    BlockType.GRASS,
    BlockType.DIRT,
    BlockType.STONE,
    BlockType.WOOD,
    BlockType.SAND,
    BlockType.COBBLESTONE,
    BlockType.PLANKS,
    BlockType.LEAVES,
]

# Block names for display
BLOCK_NAMES = {
    BlockType.GRASS: "Grass",
    BlockType.DIRT: "Dirt",
    BlockType.STONE: "Stone",
    BlockType.WOOD: "Wood",
    BlockType.SAND: "Sand",
    BlockType.COBBLESTONE: "Cobble",
    BlockType.PLANKS: "Planks",
    BlockType.LEAVES: "Leaves",
}

# Block colors for simple UI representation
BLOCK_COLORS = {
    BlockType.GRASS: color.green,
    BlockType.DIRT: color.brown,
    BlockType.STONE: color.gray,
    BlockType.WOOD: color.rgb(139, 90, 43),  # Dark brown
    BlockType.SAND: color.rgb(237, 201, 175),  # Tan
    BlockType.COBBLESTONE: color.rgb(100, 100, 100),  # Dark gray
    BlockType.PLANKS: color.rgb(180, 144, 90),  # Light brown
    BlockType.LEAVES: color.rgb(50, 120, 50),  # Dark green
}


class Hotbar(Entity):
    """
    Hotbar UI for block selection.
    
    Shows 8 block slots at the bottom of the screen.
    Selected slot is highlighted.
    """
    
    def __init__(self, **kwargs):
        super().__init__(parent=camera.ui, **kwargs)
        
        self.selected_index = 0
        self.slots = []
        self.slot_backgrounds = []
        self.selection_indicator = None
        
        # Create hotbar slots
        slot_size = 0.06
        slot_spacing = 0.07
        start_x = -slot_spacing * (len(HOTBAR_BLOCKS) - 1) / 2
        
        for i, block_type in enumerate(HOTBAR_BLOCKS):
            x_pos = start_x + i * slot_spacing
            
            # Slot background
            bg = Entity(
                parent=self,
                model='quad',
                scale=(slot_size, slot_size),
                position=(x_pos, -0.42),
                color=color.rgba(50, 50, 50, 180),
                z=0.1
            )
            self.slot_backgrounds.append(bg)
            
            # Block color indicator
            block_indicator = Entity(
                parent=self,
                model='quad',
                scale=(slot_size * 0.7, slot_size * 0.7),
                position=(x_pos, -0.42),
                color=BLOCK_COLORS.get(block_type, color.white),
                z=0
            )
            self.slots.append(block_indicator)
            
            # Slot number
            Text(
                text=str(i + 1),
                parent=self,
                position=(x_pos - slot_size/3, -0.42 + slot_size/3),
                scale=0.7,
                z=-0.1
            )
        
        # Selection indicator (highlight box)
        self.selection_indicator = Entity(
            parent=self,
            model='quad',
            scale=(slot_size + 0.01, slot_size + 0.01),
            position=(start_x, -0.42),
            color=color.white,
            z=0.2
        )
        
        # Selected block name
        self.block_name_text = Text(
            text=BLOCK_NAMES.get(HOTBAR_BLOCKS[0], ""),
            parent=self,
            origin=(0, 0),
            position=(0, -0.35),
            scale=0.8,
            z=-0.1
        )
        
        # Store start_x for position calculations
        self.start_x = start_x
        self.slot_spacing = slot_spacing
        
        self._update_selection()
    
    def select_slot(self, index: int) -> None:
        """Select a hotbar slot by index (0-7)."""
        if 0 <= index < len(HOTBAR_BLOCKS):
            self.selected_index = index
            self._update_selection()
    
    def get_selected_block(self) -> BlockType:
        """Get the currently selected block type."""
        return HOTBAR_BLOCKS[self.selected_index]
    
    def _update_selection(self) -> None:
        """Update the selection indicator position."""
        x_pos = self.start_x + self.selected_index * self.slot_spacing
        self.selection_indicator.position = (x_pos, -0.42)
        
        # Update block name
        block_type = HOTBAR_BLOCKS[self.selected_index]
        self.block_name_text.text = BLOCK_NAMES.get(block_type, "")
    
    def input(self, key):
        """Handle number key input for slot selection."""
        # Number keys 1-8
        if key in ['1', '2', '3', '4', '5', '6', '7', '8']:
            self.select_slot(int(key) - 1)
