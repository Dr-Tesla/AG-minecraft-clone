# ==============================================================================
# Hotbar - UI Widget for Block Selection
# ==============================================================================
# Displays available block types and highlights the currently selected one.
# ==============================================================================

class_name Hotbar
extends Control

# Colors for the UI
const COLOR_BG := Color(0, 0, 0, 0.4)
const COLOR_SELECTED := Color(1, 1, 1, 0.8)
const COLOR_NORMAL := Color(0.2, 0.2, 0.2, 0.6)

# UI Elements
var slots_container: HBoxContainer = null
var slot_panels: Array[PanelContainer] = []
var active_index: int = 0

# Block names mapping
const BLOCK_NAMES = {
	Block.Type.DIRT: "Dirt",
	Block.Type.GRASS: "Grass",
	Block.Type.STONE: "Stone"
}

func _ready() -> void:
	# Make this control fill the screen so children can anchor properly
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_ui()

func _create_ui() -> void:
	var screen_size := get_viewport_rect().size
	
	# Background panel for the hotbar
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 70)
	# Center horizontally, 20px from bottom
	panel.position = Vector2((screen_size.x - 300) / 2, screen_size.y - 90)
	
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	# HBox for slots
	slots_container = HBoxContainer.new()
	slots_container.add_theme_constant_override("separation", 10)
	slots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(slots_container)
	
	# Create slots for available blocks
	var blocks = [Block.Type.DIRT, Block.Type.GRASS, Block.Type.STONE]
	for i in range(blocks.size()):
		_create_slot(blocks[i], i)
	
	update_selection(0)

func _create_slot(block_type: Block.Type, index: int) -> void:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(60, 60)
	
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_NORMAL
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.2)
	slot.add_theme_stylebox_override("panel", style)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(vbox)
	
	var label := Label.new()
	label.text = BLOCK_NAMES.get(block_type, "???")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(label)
	
	# Shortcut number
	var shortcut := Label.new()
	shortcut.text = str(index + 1)
	shortcut.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shortcut.add_theme_font_size_override("font_size", 10)
	shortcut.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	slot.add_child(shortcut)
	
	slots_container.add_child(slot)
	slot_panels.append(slot)

# Update visual selection
func update_selection(index: int) -> void:
	active_index = index
	for i in range(slot_panels.size()):
		var style := slot_panels[i].get_theme_stylebox("panel") as StyleBoxFlat
		if i == index:
			style.bg_color = Color(0.4, 0.4, 0.6, 0.8)
			style.border_color = Color(1, 1, 1, 1)
		else:
			style.bg_color = COLOR_NORMAL
			style.border_color = Color(1, 1, 1, 0.2)
