class_name BotAI
extends RefCounted

# The pool of all available bot personalities
const PERSONALITY_POOL = ["Big Bobby", "Shadow", "Dr. Lu Yerf", "Professor Jim", "Mrs. Jones", "Dum Dum", "Sammy", "Max May"]

# Returns the thinking delay range (min, max) for a given personality
static func get_thinking_delay_range(personality: String) -> Vector2:
	match personality:
		"Big Bobby", "Sammy":
			return Vector2(2.0, 3.0)
		"Shadow", "Mrs. Jones":
			return Vector2(3.0, 4.0)
		"Dr. Lu Yerf", "Professor Jim", "Max May":
			return Vector2(4.0, 5.0)
		"Dum Dum":
			return Vector2(2.0, 5.0)
		_:
			return Vector2(3.0, 4.0)

# Sorts cards by ascending power (weakest to strongest) using main gameplay comparison
static func sort_cards_by_power(gameplay: Node, cards: Array) -> Array:
	var sorted = cards.duplicate()
	sorted.sort_custom(func(a, b):
		# gameplay._compare_valid_plays returns -1 if a is weaker than b
		return gameplay._compare_valid_plays([a], [b], "Single") < 0
	)
	return sorted

# Main API to select play (either leading or responding)
static func select_play(gameplay: Node, hand: Array, play_type: String, count: int, bot_idx: int) -> Array:
	var active_style = gameplay.bot_personalities.get(bot_idx, "Professor Jim")
	
	# 1. Check guaranteed endgames first (for active styles)
	if active_style in ["Big Bobby", "Shadow", "Professor Jim", "Sammy", "Max May"]:
		var endgame_setup = _get_saved_endgame_setup(gameplay, hand)
		if not endgame_setup.is_empty():
			return _select_play_with_endgame(gameplay, hand, play_type, count, active_style, endgame_setup)

	# 2. Check Double-Red-Plane-Split lead: if all Kings are played, they can be played separately.
	if play_type == "" and active_style in ["Max May", "Professor Jim"]:
		var red_planes = []
		for c in hand:
			if c["rank"] == 2 and c["color"] == "R":
				red_planes.append(c)
		if red_planes.size() == 2 and are_all_kings_played(gameplay, hand, active_style):
			return [red_planes[0]]

	# 3. Get protected cards (King-Pair setup and un-split Red Planes)
	var protected = _get_protected_cards(gameplay, hand, active_style)
	
	# Determine allowed cards (not protected)
	var allowed = []
	for c in hand:
		var is_protected = false
		for p in protected:
			if c["id"] == p["id"]:
				is_protected = true
				break
		if not is_protected:
			allowed.append(c)
			
	# If exactly 3 cards left and we have a King-Pair setup, allowed will be empty but we must play them.
	# We delegate to the saved King-Pair selector if we have it.
	if active_style in ["Big Bobby", "Shadow", "Professor Jim", "Sammy", "Max May"]:
		var saved = _has_saved_king_pair_setup(gameplay, hand)
		if not saved.is_empty() and hand.size() == 3:
			return _select_play_with_saved_king_pair(gameplay, hand, play_type, count, active_style, saved)

	# If allowed cards are available, choose play using allowed cards.
	# Otherwise, choose play using the full hand.
	var cards_to_use = allowed if not allowed.is_empty() else hand
	
	if play_type == "":
		return _select_play_as_leader(gameplay, cards_to_use, active_style)
	else:
		var valid_plays = gameplay._find_combinations(cards_to_use, play_type, count)
		if valid_plays.is_empty():
			# If using allowed cards resulted in no valid play, try the full hand
			if not allowed.is_empty():
				var fallback_valid = gameplay._find_combinations(hand, play_type, count)
				if not fallback_valid.is_empty():
					return _select_play_as_responder(gameplay, hand, play_type, count, fallback_valid, active_style)
			return _choose_fold_cards(gameplay, hand, count, active_style)
		else:
			return _select_play_as_responder(gameplay, cards_to_use, play_type, count, valid_plays, active_style)

# --- Internal Leader Play Selectors ---

static func _select_play_as_leader(gameplay: Node, hand: Array, active_style: String) -> Array:
	match active_style:
		"Big Bobby":
			# Play strongest Pair, or strongest Single
			var pairs = gameplay._find_combinations(hand, "Pair", 2)
			if not pairs.is_empty():
				pairs.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Pair") > 0
				)
				return pairs[0]
			else:
				var sorted = sort_cards_by_power(gameplay, hand)
				return [sorted[sorted.size() - 1]]
				
		"Shadow":
			# Play Noble Set (size 4 or 3), mid-tier Pair (rank 3 to 6), or lowest Single
			var noble_4 = gameplay._find_combinations(hand, "Noble Set", 4)
			var noble_3 = gameplay._find_combinations(hand, "Noble Set", 3)
			var sets = noble_4 if not noble_4.is_empty() else noble_3
			if not sets.is_empty():
				sets.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Noble Set") > 0
				)
				return sets[0]
				
			var pairs = gameplay._find_combinations(hand, "Pair", 2)
			var mid_pairs = []
			for p in pairs:
				var rank = p[0]["rank"]
				if rank >= 3 and rank <= 6:
					mid_pairs.append(p)
			if not mid_pairs.is_empty():
				mid_pairs.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Pair") > 0
				)
				return mid_pairs[0]
				
			var sorted = sort_cards_by_power(gameplay, hand)
			return [sorted[0]]
			
		"Dr. Lu Yerf":
			# Play Soldier Set (size 4 or 3), Noble Set (size 3), low-value Pair (rank 5-7), or medium Single
			var sold_4 = gameplay._find_combinations(hand, "Soldier Set", 4)
			var sold_3 = gameplay._find_combinations(hand, "Soldier Set", 3)
			var s_sets = sold_4 if not sold_4.is_empty() else sold_3
			if not s_sets.is_empty():
				s_sets.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Soldier Set") > 0
				)
				return s_sets[0]
				
			var noble_3 = gameplay._find_combinations(hand, "Noble Set", 3)
			if not noble_3.is_empty():
				noble_3.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Noble Set") > 0
				)
				return noble_3[0]
				
			var pairs = gameplay._find_combinations(hand, "Pair", 2)
			var low_pairs = []
			for p in pairs:
				var rank = p[0]["rank"]
				if rank >= 5 and rank <= 7:
					low_pairs.append(p)
			if not low_pairs.is_empty():
				low_pairs.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Pair") > 0
				)
				return low_pairs[0]
				
			var sorted = sort_cards_by_power(gameplay, hand)
			var mid_idx = sorted.size() / 2
			return [sorted[mid_idx]]
			
		"Professor Jim":
			# Prefers leading with mid-tier pairs (rank 3 to 6) or clean singles (rank 3 to 5)
			var pairs = gameplay._find_combinations(hand, "Pair", 2)
			var prof_pairs = []
			for p in pairs:
				var rank = p[0]["rank"]
				if rank >= 3 and rank <= 6:
					prof_pairs.append(p)
			if not prof_pairs.is_empty():
				prof_pairs.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Pair") > 0
				)
				return prof_pairs[0]
				
			var prof_singles = []
			for c in hand:
				if c["rank"] >= 3 and c["rank"] <= 5:
					prof_singles.append(c)
			if not prof_singles.is_empty():
				var sorted = sort_cards_by_power(gameplay, prof_singles)
				return [sorted[sorted.size() - 1]]
				
			return [hand[randi() % hand.size()]]
			
		"Mrs. Jones":
			# Play a pair or set if she gets a chance
			for size in range(6, 2, -1):
				var noble = gameplay._find_combinations(hand, "Noble Set", size)
				if not noble.is_empty():
					return noble[0]
				var soldier = gameplay._find_combinations(hand, "Soldier Set", size)
				if not soldier.is_empty():
					return soldier[0]
			var pairs = gameplay._find_combinations(hand, "Pair", 2)
			if not pairs.is_empty():
				return pairs[0]
				
			# If must play a Single: lowest (hand > 4) or highest (hand <= 4)
			var sorted = sort_cards_by_power(gameplay, hand)
			if hand.size() > 4:
				return [sorted[0]]
			else:
				return [sorted[sorted.size() - 1]]
				
		"Dum Dum":
			# Compile all valid lead options and choose one completely at random
			var options = []
			for c in hand:
				options.append([c])
			var pairs = gameplay._find_combinations(hand, "Pair", 2)
			for p in pairs:
				options.append(p)
			for size in range(3, 7):
				var noble = gameplay._find_combinations(hand, "Noble Set", size)
				for n in noble:
					options.append(n)
			for size in range(3, 6):
				var soldier = gameplay._find_combinations(hand, "Soldier Set", size)
				for s in soldier:
					options.append(s)
			return options[randi() % options.size()]
			
		"Sammy":
			# Smart aggressive: Noble Set > Pair > strongest Single
			for size in range(6, 2, -1):
				var noble = gameplay._find_combinations(hand, "Noble Set", size)
				if not noble.is_empty():
					noble.sort_custom(func(a, b):
						return gameplay._compare_valid_plays(a, b, "Noble Set") > 0
					)
					return noble[0]
			var pairs = gameplay._find_combinations(hand, "Pair", 2)
			if not pairs.is_empty():
				pairs.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Pair") > 0
				)
				return pairs[0]
			var sorted = sort_cards_by_power(gameplay, hand)
			return [sorted[sorted.size() - 1]]
			
		"Max May":
			# Optimal: Noble Set > Soldier Set (4+) > strong Pair (rank 1-3) > strategic mid Single
			for size in range(6, 2, -1):
				var noble = gameplay._find_combinations(hand, "Noble Set", size)
				if not noble.is_empty():
					noble.sort_custom(func(a, b):
						return gameplay._compare_valid_plays(a, b, "Noble Set") > 0
					)
					return noble[0]
			var sold_4 = gameplay._find_combinations(hand, "Soldier Set", 4)
			if not sold_4.is_empty():
				sold_4.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Soldier Set") > 0
				)
				return sold_4[0]
			var pairs = gameplay._find_combinations(hand, "Pair", 2)
			var strong_pairs = []
			for p in pairs:
				if p[0]["rank"] <= 3:
					strong_pairs.append(p)
			if not strong_pairs.is_empty():
				strong_pairs.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, "Pair") > 0
				)
				return strong_pairs[0]
			# Play mid-range single (rank 3-5) to probe without wasting top cards
			var probe_cards = []
			for c in hand:
				if c["rank"] >= 3 and c["rank"] <= 5:
					probe_cards.append(c)
			if not probe_cards.is_empty():
				var sorted_probe = sort_cards_by_power(gameplay, probe_cards)
				return [sorted_probe[sorted_probe.size() - 1]]
			# Fallback: weakest non-General/Advisor single
			var sorted = sort_cards_by_power(gameplay, hand)
			for c in sorted:
				if c["rank"] > 2:
					return [c]
			return [sorted[0]]
			
		_:
			# Fallback standard play
			return [hand[randi() % hand.size()]]

# --- Internal Responder Play Selectors ---

static func _select_play_as_responder(gameplay: Node, hand: Array, play_type: String, count: int, valid_plays: Array, active_style: String) -> Array:
	match active_style:
		"Big Bobby":
			# Play strongest valid play
			valid_plays.sort_custom(func(a, b):
				return gameplay._compare_valid_plays(a, b, play_type) > 0
			)
			return valid_plays[0]
			
		"Shadow", "Dr. Lu Yerf":
			# Play lowest valid play
			valid_plays.sort_custom(func(a, b):
				return gameplay._compare_valid_plays(a, b, play_type) < 0
			)
			return valid_plays[0]
			
		"Professor Jim":
			# Play mid-power valid play
			valid_plays.sort_custom(func(a, b):
				return gameplay._compare_valid_plays(a, b, play_type) < 0
			)
			var mid_idx = valid_plays.size() / 2
			return valid_plays[mid_idx]
			
		"Mrs. Jones":
			# Lowest valid (hand > 4) or highest valid (hand <= 4)
			valid_plays.sort_custom(func(a, b):
				return gameplay._compare_valid_plays(a, b, play_type) < 0
			)
			if hand.size() > 4:
				return valid_plays[0]
			else:
				return valid_plays[valid_plays.size() - 1]
				
		"Dum Dum":
			# 80% chance to play a random valid combination, 20% chance to fold randomly
			if randf() < 0.2:
				return _choose_fold_cards(gameplay, hand, count, active_style)
			else:
				return valid_plays[randi() % valid_plays.size()]
				
		"Sammy":
			# Smart aggressive: always play strongest valid combo
			valid_plays.sort_custom(func(a, b):
				return gameplay._compare_valid_plays(a, b, play_type) > 0
			)
			return valid_plays[0]
			
		"Max May":
			# Optimal: play strongest, but fold if only option uses General and hand > 5
			valid_plays.sort_custom(func(a, b):
				return gameplay._compare_valid_plays(a, b, play_type) > 0
			)
			# If hand > 5 and ALL valid plays use a General (rank 1), fold to conserve
			if hand.size() > 5:
				var has_non_general_play = false
				for vp in valid_plays:
					var uses_general = false
					for card in vp:
						if card["rank"] == 1:
							uses_general = true
							break
					if not uses_general:
						has_non_general_play = true
						break
				if not has_non_general_play:
					return _choose_fold_cards(gameplay, hand, count, active_style)
			# Play strongest non-General option if available, else strongest overall
			for vp in valid_plays:
				var uses_general = false
				for card in vp:
					if card["rank"] == 1:
						uses_general = true
						break
				if not uses_general:
					return vp
			return valid_plays[0]
			
		_:
			return valid_plays[randi() % valid_plays.size()]

# --- Internal Folding Selectors ---

static func _choose_fold_cards(gameplay: Node, hand: Array, count: int, active_style: String) -> Array:
	# 1. Categorize cards in hand to conserve Generals (rank 1) and Advisors (rank 2)
	var low_value = []
	var advisors = []
	var kings = []
	
	for c in hand:
		if c["rank"] == 1:
			kings.append(c)
		elif c["rank"] == 2:
			advisors.append(c)
		else:
			low_value.append(c)
			
	# Sort advisors and kings by ascending power so we fold weaker ones first if forced to
	var sorted_advisors = sort_cards_by_power(gameplay, advisors)
	var sorted_kings = sort_cards_by_power(gameplay, kings)
	
	# 2. Select from low_value cards according to style
	var selected_to_fold = []
	var needed = count
	
	if needed > 0 and not low_value.is_empty():
		var sorted_low = sort_cards_by_power(gameplay, low_value)
		var style_low_sorted = []
		match active_style:
			"Big Bobby", "Dr. Lu Yerf", "Mrs. Jones", "Sammy":
				style_low_sorted = sorted_low
			"Shadow":
				# Folds rank > 3 cards first to preserve Elephants (rank 3)
				var shadow_low = []
				var shadow_mid = []
				for c in low_value:
					if c["rank"] > 3:
						shadow_low.append(c)
					else:
						shadow_mid.append(c)
				style_low_sorted = sort_cards_by_power(gameplay, shadow_low) + sort_cards_by_power(gameplay, shadow_mid)
			"Professor Jim", "Max May":
				# Folds cards that don't form pairs first, then mid-value (rank 4-6)
				var prof_mid = []
				var prof_other = []
				for c in low_value:
					if c["rank"] >= 4 and c["rank"] <= 6:
						prof_mid.append(c)
					else:
						prof_other.append(c)
				style_low_sorted = sort_cards_by_power(gameplay, prof_mid) + sort_cards_by_power(gameplay, prof_other)
			"Dum Dum":
				var temp_low = low_value.duplicate()
				temp_low.shuffle()
				style_low_sorted = temp_low
			_:
				style_low_sorted = sorted_low
				
		var fold_low_count = min(needed, style_low_sorted.size())
		selected_to_fold.append_array(style_low_sorted.slice(0, fold_low_count))
		needed -= fold_low_count
		
	# 3. If needed > 0, fold from advisors
	if needed > 0 and not sorted_advisors.is_empty():
		var fold_adv_count = min(needed, sorted_advisors.size())
		selected_to_fold.append_array(sorted_advisors.slice(0, fold_adv_count))
		needed -= fold_adv_count
		
	# 4. If needed > 0, fold from kings
	if needed > 0 and not sorted_kings.is_empty():
		var fold_king_count = min(needed, sorted_kings.size())
		selected_to_fold.append_array(sorted_kings.slice(0, fold_king_count))
		needed -= fold_king_count
		
	return selected_to_fold

# --- King-Pair Endgame Strategy Helpers ---

static func _has_saved_king_pair_setup(gameplay: Node, hand: Array) -> Dictionary:
	var kings = []
	for card in hand:
		if card["rank"] == 1:
			kings.append(card)
	if kings.is_empty():
		return {}
		
	var pairs = gameplay._find_combinations(hand, "Pair", 2)
	if pairs.is_empty():
		return {}
		
	# Choose strongest King and Pair to preserve
	var best_king = kings[0]
	for k in kings:
		if k["color"] == "R" and best_king["color"] == "B":
			best_king = k
			
	pairs.sort_custom(func(a, b):
		return gameplay._compare_valid_plays(a, b, "Pair") > 0
	)
	var best_pair = pairs[0]
	
	return {
		"king": best_king,
		"pair": best_pair
	}

static func _select_play_with_saved_king_pair(gameplay: Node, hand: Array, play_type: String, count: int, active_style: String, saved: Dictionary) -> Array:
	var king_card = saved["king"]
	var pair_cards = saved["pair"]
	
	# Determine allowed (non-saved) cards in hand
	var allowed = []
	for c in hand:
		var is_saved = false
		if c["id"] == king_card["id"]:
			is_saved = true
		else:
			for pc in pair_cards:
				if c["id"] == pc["id"]:
					is_saved = true
					break
		if not is_saved:
			allowed.append(c)
			
	# If exactly 3 cards left, hand consists solely of the saved General and Pair
	if hand.size() == 3:
		if play_type == "":
			# Leading: play General to win turn and set up final Pair lead
			return [king_card]
		else:
			# Responding:
			if play_type == "Single":
				return [king_card]
			elif play_type == "Pair":
				return pair_cards
			else:
				# Noble/Soldier Set count cannot be matched, must fold whole hand using conservation
				return _choose_fold_cards(gameplay, hand, count, active_style)
				
	# If > 3 cards left, preserve the King and Pair by using allowed cards
	if play_type == "":
		# Leading: Try to lead an allowed Pair, else play allowed Single
		var allowed_pairs = gameplay._find_combinations(allowed, "Pair", 2)
		if not allowed_pairs.is_empty():
			allowed_pairs.sort_custom(func(a, b):
				return gameplay._compare_valid_plays(a, b, "Pair") > 0
			)
			return allowed_pairs[0]
		else:
			var sorted_allowed = sort_cards_by_power(gameplay, allowed)
			if active_style == "Big Bobby":
				return [sorted_allowed[sorted_allowed.size() - 1]]
			elif active_style == "Shadow":
				return [sorted_allowed[0]]
			else: # Professor Jim
				var mid_idx = sorted_allowed.size() / 2
				return [sorted_allowed[mid_idx]]
	else:
		# Responding: Try to play valid combination using only allowed cards
		var allowed_valid = gameplay._find_combinations(allowed, play_type, count)
		if not allowed_valid.is_empty():
			if active_style == "Big Bobby":
				allowed_valid.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, play_type) > 0
				)
				return allowed_valid[0]
			elif active_style == "Shadow":
				allowed_valid.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, play_type) < 0
				)
				return allowed_valid[0]
			else: # Professor Jim
				allowed_valid.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, play_type) < 0
				)
				var mid_idx = allowed_valid.size() / 2
				return allowed_valid[mid_idx]
		else:
			# Fold: select cards to fold using conservation logic
			if count > allowed.size():
				return _choose_fold_cards(gameplay, hand, count, active_style)
			else:
				return _choose_fold_cards(gameplay, allowed, count, active_style)


# --- Memory and Advanced Strategy Helpers ---

static func get_played_cards(gameplay: Node) -> Array:
	var played = []
	if gameplay:
		played.append_array(gameplay.player_won_cards)
		played.append_array(gameplay.left_won_cards)
		played.append_array(gameplay.top_won_cards)
		played.append_array(gameplay.right_won_cards)
		played.append_array(gameplay.player_table_cards)
		played.append_array(gameplay.left_table_cards)
		played.append_array(gameplay.top_table_cards)
		played.append_array(gameplay.right_table_cards)
	return played


static func get_memorized_played_cards(gameplay: Node, active_style: String) -> Array:
	var all_played = get_played_cards(gameplay)
	if active_style == "Max May":
		return all_played
	elif active_style == "Professor Jim":
		var half_count = all_played.size() / 2
		var temp = all_played.duplicate()
		temp.shuffle()
		return temp.slice(0, half_count)
	else:
		return []


static func are_all_kings_played(gameplay: Node, hand: Array, active_style: String) -> bool:
	var accounted_kings = 0
	for card in hand:
		if card["rank"] == 1:
			accounted_kings += 1
			
	var memorized = get_memorized_played_cards(gameplay, active_style)
	for card in memorized:
		if card["rank"] == 1:
			accounted_kings += 1
			
	return accounted_kings >= 2


static func _get_protected_cards(gameplay: Node, hand: Array, active_style: String) -> Array:
	var protected = []
	
	# 1. Check King-Pair-King protection (2 Kings + 1 Pair)
	if active_style in ["Big Bobby", "Shadow", "Professor Jim", "Sammy", "Max May"]:
		var kings = []
		for c in hand:
			if c["rank"] == 1:
				kings.append(c)
		var pairs = gameplay._find_combinations(hand, "Pair", 2)
		if kings.size() == 2 and not pairs.is_empty():
			pairs.sort_custom(func(a, b):
				return gameplay._compare_valid_plays(a, b, "Pair") > 0
			)
			protected.append_array(kings)
			protected.append_array(pairs[0])
			
	# 2. Check King-For-Set protection (1 Red King + 1 Set of size >= 3)
	if active_style in ["Big Bobby", "Shadow", "Professor Jim", "Sammy", "Max May"]:
		var red_king = null
		for c in hand:
			if c["rank"] == 1 and c["color"] == "R":
				red_king = c
				break
		if red_king:
			var allowed_for_set = []
			for c in hand:
				if c["id"] != red_king["id"]:
					allowed_for_set.append(c)
					
			var best_set = []
			for size in range(6, 2, -1):
				var noble = gameplay._find_combinations(allowed_for_set, "Noble Set", size)
				if not noble.is_empty():
					best_set = noble[0]
					break
				var soldier = gameplay._find_combinations(allowed_for_set, "Soldier Set", size)
				if not soldier.is_empty():
					best_set = soldier[0]
					break
			if not best_set.is_empty():
				protected.append(red_king)
				protected.append_array(best_set)

	# 3. Check King-Pair setup protection (for styles that use it)
	if active_style in ["Big Bobby", "Shadow", "Professor Jim", "Sammy", "Max May"]:
		var saved = _has_saved_king_pair_setup(gameplay, hand)
		if not saved.is_empty():
			protected.append(saved["king"])
			protected.append_array(saved["pair"])
				
	# 4. Check Double Red Plane Split protection
	if active_style in ["Max May", "Professor Jim"]:
		var red_planes = []
		for c in hand:
			if c["rank"] == 2 and c["color"] == "R":
				red_planes.append(c)
		if red_planes.size() == 2:
			# If all Kings are NOT played yet, protect them from being split
			if not are_all_kings_played(gameplay, hand, active_style):
				protected.append_array(red_planes)
				
	return protected


static func _get_lead_cards(gameplay: Node) -> Array:
	if not gameplay:
		return []
	match gameplay.current_leader:
		0:
			return gameplay.player_table_cards
		1:
			return gameplay.left_table_cards
		2:
			return gameplay.top_table_cards
		3:
			return gameplay.right_table_cards
	return []


static func _get_saved_endgame_setup(gameplay: Node, hand: Array) -> Dictionary:
	# 1. King-Pair-King Setup (exactly 4 cards: 2 Kings + 1 Pair)
	if hand.size() == 4:
		var kings = []
		for c in hand:
			if c["rank"] == 1:
				kings.append(c)
		var non_kings = []
		for c in hand:
			if c["rank"] != 1:
				non_kings.append(c)
		if kings.size() == 2 and non_kings.size() == 2:
			if non_kings[0]["rank"] == non_kings[1]["rank"] and non_kings[0]["color"] == non_kings[1]["color"]:
				return {
					"type": "King-Pair-King",
					"kings": kings,
					"pair": non_kings
				}
				
	# 2. King-For-Set Setup (Red King + 1 valid set of any size)
	var red_king = null
	for c in hand:
		if c["rank"] == 1 and c["color"] == "R":
			red_king = c
			break
	if red_king:
		var other_cards = []
		for c in hand:
			if c["id"] != red_king["id"]:
				other_cards.append(c)
		if not other_cards.is_empty():
			var play_type = CardRules.detect_play_type(other_cards)
			if play_type == "Noble Set" or play_type == "Soldier Set":
				return {
					"type": "King-For-Set",
					"king": red_king,
					"set": other_cards,
					"set_type": play_type,
					"set_size": other_cards.size()
				}
				
	return {}


static func _select_play_with_endgame(gameplay: Node, hand: Array, play_type: String, count: int, active_style: String, setup: Dictionary) -> Array:
	if setup["type"] == "King-Pair-King":
		var kings = setup["kings"]
		var pair_cards = setup["pair"]
		
		# Sort kings by ascending power (Black King first, then Red King)
		var sorted_kings = sort_cards_by_power(gameplay, kings)
		
		if play_type == "":
			# Leading: lead the weaker King (Black King) first to win the turn
			return [sorted_kings[0]]
		else:
			# Responding:
			if play_type == "Single":
				return [sorted_kings[0]]
			elif play_type == "Pair" and count == 2:
				return pair_cards
			else:
				return _choose_fold_cards(gameplay, hand, count, active_style)
				
	elif setup["type"] == "King-For-Set":
		var king_card = setup["king"]
		var set_cards = setup["set"]
		var set_type = setup["set_type"]
		var set_size = setup["set_size"]
		
		if play_type == "":
			# Leading: lead the Red King (guaranteed win)
			return [king_card]
		else:
			# Responding:
			if play_type == "Single":
				return [king_card]
			elif play_type == set_type and count == set_size:
				return set_cards
			else:
				return _choose_fold_cards(gameplay, hand, count, active_style)
				
	return []
