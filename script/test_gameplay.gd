extends Control

const BotAI = preload("res://script/bot_ai.gd")

const BACKHAND_OFFSET = 40.0
const TOP_BACKHAND_OFFSET = 40.0
const SIDE_BACKHAND_OFFSET = 100.0

@onready var slots = [
	$HandArea/CardSlot0,
	$HandArea/CardSlot1,
	$HandArea/CardSlot2,
	$HandArea/CardSlot3,
	$HandArea/CardSlot4,
	$HandArea/CardSlot5,
	$HandArea/CardSlot6,
	$HandArea/CardSlot7
]

var card_scene = preload("res://scene/test_card.tscn")
var hover_sfx = preload("res://asset/sfx/tick.mp3")
var click_sfx = preload("res://asset/sfx/tock.mp3")
var bgm_music = preload("res://asset/music/waveloom-slow-jazz.mp3")

@onready var confirm_button = $ConfirmButton
var exit_to_menu_button: Button = null
@onready var table_area = $TableArea
@onready var back_hand = $BackHand
@onready var table_slots = [
	$TableArea/TableSlot0,
	$TableArea/TableSlot1,
	$TableArea/TableSlot2,
	$TableArea/TableSlot3,
	$TableArea/TableSlot4,
	$TableArea/TableSlot5,
	$TableArea/TableSlot6,
	$TableArea/TableSlot7
]

# Bot components

@onready var left_player = $Left_Player
@onready var right_player = $Right_Player
@onready var top_player = $Top_Player

@onready var left_table_area = $Left_TableArea
@onready var right_table_area = $Right_TableArea
@onready var top_table_area = $Top_TableArea

@onready var left_slots = [
	$Left_TableArea/TableSlot0,
	$Left_TableArea/TableSlot1,
	$Left_TableArea/TableSlot2,
	$Left_TableArea/TableSlot3,
	$Left_TableArea/TableSlot4,
	$Left_TableArea/TableSlot5,
	$Left_TableArea/TableSlot6,
	$Left_TableArea/TableSlot7
]

@onready var right_slots = [
	$Right_TableArea/TableSlot0,
	$Right_TableArea/TableSlot1,
	$Right_TableArea/TableSlot2,
	$Right_TableArea/TableSlot3,
	$Right_TableArea/TableSlot4,
	$Right_TableArea/TableSlot5,
	$Right_TableArea/TableSlot6,
	$Right_TableArea/TableSlot7
]

@onready var top_slots = [
	$Top_TableArea/TableSlot0,
	$Top_TableArea/TableSlot1,
	$Top_TableArea/TableSlot2,
	$Top_TableArea/TableSlot3,
	$Top_TableArea/TableSlot4,
	$Top_TableArea/TableSlot5,
	$Top_TableArea/TableSlot6,
	$Top_TableArea/TableSlot7
]

# Textures
var l_thinking_tex = preload("res://asset/character/default/L_thinkinghand.png")
var r_thinking_tex = preload("res://asset/character/default/R_thinkinghand.png")
var t_thinking_tex = preload("res://asset/character/default/T_thinkinghand.png")
var backhand_tex = preload("res://asset/character/default/Single_backhand.png")

# Base positions
var base_hand_y := 0.0
var base_left_x := 0.0
var base_right_x := 0.0
var base_top_y := 0.0

# Breathing tweens
var breathing_tween: Tween
var left_breathing_tween: Tween
var right_breathing_tween: Tween
var top_breathing_tween: Tween

# Internal card state (data-only, skin-agnostic)
var player_hand: Array = []
var left_hand: Array = []
var right_hand: Array = []
var top_hand: Array = []

var player_table_cards: Array = []
var left_table_cards: Array = []
var right_table_cards: Array = []
var top_table_cards: Array = []

# Turn leader and active play properties
var current_leader: int = 0             # 0=Player, 1=Left, 2=Top, 3=Right
var active_play_type: String = ""       # "Single", "Pair", "Noble Set", "Soldier Set"
var active_card_count: int = 0
var has_played: Array = [false, false, false, false] # Track who has played this turn

# Won cards collection arrays
var player_won_cards: Array = []
var left_won_cards: Array = []
var right_won_cards: Array = []
var top_won_cards: Array = []

# Bot personalities configuration (1: Left Bot, 2: Top Bot, 3: Right Bot)
var bot_personalities: Dictionary = {}
# Tracks the number of loops completed in the current round
var loop_count: int = 0

# Win card area Control nodes
@onready var player_win_area = $PlayerWinArea
@onready var left_win_area = $LeftWinArea
@onready var right_win_area = $RightWinArea
@onready var top_win_area = $TopWinArea
@onready var announcement = $Annoucement
@onready var announcement_text = $Annoucement/AnnoucementText

# Player/Bot name labels
@onready var player_name_label = $PlayerName
@onready var left_name_label = $LeftName
@onready var top_name_label = $TopName
@onready var right_name_label = $RightName

var announcement_tween: Tween
var custom_font = preload("res://asset/font/mechanical-font/MechanicalBold-oOmA.otf")

# Input configurations (can be set by previous scene/external script before _ready)
@export var game_mode: String = "Mass Mode"
@export var select_time_preset: String = "Fast" # "Fast" (10s), "Normal" (20s), "Long" (30s)
@export var round_preset: String = "Normal"        # "Short" (1 round / 4 loops), "Normal" (2 rounds / 8 loops), "Long" (4 rounds / 16 loops)

var rounds_completed: int = 0

# Timer Configuration & State
@export var leader_select_time: float = 20.0
@export var responder_select_time: float = 20.0

@onready var time_label = get_node_or_null("Time")

var state_time_left: float = 0.0
var is_timer_running: bool = false
var current_timer_state: String = ""
var is_test_mode: bool = false

# Scoreboard State & Bindings
@onready var score_panel = get_node_or_null("ScorePanel")
@onready var score_grid = get_node_or_null("ScorePanel/ScoreContainer/ScoreGrid")

var loop_scores: Array = []
var all_round_scores: Array = []
var viewed_round_idx: int = 0
var bots_thinking: Array = [false, false, false, false]

func _ready() -> void:
	if back_hand:
		back_hand.visible = false
		back_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back_hand.z_index = 5
		
	# Ensure hands always render on top of table/win area cards
	left_player.z_index = 5
	right_player.z_index = 5
	top_player.z_index = 5
	
	# Ensure name labels and buttons render on the top UI layer (above hands and cards)
	player_name_label.z_index = 20
	left_name_label.z_index = 20
	right_name_label.z_index = 20
	top_name_label.z_index = 20
	announcement.z_index = 20
	score_panel.z_index = 20
	
	confirm_button.z_index = 20
		
	table_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot in table_slots:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# Ignore mouse filter for hands so they don't block button clicks
	left_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HandArea/PlayerHand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HandArea.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# Save base positions of bot player hands
	base_left_x = left_player.position.x
	base_right_x = right_player.position.x
	base_top_y = top_player.position.y
	
	# Set Table Areas and Slots for bots to ignore mouse filter
	left_table_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_table_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_table_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	for slot in left_slots:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot in right_slots:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot in top_slots:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# Ignore mouse filter for win areas and their icons so they do not block clicks
	player_win_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_win_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_win_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_win_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	for i in range(1, 9):
		var p_icon = player_win_area.get_node_or_null("CardIcon_" + str(i))
		if p_icon: p_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l_icon = left_win_area.get_node_or_null("CardIcon_" + str(i))
		if l_icon: l_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var r_icon = right_win_area.get_node_or_null("CardIcon_" + str(i))
		if r_icon: r_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var t_icon = top_win_area.get_node_or_null("CardIcon_" + str(i))
		if t_icon: t_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# Announcement UI setup
	if announcement:
		announcement.visible = false
		announcement.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if announcement_text:
			announcement_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
			announcement_text.add_theme_font_override("font", custom_font)
			announcement_text.add_theme_font_size_override("font_size", 42)
			announcement_text.add_theme_color_override("font_color", Color.WHITE)
			announcement_text.add_theme_color_override("font_outline_color", Color.BLACK)
			announcement_text.add_theme_constant_override("outline_size", 12)
		
	# Disable keyboard focus for all buttons to prevent focus outlines when pressing Tab
	confirm_button.focus_mode = Control.FOCUS_NONE

	# Connect button events
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirm_button.pressed.connect(func(): _play_sfx_transient(click_sfx))
	confirm_button.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
	
	# Create exit to menu button
	var exit_btn = Button.new()
	exit_btn.name = "ExitToMenuButton"
	exit_btn.text = "Exit to Main Menu"
	exit_btn.focus_mode = Control.FOCUS_NONE
	exit_btn.visible = false
	exit_btn.z_index = 25
	
	exit_btn.add_theme_font_override("font", custom_font)
	exit_btn.add_theme_font_size_override("font_size", 24)
	
	exit_btn.anchors_preset = Control.PRESET_CENTER
	exit_btn.anchor_left = 0.5
	exit_btn.anchor_top = 0.5
	exit_btn.anchor_right = 0.5
	exit_btn.anchor_bottom = 0.5
	exit_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	exit_btn.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	exit_btn.custom_minimum_size = Vector2(250, 60)
	exit_btn.offset_left = -125
	exit_btn.offset_right = 125
	exit_btn.offset_top = 100
	exit_btn.offset_bottom = 160
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.08, 0.09, 0.12, 0.9)
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.25, 0.27, 0.35, 0.6)
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.corner_radius_bottom_left = 8
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.12, 0.14, 0.18, 0.95)
	style_hover.border_color = Color(0.95, 0.76, 0.23, 0.8)
	
	var style_pressed = style_hover.duplicate()
	style_pressed.bg_color = Color(0.05, 0.06, 0.08, 0.9)
	
	exit_btn.add_theme_stylebox_override("normal", style_normal)
	exit_btn.add_theme_stylebox_override("hover", style_hover)
	exit_btn.add_theme_stylebox_override("pressed", style_pressed)
	
	exit_btn.add_theme_color_override("font_color", Color.WHITE)
	exit_btn.add_theme_color_override("font_hover_color", Color(0.95, 0.76, 0.23))
	exit_btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.6, 0.15))
	
	exit_btn.pressed.connect(func():
		_play_sfx_transient(click_sfx)
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	)
	exit_btn.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
	
	add_child(exit_btn)
	exit_to_menu_button = exit_btn
	
	# Start all breathing animations
	_start_all_breathing()
	
	# Start looping background music (volume down)
	if bgm_music:
		bgm_music.loop = true
		var bgm_player = AudioStreamPlayer.new()
		bgm_player.stream = bgm_music
		bgm_player.volume_db = -18.0  # Set volume low for background music
		bgm_player.name = "BGMPlayer"
		add_child(bgm_player)
		bgm_player.play()
		
	# Scoreboard UI font overrides
	var title_lbl = get_node_or_null("ScorePanel/ScoreContainer/TitleLabel")
	if title_lbl:
		title_lbl.add_theme_font_override("font", custom_font)
		title_lbl.add_theme_color_override("font_color", Color.WHITE)
		title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		title_lbl.add_theme_constant_override("outline_size", 12)
		
	# Instantiate Round Navigation Panel dynamically
	var score_container = get_node_or_null("ScorePanel/ScoreContainer")
	if score_container:
		var nav_container = HBoxContainer.new()
		nav_container.name = "RoundNav"
		nav_container.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var prev_btn = Button.new()
		prev_btn.name = "PrevRoundBtn"
		prev_btn.text = "< Prev Round"
		prev_btn.focus_mode = Control.FOCUS_NONE
		prev_btn.pressed.connect(_on_prev_round_pressed)
		prev_btn.pressed.connect(func(): _play_sfx_transient(click_sfx))
		prev_btn.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
		nav_container.add_child(prev_btn)
		
		var round_lbl = Label.new()
		round_lbl.name = "RoundNumLabel"
		round_lbl.text = "ROUND 1"
		round_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		round_lbl.add_theme_font_override("font", custom_font)
		round_lbl.add_theme_font_size_override("font_size", 18)
		round_lbl.custom_minimum_size = Vector2(150, 0)
		nav_container.add_child(round_lbl)
		
		var next_btn = Button.new()
		next_btn.name = "NextRoundBtn"
		next_btn.text = "Next Round >"
		next_btn.focus_mode = Control.FOCUS_NONE
		next_btn.pressed.connect(_on_next_round_pressed)
		next_btn.pressed.connect(func(): _play_sfx_transient(click_sfx))
		next_btn.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
		nav_container.add_child(next_btn)
		
		score_container.add_child(nav_container)
		score_container.move_child(nav_container, 1)
		
	# Initialize time label visibility
	_update_time_label()
	
	# Save the initial layout position of HandArea before positioning it off-screen
	base_hand_y = $HandArea.position.y
	
	# Initialize all hands (including player HandArea) off-screen and invisible so they can animate in smoothly on first deal
	var start_viewport_size = get_viewport_rect().size
	$HandArea.position.y = start_viewport_size.y + 50.0
	$HandArea.visible = false
	
	left_player.position.x = -600.0
	right_player.position.x = start_viewport_size.x + 600.0
	top_player.position.y = -600.0
	
	left_player.visible = false
	right_player.visible = false
	top_player.visible = false
	
	# Initialize presets
	if select_time_preset == "Fast":
		leader_select_time = 10.0
		responder_select_time = 10.0
	elif select_time_preset == "Long":
		leader_select_time = 30.0
		responder_select_time = 30.0
	else:
		leader_select_time = 20.0
		responder_select_time = 20.0

	# Show initial game configuration announcement
	var rounds_str = "2 Rounds"
	if round_preset == "Short":
		rounds_str = "1 Round"
	elif round_preset == "Long":
		rounds_str = "4 Rounds"
		
	var config_text = game_mode + "\n" + rounds_str
	
	if not is_test_mode:
		# Wait a small delay to let the window load and settle so the fade-in tween renders correctly
		await get_tree().create_timer(0.15).timeout
		var config_tween = _show_announcement(config_text, 3.0)
		if config_tween:
			await config_tween.finished
			
	# Automatically trigger first round deal
	_get_cards(false)


func _process(delta: float) -> void:
	if is_test_mode or not is_timer_running:
		return
		
	# Pause countdown if an announcement is currently visible
	if announcement and announcement.visible:
		_update_time_label()
		return
		
	state_time_left -= delta
	if state_time_left <= 0.0:
		state_time_left = 0.0
		is_timer_running = false
		_update_time_label()
		_on_state_timer_timeout()
	else:
		_update_time_label()


func _start_state_timer(state_type: String) -> void:
	if is_test_mode:
		return
	current_timer_state = state_type
	if state_type == "leader":
		state_time_left = leader_select_time
	elif state_type == "responder":
		state_time_left = responder_select_time
	is_timer_running = true
	_update_time_label()


func _stop_state_timer() -> void:
	is_timer_running = false
	current_timer_state = ""
	_update_time_label()


func _update_time_label() -> void:
	if not time_label:
		return
	if is_timer_running:
		time_label.text = "Time: %02d" % [ceil(state_time_left)]
		time_label.visible = true
		if state_time_left < 10.0:
			time_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			time_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		time_label.visible = false


func _on_state_timer_timeout() -> void:
	var state = current_timer_state
	_stop_state_timer()
	
	# Determine timeout text
	var timeout_text = "Time Out!"
	var tween = _show_announcement(timeout_text, 2.0)
	if tween:
		await tween.finished
		
	if state == "leader":
		if current_leader == 0:
			await _auto_play_leader_for_player()
		else:
			await _auto_play_for_bot(current_leader)
	elif state == "responder":
		await _auto_play_remaining_responders()


func _auto_play_leader_for_player() -> void:
	# Check if player has selected cards that form a valid play
	var selected_cards = []
	for slot in slots:
		if slot.get_child_count() > 0:
			var card = slot.get_child(0)
			if "is_selected" in card and card.is_selected:
				selected_cards.append(card)
				
	var selected_card_data = []
	for card in selected_cards:
		if card.has_meta("card_id"):
			var cid = card.get_meta("card_id")
			for hand_card in player_hand:
				if hand_card["id"] == cid:
					selected_card_data.append(hand_card)
					break
					
	if not selected_cards.is_empty() and _detect_play_type(selected_card_data) != "":
		await _on_confirm_pressed()
	else:
		# Deselect all
		for slot in slots:
			if slot.get_child_count() > 0:
				var card = slot.get_child(0)
				card.set_selected(false)
				card.reset_visuals()
				
		# Select the first card in player's hand
		for slot in slots:
			if slot.get_child_count() > 0:
				var card = slot.get_child(0)
				card.set_selected(true)
				break
				
		await _on_confirm_pressed()


func _auto_play_for_bot(bot_idx: int) -> void:
	if bot_idx == 1:
		await _play_ready_sequence(left_player, left_table_area, left_slots, l_thinking_tex, "left")
	elif bot_idx == 2:
		await _play_ready_sequence(top_player, top_table_area, top_slots, t_thinking_tex, "top")
	elif bot_idx == 3:
		await _play_ready_sequence(right_player, right_table_area, right_slots, r_thinking_tex, "right")


func _auto_play_remaining_responders() -> void:
	for i in range(4):
		var hand_sz = 0
		if i == 0: hand_sz = player_hand.size()
		elif i == 1: hand_sz = left_hand.size()
		elif i == 2: hand_sz = top_hand.size()
		else: hand_sz = right_hand.size()
		
		if hand_sz > 0 and not has_played[i]:
			if i == 0:
				await _auto_play_responder_for_player()
				while not has_played[0]:
					await get_tree().process_frame
			else:
				if i == 1:
					await _play_ready_sequence(left_player, left_table_area, left_slots, l_thinking_tex, "left")
				elif i == 2:
					await _play_ready_sequence(top_player, top_table_area, top_slots, t_thinking_tex, "top")
				elif i == 3:
					await _play_ready_sequence(right_player, right_table_area, right_slots, r_thinking_tex, "right")


func _trigger_auto_bot_play(bot_idx: int) -> void:
	if is_test_mode:
		return
		
	if bots_thinking[bot_idx]:
		return
		
	bots_thinking[bot_idx] = true
	
	# Determine random thinking delay based on bot style and delay range configs in BotAI
	var active_style = bot_personalities.get(bot_idx, "Professor Jim")
	var delay_range = BotAI.get_thinking_delay_range(active_style)
	var delay = randf_range(delay_range.x, delay_range.y)
	await get_tree().create_timer(delay).timeout
	
	# Reset state check after delay
	if not bots_thinking[bot_idx]:
		return
		
	bots_thinking[bot_idx] = false
	
	# Verify bot still needs to make a play
	var still_needs_to_play = false
	if active_play_type == "":
		if current_leader == bot_idx:
			still_needs_to_play = true
	else:
		var hand_sz = 0
		if bot_idx == 1: hand_sz = left_hand.size()
		elif bot_idx == 2: hand_sz = top_hand.size()
		else: hand_sz = right_hand.size()
		
		if hand_sz > 0 and not has_played[bot_idx]:
			still_needs_to_play = true
			
	if still_needs_to_play:
		if bot_idx == 1:
			await _play_ready_sequence(left_player, left_table_area, left_slots, l_thinking_tex, "left")
		elif bot_idx == 2:
			await _play_ready_sequence(top_player, top_table_area, top_slots, t_thinking_tex, "top")
		elif bot_idx == 3:
			await _play_ready_sequence(right_player, right_table_area, right_slots, r_thinking_tex, "right")


func _auto_play_responder_for_player() -> void:
	var selected_cards = []
	for slot in slots:
		if slot.get_child_count() > 0:
			var card = slot.get_child(0)
			if "is_selected" in card and card.is_selected:
				selected_cards.append(card)
				
	if selected_cards.size() == active_card_count:
		await _on_confirm_pressed()
	else:
		# Deselect all
		for slot in slots:
			if slot.get_child_count() > 0:
				var card = slot.get_child(0)
				card.set_selected(false)
				card.reset_visuals()
				
		# Select first active_card_count cards in hand
		var count = 0
		for slot in slots:
			if slot.get_child_count() > 0:
				var card = slot.get_child(0)
				card.set_selected(true)
				count += 1
				if count == active_card_count:
					break
					
		await _on_confirm_pressed()


func _input(event: InputEvent) -> void:
	if is_test_mode:
		return
	if event is InputEventKey and event.keycode == KEY_TAB and event.pressed and not event.is_echo():
		get_viewport().set_input_as_handled() # Consume key event to block built-in Control focus cycling
		if score_panel:
			_show_score_panel(not score_panel.visible)


func _show_score_panel(show: bool) -> void:
	if not score_panel:
		return
	if show:
		viewed_round_idx = rounds_completed
		_update_score_panel()
		score_panel.visible = true
	else:
		score_panel.visible = false


func _on_prev_round_pressed() -> void:
	if viewed_round_idx > 0:
		viewed_round_idx -= 1
		_update_score_panel()


func _on_next_round_pressed() -> void:
	var max_rounds = 2
	if round_preset == "Short":
		max_rounds = 1
	elif round_preset == "Long":
		max_rounds = 4
		
	if viewed_round_idx < max_rounds - 1:
		viewed_round_idx += 1
		_update_score_panel()


func _update_score_panel() -> void:
	if not score_grid:
		return
		
	# Update Navigation Buttons & Title Label
	var prev_btn = get_node_or_null("ScorePanel/ScoreContainer/RoundNav/PrevRoundBtn")
	var next_btn = get_node_or_null("ScorePanel/ScoreContainer/RoundNav/NextRoundBtn")
	var round_lbl = get_node_or_null("ScorePanel/ScoreContainer/RoundNav/RoundNumLabel")
	
	if round_lbl:
		round_lbl.text = "ROUND " + str(viewed_round_idx + 1)
	if prev_btn:
		prev_btn.disabled = (viewed_round_idx == 0)
		
	var max_rounds = 2
	if round_preset == "Short":
		max_rounds = 1
	elif round_preset == "Long":
		max_rounds = 4
		
	if next_btn:
		next_btn.disabled = (viewed_round_idx >= max_rounds - 1)
		
	# Get loop scores of the currently viewed round
	var current_view_loop_scores = []
	if viewed_round_idx < all_round_scores.size():
		current_view_loop_scores = all_round_scores[viewed_round_idx]
		
	# Clear existing children in grid
	for child in score_grid.get_children():
		score_grid.remove_child(child)
		child.queue_free()
		
	# 1. Add Headers
	var headers = ["PLAYER", "LOOP 1", "LOOP 2", "LOOP 3", "LOOP 4", "TOTAL"]
	for h in headers:
		var lbl = Label.new()
		lbl.text = h
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_override("font", custom_font)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color.YELLOW)
		lbl.add_theme_constant_override("outline_size", 6)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		score_grid.add_child(lbl)
		
	# 2. Add Row Data (0=Player, 1=Left, 2=Top, 3=Right)
	var players = [
		{"name": "Player", "key": "player", "idx": 0},
		{"name": bot_personalities.get(1, "Left Bot"), "key": "left", "idx": 1},
		{"name": bot_personalities.get(2, "Top Bot"), "key": "top", "idx": 2},
		{"name": bot_personalities.get(3, "Right Bot"), "key": "right", "idx": 3}
	]
	
	for p_info in players:
		var name_lbl = Label.new()
		var is_last_winner = (p_info["idx"] == current_leader)
		
		if is_last_winner:
			name_lbl.text = "**" + p_info["name"] + "**"
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # Gold Color
		else:
			name_lbl.text = p_info["name"]
			name_lbl.add_theme_color_override("font_color", Color.WHITE)
			
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_override("font", custom_font)
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_constant_override("outline_size", 4)
		name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		score_grid.add_child(name_lbl)
		
		# Show loop scores for selected round
		for loop_idx in range(4):
			var score_lbl = Label.new()
			var val = ""
			if loop_idx < current_view_loop_scores.size():
				var s = current_view_loop_scores[loop_idx][p_info["key"]]
				val = str(s)
			else:
				val = "-"
			score_lbl.text = val
			score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			score_lbl.add_theme_font_override("font", custom_font)
			score_lbl.add_theme_font_size_override("font_size", 16)
			score_lbl.add_theme_color_override("font_color", Color.WHITE if val != "-" else Color.GRAY)
			score_lbl.add_theme_constant_override("outline_size", 4)
			score_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
			score_grid.add_child(score_lbl)
			
		# Cumulative TOTAL score across ALL rounds played so far
		var total_score = 0
		for r_idx in range(all_round_scores.size()):
			var r_scores = all_round_scores[r_idx]
			for l_score in r_scores:
				total_score += l_score[p_info["key"]]
				
		var total_lbl = Label.new()
		total_lbl.text = str(total_score)
		total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		total_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		total_lbl.add_theme_font_override("font", custom_font)
		total_lbl.add_theme_font_size_override("font_size", 18)
		total_lbl.add_theme_color_override("font_color", Color.GREEN)
		total_lbl.add_theme_constant_override("outline_size", 6)
		total_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		score_grid.add_child(total_lbl)

	# 3. Add Check Sum Row (should be 8 for each loop, and up to 32 * max_rounds at Total)
	var checksum_lbl = Label.new()
	checksum_lbl.text = "Check Sum"
	checksum_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	checksum_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	checksum_lbl.add_theme_font_override("font", custom_font)
	checksum_lbl.add_theme_font_size_override("font_size", 16)
	checksum_lbl.add_theme_color_override("font_color", Color.CYAN)
	checksum_lbl.add_theme_constant_override("outline_size", 4)
	checksum_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	score_grid.add_child(checksum_lbl)
	
	var grand_checksum = 0
	for loop_idx in range(4):
		var check_lbl = Label.new()
		var val = ""
		if loop_idx < current_view_loop_scores.size():
			var s = current_view_loop_scores[loop_idx]["player"] + current_view_loop_scores[loop_idx]["left"] + current_view_loop_scores[loop_idx]["top"] + current_view_loop_scores[loop_idx]["right"]
			val = str(s)
			grand_checksum += s
		else:
			val = "-"
		check_lbl.text = val
		check_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		check_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		check_lbl.add_theme_font_override("font", custom_font)
		check_lbl.add_theme_font_size_override("font_size", 16)
		check_lbl.add_theme_color_override("font_color", Color.CYAN if val != "-" else Color.GRAY)
		check_lbl.add_theme_constant_override("outline_size", 4)
		check_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		score_grid.add_child(check_lbl)
		
	# All-time check sum total
	var grand_checksum_all_time = 0
	for r_scores in all_round_scores:
		for l_score in r_scores:
			grand_checksum_all_time += l_score["player"] + l_score["left"] + l_score["top"] + l_score["right"]
			
	var grand_lbl = Label.new()
	grand_lbl.text = str(grand_checksum_all_time)
	grand_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grand_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grand_lbl.add_theme_font_override("font", custom_font)
	grand_lbl.add_theme_font_size_override("font_size", 18)
	grand_lbl.add_theme_color_override("font_color", Color.CYAN)
	grand_lbl.add_theme_constant_override("outline_size", 6)
	grand_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	score_grid.add_child(grand_lbl)


func _finish_loop_and_transition() -> void:
	# 1. Force showing the ScorePanel to show score of every player. (5 seconds)
	_show_score_panel(true)
	await get_tree().create_timer(5.0).timeout
	_show_score_panel(false)
	
	# 2. Check if loop_count < 4 to continue next loop or round winner announcement
	if loop_count < 4:
		# Continue to the next loop with "last winner is the leader"
		# The last winner index is already current_leader, so we keep it.
		_get_cards(true)
	else:
		# Round is complete (4 loops finished)
		rounds_completed += 1
		
		# Calculate round winner
		var totals = {"player": 0, "left": 0, "top": 0, "right": 0}
		var current_round_scores = all_round_scores[rounds_completed - 1]
		for s in current_round_scores:
			totals["player"] += s["player"]
			totals["left"] += s["left"]
			totals["top"] += s["top"]
			totals["right"] += s["right"]
			
		var max_score = -1
		var winners = []
		for key in totals.keys():
			if totals[key] > max_score:
				max_score = totals[key]
				winners = [key]
			elif totals[key] == max_score:
				winners.append(key)
				
		var winner_names = []
		for w in winners:
			if w == "player":
				winner_names.append("Player")
			elif w == "left":
				winner_names.append(bot_personalities.get(1, "Left Bot"))
			elif w == "top":
				winner_names.append(bot_personalities.get(2, "Top Bot"))
			else:
				winner_names.append(bot_personalities.get(3, "Right Bot"))
				
		var winner_text = ""
		if winner_names.size() == 1:
			winner_text = winner_names[0] + "\nget highest score!"
		else:
			winner_text = str(winner_names.size()) + " players\nget highest score!"
			
		var tween = _show_announcement(winner_text, 10.0)
		if tween and not is_test_mode:
			await tween.finished
			
		var max_rounds = 2
		if round_preset == "Short":
			max_rounds = 1
		elif round_preset == "Long":
			max_rounds = 4
			
		if rounds_completed >= max_rounds:
			# Calculate match winner (total across all rounds)
			var match_totals = {"player": 0, "left": 0, "top": 0, "right": 0}
			for round_scores in all_round_scores:
				for s in round_scores:
					match_totals["player"] += s["player"]
					match_totals["left"] += s["left"]
					match_totals["top"] += s["top"]
					match_totals["right"] += s["right"]
					
			var all_equal = (match_totals["player"] == match_totals["left"] and 
							 match_totals["left"] == match_totals["top"] and 
							 match_totals["top"] == match_totals["right"])
							 
			var match_text = "Match Completed!\n"
			if all_equal:
				match_text += "YOU PLAYED FOR NOTHING!"
			else:
				var max_match_score = -1
				var match_winners = []
				for key in match_totals.keys():
					if match_totals[key] > max_match_score:
						max_match_score = match_totals[key]
						match_winners = [key]
					elif match_totals[key] == max_match_score:
						match_winners.append(key)
						
				var match_winner_names = []
				for w in match_winners:
					if w == "player":
						match_winner_names.append("Player")
					elif w == "left":
						match_winner_names.append(bot_personalities.get(1, "Left Bot"))
					elif w == "top":
						match_winner_names.append(bot_personalities.get(2, "Top Bot"))
					else:
						match_winner_names.append(bot_personalities.get(3, "Right Bot"))
						
				if match_winner_names.size() == 1:
					match_text += "Winner: " + match_winner_names[0]
				else:
					match_text += "Winners: " + ", ".join(match_winner_names)
					
			if not is_test_mode:
				if exit_to_menu_button:
					exit_to_menu_button.visible = true
				_show_final_announcement(match_text)
				rounds_completed = 0
			else:
				_show_announcement(match_text, 5.0)
				rounds_completed = 0
				all_round_scores.clear()
				_reset()
				_get_cards(false)
		else:
			# Automatically reset scoreboard and trigger a new round deal
			_reset()
			_get_cards(false)


func _play_sfx_transient(stream: AudioStream) -> void:
	if not stream: return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -5.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func _get_cards(keep_leader: bool = false) -> void:
	# Check if 4 loops have completed, in which case reset scoreboard for a new round
	if loop_count >= 4:
		loop_count = 0
		loop_scores.clear()
		_update_score_panel()

	var hand_area = $HandArea
	if not is_test_mode:
		confirm_button.disabled = true
		
		if breathing_tween:
			breathing_tween.kill()
		if left_breathing_tween:
			left_breathing_tween.kill()
		if right_breathing_tween:
			right_breathing_tween.kill()
		if top_breathing_tween:
			top_breathing_tween.kill()
			
		var screen_height = get_viewport_rect().size.y
		var viewport_size = get_viewport_rect().size
		
		var tween_out = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween_out.tween_property(hand_area, "position:y", screen_height + 50.0, 0.4)
		tween_out.tween_property(left_player, "position:x", -600.0, 0.4)
		tween_out.tween_property(right_player, "position:x", viewport_size.x + 600.0, 0.4)
		tween_out.tween_property(top_player, "position:y", -600.0, 0.4)
		
		await tween_out.finished
		
		# Hide hands off-screen while dealing and showing announcement
		hand_area.visible = false
		left_player.visible = false
		right_player.visible = false
		top_player.visible = false

	# 1. Clear any existing card views in all slots
	for slot in slots:
		for child in slot.get_children():
			child.queue_free()
	for slot in table_slots:
		for child in slot.get_children():
			child.queue_free()
	for slot in left_slots:
		for child in slot.get_children():
			child.queue_free()
	for slot in right_slots:
		for child in slot.get_children():
			child.queue_free()
	for slot in top_slots:
		for child in slot.get_children():
			child.queue_free()
			
	# Reset bot player visuals and place them off-screen before animating in
	left_player.texture = l_thinking_tex
	right_player.texture = r_thinking_tex
	top_player.texture = t_thinking_tex
	
	var viewport_size = get_viewport_rect().size
	left_player.position.x = -600.0
	right_player.position.x = viewport_size.x + 600.0
	top_player.position.y = -600.0
	
	# Clear all internal card state
	player_hand.clear()
	left_hand.clear()
	right_hand.clear()
	top_hand.clear()
	player_table_cards.clear()
	left_table_cards.clear()
	right_table_cards.clear()
	top_table_cards.clear()
	player_won_cards.clear()
	left_won_cards.clear()
	right_won_cards.clear()
	top_won_cards.clear()

	# Clear won areas
	_update_win_area_icons(player_win_area, 0)
	_update_win_area_icons(left_win_area, 0)
	_update_win_area_icons(right_win_area, 0)
	_update_win_area_icons(top_win_area, 0)

	# Initialize leader and active states
	if not keep_leader:
		current_leader = randi() % 4
	active_play_type = ""
	active_card_count = 0
	has_played = [false, false, false, false]
	
	var leader_name = "Player"
	if current_leader == 1: leader_name = bot_personalities.get(1, "Left Bot")
	elif current_leader == 2: leader_name = bot_personalities.get(2, "Top Bot")
	elif current_leader == 3: leader_name = bot_personalities.get(3, "Right Bot")
			
	# 2. Generate a fresh deck of 32 cards, shuffle, and deal 8 to each player
	var deck = _generate_deck()
	deck.shuffle()
	
	player_hand = deck.slice(0, 8)
	left_hand = deck.slice(8, 16)
	right_hand = deck.slice(16, 24)
	top_hand = deck.slice(24, 32)
	
	_initialize_loop_personalities()
	
	# 3. Create visual card nodes only for the user's hand
	for i in range(8):
		var card = player_hand[i]
		var slot = slots[i]
		
		var card_node = card_scene.instantiate()
		slot.add_child(card_node)
		
		# Set layout to fill parent Slot container
		card_node.anchor_right = 1.0
		card_node.anchor_bottom = 1.0
		card_node.offset_left = 0
		card_node.offset_top = 0
		card_node.offset_right = 0
		card_node.offset_bottom = 0
		
		card_node.setup_card(card["texture_path"])
		# Store card id as metadata on the node for later matching
		card_node.set_meta("card_id", card["id"])
	
	# Show start round announcement and wait for it to finish before showing hands
	var start_tween = _show_announcement("Start Round\nLeader: " + leader_name, 2.5)
	if start_tween and not is_test_mode:
		await start_tween.finished
		
	# Animate hand back up to default position if not in test mode, otherwise snap
	if not is_test_mode:
		hand_area.visible = true
		left_player.visible = true
		right_player.visible = true
		top_player.visible = true
		
		var tween_all = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# Animate player hand area up
		tween_all.tween_property(hand_area, "position:y", base_hand_y, 0.8)
		# Animate bot hands in from off-screen
		tween_all.tween_property(left_player, "position:x", base_left_x, 0.8)
		tween_all.tween_property(right_player, "position:x", base_right_x, 0.8)
		tween_all.tween_property(top_player, "position:y", base_top_y, 0.8)
		
		await tween_all.finished
		
		_start_breathing_animation()
		_start_left_breathing()
		_start_right_breathing()
		_start_top_breathing()
	else:
		hand_area.visible = true
		left_player.visible = true
		right_player.visible = true
		top_player.visible = true
		if base_hand_y != 0.0:
			hand_area.position.y = base_hand_y
		left_player.position.x = base_left_x
		right_player.position.x = base_right_x
		top_player.position.y = base_top_y
		_start_breathing_animation()
		_start_left_breathing()
		_start_right_breathing()
		_start_top_breathing()

	# Update button states for leader
	_update_button_states_for_turn()

	
	# Debug log
	_print_debug_state("GET CARDS - All players dealt")


func _generate_deck() -> Array:
	return CardRules.generate_deck()


func _get_card_ids(cards: Array) -> Array:
	var ids = []
	for c in cards:
		ids.append(c["id"])
	return ids


func _print_debug_state(context: String) -> void:
	var leader_name = "Player"
	if current_leader == 1: leader_name = "Left"
	elif current_leader == 2: leader_name = "Top"
	elif current_leader == 3: leader_name = "Right"
	
	print("=== ", context, " (Leader: ", leader_name, ") ===")
	print("Player Hand: ", _get_card_ids(player_hand), " | Won: ", player_won_cards.size())
	print("Player Table: ", _get_card_ids(player_table_cards))
	print("Left Hand: ", _get_card_ids(left_hand), " | Won: ", left_won_cards.size())
	print("Left Table: ", _get_card_ids(left_table_cards))
	print("Right Hand: ", _get_card_ids(right_hand), " | Won: ", right_won_cards.size())
	print("Right Table: ", _get_card_ids(right_table_cards))
	print("Top Hand: ", _get_card_ids(top_hand), " | Won: ", top_won_cards.size())
	print("Top Table: ", _get_card_ids(top_table_cards))
	print("=================")


func _has_everyone_played() -> bool:
	for i in range(4):
		var hand_sz = 0
		var table_sz = 0
		if i == 0:
			hand_sz = player_hand.size()
			table_sz = player_table_cards.size()
		elif i == 1:
			hand_sz = left_hand.size()
			table_sz = left_table_cards.size()
		elif i == 2:
			hand_sz = top_hand.size()
			table_sz = top_table_cards.size()
		else:
			hand_sz = right_hand.size()
			table_sz = right_table_cards.size()
			
		if (hand_sz + table_sz) > 0 and not has_played[i]:
			return false
	return true


func _update_leader_name_labels() -> void:
	var labels = [player_name_label, left_name_label, top_name_label, right_name_label]
	var base_names = [
		"Player",
		bot_personalities.get(1, "Left Bot"),
		bot_personalities.get(2, "Top Bot"),
		bot_personalities.get(3, "Right Bot")
	]
	
	for i in range(4):
		var lbl = labels[i]
		if not lbl:
			continue
		var name_str = base_names[i]
		if name_str == "" or name_str == null:
			lbl.text = ""
			continue
			
		if i == current_leader:
			lbl.text = "** " + name_str + " **"
			lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0)) # Gold Color
		else:
			lbl.text = name_str
			lbl.add_theme_color_override("font_color", Color.WHITE) # Normal White Color


func _update_button_states_for_turn() -> void:
	# If hands are empty, disable everything and return
	if player_hand.is_empty() and left_hand.is_empty() and right_hand.is_empty() and top_hand.is_empty():
		confirm_button.disabled = true
		_stop_state_timer()
		return
		
	# Check if everyone has played (or if the turn is transitioning to reveal/scoring)
	if _has_everyone_played():
		confirm_button.disabled = true
		_stop_state_timer()
		return
		
	if active_play_type == "":
		# Leader has not played yet
		confirm_button.disabled = (current_leader != 0)
		
		if current_timer_state != "leader":
			_start_state_timer("leader")
	else:
		# Leader has played, other players must respond
		confirm_button.disabled = has_played[0] or player_hand.is_empty()
		
		if current_timer_state != "responder":
			_start_state_timer("responder")
			
	# Auto Bot Plays Scheduling
	if active_play_type == "":
		if current_leader != 0 and not bots_thinking[current_leader]:
			_trigger_auto_bot_play(current_leader)
	else:
		# Bot Responders
		for i in [1, 2, 3]:
			var hand_sz = 0
			if i == 1: hand_sz = left_hand.size()
			elif i == 2: hand_sz = top_hand.size()
			else: hand_sz = right_hand.size()
			
			if hand_sz > 0 and not has_played[i] and not bots_thinking[i]:
				_trigger_auto_bot_play(i)


func _detect_play_type(cards: Array) -> String:
	return CardRules.detect_play_type(cards)


func _is_valid_play(cards: Array, play_type: String, required_count: int) -> bool:
	return CardRules.is_valid_play(cards, play_type, required_count)


func _compare_valid_plays(play_a: Array, play_b: Array, play_type: String) -> int:
	return CardRules.compare_valid_plays(play_a, play_b, play_type)


func _find_combinations(hand: Array, play_type: String, count: int) -> Array:
	return CardRules.find_combinations(hand, play_type, count)


func _initialize_loop_personalities() -> void:
	if loop_count == 0:
		# Very first loop of the round: randomly assign unique base personalities
		var pool = BotAI.PERSONALITY_POOL.duplicate()
		pool.shuffle()
		bot_personalities[1] = pool[0]
		bot_personalities[2] = pool[1]
		bot_personalities[3] = pool[2]
		print("--- ROUND START: Bot Personalities Assigned ---")
		print("Left Bot (1): ", bot_personalities[1])
		print("Top Bot (2): ", bot_personalities[2])
		print("Right Bot (3): ", bot_personalities[3])
		print("-----------------------------------------------")
		
	loop_count += 1
	
	print("--- Loop ", loop_count, " Active Bot Styles ---")
	print("Left Bot (1): ", bot_personalities[1])
	print("Top Bot (2): ", bot_personalities[2])
	print("Right Bot (3): ", bot_personalities[3])
	print("--------------------------------------")
	
	# Highlight active leader
	_update_leader_name_labels()


func _start_all_breathing() -> void:
	_start_breathing_animation()
	_start_left_breathing()
	_start_right_breathing()
	_start_top_breathing()

func _start_breathing_animation() -> void:
	# Wait a frame to let anchors resolve initial layout position
	await get_tree().process_frame
	
	var hand_area = $HandArea
	if base_hand_y == 0.0:
		base_hand_y = hand_area.position.y
	
	if breathing_tween:
		breathing_tween.kill()
	# Loop standard sine tween for idle breathing effect (6px up/down over 3.0s cycle)
	breathing_tween = create_tween().set_loops()
	breathing_tween.tween_property(hand_area, "position:y", base_hand_y + 6.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	breathing_tween.tween_property(hand_area, "position:y", base_hand_y, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_left_breathing() -> void:
	if left_breathing_tween:
		left_breathing_tween.kill()
	left_breathing_tween = create_tween().set_loops()
	left_breathing_tween.tween_property(left_player, "position:x", base_left_x + 6.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	left_breathing_tween.tween_property(left_player, "position:x", base_left_x, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_right_breathing() -> void:
	if right_breathing_tween:
		right_breathing_tween.kill()
	right_breathing_tween = create_tween().set_loops()
	right_breathing_tween.tween_property(right_player, "position:x", base_right_x - 6.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	right_breathing_tween.tween_property(right_player, "position:x", base_right_x, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _start_top_breathing() -> void:
	if top_breathing_tween:
		top_breathing_tween.kill()
	top_breathing_tween = create_tween().set_loops()
	top_breathing_tween.tween_property(top_player, "position:y", base_top_y + 6.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	top_breathing_tween.tween_property(top_player, "position:y", base_top_y, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_confirm_pressed() -> void:
	# 1. Collect all selected cards
	var selected_cards = []
	var selected_slots = []
	
	for slot in slots:
		if slot.get_child_count() > 0:
			var card = slot.get_child(0)
			if "is_selected" in card and card.is_selected:
				selected_cards.append(card)
				selected_slots.append(slot)
				
	if selected_cards.is_empty():
		return
		
	# Gather selected card data
	var selected_card_data = []
	for card in selected_cards:
		if card.has_meta("card_id"):
			var cid = card.get_meta("card_id")
			for hand_card in player_hand:
				if hand_card["id"] == cid:
					selected_card_data.append(hand_card)
					break
					
	# Validate player play
	if active_play_type == "":
		var detected = _detect_play_type(selected_card_data)
		if detected == "":
			print("Invalid combination for Leader! Must form Single, Pair, Noble Set, or Soldier Set.")
			return
		active_play_type = detected
		active_card_count = selected_cards.size()
		_show_announcement("Play Type: " + active_play_type, 2.0)
	else:
		if selected_cards.size() != active_card_count:
			print("Invalid count! Must play exactly ", active_card_count, " cards to match or fold.")
			return

	# Move selected card data from player_hand to player_table_cards
	for card in selected_cards:
		if card.has_meta("card_id"):
			var cid = card.get_meta("card_id")
			var found_idx = -1
			for idx in range(player_hand.size()):
				if player_hand[idx]["id"] == cid:
					found_idx = idx
					break
			if found_idx != -1:
				var card_data = player_hand[found_idx]
				player_hand.remove_at(found_idx)
				player_table_cards.append(card_data)

	confirm_button.disabled = true
	
	# Stop idle breathing animation
	if breathing_tween:
		breathing_tween.kill()
		
	# Step 1: HandArea moves down off-screen
	var hand_area = $HandArea
	var screen_height = get_viewport_rect().size.y
	
	var tween_down = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween_down.tween_property(hand_area, "position:y", screen_height + 50.0, 0.6)
	await tween_down.finished
	
	# Reparent selected cards to available TableSlots and configure them
	var newly_played_cards = []
	for card in selected_cards:
		var target_slot = null
		for t_slot in table_slots:
			if t_slot.get_child_count() == 0:
				target_slot = t_slot
				break
				
		if target_slot == null:
			# No more table slots available
			break
			
		var old_slot = card.get_parent()
		if old_slot:
			old_slot.remove_child(card)
			
		target_slot.add_child(card)
		
		# Configure layout to fill the TableSlot and match its size
		card.anchor_left = 0.0
		card.anchor_top = 0.0
		card.anchor_right = 1.0
		card.anchor_bottom = 1.0
		card.offset_left = 0
		card.offset_top = 0
		card.offset_right = 0
		card.offset_bottom = 0
		card.custom_minimum_size = target_slot.size
		card.pivot_offset = target_slot.size / 2.0
		
		# Deselect and reset visuals
		card.set_selected(false)
		card.reset_visuals()
		
		# Change texture to Backcard
		card.setup_card("res://asset/card/default/Backcard.png")
		
		# Reset basic node transforms and hide initially
		card.rotation = 0.0
		card.scale = Vector2.ONE
		card.visible = false
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		newly_played_cards.append(card)
		
	if newly_played_cards.is_empty():
		# If somehow no slots were available, just slide hand back and re-enable
		var tween_hand_up_again = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween_hand_up_again.tween_property(hand_area, "position:y", base_hand_y, 0.6)
		await tween_hand_up_again.finished
		_start_breathing_animation()
		confirm_button.disabled = false
		return
	
	# Step 2: Backhand moves up to the center of TableArea
	back_hand.visible = true
	back_hand.position.x = (get_viewport_rect().size.x - back_hand.size.x) / 2.0
	back_hand.position.y = screen_height + 50.0
	
	var target_hand_y = table_area.position.y + (table_area.size.y / 2.0) - (back_hand.size.y / 2.0) + BACKHAND_OFFSET
	
	var tween_hand_up = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_hand_up.tween_property(back_hand, "position:y", target_hand_y, 0.8)
	await tween_hand_up.finished
	
	# Step 3: Backcards appear inside their TableSlots
	var tween_reveal = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for card in newly_played_cards:
		card.visible = true
		card.scale = Vector2.ZERO
		card.modulate.a = 0.0
		tween_reveal.tween_property(card, "scale", Vector2.ONE, 0.35)
		tween_reveal.tween_property(card, "modulate:a", 1.0, 0.35)
	
	_play_sfx_transient(click_sfx)
	await tween_reveal.finished
	
	# Step 4: Backhand moves down off-screen
	var tween_hand_down = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween_hand_down.tween_property(back_hand, "position:y", screen_height + 50.0, 0.6)
	await tween_hand_down.finished
	back_hand.visible = false
	
	# Mark as played
	has_played[0] = true
	
	# Update buttons
	_update_button_states_for_turn()
	
	# Print debug state
	_print_debug_state("CONFIRM - Player confirmed " + str(selected_cards.size()) + " card(s)")
	
	# Check if everyone has played
	if _has_everyone_played():
		_start_reveal_and_scoring_sequence()

func _play_ready_sequence(player: TextureRect, table_area: Control, slots_list: Array, thinking_tex: Texture2D, direction: String) -> void:
	# Find appropriate hand data reference
	var hand_ref: Array
	var table_ref: Array
	if direction == "left":
		hand_ref = left_hand
		table_ref = left_table_cards
	elif direction == "right":
		hand_ref = right_hand
		table_ref = right_table_cards
	else:
		hand_ref = top_hand
		table_ref = top_table_cards
		
	# Determine bot player index (1=Left, 2=Top, 3=Right)
	var bot_idx = 1
	if direction == "left": bot_idx = 1
	elif direction == "right": bot_idx = 3
	else: bot_idx = 2

	# Pick cards using Decoupled BotAI helper
	var played_cards_data = BotAI.select_play(self, hand_ref, active_play_type, active_card_count, bot_idx)
	var num_cards = played_cards_data.size()
	
	if num_cards == 0:
		print("No cards left to play for bot in direction: ", direction)
		return
		
	# If bot is leader, lock active play type and card count
	if active_play_type == "":
		active_card_count = num_cards
		active_play_type = _detect_play_type(played_cards_data)
		_show_announcement("Play Type: " + active_play_type, 2.0)
		print("Leader Bot ", direction, " plays: ", active_play_type, " of count ", active_card_count)
		
	# Remove played cards from hand_ref and add to table_ref
	for card in played_cards_data:
		var idx = -1
		for k in range(hand_ref.size()):
			if hand_ref[k]["id"] == card["id"]:
				idx = k
				break
		if idx != -1:
			hand_ref.remove_at(idx)
		table_ref.append(card)


	
	# Stop breathing tween
	var breathing_tween: Tween
	var base_pos = Vector2.ZERO
	if direction == "left":
		breathing_tween = left_breathing_tween
		base_pos = Vector2(base_left_x, player.position.y)
	elif direction == "right":
		breathing_tween = right_breathing_tween
		base_pos = Vector2(base_right_x, player.position.y)
	else:
		breathing_tween = top_breathing_tween
		base_pos = Vector2(player.position.x, base_top_y)
		
	if breathing_tween:
		breathing_tween.kill()
		
	# Move off-screen
	var viewport_size = get_viewport_rect().size
	var target_offscreen = base_pos
	if direction == "left":
		target_offscreen.x = -600.0
	elif direction == "right":
		target_offscreen.x = viewport_size.x + 600.0
	else:
		target_offscreen.y = -600.0
		
	var tween_out = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween_out.tween_property(player, "position", target_offscreen, 0.6)
	await tween_out.finished
	
	# Change texture to backhand
	player.texture = backhand_tex
	
	# Move to table area center
	var area_center = table_area.position + (table_area.size / 2.0).rotated(table_area.rotation)
	var target_table_pos = area_center - (player.size / 2.0).rotated(player.rotation)
	
	# Apply offset to pull the hand back towards its respective screen edge
	if direction == "left":
		target_table_pos += Vector2.LEFT * SIDE_BACKHAND_OFFSET
	elif direction == "right":
		target_table_pos += Vector2.RIGHT * SIDE_BACKHAND_OFFSET
	else: # top
		target_table_pos += Vector2.UP * TOP_BACKHAND_OFFSET
		
	var tween_in = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(player, "position", target_table_pos, 0.8)
	await tween_in.finished
	
	# Spawn cards inside slots
	var newly_played = []
	for i in range(num_cards):
		var slot = slots_list[i]
		# Clear existing cards in this slot
		for child in slot.get_children():
			child.queue_free()
			
		var card = card_scene.instantiate()
		slot.add_child(card)
		
		card.anchor_left = 0.0
		card.anchor_top = 0.0
		card.anchor_right = 1.0
		card.anchor_bottom = 1.0
		card.offset_left = 0
		card.offset_top = 0
		card.offset_right = 0
		card.offset_bottom = 0
		card.custom_minimum_size = slot.size
		card.pivot_offset = slot.size / 2.0
		
		card.setup_card("res://asset/card/default/Backcard.png")
		# Store metadata for identification
		var card_data = played_cards_data[i]
		card.set_meta("card_id", card_data["id"])
		
		card.visible = false
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		newly_played.append(card)
		
	# Reveal cards
	var tween_reveal = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for card in newly_played:
		card.visible = true
		card.scale = Vector2.ZERO
		card.modulate.a = 0.0
		tween_reveal.tween_property(card, "scale", Vector2.ONE, 0.35)
		tween_reveal.tween_property(card, "modulate:a", 1.0, 0.35)
	
	_play_sfx_transient(click_sfx)
	await tween_reveal.finished
	
	# Move hand off-screen again
	var tween_back = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween_back.tween_property(player, "position", target_offscreen, 0.6)
	await tween_back.finished
	
	player.visible = false
	
	# Mark as played
	has_played[bot_idx] = true
	
	# Update button states for others
	_update_button_states_for_turn()
	

	
	# Print debug state
	_print_debug_state("READY - Bot " + direction + " played " + str(num_cards) + " card(s)")
	
	# Check if everyone has played
	if _has_everyone_played():
		_start_reveal_and_scoring_sequence()

func _reset() -> void:
	# Clear all internal card state
	player_hand.clear()
	left_hand.clear()
	right_hand.clear()
	top_hand.clear()
	player_table_cards.clear()
	left_table_cards.clear()
	right_table_cards.clear()
	top_table_cards.clear()
	player_won_cards.clear()
	left_won_cards.clear()
	right_won_cards.clear()
	top_won_cards.clear()

	# Clear won areas
	_update_win_area_icons(player_win_area, 0)
	_update_win_area_icons(left_win_area, 0)
	_update_win_area_icons(right_win_area, 0)
	_update_win_area_icons(top_win_area, 0)

	# Clear active states
	current_leader = 0
	active_play_type = ""
	active_card_count = 0
	has_played = [false, false, false, false]
	
	loop_count = 0
	bot_personalities.clear()
	loop_scores.clear()
	bots_thinking = [false, false, false, false]
	_update_score_panel()
	_show_score_panel(false)
	
	# Clear the texts on reset
	player_name_label.text = ""
	left_name_label.text = ""
	top_name_label.text = ""
	right_name_label.text = ""

	# Clear all cards in slots for everyone
	for slot in slots:
		for child in slot.get_children():
			child.queue_free()
	for slot in table_slots:
		for child in slot.get_children():
			child.queue_free()
	for slot in left_slots:
		for child in slot.get_children():
			child.queue_free()
	for slot in right_slots:
		for child in slot.get_children():
			child.queue_free()
	for slot in top_slots:
		for child in slot.get_children():
			child.queue_free()
			
	# Reset textures
	left_player.texture = l_thinking_tex
	right_player.texture = r_thinking_tex
	top_player.texture = t_thinking_tex
	
	# Make players visible
	left_player.visible = true
	right_player.visible = true
	top_player.visible = true
	
	# Reset main player's HandArea position and backhand if visible
	var hand_area = $HandArea
	if base_hand_y != 0.0:
		hand_area.position.y = base_hand_y
	back_hand.visible = false
	
	# Tween hands back to base positions
	var tween_reset = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_reset.tween_property(left_player, "position", Vector2(base_left_x, left_player.position.y), 0.6)
	tween_reset.tween_property(right_player, "position", Vector2(base_right_x, right_player.position.y), 0.6)
	tween_reset.tween_property(top_player, "position", Vector2(top_player.position.x, base_top_y), 0.6)
	await tween_reset.finished
	
	# Restart breathing tweens
	_start_all_breathing()
	
	# Re-enable buttons
	_update_button_states_for_turn()

	
	# Print debug state
	_print_debug_state("RESET - Game state cleared")


func _reveal_table_cards(slots_list: Array, table_cards_data: Array, is_folded: bool) -> void:
	for i in range(table_cards_data.size()):
		if i < slots_list.size():
			var slot = slots_list[i]
			if slot.get_child_count() > 0:
				var card_node = slot.get_child(0)
				if is_folded:
					card_node.setup_card("res://asset/card/default/Backcard.png")
				else:
					card_node.setup_card(table_cards_data[i]["texture_path"])


func _determine_turn_winner() -> int:
	var play_type = active_play_type
	var required_count = active_card_count
	
	var is_valid_list = [
		_is_valid_play(player_table_cards, play_type, required_count),
		_is_valid_play(left_table_cards, play_type, required_count),
		_is_valid_play(top_table_cards, play_type, required_count),
		_is_valid_play(right_table_cards, play_type, required_count)
	]
	
	var plays = [
		player_table_cards,
		left_table_cards,
		top_table_cards,
		right_table_cards
	]
	
	# Find players with valid plays
	var valid_players = []
	for i in range(4):
		if plays[i].size() > 0 and is_valid_list[i]:
			valid_players.append(i)
			
	print("--- Winner Determination Debug ---")
	print("  Leader: ", current_leader)
	print("  Play Type: ", play_type, " | Count: ", required_count)
	for i in range(4):
		var p_name = "Player"
		if i == 1: p_name = bot_personalities.get(1, "Left Bot")
		elif i == 2: p_name = bot_personalities.get(2, "Top Bot")
		elif i == 3: p_name = bot_personalities.get(3, "Right Bot")
		print("  ", p_name, " Table Cards: ", _get_card_ids(plays[i]), " | Valid: ", is_valid_list[i])
		
	if valid_players.is_empty():
		print("  Everyone folded! Leader wins: ", current_leader)
		print("----------------------------------")
		return current_leader
		
	# Find the strongest play among valid plays
	var best_player = valid_players[0]
	for i in range(1, valid_players.size()):
		var p = valid_players[i]
		var cmp = _compare_valid_plays(plays[p], plays[best_player], play_type)
		print("  Comparing ", p, " vs ", best_player, " -> cmp result: ", cmp)
		if cmp > 0:
			best_player = p
		elif cmp == 0:
			# Tie breaker: who is closer to current_leader clockwise? Bottom -> Left -> Top -> Right -> Bottom
			var dist_p = posmod(p - current_leader, 4)
			var dist_best = posmod(best_player - current_leader, 4)
			print("    Tie! Dist ", p, ": ", dist_p, " | Dist ", best_player, ": ", dist_best)
			if dist_p < dist_best:
				best_player = p
				
	print("  Winner Chosen: ", best_player)
	print("----------------------------------")
	return best_player


func _reparent_card_to_top_level(card_node: Control) -> void:
	if not card_node:
		return
	var orig_pos = card_node.global_position
	var orig_rot = card_node.get_global_transform().get_rotation()
	var orig_size = card_node.size
	
	card_node.reparent(self, false) # Reparent without native global transform conversion to avoid anchor matching quirks
	
	# Reset anchors to absolute positioning under self
	card_node.anchor_left = 0.0
	card_node.anchor_top = 0.0
	card_node.anchor_right = 0.0
	card_node.anchor_bottom = 0.0
	card_node.offset_left = 0
	card_node.offset_top = 0
	card_node.offset_right = 0
	card_node.offset_bottom = 0
	
	# Re-apply dimensions and transform details
	card_node.size = orig_size
	card_node.custom_minimum_size = orig_size
	card_node.pivot_offset = orig_size / 2.0
	card_node.global_position = orig_pos
	card_node.rotation = orig_rot
	card_node.scale = Vector2.ONE
	card_node.z_index = 0


func _show_winner(winner_idx: int) -> void:
	var slots_list = []
	if winner_idx == 0: slots_list = table_slots
	elif winner_idx == 1: slots_list = left_slots
	elif winner_idx == 2: slots_list = top_slots
	else: slots_list = right_slots
	
	var winner_cards = []
	for slot in slots_list:
		if slot.get_child_count() > 0:
			winner_cards.append(slot.get_child(0))
			
	if not winner_cards.is_empty() and not is_test_mode:
		# Scale up to 1.4x
		var tween_up = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		for card in winner_cards:
			card.z_index = 10
			card.pivot_offset = card.size / 2.0
			tween_up.tween_property(card, "scale", Vector2(1.4, 1.4), 0.3)
		await tween_up.finished
		
		# Stay big for 2 seconds
		await get_tree().create_timer(2.0).timeout
		
		# Shrink back to 1.0x
		var tween_down = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		for card in winner_cards:
			tween_down.tween_property(card, "scale", Vector2.ONE, 0.3)
		await tween_down.finished
		for card in winner_cards:
			card.z_index = 0
	elif not winner_cards.is_empty() and is_test_mode:
		pass
		
	# Show announcement of the winner name
	var winner_name = "Player"
	if winner_idx == 1: winner_name = bot_personalities.get(1, "Left Bot")
	elif winner_idx == 2: winner_name = bot_personalities.get(2, "Top Bot")
	elif winner_idx == 3: winner_name = bot_personalities.get(3, "Right Bot")
	
	var tween_announce = _show_announcement("Winner: " + winner_name, 2.0)
	if tween_announce and not is_test_mode:
		await tween_announce.finished


func _collect_cards_to_winner(winner_idx: int) -> void:
	var winner_won_ref: Array
	var winner_win_area: Control
	
	if winner_idx == 0:
		winner_won_ref = player_won_cards
		winner_win_area = player_win_area
	elif winner_idx == 1:
		winner_won_ref = left_won_cards
		winner_win_area = left_win_area
	elif winner_idx == 2:
		winner_won_ref = top_won_cards
		winner_win_area = top_win_area
	else:
		winner_won_ref = right_won_cards
		winner_win_area = right_win_area

	# 1. Setup hand visual node, base positions, and targets based on winner_idx
	var winner_hand_node: Control
	var bottom_target: float = 0.0
	var hand_target: Vector2 = Vector2.ZERO
	var hand_offscreen: Vector2 = Vector2.ZERO
	
	var viewport_size = get_viewport_rect().size
	var screen_height = viewport_size.y
	
	if winner_idx == 0:
		winner_hand_node = back_hand
		bottom_target = table_area.position.y + (table_area.size.y / 2.0) - (back_hand.size.y / 2.0) + BACKHAND_OFFSET
	elif winner_idx == 1:
		winner_hand_node = left_player
		left_player.texture = backhand_tex
		hand_offscreen = Vector2(-600.0, left_player.position.y)
		var left_center = left_table_area.position + (left_table_area.size / 2.0).rotated(left_table_area.rotation)
		hand_target = left_center - (left_player.size / 2.0).rotated(left_player.rotation) + Vector2.LEFT * SIDE_BACKHAND_OFFSET
	elif winner_idx == 2:
		winner_hand_node = top_player
		top_player.texture = backhand_tex
		hand_offscreen = Vector2(top_player.position.x, -600.0)
		var top_center = top_table_area.position + (top_table_area.size / 2.0).rotated(top_table_area.rotation)
		hand_target = top_center - (top_player.size / 2.0).rotated(top_player.rotation) + Vector2.UP * TOP_BACKHAND_OFFSET
	else:
		winner_hand_node = right_player
		right_player.texture = backhand_tex
		hand_offscreen = Vector2(viewport_size.x + 600.0, right_player.position.y)
		var right_center = right_table_area.position + (right_table_area.size / 2.0).rotated(right_table_area.rotation)
		hand_target = right_center - (right_player.size / 2.0).rotated(right_player.rotation) + Vector2.RIGHT * SIDE_BACKHAND_OFFSET

	# 2. Position hand off-screen and animate toward the table area (Grab Phase)
	if not is_test_mode:
		winner_hand_node.visible = true
		if winner_idx == 0:
			winner_hand_node.position.y = screen_height + 50.0
			winner_hand_node.position.x = (viewport_size.x - winner_hand_node.size.x) / 2.0
		else:
			winner_hand_node.position = hand_offscreen
			
		var grab_hand_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if winner_idx == 0:
			grab_hand_tween.tween_property(winner_hand_node, "position:y", bottom_target, 0.6)
		else:
			grab_hand_tween.tween_property(winner_hand_node, "position", hand_target, 0.6)
		await grab_hand_tween.finished

	# Play sfx after hand reaches cards
	_play_sfx_transient(click_sfx)
	if not is_test_mode:
		await get_tree().create_timer(0.2).timeout

	# 3. Update won card data collections
	var current_won_count = winner_won_ref.size()
	winner_won_ref.append_array(player_table_cards)
	winner_won_ref.append_array(left_table_cards)
	winner_won_ref.append_array(right_table_cards)
	winner_won_ref.append_array(top_table_cards)
	
	# Clear tables card data
	player_table_cards.clear()
	left_table_cards.clear()
	right_table_cards.clear()
	top_table_cards.clear()

	# 4. Gather all played cards from slots
	var cards_to_collect = []
	var all_slots = table_slots + left_slots + top_slots + right_slots
	for slot in all_slots:
		if slot.get_child_count() > 0:
			var card_node = slot.get_child(0)
			_reparent_card_to_top_level(card_node)
			move_child(card_node, -1)
			cards_to_collect.append(card_node)

	# 5. Animate cards flying to the winner's win area along with the hand (Flight Phase)
	if not cards_to_collect.is_empty() and not is_test_mode:
		var hand_win_target = winner_win_area.global_position + (winner_win_area.size / 2.0) - (winner_hand_node.size / 2.0)
		var collect_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		
		# Move hand to win area
		if winner_idx == 0:
			collect_tween.tween_property(winner_hand_node, "position", hand_win_target, 0.8)
		else:
			collect_tween.tween_property(winner_hand_node, "global_position", hand_win_target, 0.8)
			
		# Move cards to win area
		for i in range(cards_to_collect.size()):
			var card_node = cards_to_collect[i]
			card_node.pivot_offset = card_node.size / 2.0
			
			var stack_offset = i / 4
			var stack_idx = (current_won_count / 4) + 1 + stack_offset
			stack_idx = clamp(stack_idx, 1, 8)
			
			var icon_node = winner_win_area.get_node_or_null("CardIcon_" + str(stack_idx))
			var target_pos: Vector2
			if icon_node:
				target_pos = icon_node.global_position + (icon_node.size / 2.0) - (card_node.size / 2.0)
			else:
				target_pos = winner_win_area.global_position + (winner_win_area.size / 2.0) - (card_node.size / 2.0)
				
			collect_tween.tween_property(card_node, "global_position", target_pos, 0.8)
			collect_tween.tween_property(card_node, "scale", Vector2(0.5, 0.5), 0.8)
			collect_tween.tween_property(card_node, "modulate:a", 0.0, 0.8)
			
		await collect_tween.finished
		
	# Free visual card nodes
	for card_node in cards_to_collect:
		card_node.queue_free()

	# 6. Update the win area stack counters
	_update_win_area_icons(winner_win_area, winner_won_ref.size())

	# 7. Move winner's hand back off-screen and hide it (Return Phase)
	if not is_test_mode:
		var return_hand_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		if winner_idx == 0:
			return_hand_tween.tween_property(winner_hand_node, "position:y", screen_height + 50.0, 0.6)
		else:
			return_hand_tween.tween_property(winner_hand_node, "position", hand_offscreen, 0.6)
		await return_hand_tween.finished
		winner_hand_node.visible = false


func _update_win_area_icons(win_area: Control, won_cards_count: int) -> void:
	if not win_area:
		return
	var visible_count = won_cards_count / 4
	for i in range(1, 9):
		var icon_node = win_area.get_node_or_null("CardIcon_" + str(i))
		if icon_node:
			icon_node.visible = (i <= visible_count)


func _show_announcement(text: String, duration: float = 2.0) -> Tween:
	if not announcement or not announcement_text:
		return null
	announcement_text.text = text
	
	if announcement_tween:
		announcement_tween.kill()
		
	announcement.visible = true
	announcement.modulate.a = 0.0
	
	announcement_tween = create_tween()
	# Fade in
	announcement_tween.tween_property(announcement, "modulate:a", 1.0, 0.3).from(0.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Wait duration
	announcement_tween.tween_interval(duration)
	# Fade out
	announcement_tween.tween_property(announcement, "modulate:a", 0.0, 0.4).from(1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Hide
	announcement_tween.tween_callback(func(): announcement.visible = false)
	return announcement_tween


func _show_final_announcement(text: String) -> void:
	if not announcement or not announcement_text:
		return
	announcement_text.text = text
	
	if announcement_tween:
		announcement_tween.kill()
		
	announcement.visible = true
	announcement.modulate.a = 0.0
	
	announcement_tween = create_tween()
	# Fade in and keep it visible
	announcement_tween.tween_property(announcement, "modulate:a", 1.0, 0.3).from(0.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _start_reveal_and_scoring_sequence() -> void:
	confirm_button.disabled = true
	
	_show_announcement("Revealing The Card!", 2.0)
	
	# 1. 2 seconds delay
	await get_tree().create_timer(2.0).timeout
	
	# 2. Setup reveal positions for the hands (exact target positions from play sequences)
	# Bottom Player Hand setup
	var screen_height = get_viewport_rect().size.y
	back_hand.visible = true
	back_hand.position.y = screen_height + 50.0
	back_hand.position.x = (get_viewport_rect().size.x - back_hand.size.x) / 2.0
	var bottom_target = table_area.position.y + (table_area.size.y / 2.0) - (back_hand.size.y / 2.0) + BACKHAND_OFFSET
	
	# Left Player Hand setup
	left_player.texture = backhand_tex
	left_player.visible = true
	var left_base = Vector2(base_left_x, left_player.position.y)
	var left_offscreen = Vector2(-600.0, left_player.position.y)
	left_player.position = left_offscreen
	var left_center = left_table_area.position + (left_table_area.size / 2.0).rotated(left_table_area.rotation)
	var left_target = left_center - (left_player.size / 2.0).rotated(left_player.rotation) + Vector2.LEFT * SIDE_BACKHAND_OFFSET
	
	# Right Player Hand setup
	right_player.texture = backhand_tex
	right_player.visible = true
	var right_base = Vector2(base_right_x, right_player.position.y)
	var right_offscreen = Vector2(get_viewport_rect().size.x + 600.0, right_player.position.y)
	right_player.position = right_offscreen
	var right_center = right_table_area.position + (right_table_area.size / 2.0).rotated(right_table_area.rotation)
	var right_target = right_center - (right_player.size / 2.0).rotated(right_player.rotation) + Vector2.RIGHT * SIDE_BACKHAND_OFFSET
	
	# Top Player Hand setup
	top_player.texture = backhand_tex
	top_player.visible = true
	var top_base = Vector2(top_player.position.x, base_top_y)
	var top_offscreen = Vector2(top_player.position.x, -600.0)
	top_player.position = top_offscreen
	var top_center = top_table_area.position + (top_table_area.size / 2.0).rotated(top_table_area.rotation)
	var top_target = top_center - (top_player.size / 2.0).rotated(top_player.rotation) + Vector2.UP * TOP_BACKHAND_OFFSET
	
	# Tween hands to table slot positions simultaneously
	var tween_in = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(back_hand, "position:y", bottom_target, 0.8)
	tween_in.tween_property(left_player, "position", left_target, 0.8)
	tween_in.tween_property(right_player, "position", right_target, 0.8)
	tween_in.tween_property(top_player, "position", top_target, 0.8)
	await tween_in.finished
	
	# Reveal the real cards
	var play_type = active_play_type
	var required_count = active_card_count
	var player_folded = player_table_cards.size() > 0 and not _is_valid_play(player_table_cards, play_type, required_count)
	var left_folded = left_table_cards.size() > 0 and not _is_valid_play(left_table_cards, play_type, required_count)
	var top_folded = top_table_cards.size() > 0 and not _is_valid_play(top_table_cards, play_type, required_count)
	var right_folded = right_table_cards.size() > 0 and not _is_valid_play(right_table_cards, play_type, required_count)
	
	_reveal_table_cards(table_slots, player_table_cards, player_folded)
	_reveal_table_cards(left_slots, left_table_cards, left_folded)
	_reveal_table_cards(right_slots, right_table_cards, right_folded)
	_reveal_table_cards(top_slots, top_table_cards, top_folded)
	_play_sfx_transient(click_sfx)
	
	# Move hands back off-screen
	var tween_out = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween_out.tween_property(back_hand, "position:y", screen_height + 50.0, 0.6)
	tween_out.tween_property(left_player, "position", left_offscreen, 0.6)
	tween_out.tween_property(right_player, "position", right_offscreen, 0.6)
	tween_out.tween_property(top_player, "position", top_offscreen, 0.6)
	await tween_out.finished
	
	back_hand.visible = false
	left_player.visible = false
	right_player.visible = false
	top_player.visible = false
	
	# Wait 2 seconds showing the revealed cards
	await get_tree().create_timer(2.0).timeout
	
	# Determine winner
	var winner_idx = _determine_turn_winner()
	var winner_name = "Player"
	if winner_idx == 1: winner_name = bot_personalities.get(1, "Left Bot")
	elif winner_idx == 2: winner_name = bot_personalities.get(2, "Top Bot")
	elif winner_idx == 3: winner_name = bot_personalities.get(3, "Right Bot")
	
	print("Scoring: Winner of the turn is ", winner_name)
	
	# Animate card collection to winner
	await _show_winner(winner_idx)
	await _collect_cards_to_winner(winner_idx)
	
	# Set next leader to winner
	current_leader = winner_idx
	
	# Update name labels for the new leader
	_update_leader_name_labels()
	
	# Reset active turn properties
	active_play_type = ""
	active_card_count = 0
	has_played = [false, false, false, false]
	

	
	# Check if hand cards are empty (loop ends)
	if player_hand.is_empty():
		print("Round completed! All cards played.")
		
		# Calculate and store scores: Score = (Collected Cards) / 4
		var p_score = player_won_cards.size() / 4
		var l_score = left_won_cards.size() / 4
		var t_score = top_won_cards.size() / 4
		var r_score = right_won_cards.size() / 4
		
		var r_idx = rounds_completed
		while all_round_scores.size() <= r_idx:
			all_round_scores.append([])
			
		var loop_idx = loop_count - 1 # loop_count is 1-indexed (incremented in _initialize_loop_personalities)
		var round_scores = all_round_scores[r_idx]
		while round_scores.size() <= loop_idx:
			round_scores.append({"player": 0, "left": 0, "top": 0, "right": 0})
		round_scores[loop_idx] = {
			"player": p_score,
			"left": l_score,
			"top": t_score,
			"right": r_score
		}
		
		_update_score_panel()
		_update_button_states_for_turn()
		
		# Trigger automatic scoreboard display and transition
		_finish_loop_and_transition()
	else:
		# Enforce new leader button states for the next turn
		_update_button_states_for_turn()
		
		# Tween active player hands back to thinking positions
		var tween_restore = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if not left_hand.is_empty():
			left_player.texture = l_thinking_tex
			left_player.visible = true
			tween_restore.tween_property(left_player, "position", left_base, 0.6)
		if not right_hand.is_empty():
			right_player.texture = r_thinking_tex
			right_player.visible = true
			tween_restore.tween_property(right_player, "position", right_base, 0.6)
		if not top_hand.is_empty():
			top_player.texture = t_thinking_tex
			top_player.visible = true
			tween_restore.tween_property(top_player, "position", top_base, 0.6)
			
		# Player HandArea back up
		var hand_area = $HandArea
		tween_restore.tween_property(hand_area, "position:y", base_hand_y, 0.6)
		
		await tween_restore.finished
		
		# Restart breathing tweens
		_start_all_breathing()
			
	_print_debug_state("TURN ENDED")
