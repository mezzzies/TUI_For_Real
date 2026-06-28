extends Control

@onready var menu_screen = $UILayout/MenuScreen
@onready var options_screen = $UILayout/OptionsScreen
@onready var credits_screen = $UILayout/CreditsScreen

@onready var play_button = $UILayout/MenuScreen/ButtonsContainer/PlayButton
@onready var options_button = $UILayout/MenuScreen/ButtonsContainer/OptionsButton
@onready var credits_button = $UILayout/MenuScreen/ButtonsContainer/CreditsButton
@onready var exit_button = $UILayout/MenuScreen/ButtonsContainer/ExitButton

@onready var options_back_button = $UILayout/OptionsScreen/OptionsBackButton
@onready var credits_back_button = $UILayout/CreditsScreen/CreditsBackButton
@onready var fullscreen_check = $UILayout/OptionsScreen/OptionsGrid/FullscreenCheck
@onready var volume_slider = $UILayout/OptionsScreen/OptionsGrid/VolumeSlider
@onready var music_slider = $UILayout/OptionsScreen/OptionsGrid/MusicSlider
@onready var resolution_option = $UILayout/OptionsScreen/OptionsGrid/ResolutionOption
@onready var bg_music = $BackgroundMusic

var button_original_texts = {}

func _ready() -> void:
	# Store and setup menu buttons
	var buttons = [
		play_button,
		options_button,
		credits_button,
		exit_button,
		options_back_button,
		credits_back_button
	]
	
	for btn in buttons:
		button_original_texts[btn] = btn.text
		_setup_button(btn)
		
	# Connect button pressed signals
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	options_back_button.pressed.connect(_show_menu_screen)
	credits_back_button.pressed.connect(_show_menu_screen)
	
	# Fullscreen CheckBox setup
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	# Set initial fullscreen checkbox state
	var current_mode = DisplayServer.window_get_mode()
	fullscreen_check.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN 
		or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		
	# Set volume slider events
	volume_slider.value_changed.connect(_on_volume_changed)
	music_slider.value_changed.connect(_on_music_changed)
	
	# Resolution OptionButton setup
	resolution_option.clear()
	resolution_option.add_item("1280x720")
	resolution_option.add_item("1600x900")
	resolution_option.add_item("1920x1080")
	
	# Select currently configured resolution
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
	
	# Initialize music and master volumes on startup
	_on_volume_changed(volume_slider.value)
	_on_music_changed(music_slider.value)
	
	# Start with main menu active
	_show_menu_screen()

func _setup_button(btn: Button) -> void:
	# Set pivot offset for scale tweening
	btn.pivot_offset = Vector2(0, btn.custom_minimum_size.y / 2.0)
	
	btn.mouse_entered.connect(func(): _focus_button(btn))
	btn.mouse_exited.connect(func(): _unfocus_button(btn))
	btn.focus_entered.connect(func(): _focus_button(btn))
	btn.focus_exited.connect(func(): _unfocus_button(btn))

func _focus_button(btn: Button) -> void:
	# Visual feedback on focus/hover
	btn.text = "> " + button_original_texts[btn]
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.15)
	tween.tween_property(btn, "modulate", Color(1.2, 1.1, 0.7), 0.15) # Gold glow tint

func _unfocus_button(btn: Button) -> void:
	# Restore standard state
	btn.text = button_original_texts[btn]
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.15)

func _show_menu_screen() -> void:
	menu_screen.visible = true
	options_screen.visible = false
	credits_screen.visible = false
	play_button.grab_focus()

func _on_play_pressed() -> void:
	print("Play Game pressed! Loading gameplay 3D...")
	get_tree().change_scene_to_file("res://scene/gameplay_3d.tscn")

func _on_options_pressed() -> void:
	menu_screen.visible = false
	options_screen.visible = true
	credits_screen.visible = false
	options_back_button.grab_focus()

func _on_credits_pressed() -> void:
	menu_screen.visible = false
	options_screen.visible = false
	credits_screen.visible = true
	credits_back_button.grab_focus()

func _on_exit_pressed() -> void:
	print("Exit pressed! Quitting game...")
	get_tree().quit()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_volume_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx != -1:
		var db = linear_to_db(value / 100.0)
		if value == 0:
			db = -80.0
		AudioServer.set_bus_volume_db(bus_idx, db)

func _on_music_changed(value: float) -> void:
	var db = linear_to_db(value / 100.0)
	if value == 0:
		db = -80.0
	
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, db)
	
	if is_instance_valid(bg_music):
		bg_music.volume_db = db

func _on_resolution_selected(index: int) -> void:
	# If currently in fullscreen, switch back to windowed mode
	if fullscreen_check.button_pressed:
		fullscreen_check.button_pressed = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
	var res_text = resolution_option.get_item_text(index)
	var parts = res_text.split("x")
	if parts.size() == 2:
		var width = int(parts[0])
		var height = int(parts[1])
		DisplayServer.window_set_size(Vector2i(width, height))
		
		# Center the window on the screen
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - Vector2i(width, height)) / 2
		DisplayServer.window_set_position(window_pos)
