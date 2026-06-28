extends Control

# UI References
@onready var story_button = $UILayout/CenterContainer/LobbyCard/CardMargin/VBoxContainer/ButtonsContainer/StoryModeButton
@onready var calling_button = $UILayout/CenterContainer/LobbyCard/CardMargin/VBoxContainer/ButtonsContainer/PlayCallingButton
@onready var mass_button = $UILayout/CenterContainer/LobbyCard/CardMargin/VBoxContainer/ButtonsContainer/MassModeButton
@onready var customization_button = $UILayout/CenterContainer/LobbyCard/CardMargin/VBoxContainer/ButtonsContainer/CustomizationButton
@onready var back_button = $UILayout/CenterContainer/LobbyCard/CardMargin/VBoxContainer/ButtonsContainer/BackButton

# Sound Effects
var hover_sfx = preload("res://asset/sfx/menu-selection.mp3")
var click_sfx = preload("res://asset/sfx/confirm-selection.mp3")

var button_original_texts = {}

func _ready() -> void:
	var active_buttons = [
		story_button,
		calling_button,
		mass_button,
		customization_button,
		back_button
	]
	
	for btn in active_buttons:
		button_original_texts[btn] = btn.text
		_setup_button(btn)
		_connect_button_sfx(btn)
		
	# Connect click signals
	story_button.pressed.connect(_on_story_pressed)
	calling_button.pressed.connect(_on_calling_pressed)
	mass_button.pressed.connect(_on_mass_pressed)
	customization_button.pressed.connect(_on_customization_pressed)
	back_button.pressed.connect(_on_back_pressed)
	# No button is pre-focused on startup

# --- Button Hover and Focus Visuals ---
func _setup_button(btn: Button) -> void:
	# Remove default rectangular border/outline on all button states
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	
	# Set pivot offset for zoom scaling (center alignment)
	btn.pivot_offset = Vector2(btn.custom_minimum_size.x / 2.0, btn.custom_minimum_size.y / 2.0)
	
	btn.mouse_entered.connect(func(): _focus_button(btn))
	btn.mouse_exited.connect(func(): _unfocus_button(btn))
	btn.focus_entered.connect(func(): _focus_button(btn))
	btn.focus_exited.connect(func(): _unfocus_button(btn))

func _focus_button(btn: Button) -> void:
	if btn.disabled:
		return
	btn.text = "> " + button_original_texts[btn]
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.15)
	tween.tween_property(btn, "modulate", Color(1.3, 1.15, 0.7), 0.15) # Warm gold tint glow

func _unfocus_button(btn: Button) -> void:
	if btn.disabled:
		return
	btn.text = button_original_texts[btn]
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.15)

# --- Button Handlers ---
func _on_story_pressed() -> void:
	print("Story Mode Clicked! (Placeholder)")

func _on_calling_pressed() -> void:
	print("Play Calling Mode Clicked! (Placeholder)")

func _on_mass_pressed() -> void:
	print("Mass Mode Clicked! (Placeholder)")

func _on_customization_pressed() -> void:
	print("Customization Clicked! (Placeholder)")

func _on_back_pressed() -> void:
	# Wait a small delay so the click SFX can play before transition
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

# --- Audio Feedback Helpers ---
func _connect_button_sfx(btn: BaseButton) -> void:
	if not btn:
		return
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			_play_hover_sfx()
	)
	btn.pressed.connect(func():
		if not btn.disabled:
			_play_click_sfx()
	)

func _play_sfx_transient(stream: AudioStream) -> void:
	if not stream:
		return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _play_hover_sfx() -> void:
	_play_sfx_transient(hover_sfx)

func _play_click_sfx() -> void:
	_play_sfx_transient(click_sfx)
