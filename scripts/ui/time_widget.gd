# ==============================================================================
# Time Widget - UI Display for Day/Night Cycle
# ==============================================================================
# Displays current time of day, day count, and day/night status.
# Place in top-right corner of screen.
# ==============================================================================

class_name TimeWidget
extends Control

# References
var day_night_cycle: DayNightCycle = null

# UI elements (created in code for simplicity)
var time_label: Label = null
var status_label: Label = null
var progress_bar: ProgressBar = null

func _ready() -> void:
	_create_ui()

func _create_ui() -> void:
	# Create a simple panel directly positioned in top-right
	var panel := PanelContainer.new()
	panel.position = Vector2(10, 10)
	panel.size = Vector2(150, 80)
	
	# Make panel semi-transparent
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	# VBox for layout
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Status label (Day/Night indicator)
	status_label = Label.new()
	status_label.text = "Day 1"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(status_label)
	
	# Time label
	time_label = Label.new()
	time_label.text = "06:00"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(time_label)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(130, 8)
	vbox.add_child(progress_bar)

func setup(cycle: DayNightCycle) -> void:
	day_night_cycle = cycle
	if day_night_cycle:
		day_night_cycle.time_changed.connect(_on_time_changed)
		_update_display()

func _on_time_changed(normalized_time: float, is_day: bool) -> void:
	_update_display()

func _update_display() -> void:
	if day_night_cycle == null:
		return
	
	var is_day := day_night_cycle.is_day()
	var day_num := day_night_cycle.get_day()
	var time_str := day_night_cycle.get_time_string()
	var progress := day_night_cycle.get_normalized_time()
	
	# Update status (sun/moon icon + day count)
	var icon := "☀" if is_day else "🌙"
	status_label.text = "%s Day %d" % [icon, day_num]
	
	# Update time
	time_label.text = time_str
	
	# Update progress bar
	progress_bar.value = progress
	
	# Color the progress bar based on time
	var bar_style := StyleBoxFlat.new()
	if is_day:
		bar_style.bg_color = Color(1.0, 0.8, 0.2)  # Golden/yellow
	else:
		bar_style.bg_color = Color(0.3, 0.3, 0.7)  # Dark blue
	bar_style.corner_radius_top_left = 4
	bar_style.corner_radius_top_right = 4
	bar_style.corner_radius_bottom_left = 4
	bar_style.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("fill", bar_style)
