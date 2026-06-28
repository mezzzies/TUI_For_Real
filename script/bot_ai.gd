class_name BotAI
extends RefCounted

# The pool of all available bot personalities
const PERSONALITY_POOL = ["Big Bobby", "Shadow", "The Owl", "The Professor", "Mrs. Jones", "Joker", "Meta Mezz"]

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
	var active_style = gameplay.active_bot_personalities.get(bot_idx, "The Professor")
	
	if active_style in ["Big Bobby", "Shadow", "The Professor"]:
		var saved = _has_saved_king_pair_setup(gameplay, hand)
		if not saved.is_empty():
			return _select_play_with_saved_king_pair(gameplay, hand, play_type, count, active_style, saved)

	if play_type == "":
		return _select_play_as_leader(gameplay, hand, active_style)
	else:
		var valid_plays = gameplay._find_combinations(hand, play_type, count)
		if valid_plays.is_empty():
			return _choose_fold_cards(gameplay, hand, count, active_style)
		else:
			return _select_play_as_responder(gameplay, hand, play_type, count, valid_plays, active_style)

# Helper to determine Meta Mezz's active personality based on the starting loop hand
static func get_meta_mezz_personality(gameplay: Node, hand: Array) -> String:
	# 1. Both Generals (Red & Black)
	var has_red_general = false
	var has_black_general = false
	for card in hand:
		if card["rank"] == 1:
			if card["color"] == "R":
				has_red_general = true
			elif card["color"] == "B":
				has_black_general = true
				
	if has_red_general and has_black_general:
		return "Big Bobby"
		
	# 2. Single General
	if has_red_general or has_black_general:
		return "Shadow"
		
	# 3. 2 Pairs or 1 Set (Noble/Soldier)
	var pairs = gameplay._find_combinations(hand, "Pair", 2)
	var pair_count = pairs.size()
	
	var has_set = false
	for size in range(3, 7):
		var noble_combos = gameplay._find_combinations(hand, "Noble Set", size)
		if not noble_combos.is_empty():
			has_set = true
			break
		var soldier_combos = gameplay._find_combinations(hand, "Soldier Set", size)
		if not soldier_combos.is_empty():
			has_set = true
			break
			
	if pair_count >= 2 or has_set:
		return "The Owl"
		
	# 4. Fallback
	return "The Professor"

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
			
		"The Owl":
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
			
		"The Professor":
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
				
		"Joker":
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
			
		"Shadow", "The Owl":
			# Play lowest valid play
			valid_plays.sort_custom(func(a, b):
				return gameplay._compare_valid_plays(a, b, play_type) < 0
			)
			return valid_plays[0]
			
		"The Professor":
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
				
		"Joker":
			# 80% chance to play a random valid combination, 20% chance to fold randomly
			if randf() < 0.2:
				return _choose_fold_cards(gameplay, hand, count, active_style)
			else:
				return valid_plays[randi() % valid_plays.size()]
				
		_:
			return valid_plays[randi() % valid_plays.size()]

# --- Internal Folding Selectors ---

static func _choose_fold_cards(gameplay: Node, hand: Array, count: int, active_style: String) -> Array:
	var sorted = sort_cards_by_power(gameplay, hand)
	
	match active_style:
		"Big Bobby", "The Owl":
			# Fold lowest-value cards first
			return sorted.slice(0, count)
			
		"Shadow":
			# Folds rank > 3 cards first to preserve Generals/Advisors/Elephants
			var low_cards = []
			var high_cards = []
			for c in hand:
				if c["rank"] > 3:
					low_cards.append(c)
				else:
					high_cards.append(c)
			var sorted_low = sort_cards_by_power(gameplay, low_cards)
			var sorted_high = sort_cards_by_power(gameplay, high_cards)
			var all_sorted = sorted_low + sorted_high
			return all_sorted.slice(0, count)
			
		"The Professor":
			# Folds mid-value single cards (rank 4, 5, 6) first
			var mid_cards = []
			var other_cards = []
			for c in hand:
				if c["rank"] >= 4 and c["rank"] <= 6:
					mid_cards.append(c)
				else:
					other_cards.append(c)
			var sorted_mid = sort_cards_by_power(gameplay, mid_cards)
			var sorted_other = sort_cards_by_power(gameplay, other_cards)
			var all_sorted = sorted_mid + sorted_other
			return all_sorted.slice(0, count)
			
		"Mrs. Jones":
			# Fold lowest (hand > 4) or highest (hand <= 4)
			if hand.size() > 4:
				return sorted.slice(0, count)
			else:
				return sorted.slice(sorted.size() - count, sorted.size())
				
		"Joker":
			# Folds completely random cards
			var temp = hand.duplicate()
			temp.shuffle()
			return temp.slice(0, count)
			
		_:
			return sorted.slice(0, count)

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
				# Noble/Soldier Set count cannot be matched, must fold whole hand
				var sorted = sort_cards_by_power(gameplay, hand)
				return sorted.slice(0, count)
				
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
			else: # The Professor
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
			else: # The Professor
				allowed_valid.sort_custom(func(a, b):
					return gameplay._compare_valid_plays(a, b, play_type) < 0
				)
				var mid_idx = allowed_valid.size() / 2
				return allowed_valid[mid_idx]
		else:
			# Fold: select cards to fold exclusively from allowed cards if count matches
			if count > allowed.size():
				var sorted_hand = sort_cards_by_power(gameplay, hand)
				return sorted_hand.slice(0, count)
			else:
				var sorted_allowed = sort_cards_by_power(gameplay, allowed)
				return sorted_allowed.slice(0, count)
