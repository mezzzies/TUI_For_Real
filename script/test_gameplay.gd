extends Control

const BotAI = preload("res://script/bot_ai.gd")

const BACKHAND_OFFSET = 40.0
const TOP_BACKHAND_OFFSET = 40.0
const SIDE_BACKHAND_OFFSET = 100.0

@onready var get_cards_button = $GetCardsButton
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
@onready var reset_button = $ResetButton
@onready var left_ready_button = $LeftReadyButton
@onready var right_ready_button = $RightReadyButton
@onready var top_ready_button = $TopReadyButton

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
# The active personality for the current loop (resolves Meta Mezz transitions)
var active_bot_personalities: Dictionary = {}
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

# Timer Configuration & State
<<<<<<< HEAD
@export var leader_select_time: float = 20.0
@export var responder_select_time: float = 20.0
=======
@export var leader_select_time: float = 5.0
@export var responder_select_time: float = 5.0
>>>>>>> 94e3a1a041b04d1f95156a394635f520424a4a9c

@onready var time_label = get_node_or_null("Time")

var state_time_left: float = 0.0
var is_timer_running: bool = false
var current_timer_state: String = ""
var is_test_mode: bool = false

# Scoreboard State & Bindings
@onready var score_panel = get_node_or_null("ScorePanel")
@onready var score_grid = get_node_or_null("ScorePanel/ScoreContainer/ScoreGrid")

var loop_scores: Array = []

func _ready() -> void:
	if back_hand:
		back_hand.visible = false
		back_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
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
	get_cards_button.focus_mode = Control.FOCUS_NONE
	confirm_button.focus_mode = Control.FOCUS_NONE
	reset_button.focus_mode = Control.FOCUS_NONE
	left_ready_button.focus_mode = Control.FOCUS_NONE
	right_ready_button.focus_mode = Control.FOCUS_NONE
	top_ready_button.focus_mode = Control.FOCUS_NONE

	# Connect button events
	get_cards_button.pressed.connect(_on_get_cards_pressed)
	get_cards_button.pressed.connect(func(): _play_sfx_transient(click_sfx))
	get_cards_button.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	confirm_button.pressed.connect(func(): _play_sfx_transient(click_sfx))
	confirm_button.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
	
	reset_button.pressed.connect(_on_reset_pressed)
	reset_button.pressed.connect(func(): _play_sfx_transient(click_sfx))
	reset_button.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
	
	left_ready_button.pressed.connect(func(): _play_ready_sequence(left_player, left_table_area, left_slots, left_ready_button, l_thinking_tex, "left"))
	left_ready_button.pressed.connect(func(): _play_sfx_transient(click_sfx))
	left_ready_button.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
	
	right_ready_button.pressed.connect(func(): _play_ready_sequence(right_player, right_table_area, right_slots, right_ready_button, r_thinking_tex, "right"))
	right_ready_button.pressed.connect(func(): _play_sfx_transient(click_sfx))
	right_ready_button.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
	
	top_ready_button.pressed.connect(func(): _play_ready_sequence(top_player, top_table_area, top_slots, top_ready_button, t_thinking_tex, "top"))
	top_ready_button.pressed.connect(func(): _play_sfx_transient(click_sfx))
	top_ready_button.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
	
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
<<<<<<< HEAD
		
	# Initialize time label visibility
	_update_time_label()
=======
>>>>>>> 94e3a1a041b04d1f95156a394635f520424a4a9c


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
		await _play_ready_sequence(left_player, left_table_area, left_slots, left_ready_button, l_thinking_tex, "left")
	elif bot_idx == 2:
		await _play_ready_sequence(top_player, top_table_area, top_slots, top_ready_button, t_thinking_tex, "top")
	elif bot_idx == 3:
		await _play_ready_sequence(right_player, right_table_area, right_slots, right_ready_button, r_thinking_tex, "right")


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
					await _play_ready_sequence(left_player, left_table_area, left_slots, left_ready_button, l_thinking_tex, "left")
				elif i == 2:
					await _play_ready_sequence(top_player, top_table_area, top_slots, top_ready_button, t_thinking_tex, "top")
				elif i == 3:
					await _play_ready_sequence(right_player, right_table_area, right_slots, right_ready_button, r_thinking_tex, "right")


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
	if event is InputEventKey and event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled() # Consume key event to block built-in Control focus cycling
		if event.pressed:
			_show_score_panel(true)
		else:
			_show_score_panel(false)


func _show_score_panel(show: bool) -> void:
	if not score_panel:
		return
	if show:
		_update_score_panel()
		score_panel.visible = true
	else:
		score_panel.visible = false


func _update_score_panel() -> void:
	if not score_grid:
		return
		
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
		{"name": "Player", "key": "player"},
		{"name": bot_personalities.get(1, "Left Bot"), "key": "left"},
		{"name": bot_personalities.get(2, "Top Bot"), "key": "top"},
		{"name": bot_personalities.get(3, "Right Bot"), "key": "right"}
	]
	
	for p_info in players:
		var name_lbl = Label.new()
		name_lbl.text = p_info["name"]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_override("font", custom_font)
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		name_lbl.add_theme_constant_override("outline_size", 4)
		name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		score_grid.add_child(name_lbl)
		
		var total_score = 0
		for loop_idx in range(4):
			var score_lbl = Label.new()
			var val = ""
			if loop_idx < loop_scores.size():
				var s = loop_scores[loop_idx][p_info["key"]]
				val = str(s)
				total_score += s
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

	# 3. Add Check Sum Row (should be 8 for each loop, and up to 32 at Total)
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
		if loop_idx < loop_scores.size():
			var s = loop_scores[loop_idx]["player"] + loop_scores[loop_idx]["left"] + loop_scores[loop_idx]["top"] + loop_scores[loop_idx]["right"]
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
		
	var grand_lbl = Label.new()
	grand_lbl.text = str(grand_checksum)
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
		_on_get_cards_pressed(true)
	else:
		# Round is complete (4 loops finished)
		# Calculate round winner
		var totals = {"player": 0, "left": 0, "top": 0, "right": 0}
		for s in loop_scores:
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
			winner_text = "Round Winner:\n" + winner_names[0]
		else:
			winner_text = "Round Tie:\n" + ", ".join(winner_names)
			
		_show_announcement(winner_text, 4.0)


func _play_sfx_transient(stream: AudioStream) -> void:
	if not stream: return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -5.0
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func _on_get_cards_pressed(keep_leader: bool = false) -> void:
	# Check if 4 loops have completed, in which case reset scoreboard for a new round
	if loop_count >= 4:
		loop_count = 0
		loop_scores.clear()
		_update_score_panel()

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
			
	# Reset HandArea position and restart breathing animation
	var hand_area = $HandArea
	if breathing_tween:
		breathing_tween.kill()
	if base_hand_y != 0.0:
		hand_area.position.y = base_hand_y
	_start_breathing_animation()
	
	# Reset bot player visuals
	left_player.texture = l_thinking_tex
	right_player.texture = r_thinking_tex
	top_player.texture = t_thinking_tex
	left_player.visible = true
	right_player.visible = true
	top_player.visible = true
	left_player.position.x = base_left_x
	right_player.position.x = base_right_x
	top_player.position.y = base_top_y
	_start_left_breathing()
	_start_right_breathing()
	_start_top_breathing()
	
	# Re-enable all buttons
	left_ready_button.disabled = false
	right_ready_button.disabled = false
	top_ready_button.disabled = false
	
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
	
	_show_announcement("Start Round\nLeader: " + leader_name, 2.5)
			
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
	
	# Update button states for leader
	_update_button_states_for_turn()
	
	# Debug log
	_print_debug_state("GET CARDS - All players dealt")


func _generate_deck() -> Array:
	var new_deck = []
	var card_defs = [
		{"rank": 1, "filename": "1King"},
		{"rank": 2, "filename": "2Plane"},
		{"rank": 3, "filename": "3Elephant"},
		{"rank": 4, "filename": "4Boat"},
		{"rank": 5, "filename": "5Horse"},
		{"rank": 6, "filename": "6House"},
		{"rank": 7, "filename": "7Chip"}
	]
	var counts = {
		1: 1, # General
		2: 2, # Advisor
		3: 2, # Elephant
		4: 2, # Rook
		5: 2, # Horse
		6: 2, # Cannon
		7: 5  # Soldier
	}
	
	for color in ["R", "B"]:
		for def in card_defs:
			var qty = counts[def["rank"]]
			for i in range(qty):
				var card_id = color + "_" + def["filename"]
				if qty > 1:
					card_id += "_" + str(i + 1)
				new_deck.append({
					"id": card_id,
					"rank": def["rank"],
					"color": color,
					"texture_path": "res://asset/card/default/TuiSkin_" + color + "_" + def["filename"] + ".png"
				})
	return new_deck


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


func _update_button_states_for_turn() -> void:
	# If hands are empty, disable everything and return
	if player_hand.is_empty() and left_hand.is_empty() and right_hand.is_empty() and top_hand.is_empty():
		confirm_button.disabled = true
		left_ready_button.disabled = true
		right_ready_button.disabled = true
		top_ready_button.disabled = true
		_stop_state_timer()
		return
		
	# Check if everyone has played (or if the turn is transitioning to reveal/scoring)
	var everyone_played = true
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
			
		if (hand_sz + table_sz) > 0 and table_sz == 0:
			everyone_played = false
			break
			
	if everyone_played:
		confirm_button.disabled = true
		left_ready_button.disabled = true
		right_ready_button.disabled = true
		top_ready_button.disabled = true
		_stop_state_timer()
		return
		
	if active_play_type == "":
		# Leader has not played yet
		confirm_button.disabled = (current_leader != 0)
		left_ready_button.disabled = (current_leader != 1)
		top_ready_button.disabled = (current_leader != 2)
		right_ready_button.disabled = (current_leader != 3)
		
		if current_timer_state != "leader":
			_start_state_timer("leader")
	else:
		# Leader has played, other players must respond
		confirm_button.disabled = has_played[0] or player_hand.is_empty()
		left_ready_button.disabled = has_played[1] or left_hand.is_empty()
		top_ready_button.disabled = has_played[2] or top_hand.is_empty()
		right_ready_button.disabled = has_played[3] or right_hand.is_empty()
		
		if current_timer_state != "responder":
			_start_state_timer("responder")


func _detect_play_type(cards: Array) -> String:
	var count = cards.size()
	if count == 1:
		return "Single"
	elif count == 2:
		if cards[0]["rank"] == cards[1]["rank"] and cards[0]["color"] == cards[1]["color"]:
			return "Pair"
	elif count >= 3 and count <= 6:
		# Check if it's a Soldier Set
		var is_soldier_set = true
		var color = cards[0]["color"]
		for c in cards:
			if c["rank"] != 7 or c["color"] != color:
				is_soldier_set = false
				break
		if is_soldier_set and count <= 5:
			return "Soldier Set"
			
		# Check if it's a Noble Set
		var is_noble_set = true
		for c in cards:
			if c["color"] != color:
				is_noble_set = false
				break
		if is_noble_set:
			var ranks = []
			for c in cards:
				ranks.append(c["rank"])
			
			var is_royal = true
			var is_war = true
			for r in ranks:
				if not r in [1, 2, 3]:
					is_royal = false
				if not r in [4, 5, 6]:
					is_war = false
					
			if is_royal and (1 in ranks) and (2 in ranks) and (3 in ranks):
				return "Noble Set"
			elif is_war and (4 in ranks) and (5 in ranks) and (6 in ranks):
				return "Noble Set"
				
	return ""


func _is_valid_play(cards: Array, play_type: String, required_count: int) -> bool:
	if cards.size() != required_count:
		return false
	return _detect_play_type(cards) == play_type


func _compare_valid_plays(play_a: Array, play_b: Array, play_type: String) -> int:
	match play_type:
		"Single", "Pair":
			var rank_a = play_a[0]["rank"]
			var rank_b = play_b[0]["rank"]
			if rank_a < rank_b:
				return 1
			elif rank_a > rank_b:
				return -1
			else:
				var color_a = play_a[0]["color"]
				var color_b = play_b[0]["color"]
				if color_a == "R" and color_b == "B":
					return 1
				elif color_a == "B" and color_b == "R":
					return -1
				else:
					return 0
		"Noble Set":
			var a_is_royal = play_a[0]["rank"] in [1, 2, 3]
			var b_is_royal = play_b[0]["rank"] in [1, 2, 3]
			if a_is_royal and not b_is_royal:
				return 1
			elif not a_is_royal and b_is_royal:
				return -1
			else:
				var color_a = play_a[0]["color"]
				var color_b = play_b[0]["color"]
				if color_a == "R" and color_b == "B":
					return 1
				elif color_a == "B" and color_b == "R":
					return -1
				else:
					return 0
		"Soldier Set":
			var color_a = play_a[0]["color"]
			var color_b = play_b[0]["color"]
			if color_a == "R" and color_b == "B":
				return 1
			elif color_a == "B" and color_b == "R":
				return -1
			else:
				return 0
	return 0


func _find_combinations(hand: Array, play_type: String, count: int) -> Array:
	var combos = []
	match play_type:
		"Single":
			for c in hand:
				combos.append([c])
		"Pair":
			for i in range(hand.size()):
				for j in range(i + 1, hand.size()):
					var c1 = hand[i]
					var c2 = hand[j]
					if c1["rank"] == c2["rank"] and c1["color"] == c2["color"]:
						combos.append([c1, c2])
		"Noble Set":
			var red_cards = []
			var black_cards = []
			for c in hand:
				if c["color"] == "R":
					red_cards.append(c)
				else:
					black_cards.append(c)
			for color_group in [red_cards, black_cards]:
				var sub_combos = _get_combinations_of_size(color_group, count)
				for combo in sub_combos:
					var ranks = []
					for c in combo:
						ranks.append(c["rank"])
					var is_royal = true
					var is_war = true
					for r in ranks:
						if not r in [1, 2, 3]:
							is_royal = false
						if not r in [4, 5, 6]:
							is_war = false
					if is_royal and (1 in ranks) and (2 in ranks) and (3 in ranks):
						combos.append(combo)
					elif is_war and (4 in ranks) and (5 in ranks) and (6 in ranks):
						combos.append(combo)
		"Soldier Set":
			var red_soldiers = []
			var black_soldiers = []
			for c in hand:
				if c["rank"] == 7:
					if c["color"] == "R":
						red_soldiers.append(c)
					else:
						black_soldiers.append(c)
			for color_group in [red_soldiers, black_soldiers]:
				if color_group.size() >= count:
					var sub_combos = _get_combinations_of_size(color_group, count)
					combos.append_array(sub_combos)
	return combos


func _get_combinations_of_size(arr: Array, k: int) -> Array:
	var results = []
	_combine_helper(arr, k, 0, [], results)
	return results


func _combine_helper(arr: Array, k: int, start: int, current: Array, results: Array) -> void:
	if current.size() == k:
		results.append(current.duplicate())
		return
	for i in range(start, arr.size()):
		current.append(arr[i])
		_combine_helper(arr, k, i + 1, current, results)
		current.remove_at(current.size() - 1)


func _initialize_loop_personalities() -> void:
	if loop_count == 0:
		# Very first loop of the round: randomly assign base personalities
		var pool = BotAI.PERSONALITY_POOL
		bot_personalities[1] = pool[randi() % pool.size()]
		bot_personalities[2] = pool[randi() % pool.size()]
		bot_personalities[3] = pool[randi() % pool.size()]
		print("--- ROUND START: Bot Personalities Assigned ---")
		print("Left Bot (1): ", bot_personalities[1])
		print("Top Bot (2): ", bot_personalities[2])
		print("Right Bot (3): ", bot_personalities[3])
		print("-----------------------------------------------")
		
		# Set text on the UI labels to reflect assigned base personalities
		player_name_label.text = "Player"
		left_name_label.text = bot_personalities[1]
		top_name_label.text = bot_personalities[2]
		right_name_label.text = bot_personalities[3]
		
	loop_count += 1
	
	# Resolve active personalities for this loop
	for bot_idx in [1, 2, 3]:
		var base = bot_personalities[bot_idx]
		if base == "Meta Mezz":
			if loop_count == 1:
				active_bot_personalities[bot_idx] = "Joker"
			else:
				# Evaluate starting hand
				var hand = []
				if bot_idx == 1: hand = left_hand
				elif bot_idx == 2: hand = top_hand
				elif bot_idx == 3: hand = right_hand
				active_bot_personalities[bot_idx] = BotAI.get_meta_mezz_personality(self, hand)
		else:
			active_bot_personalities[bot_idx] = base
			
	print("--- Loop ", loop_count, " Active Bot Styles ---")
	print("Left Bot (1): ", active_bot_personalities[1])
	print("Top Bot (2): ", active_bot_personalities[2])
	print("Right Bot (3): ", active_bot_personalities[3])
	print("--------------------------------------")


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

	# Disable buttons during animation
	get_cards_button.disabled = true
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
		get_cards_button.disabled = false
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
	var everyone_played = true
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
			
		if (hand_sz + table_sz) > 0 and table_sz == 0:
			everyone_played = false
			break
			
	if everyone_played:
		_start_reveal_and_scoring_sequence()

func _play_ready_sequence(player: TextureRect, table_area: Control, slots_list: Array, ready_button: Button, thinking_tex: Texture2D, direction: String) -> void:
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

	# Disable all controls during animation to avoid state overlap
	left_ready_button.disabled = true
	right_ready_button.disabled = true
	top_ready_button.disabled = true
	reset_button.disabled = true
	get_cards_button.disabled = true
	confirm_button.disabled = true
	
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
	
	# Keep the ready button that was just used disabled so they can't spam play on the same player
	ready_button.disabled = true
	
	# Print debug state
	_print_debug_state("READY - Bot " + direction + " played " + str(num_cards) + " card(s)")
	
	# Check if everyone has played
	var everyone_played = true
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
			
		if (hand_sz + table_sz) > 0 and table_sz == 0:
			everyone_played = false
			break
			
	if everyone_played:
		_start_reveal_and_scoring_sequence()

func _on_reset_pressed() -> void:
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
	active_bot_personalities.clear()
	loop_scores.clear()
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
	reset_button.disabled = false
	get_cards_button.disabled = false
	
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


func _collect_cards_to_winner(winner_idx: int) -> void:
	var winner_won_ref: Array
	var winner_win_area: Control
	var winner_table_area: Control
	var winner_slots: Array
	
	if winner_idx == 0:
		winner_won_ref = player_won_cards
		winner_win_area = player_win_area
		winner_table_area = table_area
		winner_slots = table_slots
	elif winner_idx == 1:
		winner_won_ref = left_won_cards
		winner_win_area = left_win_area
		winner_table_area = left_table_area
		winner_slots = left_slots
	elif winner_idx == 2:
		winner_won_ref = top_won_cards
		winner_win_area = top_win_area
		winner_table_area = top_table_area
		winner_slots = top_slots
	else:
		winner_won_ref = right_won_cards
		winner_win_area = right_win_area
		winner_table_area = right_table_area
		winner_slots = right_slots

	# 1. Floating Winner Cards Animation (Fake 3D)
	var winner_card_nodes = []
	for slot in winner_slots:
		if slot.get_child_count() > 0:
			winner_card_nodes.append(slot.get_child(0))
			
	var winner_name = "Player"
	if winner_idx == 1: winner_name = bot_personalities.get(1, "Left Bot")
	elif winner_idx == 2: winner_name = bot_personalities.get(2, "Top Bot")
	elif winner_idx == 3: winner_name = bot_personalities.get(3, "Right Bot")
			
	if not winner_card_nodes.is_empty():
		var float_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var orig_positions = {}
		var orig_global_positions = {}
		var orig_global_rotations = {}
		var orig_parents = {}
		
		var N = winner_card_nodes.size()
		
		# Temporarily reparent to top-level to render on the highest layer (drawn on top)
		for card_node in winner_card_nodes:
			var slot = card_node.get_parent()
			orig_parents[card_node] = slot
			orig_positions[card_node] = card_node.position
			orig_global_positions[card_node] = card_node.global_position
			orig_global_rotations[card_node] = card_node.get_global_transform().get_rotation()
			
			_reparent_card_to_top_level(card_node)
			move_child(card_node, -1) # Draw on top of all siblings
		
		for i in range(N):
			var card_node = winner_card_nodes[i]
			
			# Float in place slightly (offset by 20px inward towards center of screen)
			var target_global_pos = orig_global_positions[card_node]
			if winner_idx == 0:
				target_global_pos.y -= 20.0
			elif winner_idx == 2:
				target_global_pos.y += 20.0
			elif winner_idx == 1:
				target_global_pos.x += 20.0
			else:
				target_global_pos.x -= 20.0
			
			float_tween.tween_property(card_node, "global_position", target_global_pos, 0.8)
			float_tween.tween_property(card_node, "scale", Vector2(1.5, 1.5), 0.8)
			float_tween.tween_property(card_node, "rotation", orig_global_rotations[card_node] + 0.05, 0.8)
		await float_tween.finished
		
		# Show the floating winner cards for 3.0 seconds
		await get_tree().create_timer(3.0).timeout
		
		# Return to original default position (winner's table) first
		var land_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		for card_node in winner_card_nodes:
			land_tween.tween_property(card_node, "global_position", orig_global_positions[card_node], 0.8)
			land_tween.tween_property(card_node, "scale", Vector2.ONE, 0.8)
			land_tween.tween_property(card_node, "rotation", orig_global_rotations[card_node], 0.8)
		await land_tween.finished
		
		# Put them back into their original slots
		for card_node in winner_card_nodes:
			var slot = orig_parents[card_node]
			card_node.reparent(slot, false) # Reparent without keeping native global transform
			
		# After returning to default, show the announcement!
		_show_announcement("Winner: " + winner_name, 2.5)
	else:
		# If no winner cards to float, show announcement immediately
		_show_announcement("Winner: " + winner_name, 2.5)

	# 2. Gather losing cards to winner's table area center
	var losing_card_nodes = []
	var all_slots_lists = [table_slots, left_slots, top_slots, right_slots]
	for s_list in all_slots_lists:
		if s_list != winner_slots:
			for slot in s_list:
				if slot.get_child_count() > 0:
					var card_node = slot.get_child(0)
					_reparent_card_to_top_level(card_node)
					move_child(card_node, -1)
					
					var area_center = winner_table_area.global_position + (winner_table_area.size / 2.0)
					var random_offset = Vector2(randf_range(-15, 15), randf_range(-15, 15))
					var target_pos = area_center - (card_node.size / 2.0) + random_offset
					losing_card_nodes.append({
						"node": card_node,
						"target_pos": target_pos,
						"target_rot": randf_range(-0.15, 0.15)
					})
					
	if not losing_card_nodes.is_empty():
		var gather_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		for item in losing_card_nodes:
			gather_tween.tween_property(item["node"], "global_position", item["target_pos"], 0.6)
			gather_tween.tween_property(item["node"], "rotation", item["target_rot"], 0.6)
		await gather_tween.finished

	# 3. Winner's hand moves from offscreen to grab the pile
	var winner_hand_node = back_hand
	var hand_offscreen = Vector2.ZERO
	var hand_target = Vector2.ZERO
	var screen_height = get_viewport_rect().size.y
	
	# Recalculate target coordinates for reveal hands
	var bottom_target = table_area.position.y + (table_area.size.y / 2.0) - (back_hand.size.y / 2.0) + BACKHAND_OFFSET
	var left_center = left_table_area.position + (left_table_area.size / 2.0).rotated(left_table_area.rotation)
	var left_target = left_center - (left_player.size / 2.0).rotated(left_player.rotation) + Vector2.LEFT * SIDE_BACKHAND_OFFSET
	var left_offscreen = Vector2(-600.0, left_player.position.y)
	var right_center = right_table_area.position + (right_table_area.size / 2.0).rotated(right_table_area.rotation)
	var right_target = right_center - (right_player.size / 2.0).rotated(right_player.rotation) + Vector2.RIGHT * SIDE_BACKHAND_OFFSET
	var right_offscreen = Vector2(get_viewport_rect().size.x + 600.0, right_player.position.y)
	var top_center = top_table_area.position + (top_table_area.size / 2.0).rotated(top_table_area.rotation)
	var top_target = top_center - (top_player.size / 2.0).rotated(top_player.rotation) + Vector2.UP * TOP_BACKHAND_OFFSET
	var top_offscreen = Vector2(top_player.position.x, -600.0)

	if winner_idx == 0:
		winner_hand_node = back_hand
		winner_hand_node.position.y = screen_height + 50.0
		winner_hand_node.position.x = (get_viewport_rect().size.x - winner_hand_node.size.x) / 2.0
		hand_offscreen = Vector2(winner_hand_node.position.x, screen_height + 50.0)
		hand_target = Vector2(winner_hand_node.position.x, bottom_target)
	elif winner_idx == 1:
		winner_hand_node = left_player
		winner_hand_node.texture = backhand_tex
		winner_hand_node.position = left_offscreen
		hand_offscreen = left_offscreen
		hand_target = left_target
	elif winner_idx == 2:
		winner_hand_node = top_player
		winner_hand_node.texture = backhand_tex
		winner_hand_node.position = top_offscreen
		hand_offscreen = top_offscreen
		hand_target = top_target
	else:
		winner_hand_node = right_player
		winner_hand_node.texture = backhand_tex
		winner_hand_node.position = right_offscreen
		hand_offscreen = right_offscreen
		hand_target = right_target
		
	winner_hand_node.visible = true
	var grab_hand_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if winner_idx == 0:
		grab_hand_tween.tween_property(winner_hand_node, "position:y", bottom_target, 0.6)
	else:
		grab_hand_tween.tween_property(winner_hand_node, "position", hand_target, 0.6)
	await grab_hand_tween.finished
	
	_play_sfx_transient(click_sfx)
	await get_tree().create_timer(0.2).timeout

	# 4. Reparent winner cards and gather all cards to fly to WinArea with hand
	var cards_to_collect = []
	
	# Add winner's cards
	for slot in winner_slots:
		if slot.get_child_count() > 0:
			var card_node = slot.get_child(0)
			_reparent_card_to_top_level(card_node)
			move_child(card_node, -1)
			cards_to_collect.append(card_node)
			
	# Add losing cards
	for item in losing_card_nodes:
		cards_to_collect.append(item["node"])

	# Append card data to the winner's list
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
	
	# Build parallel tween to move hand and cards
	var hand_win_target = winner_win_area.global_position + (winner_win_area.size / 2.0) - (winner_hand_node.size / 2.0)
	var collect_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Move hand
	if winner_idx == 0:
		collect_tween.tween_property(winner_hand_node, "position", hand_win_target, 0.8)
	else:
		collect_tween.tween_property(winner_hand_node, "global_position", hand_win_target, 0.8)
		
	# Move cards
	for i in range(cards_to_collect.size()):
		var card_node = cards_to_collect[i]
		card_node.pivot_offset = card_node.size / 2.0
		
		# Find the target slot for this specific card
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
	
	for card_node in cards_to_collect:
		card_node.queue_free()
		
	_update_win_area_icons(winner_win_area, winner_won_ref.size())

	# 5. Move winner's hand back offscreen and hide it
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
	announcement_tween.tween_property(announcement, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Wait duration
	announcement_tween.tween_interval(duration)
	# Fade out
	announcement_tween.tween_property(announcement, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Hide
	announcement_tween.tween_callback(func(): announcement.visible = false)
	return announcement_tween


func _start_reveal_and_scoring_sequence() -> void:
	# Disable all ready/confirm buttons during reveal
	confirm_button.disabled = true
	left_ready_button.disabled = true
	right_ready_button.disabled = true
	top_ready_button.disabled = true
	reset_button.disabled = true
	get_cards_button.disabled = true
	
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
	await _collect_cards_to_winner(winner_idx)
	
	# Set next leader to winner
	current_leader = winner_idx
	
	# Reset active turn properties
	active_play_type = ""
	active_card_count = 0
	has_played = [false, false, false, false]
	
	# Re-enable reset and get_cards
	reset_button.disabled = false
	get_cards_button.disabled = false
	
	# Check if hand cards are empty (loop ends)
	if player_hand.is_empty():
		print("Round completed! All cards played.")
		
		# Calculate and store scores: Score = (Collected Cards) / 4
		var p_score = player_won_cards.size() / 4
		var l_score = left_won_cards.size() / 4
		var t_score = top_won_cards.size() / 4
		var r_score = right_won_cards.size() / 4
		
		var loop_idx = loop_count - 1 # loop_count is 1-indexed (incremented in _initialize_loop_personalities)
		while loop_scores.size() <= loop_idx:
			loop_scores.append({"player": 0, "left": 0, "top": 0, "right": 0})
		loop_scores[loop_idx] = {
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
