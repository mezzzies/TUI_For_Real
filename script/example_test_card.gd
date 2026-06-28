extends Control

@onready var hand_container = $HandContainer
@onready var add_card_button = $ButtonContainer/AddCardButton
@onready var remove_card_button = $ButtonContainer/RemoveCardButton

var card_scene = preload("res://scene/card.tscn")
var cards = []

# Dynamic stickman card templates
var card_templates = [
	{
		"name": "Stick Knight",
		"cost": 3,
		"type": "Unit",
		"description": "Heavily armored stick warrior with solid defense and a heavy iron sword.",
		"atk": 3,
		"hp": 6,
		"color": Color(0.25, 0.45, 0.85)
	},
	{
		"name": "Stick Archer",
		"cost": 2,
		"type": "Unit",
		"description": "Ranged attacker that fires swift stick-arrows from afar.",
		"atk": 4,
		"hp": 2,
		"color": Color(0.2, 0.6, 0.3)
	},
	{
		"name": "Stick Mage",
		"cost": 4,
		"type": "Unit",
		"description": "Spellslinger capable of dealing massive area fire damage.",
		"atk": 5,
		"hp": 3,
		"color": Color(0.6, 0.3, 0.8)
	},
	{
		"name": "Stick Healer",
		"cost": 2,
		"type": "Unit",
		"description": "Restores health to wounded allies on the battlefield.",
		"atk": 1,
		"hp": 4,
		"color": Color(0.85, 0.65, 0.15)
	},
	{
		"name": "Stick Giant",
		"cost": 6,
		"type": "Unit",
		"description": "Colossal stickman that crushes gates and defenses easily.",
		"atk": 8,
		"hp": 10,
		"color": Color(0.8, 0.2, 0.2)
	}
]

func _ready() -> void:
	add_card_button.pressed.connect(_on_add_card_pressed)
	remove_card_button.pressed.connect(_on_remove_card_pressed)
	
	# Spawn 5 starting cards to fill the hand
	for i in range(5):
		_add_card_to_hand(i)

func _on_add_card_pressed() -> void:
	if cards.size() < 10: # Limit hand size to 10
		_add_card_to_hand(cards.size())

func _on_remove_card_pressed() -> void:
	if not cards.is_empty():
		var card_to_remove = cards.pop_back()
		card_to_remove.queue_free()
		update_hand_layout()

func _add_card_to_hand(index: int) -> void:
	var card_instance = card_scene.instantiate()
	hand_container.add_child(card_instance)
	
	# Select template based on index or random
	var template = card_templates[index % card_templates.size()]
	card_instance.setup_card(template)
	
	# Connect signals
	card_instance.drag_ended.connect(_on_card_drag_ended)
	card_instance.card_selected.connect(_on_card_selected)
	
	# Set pivot to bottom center for fanning
	card_instance.pivot_offset = Vector2(75.0, 220.0)
	
	cards.append(card_instance)
	update_hand_layout()

func update_hand_layout() -> void:
	var N = cards.size()
	if N == 0:
		return
		
	# Spacing decreases as hand size increases to fit cards on screen
	var spacing = clamp(700.0 / N, 40.0, 95.0)
	var center_idx = (N - 1) / 2.0
	
	# Arc / Fan settings
	var arc_factor = 4.0 # Pixels to offset down per squared index difference
	var rot_step = 0.05  # Radians to rotate per card index difference
	
	for i in range(N):
		var card = cards[i]
		var offset_from_center = i - center_idx
		
		# Target Position:
		# X is centered around HandContainer's local (0, 0)
		var target_x = offset_from_center * spacing - (150.0 / 2.0)
		# Y offsets downwards forming an arc
		var target_y = (offset_from_center * offset_from_center) * arc_factor - 110.0 # Vertical shift
		
		var target_pos = Vector2(target_x, target_y)
		var target_rot = offset_from_center * rot_step
		
		# Set card's hand rotation
		card.hand_rotation = target_rot
		
		# Animate positioning using tween
		# Kill any active tween to prevent conflicts
		var active_tween = card.get_meta("active_tween", null)
		if active_tween and active_tween.is_valid():
			active_tween.kill()

		var tween = card.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		card.set_meta("active_tween", tween)
		
		# If the card is dragging, don't override its visual position
		if not card.is_dragging:
			tween.tween_property(card, "position", target_pos, 0.25)
			
		# Reset hover states to default just in case
		if not card.is_hovered and not card.is_dragging:
			var visual = card.viewport_container
			var shadow = card.shadow_container
			tween.tween_property(visual, "scale", Vector2(1.0, 1.0), 0.25)
			tween.tween_property(visual, "position", Vector2.ZERO, 0.25)
			tween.tween_property(shadow, "scale", Vector2(1.0, 1.0), 0.25)
			tween.tween_property(shadow, "position", Vector2(0.0, 4.0), 0.25)
			if shadow and shadow.material is ShaderMaterial:
				tween.tween_method(
					func(val): 
						if is_instance_valid(shadow) and shadow.material is ShaderMaterial:
							shadow.material.set_shader_parameter("shadow_alpha", val),
					0.22, 0.45, 0.25
				)

func _on_card_drag_ended(card_node: Control, _drop_position: Vector2) -> void:
	print("Drag ended! Snapping card back into hand.")
	card_node.return_to_hand()
	update_hand_layout()

func _on_card_selected(card_node: Control) -> void:
	print("Card clicked! Toggling selection style.")
	card_node.set_selected(!card_node.is_selected)
