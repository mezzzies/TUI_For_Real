extends Control

signal card_selected(card_node)
signal drag_started(card_node)
signal drag_ended(card_node, drop_position)

@onready var viewport_container = $CardTexture
@onready var shadow_container = $CardShadow
@onready var card_content = $SubViewport/CardContent
@onready var frame = $SubViewport/CardContent/Frame
@onready var name_label = $SubViewport/CardContent/Margin/VBox/Header/Name
@onready var cost_label = $SubViewport/CardContent/Margin/VBox/Header/Cost
@onready var type_label = $SubViewport/CardContent/Margin/VBox/TypeLabel
@onready var image_rect = $SubViewport/CardContent/Margin/VBox/CardImage
@onready var desc_label = $SubViewport/CardContent/Margin/VBox/Description
@onready var stats_container = $SubViewport/CardContent/Margin/VBox/Stats
@onready var atk_label = $SubViewport/CardContent/Margin/VBox/Stats/Atk
@onready var hp_label = $SubViewport/CardContent/Margin/VBox/Stats/Hp


var card_data = {}
var is_hovered = false
var is_selected = false

# Dragging variables
var is_pressed = false
var is_dragging = false
var drag_start_mouse_pos = Vector2.ZERO
var drag_start_content_pos = Vector2.ZERO

# Rotations for the 3D perspective hover effect
var target_x_rot = 0.0
var target_y_rot = 0.0
var current_x_rot = 0.0
var current_y_rot = 0.0
var hand_rotation = 0.0

# Store original base position for hover offset
var base_pos_y = 0.0

func _ready() -> void:
	# Enable mouse filter to receive inputs
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect mouse interactions directly to root Control
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Set up dynamic shader material properties
	if viewport_container and viewport_container.material is ShaderMaterial:
		viewport_container.material = viewport_container.material.duplicate()
		# Set inset to prevent texture clipping at extreme rotation angles
		viewport_container.material.set_shader_parameter("inset", 0.08)
		
	if shadow_container and shadow_container.material is ShaderMaterial:
		shadow_container.material = shadow_container.material.duplicate()
		shadow_container.material.set_shader_parameter("inset", 0.08)
		shadow_container.material.set_shader_parameter("is_shadow", true)
		shadow_container.material.set_shader_parameter("shadow_alpha", 0.45)
	
	# Initial setup of visuals if data exists
	if not card_data.is_empty():
		setup_card(card_data)

func setup_card(data: Dictionary) -> void:
	card_data = data
	
	# Set texts
	name_label.text = data.get("name", "Card Name")
	cost_label.text = str(data.get("cost", 0))
	type_label.text = data.get("type", "Unit").to_upper()
	desc_label.text = data.get("description", "")
	
	# Setup type-specific visuals
	var card_type = data.get("type", "Unit")
	if card_type == "Unit":
		stats_container.visible = true
		atk_label.text = "ATK: " + str(data.get("atk", 0))
		hp_label.text = "HP: " + str(data.get("hp", 0))
	else:
		stats_container.visible = false
		
	# Setup card color frame
	var frame_style = frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if frame_style:
		var theme_color = data.get("color", Color(0.2, 0.2, 0.2))
		frame_style.border_color = theme_color
		# Preserve the editor's configured background color (e.g. white)
		frame.add_theme_stylebox_override("panel", frame_style)
		
	# Temporary card art placeholder color
	var image_style = StyleBoxFlat.new()
	var theme_color = data.get("color", Color(0.2, 0.2, 0.2))
	image_style.bg_color = Color(theme_color.r * 0.3, theme_color.g * 0.3, theme_color.b * 0.3, 0.6)
	image_style.corner_radius_top_left = 4
	image_style.corner_radius_top_right = 4
	image_style.corner_radius_bottom_left = 4
	image_style.corner_radius_bottom_right = 4
	image_rect.add_theme_stylebox_override("panel", image_style)

func set_selected(selected: bool) -> void:
	is_selected = selected
	var frame_style = frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if frame_style:
		if is_selected:
			frame_style.border_width_left = 4
			frame_style.border_width_top = 4
			frame_style.border_width_right = 4
			frame_style.border_width_bottom = 4
			frame_style.shadow_color = Color(1.0, 0.8, 0.2, 0.5)
			frame_style.shadow_size = 12
		else:
			frame_style.border_width_left = 2
			frame_style.border_width_top = 2
			frame_width_restore(frame_style)
		frame.add_theme_stylebox_override("panel", frame_style)

func frame_width_restore(style: StyleBoxFlat) -> void:
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_size = 0

func _process(delta: float) -> void:
	# Fan hand rotation lerping
	var target_rot = 0.0 if (is_hovered or is_dragging) else hand_rotation
	rotation = lerp(rotation, target_rot, 10.0 * delta)

	# Compute target tilt angles on hover (only when not dragging)
	if is_hovered and not is_dragging:
		var mouse_pos = get_local_mouse_position()
		var center = size / 2.0
		var offset = mouse_pos - center
		
		# Normalize offset into [-1.0, 1.0] range
		var norm_x = clamp(offset.x / center.x, -1.0, 1.0)
		var norm_y = clamp(offset.y / center.y, -1.0, 1.0)
		
		# Set target rotation angles (max tilt is 22 degrees)
		target_x_rot = -norm_y * 22.0
		target_y_rot = norm_x * 22.0
	else:
		# Return to flat perspective
		target_x_rot = 0.0
		target_y_rot = 0.0
		
	# Smoothly interpolate rotation parameters
	current_x_rot = lerp(current_x_rot, target_x_rot, 15.0 * delta)
	current_y_rot = lerp(current_y_rot, target_y_rot, 15.0 * delta)
	
	# Apply uniforms to ShaderMaterial
	if viewport_container and viewport_container.material is ShaderMaterial:
		viewport_container.material.set_shader_parameter("x_rot", current_x_rot)
		viewport_container.material.set_shader_parameter("y_rot", current_y_rot)
	if shadow_container and shadow_container.material is ShaderMaterial:
		shadow_container.material.set_shader_parameter("x_rot", current_x_rot)
		shadow_container.material.set_shader_parameter("y_rot", current_y_rot)
		
	if is_dragging:
		shadow_container.position = viewport_container.position + Vector2(25.0, 45.0)
		shadow_container.scale = viewport_container.scale * 0.95

func _on_mouse_entered() -> void:
	if is_pressed:
		return
	is_hovered = true
	# Bring card visual to front
	z_index = 5
	
	# Set pivot center for scaling
	viewport_container.pivot_offset = viewport_container.size / 2.0
	shadow_container.pivot_offset = shadow_container.size / 2.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(viewport_container, "scale", Vector2(1.15, 1.15), 0.2)
	tween.tween_property(viewport_container, "position:y", base_pos_y - 40.0, 0.2)
	
	# Lift shadow
	tween.tween_property(shadow_container, "scale", Vector2(1.08, 1.08), 0.2)
	tween.tween_property(shadow_container, "position", Vector2(15.0, base_pos_y + 25.0), 0.2)
	if shadow_container.material is ShaderMaterial:
		tween.tween_method(
			func(val): shadow_container.material.set_shader_parameter("shadow_alpha", val),
			0.45, 0.22, 0.2
		)

func _on_mouse_exited() -> void:
	if is_pressed or is_dragging:
		return
	is_hovered = false
	if not is_selected:
		z_index = 0
		
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(viewport_container, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(viewport_container, "position:y", base_pos_y, 0.2)
	
	# Restore shadow
	tween.tween_property(shadow_container, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(shadow_container, "position", Vector2(0.0, base_pos_y + 4.0), 0.2)
	if shadow_container.material is ShaderMaterial:
		tween.tween_method(
			func(val): shadow_container.material.set_shader_parameter("shadow_alpha", val),
			0.22, 0.45, 0.2
		)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressed = true
			is_dragging = false
			drag_start_mouse_pos = get_global_mouse_position()
			drag_start_content_pos = viewport_container.position
			viewport_container.pivot_offset = viewport_container.size / 2.0
			accept_event()
		else:
			if is_pressed:
				is_pressed = false
				if is_dragging:
					is_dragging = false
					drag_ended.emit(self, get_global_mouse_position())
				else:
					card_selected.emit(self) # simple click
				accept_event()
				
	elif event is InputEventMouseMotion and is_pressed:
		var distance = get_global_mouse_position().distance_to(drag_start_mouse_pos)
		if not is_dragging and distance > 8.0:
			is_dragging = true
			z_index = 30 # Spawn over other elements
			drag_started.emit(self)
			# Scale up slightly on drag start
			var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(viewport_container, "scale", Vector2(1.1, 1.1), 0.15)
			tween.tween_property(viewport_container, "modulate", Color(1.1, 1.1, 0.95), 0.15)
			
			# Lift shadow on drag start
			tween.tween_property(shadow_container, "scale", Vector2(1.05, 1.05), 0.15)
			if shadow_container.material is ShaderMaterial:
				tween.tween_method(
					func(val): shadow_container.material.set_shader_parameter("shadow_alpha", val),
					0.45, 0.18, 0.15
				)
			
		if is_dragging:
			# Move visual card content to follow mouse delta
			viewport_container.position = drag_start_content_pos + (get_global_mouse_position() - drag_start_mouse_pos)
			accept_event()

func return_to_hand() -> void:
	z_index = 0
	is_pressed = false
	is_dragging = false
	is_hovered = false
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(viewport_container, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(viewport_container, "position", Vector2(0, base_pos_y), 0.2)
	tween.tween_property(viewport_container, "modulate", Color(1.0, 1.0, 1.0), 0.2)
	
	# Return shadow to hand
	tween.tween_property(shadow_container, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(shadow_container, "position", Vector2(0.0, base_pos_y + 4.0), 0.2)
	if shadow_container.material is ShaderMaterial:
		tween.tween_method(
			func(val): shadow_container.material.set_shader_parameter("shadow_alpha", val),
			0.18, 0.45, 0.2
		)
