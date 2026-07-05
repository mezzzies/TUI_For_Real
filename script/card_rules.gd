class_name CardRules
extends RefCounted

static func generate_deck() -> Array:
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


static func detect_play_type(cards: Array) -> String:
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


static func is_valid_play(cards: Array, play_type: String, required_count: int) -> bool:
	if cards.size() != required_count:
		return false
	return detect_play_type(cards) == play_type


static func compare_valid_plays(play_a: Array, play_b: Array, play_type: String) -> int:
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


static func find_combinations(hand: Array, play_type: String, count: int) -> Array:
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
				var sub_combos = get_combinations_of_size(color_group, count)
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
					var sub_combos = get_combinations_of_size(color_group, count)
					combos.append_array(sub_combos)
	return combos


static func get_combinations_of_size(arr: Array, k: int) -> Array:
	var results = []
	combine_helper(arr, k, 0, [], results)
	return results


static func combine_helper(arr: Array, k: int, start: int, current: Array, results: Array) -> void:
	if current.size() == k:
		results.append(current.duplicate())
		return
	for i in range(start, arr.size()):
		current.append(arr[i])
		combine_helper(arr, k, i + 1, current, results)
		current.remove_at(current.size() - 1)
