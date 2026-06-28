extends Control

# UI References
@onready var menu_buttons_container = $UILayout/HBoxContainer/LeftPanel/MenuContainer/MenuButtons
@onready var sub_menu_panel = $UILayout/HBoxContainer/LeftPanel/MenuContainer/SubMenuPanel
@onready var play_submenu_container = $UILayout/HBoxContainer/LeftPanel/MenuContainer/SubMenuPanel/PanelMargin/PlaySubMenu

# Main Buttons
@onready var play_button = $UILayout/HBoxContainer/LeftPanel/MenuContainer/MenuButtons/PlayButton
@onready var tutorial_button = $UILayout/HBoxContainer/LeftPanel/MenuContainer/MenuButtons/TutorialButton
@onready var option_button = $UILayout/HBoxContainer/LeftPanel/MenuContainer/MenuButtons/OptionButton
@onready var quit_button = $UILayout/HBoxContainer/LeftPanel/MenuContainer/MenuButtons/QuitButton

# Play Submenu Buttons
@onready var solo_button = $UILayout/HBoxContainer/LeftPanel/MenuContainer/SubMenuPanel/PanelMargin/PlaySubMenu/SoloButton
@onready var multiplayer_button = $UILayout/HBoxContainer/LeftPanel/MenuContainer/SubMenuPanel/PanelMargin/PlaySubMenu/MultiplayerButton

# Modals
@onready var tutorial_modal = $TutorialModal
@onready var tutorial_panel = $TutorialModal/TutorialPanel
@onready var tutorial_close_button = $TutorialModal/TutorialPanel/CloseButton

@onready var options_modal = $OptionsModal
@onready var options_panel = $OptionsModal/OptionsPanel
@onready var options_close_button = $OptionsModal/OptionsPanel/CloseButton

# Options Controls
@onready var fullscreen_check = $OptionsModal/OptionsPanel/OptionsGrid/FullscreenCheck
@onready var resolution_option = $OptionsModal/OptionsPanel/OptionsGrid/ResolutionOption
@onready var master_slider = $OptionsModal/OptionsPanel/OptionsGrid/MasterSlider
@onready var music_slider = $OptionsModal/OptionsPanel/OptionsGrid/MusicSlider
@onready var sfx_slider = $OptionsModal/OptionsPanel/OptionsGrid/SfxSlider

# Music
@onready var bg_music = $BackgroundMusic

# Sound Effects
var hover_sfx = preload("res://asset/sfx/menu-selection.mp3")
var click_sfx = preload("res://asset/sfx/confirm-selection.mp3")

var button_original_texts = {}
var is_submenu_open = false

func _ready() -> void:

	# Initialize submenu panel collapsed
	sub_menu_panel.visible = false
	sub_menu_panel.custom_minimum_size.x = 0.0
	sub_menu_panel.modulate.a = 0.0
	
	# Setup disabled state for multiplayer button
	multiplayer_button.disabled = true
	multiplayer_button.focus_mode = Control.FOCUS_NONE
	multiplayer_button.modulate = Color(0.4, 0.4, 0.4, 0.6) # Grayed out and semi-transparent
	
	# Program focus neighbors for seamless keyboard/controller navigation
	solo_button.focus_neighbor_left = play_button.get_path()
	multiplayer_button.focus_neighbor_left = play_button.get_path()
	play_button.focus_neighbor_right = solo_button.get_path()
	
	# Setup button hover/focus effects
	var active_buttons = [
		play_button,
		tutorial_button,
		option_button,
		quit_button,
		solo_button,
		tutorial_close_button,
		options_close_button
	]
	
	for btn in active_buttons:
		button_original_texts[btn] = btn.text
		_setup_button(btn)
		_connect_button_sfx(btn)
		
	# Connect SFX for disabled or special buttons
	_connect_button_sfx(multiplayer_button)
	_connect_button_sfx(fullscreen_check)
	_connect_button_sfx(resolution_option)
		
	# Connect button pressed signals
	play_button.pressed.connect(_on_play_pressed)
	tutorial_button.pressed.connect(_on_tutorial_pressed)
	option_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	solo_button.pressed.connect(_on_solo_pressed)
	
	tutorial_close_button.pressed.connect(_close_tutorial)
	options_close_button.pressed.connect(_close_options)
	
	# Initialize Modals as hidden
	tutorial_modal.visible = false
	tutorial_modal.modulate.a = 0.0
	options_modal.visible = false
	options_modal.modulate.a = 0.0
	
	# Setup Options menu controls
	_setup_options_controls()
	
	# No button is pre-focused; interaction starts on hover or keypress

# --- Button Hover and Focus Visuals ---
func _setup_button(btn: Button) -> void:
	# Remove default rectangular border/outline on all button states
	var empty_style = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_style)
	btn.add_theme_stylebox_override("hover", empty_style)
	btn.add_theme_stylebox_override("pressed", empty_style)
	btn.add_theme_stylebox_override("focus", empty_style)
	
	# Set pivot offset for zoom scaling
	btn.pivot_offset = Vector2(btn.custom_minimum_size.x / 2.0, btn.custom_minimum_size.y / 2.0)
	
	btn.mouse_entered.connect(func(): 
		_focus_button(btn)
		if btn in [tutorial_button, option_button, quit_button]:
			_close_play_submenu()
	)
	btn.mouse_exited.connect(func(): _unfocus_button(btn))
	btn.focus_entered.connect(func(): 
		_focus_button(btn)
		if btn in [tutorial_button, option_button, quit_button]:
			_close_play_submenu()
	)
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

# --- Play Menu Transition Actions ---
func _on_play_pressed() -> void:
	if is_submenu_open:
		_close_play_submenu()
		return
		
	is_submenu_open = true
	sub_menu_panel.visible = true
	
	# Smoothly expand SubMenuPanel width and fade it in
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sub_menu_panel, "custom_minimum_size:x", 340.0, 0.25)
	tween.tween_property(sub_menu_panel, "modulate:a", 1.0, 0.2)

func _close_play_submenu() -> void:
	if not is_submenu_open:
		return
	is_submenu_open = false
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(sub_menu_panel, "custom_minimum_size:x", 0.0, 0.2)
	tween.tween_property(sub_menu_panel, "modulate:a", 0.0, 0.15)
	
	tween.chain().tween_callback(func():
		sub_menu_panel.visible = false
	)

func _on_solo_pressed() -> void:
	# Wait a small delay so the click SFX can play before transition
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file("res://scene/lobby.tscn")

# --- Tutorial Popup Logic ---
func _on_tutorial_pressed() -> void:
	tutorial_modal.visible = true
	tutorial_panel.scale = Vector2(0.8, 0.8)
	tutorial_panel.pivot_offset = tutorial_panel.size / 2.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(tutorial_modal, "modulate:a", 1.0, 0.25)
	tween.tween_property(tutorial_panel, "scale", Vector2(1.0, 1.0), 0.25)
	
	tutorial_close_button.grab_focus()

func _close_tutorial() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(tutorial_modal, "modulate:a", 0.0, 0.2)
	tween.tween_property(tutorial_panel, "scale", Vector2(0.8, 0.8), 0.2)
	
	tween.chain().tween_callback(func():
		tutorial_modal.visible = false
		tutorial_button.grab_focus()
	)

# --- Options Popup Logic ---
func _on_options_pressed() -> void:
	options_modal.visible = true
	options_panel.scale = Vector2(0.8, 0.8)
	options_panel.pivot_offset = options_panel.size / 2.0
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(options_modal, "modulate:a", 1.0, 0.25)
	tween.tween_property(options_panel, "scale", Vector2(1.0, 1.0), 0.25)
	
	options_close_button.grab_focus()

func _close_options() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(options_modal, "modulate:a", 0.0, 0.2)
	tween.tween_property(options_panel, "scale", Vector2(0.8, 0.8), 0.2)
	
	tween.chain().tween_callback(func():
		options_modal.visible = false
		option_button.grab_focus()
	)

func _on_quit_pressed() -> void:
	# Wait a small delay so the click SFX can play before quitting
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()

# --- Options System Configurations ---
func _setup_options_controls() -> void:
	# Fullscreen checkbox state
	var current_mode = DisplayServer.window_get_mode()
	fullscreen_check.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN 
		or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	
	# Resolution OptionButton setup
	resolution_option.clear()
	resolution_option.add_item("1280x720")
	resolution_option.add_item("1600x900")
	resolution_option.add_item("1920x1080")
	
	var current_size = DisplayServer.window_get_size()
	var size_str = str(current_size.x) + "x" + str(current_size.y)
	var select_idx = -1
	for i in range(resolution_option.item_count):
		if resolution_option.get_item_text(i) == size_str:
			select_idx = i
			break
	
	if select_idx != -1:
		resolution_option.selected = select_idx
	else:
		resolution_option.selected = 0
		
	resolution_option.item_selected.connect(_on_resolution_selected)
	
	# Volume sliders initialization
	master_slider.value_changed.connect(func(v): _on_volume_slider_changed("Master", v))
	music_slider.value_changed.connect(func(v): _on_volume_slider_changed("Music", v))
	sfx_slider.value_changed.connect(func(v): _on_volume_slider_changed("SFX", v))
	
	# Preset values
	master_slider.value = 80.0
	music_slider.value = 70.0
	sfx_slider.value = 80.0
	
	_on_volume_slider_changed("Master", master_slider.value)
	_on_volume_slider_changed("Music", music_slider.value)
	_on_volume_slider_changed("SFX", sfx_slider.value)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_resolution_selected(index: int) -> void:
	if fullscreen_check.button_pressed:
		fullscreen_check.button_pressed = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	var res_text = resolution_option.get_item_text(index)
	var parts = res_text.split("x")
	if parts.size() == 2:
		var width = int(parts[0])
		var height = int(parts[1])
		DisplayServer.window_set_size(Vector2i(width, height))
		
		# Center window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - Vector2i(width, height)) / 2
		DisplayServer.window_set_position(window_pos)

func _on_volume_slider_changed(bus_name: String, value: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	# If the bus exists in the engine, modify it
	if bus_idx != -1:
		var db = linear_to_db(value / 100.0)
		if value == 0:
			db = -80.0
		AudioServer.set_bus_volume_db(bus_idx, db)
	
	# Apply volume directly to background music if it is the music slider
	if bus_name == "Music" and is_instance_valid(bg_music):
		var db = linear_to_db(value / 100.0)
		if value == 0:
			db = -80.0
		bg_music.volume_db = db

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
