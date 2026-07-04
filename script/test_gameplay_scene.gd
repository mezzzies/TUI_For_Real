extends SceneTree

func _init():
	call_deferred("run_tests")

func run_tests():
	print("=========================================")
	print("--- Running Godot Gameplay Scene Tests ---")
	print("=========================================")
	
	var scene = load("res://scene/test_gameplay.tscn")
	if not scene:
		print("FAIL: Cannot load test_gameplay.tscn!")
		quit(1)
		return
		
	var gameplay = scene.instantiate()
	if not gameplay:
		print("FAIL: Cannot instantiate test_gameplay!")
		quit(1)
		return
		
	# Disable state timers during headless testing
	gameplay.is_test_mode = true
		
	# Add to tree so onready and _ready are called
	root.add_child(gameplay)
	
	# Run tests
	run_basic_checks(gameplay)
	run_deal_checks(gameplay)
	run_winner_logic_checks(gameplay)
	
	# Cleanup
	root.remove_child(gameplay)
	gameplay.queue_free()
	
	print("=========================================")
	print("ALL GODOT GAMEPLAY SCENE TESTS PASSED!")
	print("=========================================")
	quit(0)


func run_basic_checks(gameplay):
	print("Testing basic node bindings...")
	assert(gameplay.get_cards_button != null, "get_cards_button must exist")
	assert(gameplay.reset_button != null, "reset_button must exist")
	assert(gameplay.left_ready_button != null, "left_ready_button must exist")
	assert(gameplay.right_ready_button != null, "right_ready_button must exist")
	assert(gameplay.top_ready_button != null, "top_ready_button must exist")
	assert(gameplay.confirm_button != null, "confirm_button must exist")
	assert(gameplay.announcement != null, "announcement overlay must exist")
	assert(gameplay.announcement_text != null, "announcement_text label must exist")
	assert(gameplay.time_label != null, "time_label must exist")
	assert(gameplay.score_panel != null, "score_panel must exist")
	assert(gameplay.score_grid != null, "score_grid must exist")
	print("Basic checks passed.")

func run_deal_checks(gameplay):
	print("Testing deal/starting round...")
	gameplay._on_get_cards_pressed()
	
	assert(gameplay.player_hand.size() == 8, "Player hand should be 8 cards")
	assert(gameplay.left_hand.size() == 8, "Left hand should be 8 cards")
	assert(gameplay.top_hand.size() == 8, "Top hand should be 8 cards")
	assert(gameplay.right_hand.size() == 8, "Right hand should be 8 cards")
	assert(gameplay.current_leader >= 0 and gameplay.current_leader <= 3, "Leader index must be 0-3")
	print("Deal checks passed. Current leader: ", gameplay.current_leader)

func run_winner_logic_checks(gameplay):
	print("Testing winner determination scenarios...")
	
	# Scenario 1: Leader is Bottom (0), plays Red General (strongest Single). Everyone else plays weaker cards.
	gameplay.current_leader = 0
	gameplay.active_play_type = "Single"
	gameplay.active_card_count = 1
	
	gameplay.player_table_cards = [{"rank": 1, "color": "R", "id": "R_1King"}] # Red General
	gameplay.left_table_cards = [{"rank": 2, "color": "R", "id": "R_2Plane"}]   # Red Advisor
	gameplay.top_table_cards = [{"rank": 7, "color": "B", "id": "B_7Chip"}]     # Black Soldier
	gameplay.right_table_cards = []                                             # Folded
	
	var winner = gameplay._determine_turn_winner()
	assert(winner == 0, "Bottom (Player) should win")
	
	# Scenario 2: Leader is Top (2), plays Red Advisor Pair (rank 2, color R).
	# Left plays Red Soldier Pair (rank 7, color R). Bottom plays Black Horse Pair (rank 5, color B).
	gameplay.current_leader = 2
	gameplay.active_play_type = "Pair"
	gameplay.active_card_count = 2
	
	gameplay.player_table_cards = [
		{"rank": 5, "color": "B", "id": "B_5Horse_1"},
		{"rank": 5, "color": "B", "id": "B_5Horse_2"}
	]
	gameplay.left_table_cards = [
		{"rank": 7, "color": "R", "id": "R_7Chip_1"},
		{"rank": 7, "color": "R", "id": "R_7Chip_2"}
	]
	gameplay.top_table_cards = [
		{"rank": 2, "color": "R", "id": "R_2Plane_1"},
		{"rank": 2, "color": "R", "id": "R_2Plane_2"}
	]
	gameplay.right_table_cards = []
	
	winner = gameplay._determine_turn_winner()
	assert(winner == 2, "Top should win")
	
	# Scenario 3: Leader is Left (1). Left and Top tie with Red Elephant (rank 3, color R).
	# Left is leader, so Left should win the tie-breaker.
	gameplay.current_leader = 1
	gameplay.active_play_type = "Single"
	gameplay.active_card_count = 1
	
	gameplay.player_table_cards = [{"rank": 5, "color": "B", "id": "B_5Horse"}]
	gameplay.left_table_cards = [{"rank": 3, "color": "R", "id": "R_3Elephant"}]
	gameplay.top_table_cards = [{"rank": 3, "color": "R", "id": "R_3Elephant"}]
	gameplay.right_table_cards = [{"rank": 6, "color": "R", "id": "R_6House"}]
	
	winner = gameplay._determine_turn_winner()
	assert(winner == 1, "Left (Leader) should win the tie-breaker")
	
	# Scenario 4: Leader is Bottom (0). Left (1) and Top (2) tie with Red Advisor (rank 2, color R).
	# Leader Bottom plays weaker Black Rook (rank 4, color B).
	# Left is closer clockwise to Leader (0) than Top is. Distance: Left=1, Top=2. Left wins.
	gameplay.current_leader = 0
	gameplay.active_play_type = "Single"
	gameplay.active_card_count = 1
	
	gameplay.player_table_cards = [{"rank": 4, "color": "B", "id": "B_4Boat"}]
	gameplay.left_table_cards = [{"rank": 2, "color": "R", "id": "R_2Plane"}]
	gameplay.top_table_cards = [{"rank": 2, "color": "R", "id": "R_2Plane"}]
	gameplay.right_table_cards = [{"rank": 3, "color": "R", "id": "R_3Elephant"}]
	
	winner = gameplay._determine_turn_winner()
	assert(winner == 1, "Left should win tie-breaker over Top")
	
	# Scenario 5: Leader is Top (2). Right (3) and Bottom (0) tie with Red Elephant (rank 3, color R).
	# Leader Top plays weaker Red Horse (rank 5, color R).
	# Clockwise order starting from Top (2) is: Top (2) -> Right (3) -> Bottom (0).
	# Distance: Right = (3-2)%4 = 1. Bottom = (0-2)%4 = 2. Right wins.
	gameplay.current_leader = 2
	gameplay.active_play_type = "Single"
	gameplay.active_card_count = 1
	
	gameplay.player_table_cards = [{"rank": 3, "color": "R", "id": "R_3Elephant"}]
	gameplay.left_table_cards = [{"rank": 4, "color": "R", "id": "R_4Boat"}]
	gameplay.top_table_cards = [{"rank": 5, "color": "R", "id": "R_5Horse"}]
	gameplay.right_table_cards = [{"rank": 3, "color": "R", "id": "R_3Elephant"}]
	
	winner = gameplay._determine_turn_winner()
	assert(winner == 3, "Right should win tie-breaker over Bottom")
	
	# Scenario 6: Black Elephant (Top/2) vs Red Elephant (Right/3) Single.
	# Red Elephant (Right/3) must win over Black Elephant (Top/2).
	gameplay.current_leader = 2
	gameplay.active_play_type = "Single"
	gameplay.active_card_count = 1
	gameplay.player_table_cards = []
	gameplay.left_table_cards = []
	gameplay.top_table_cards = [{"rank": 3, "color": "B", "id": "B_3Elephant"}]
	gameplay.right_table_cards = [{"rank": 3, "color": "R", "id": "R_3Elephant"}]
	
	winner = gameplay._determine_turn_winner()
	assert(winner == 3, "Red Elephant (Right) should beat Black Elephant (Top)")
	
	# Scenario 7: Black Elephant Pair (Top/2) vs Red Elephant Pair (Right/3).
	# Red Elephant Pair (Right/3) must win over Black Elephant Pair (Top/2).
	gameplay.current_leader = 2
	gameplay.active_play_type = "Pair"
	gameplay.active_card_count = 2
	gameplay.player_table_cards = []
	gameplay.left_table_cards = []
	gameplay.top_table_cards = [
		{"rank": 3, "color": "B", "id": "B_3Elephant_1"},
		{"rank": 3, "color": "B", "id": "B_3Elephant_2"}
	]
	gameplay.right_table_cards = [
		{"rank": 3, "color": "R", "id": "R_3Elephant_1"},
		{"rank": 3, "color": "R", "id": "R_3Elephant_2"}
	]
	
	winner = gameplay._determine_turn_winner()
	assert(winner == 3, "Red Elephant Pair (Right) should beat Black Elephant Pair (Top)")
	
	# Scenario 8: Black Royal Noble Set (Top/2) vs Red Royal Noble Set (Right/3).
	# Red Royal Noble Set (Right/3) must win over Black Royal Noble Set (Top/2).
	gameplay.current_leader = 2
	gameplay.active_play_type = "Noble Set"
	gameplay.active_card_count = 3
	gameplay.player_table_cards = []
	gameplay.left_table_cards = []
	gameplay.top_table_cards = [
		{"rank": 1, "color": "B", "id": "B_1King"},
		{"rank": 2, "color": "B", "id": "B_2Plane"},
		{"rank": 3, "color": "B", "id": "B_3Elephant"}
	]
	gameplay.right_table_cards = [
		{"rank": 1, "color": "R", "id": "R_1King"},
		{"rank": 2, "color": "R", "id": "R_2Plane"},
		{"rank": 3, "color": "R", "id": "R_3Elephant"}
	]
	
	winner = gameplay._determine_turn_winner()
	assert(winner == 3, "Red Royal Noble Set (Right) should beat Black Royal Noble Set (Top)")
	
	# Scenario 9: King-Pair Endgame Strategy check for Big Bobby, Shadow, and The Professor.
	var test_hand = [
		{"rank": 1, "color": "B", "id": "B_1King"},
		{"rank": 3, "color": "R", "id": "R_3Elephant_1"},
		{"rank": 3, "color": "R", "id": "R_3Elephant_2"},
		{"rank": 4, "color": "B", "id": "B_4Boat"},
		{"rank": 7, "color": "B", "id": "B_7Chip"}
	]
	# Hand contains B_1King (General) and R_3Elephant pair. Hand size = 5.
	gameplay.active_bot_personalities[1] = "The Professor"
	
	# Test 9.1: Leader play with hand size > 3
	var lead_play = BotAI.select_play(gameplay, test_hand, "", 0, 1)
	assert(lead_play.size() == 1, "Should lead 1 card from allowed")
	assert(lead_play[0]["id"] in ["B_4Boat", "B_7Chip"], "Should not lead the saved King or Pair cards")
	
	# Test 9.2: Leader play with hand size == 3 (only King and Pair remaining)
	var three_card_hand = [
		{"rank": 1, "color": "B", "id": "B_1King"},
		{"rank": 3, "color": "R", "id": "R_3Elephant_1"},
		{"rank": 3, "color": "R", "id": "R_3Elephant_2"}
	]
	var lead_three = BotAI.select_play(gameplay, three_card_hand, "", 0, 1)
	assert(lead_three.size() == 1, "Should lead 1 card")
	assert(lead_three[0]["id"] == "B_1King", "Should lead the General to win the turn")
	
	# Test 9.3: Responder play to Pair with hand size == 3
	var respond_pair = BotAI.select_play(gameplay, three_card_hand, "Pair", 2, 1)
	assert(respond_pair.size() == 2, "Should play 2 cards")
	assert(respond_pair[0]["id"].begins_with("R_3Elephant") and respond_pair[1]["id"].begins_with("R_3Elephant"), "Should play the saved pair")
	
	print("Winner determination scenarios passed.")
	
	run_timer_timeout_checks(gameplay)


func run_timer_timeout_checks(gameplay):
	print("Testing timer timeout and auto-play triggers...")
	
	# Setup Player hand and Leader state
	gameplay.current_leader = 0
	gameplay.active_play_type = ""
	gameplay.active_card_count = 0
	gameplay.has_played = [false, false, false, false]
	gameplay.player_hand = [{"id": "R_1King", "rank": 1, "color": "R", "texture_path": "res://asset/card/default/TuiSkin_R_1King.png"}]
	
	# Add a card node to slot0 to represent Player's hand card
	for child in gameplay.slots[0].get_children():
		gameplay.slots[0].remove_child(child)
		child.queue_free()
	var card_node = load("res://scene/test_card.tscn").instantiate()
	gameplay.slots[0].add_child(card_node)
	card_node.setup_card("res://asset/card/default/TuiSkin_R_1King.png")
	card_node.set_meta("card_id", "R_1King")
	
	# Execute the auto-play leader for player trigger directly
	await gameplay._auto_play_leader_for_player()
	
	# Verify player played their General
	assert(gameplay.has_played[0] == true, "Player should have played via auto-play")
	assert(gameplay.player_hand.is_empty(), "Player hand should be empty after play")
	assert(gameplay.player_table_cards.size() == 1, "Player should have 1 card on the table")
	assert(gameplay.player_table_cards[0]["id"] == "R_1King", "Played card should be Red General")
	
	print("Timer timeout checks passed.")
