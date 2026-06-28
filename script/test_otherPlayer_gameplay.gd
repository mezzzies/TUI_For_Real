extends Control

const TOP_BACKHAND_OFFSET = 40.0
const SIDE_BACKHAND_OFFSET = 100.0

@onready var reset_button = $ResetButton
@onready var left_ready_button = $LeftReadyButton
@onready var right_ready_button = $RightReadyButton
@onready var top_ready_button = $TopReadyButton
@onready var play_type_button = $PlayTypeButton

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

var card_scene = preload("res://scene/test_card.tscn")
var hover_sfx = preload("res://asset/sfx/type-click.mp3")
var click_sfx = preload("res://asset/sfx/shutter-click.mp3")

# Textures
var l_thinking_tex = preload("res://asset/character/default/L_thinkinghand.png")
var r_thinking_tex = preload("res://asset/character/default/R_thinkinghand.png")
var t_thinking_tex = preload("res://asset/character/default/T_thinkinghand.png")
var backhand_tex = preload("res://asset/character/default/Single_backhand.png")

# Base positions
var base_left_x := 0.0
var base_right_x := 0.0
var base_top_y := 0.0

# Breathing tweens
var left_breathing_tween: Tween
var right_breathing_tween: Tween
var top_breathing_tween: Tween

func _ready() -> void:
	# Save base positions of player hands
	base_left_x = left_player.position.x
	base_right_x = right_player.position.x
	base_top_y = top_player.position.y
	
	# Set Table Areas and Slots to ignore mouse filter
	left_table_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_table_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_table_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	for slot in left_slots:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot in right_slots:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for slot in top_slots:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# Connect button events
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
	
	# Populate play type OptionButton
	play_type_button.add_item("1 Card")
	play_type_button.add_item("2 Cards")
	play_type_button.add_item("3 Cards")
	play_type_button.add_item("4 Cards")
	play_type_button.add_item("5 Cards")
	play_type_button.add_item("6 Cards")
	play_type_button.add_item("7 Cards")
	play_type_button.add_item("8 Cards")
	play_type_button.selected = 0
	play_type_button.pressed.connect(func(): _play_sfx_transient(click_sfx))
	play_type_button.mouse_entered.connect(func(): _play_sfx_transient(hover_sfx))
	
	# Start breathing animations
	_start_all_breathing()

func _play_sfx_transient(stream: AudioStream) -> void:
	if not stream: return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _start_all_breathing() -> void:
	_start_left_breathing()
	_start_right_breathing()
	_start_top_breathing()

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

func _play_ready_sequence(player: TextureRect, table_area: Control, slots_list: Array, ready_button: Button, thinking_tex: Texture2D, direction: String) -> void:
	# Disable all controls during animation to avoid state overlap
	left_ready_button.disabled = true
	right_ready_button.disabled = true
	top_ready_button.disabled = true
	reset_button.disabled = true
	
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
		target_offscreen.x = -viewport_size.x / 2.0 - 400.0
	elif direction == "right":
		target_offscreen.x = viewport_size.x / 2.0 + 400.0
	else:
		target_offscreen.y = -viewport_size.y / 2.0 - 400.0
		
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
	var num_cards = play_type_button.selected + 1
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
	
	# Re-enable other ready buttons and reset
	left_ready_button.disabled = false
	right_ready_button.disabled = false
	top_ready_button.disabled = false
	reset_button.disabled = false
	
	# Keep the ready button that was just used disabled so they can't spam play on the same player
	ready_button.disabled = true

func _on_reset_pressed() -> void:
	# Clear all cards in slots
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
	
	# Tween hands back to base positions
	var tween_reset = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_reset.tween_property(left_player, "position", Vector2(base_left_x, left_player.position.y), 0.6)
	tween_reset.tween_property(right_player, "position", Vector2(base_right_x, right_player.position.y), 0.6)
	tween_reset.tween_property(top_player, "position", Vector2(top_player.position.x, base_top_y), 0.6)
	await tween_reset.finished
	
	# Restart breathing tweens
	_start_all_breathing()
	
	# Re-enable buttons
	left_ready_button.disabled = false
	right_ready_button.disabled = false
	top_ready_button.disabled = false
