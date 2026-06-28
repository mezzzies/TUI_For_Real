extends Control

@onready var viewport_container = $CardTexture
@onready var shadow_container = $CardShadow
@onready var card_image = $SubViewport/CardContent/CardImage

var hover_sfx = preload("res://asset/sfx/type-click.mp3")
var click_sfx = preload("res://asset/sfx/shutter-click.mp3")

var is_hovered = false
var base_pos_y = 0.0
var is_selected = false
@onready var o_mark = $SubViewport/CardContent/OMark

# Rotations for the 3D perspective hover effect
var target_x_rot = 0.0
var target_y_rot = 0.0
var current_x_rot = 0.0
var current_y_rot = 0.0

func _ready() -> void:
	# Enable mouse filter to receive inputs
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect mouse interactions
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	# Set up dynamic shader material properties
	if viewport_container and viewport_container.material is ShaderMaterial:
		viewport_container.material = viewport_container.material.duplicate()
		viewport_container.material.set_shader_parameter("inset", 0.08)
		
	if shadow_container and shadow_container.material is ShaderMaterial:
		shadow_container.material = shadow_container.material.duplicate()
		shadow_container.material.set_shader_parameter("inset", 0.08)
		shadow_container.material.set_shader_parameter("is_shadow", true)
		shadow_container.material.set_shader_parameter("shadow_alpha", 0.45)

func setup_card(texture_path: String) -> void:
	card_image.texture = load(texture_path)

func _process(delta: float) -> void:
	# Compute target tilt angles on hover
	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		is_hovered = false
		target_x_rot = 0.0
		target_y_rot = 0.0
	elif is_hovered:
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

func _on_mouse_entered() -> void:
	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	_play_sfx_transient(hover_sfx)
	is_hovered = true
	# Bring card visual to front
	z_index = 5
	
	# Set pivot center for scaling
	viewport_container.pivot_offset = viewport_container.size / 2.0
	shadow_container.pivot_offset = shadow_container.size / 2.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(viewport_container, "scale", Vector2(1.15, 1.15), 0.2)
	tween.tween_property(viewport_container, "position:y", base_pos_y - 20.0, 0.2)
	
	# Lift shadow
	tween.tween_property(shadow_container, "scale", Vector2(1.08, 1.08), 0.2)
	tween.tween_property(shadow_container, "position", Vector2(8.0, base_pos_y + 12.0), 0.2)
	if shadow_container.material is ShaderMaterial:
		tween.tween_method(
			func(val): shadow_container.material.set_shader_parameter("shadow_alpha", val),
			0.45, 0.22, 0.2
		)

func _on_mouse_exited() -> void:
	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	is_hovered = false
	z_index = 0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(viewport_container, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(viewport_container, "position:y", base_pos_y, 0.2)
	
	# Restore shadow
	tween.tween_property(shadow_container, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(shadow_container, "position", Vector2(0.0, base_pos_y + 2.0), 0.2)
	if shadow_container.material is ShaderMaterial:
		tween.tween_method(
			func(val): shadow_container.material.set_shader_parameter("shadow_alpha", val),
			0.22, 0.45, 0.2
		)

func _on_gui_input(event: InputEvent) -> void:
	if mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_play_sfx_transient(click_sfx)
		set_selected(!is_selected)

func set_selected(value: bool) -> void:
	is_selected = value
	if o_mark:
		o_mark.visible = is_selected

func _play_sfx_transient(stream: AudioStream) -> void:
	if not stream: return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func reset_visuals() -> void:
	is_hovered = false
	z_index = 0
	target_x_rot = 0.0
	target_y_rot = 0.0
	current_x_rot = 0.0
	current_y_rot = 0.0
	
	if viewport_container:
		viewport_container.scale = Vector2.ONE
		viewport_container.position.y = base_pos_y
		if viewport_container.material is ShaderMaterial:
			viewport_container.material.set_shader_parameter("x_rot", 0.0)
			viewport_container.material.set_shader_parameter("y_rot", 0.0)
			
	if shadow_container:
		shadow_container.scale = Vector2.ONE
		shadow_container.position = Vector2(0.0, base_pos_y + 2.0)
		if shadow_container.material is ShaderMaterial:
			shadow_container.material.set_shader_parameter("x_rot", 0.0)
			shadow_container.material.set_shader_parameter("y_rot", 0.0)
			shadow_container.material.set_shader_parameter("shadow_alpha", 0.45)
