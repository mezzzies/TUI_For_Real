# TUI - Card Game Gameplay Document

> A card game with Chinese chess themed cards (not Chinese chess gameplay).

---

## 1. Card Overview

There are **32 cards** in total, split into **2 colors**: **Red** and **Black** (16 cards each).
**Red** cards have **higher value** than Black cards of the same character rank.

### Card Characters & Quantities (per color)

| Rank | Character                          | Units per Color | Total (Both Colors) |
|------|------------------------------------|:---------------:|:--------------------:|
| 1    | **General** (aka King)             | 1               | 2                    |
| 2    | **Advisor** (aka Plane)            | 2               | 4                    |
| 3    | **Elephant**                       | 2               | 4                    |
| 4    | **Rook** (aka Boat)                | 2               | 4                    |
| 5    | **Horse**                          | 2               | 4                    |
| 6    | **Cannon** (aka House)             | 2               | 4                    |
| 7    | **Soldier** (aka Chip)             | 5               | 10                   |

**Total per color:** 1 + 2 + 2 + 2 + 2 + 2 + 5 = **16**
**Grand total:** 16 × 2 = **32**

### Card Power Hierarchy (Highest → Lowest)

```
Red General > Black General > Red Advisor > Black Advisor > Red Elephant > Black Elephant
> Red Rook > Black Rook > Red Horse > Black Horse > Red Cannon > Black Cannon
> Red Soldier > Black Soldier
```

> Within the same character rank, **Red always beats Black**.
> A higher-ranked character always beats a lower-ranked one regardless of color.

---

## 2. Players & Setup

- **Default player count:** 4 players
- **Card distribution:** All 32 cards are **shuffled** and dealt **randomly**
- Each player receives **8 cards** (32 ÷ 4 = 8)
- Cards are **hidden** (face-down) in each player's hand until played

---

## 3. Turn Structure

### 3.1 Leader System

- At the start of the game, one player is designated as the **Leader** for the first turn (chosen **randomly**).
- The **Leader announces** (speaks out) the **exact play type** they want to play.
- **All other players must follow the announced play type exactly.**

### 3.2 Play Types

The Leader **announces** one of the following play types:

#### Play Type A: Single Card (1 unit)
- Leader announces: **"Single"**
- Play **any single card** from hand.
- All other players must also play **1 card** each.

#### Play Type B: Pair (2 units)
- Leader announces: **"Pair"**
- Play **2 cards** of the **same character AND same color**.
- Example: Red Advisor + Red Advisor ✅
- Example: Red Advisor + Black Advisor ❌ (different color)
- Example: Red Advisor + Red Horse ❌ (different character)
- All other players must also play a **valid pair**.

#### Play Type C: Noble Set (3–6 cards, same color)
- Leader announces: **"Noble Set"** (and specifies the card count)
- Two valid noble **groups** exist:

| Royal Noble (Higher)              | War Noble (Lower)                |
|-----------------------------------|----------------------------------|
| General, Advisor, Elephant        | Rook, Horse, Cannon              |

- A Noble Set must contain **at least 1 of each character** in the group, all in the **same color**.
- **Duplicate characters are allowed** — if you have 2 of the same character (same color), you can include both.
- All cards in the set must be the **same color** (all Red or all Black).
- All other players must also play a **Noble Set of the same card count**.

**Minimum (3 cards):**
- Royal Noble: General + Advisor + Elephant
- War Noble: Rook + Horse + Cannon

**With duplicates (4–6 cards) — examples:**

| Cards | Royal Noble Example                                  | War Noble Example                                    |
|-------|------------------------------------------------------|------------------------------------------------------|
| 4     | General + Advisor + **Advisor** + Elephant           | Rook + **Rook** + Horse + Cannon                     |
| 5     | General + **Advisor + Advisor** + **Elephant + Elephant** | **Rook + Rook** + **Horse + Horse** + Cannon         |
| 6     | *(impossible: 1 General + 2 Advisors + 2 Elephants = 5 max)* | **Rook + Rook** + **Horse + Horse** + **Cannon + Cannon** |

> [!NOTE]
> **Royal Noble max = 5 cards** (1 General + 2 Advisors + 2 Elephants).
> **War Noble max = 6 cards** (2 Rooks + 2 Horses + 2 Cannons).

> **Noble Sets and Soldier Sets are completely different play types.** If the Leader plays Noble Set, players **cannot** respond with a Soldier Set, and vice versa.

#### Play Type D: Soldier Set (3–5 cards, same color)
- Leader announces: **"Soldier Set"** (and specifies the count, e.g., "3 Soldiers")
- A group of **Soldiers**, all the **same color**.
- Minimum 3 soldiers, maximum 5 soldiers (since there are 5 soldiers per color).
- All other players must also play a **Soldier Set** of the **same count**.

### 3.3 Folding

> [!IMPORTANT]
> If a player **cannot form the required play type**, or **chooses not to play** their valid cards, they must **fold**.

- **Folding Constraints & Triggers**:
  1. The **Leader cannot fold** since they select the play type.
  2. Folding is only possible when the play type is **Pair**, **Noble Set**, or **Soldier Set**. **Single play type cannot be folded** (players must play a valid single card).
  3. A player folds by playing the required number of cards which **do not match** the active play type. If the played cards match the active play type, it counts as a valid contest (cannot be folded).
- **Folding Mechanics**:
  - Folded cards go to the turn winner and are collected along with the winning cards.
  - A folding player **cannot win** that turn.
  - At the reveal phase, **folded cards remain face-down** (visual status is not shown) and are counted as losing cards.

### 3.4 Playing a Turn

1. **Leader announces** the play type (Single, Pair, Noble Set, or Soldier Set).
2. **Leader** places their card(s) **face-down** on the table.
3. **All other players** must respond. For **Pair** or **Set** plays, if they cannot or choose not to match the play type, they must **fold** (play non-matching cards of the same count). For **Single** plays, they must play a valid single card.
4. Once all players have placed their cards, **everyone reveals** simultaneously. (Folded cards remain face-down).
5. The **highest-ranking card or set wins** the turn.
6. The winner **collects all cards** from the table — including face-down folded cards.

### 3.5 Determining the Winner of a Turn

#### Single Card Comparison
- Compare by character rank first (General > Advisor > Elephant > Rook > Horse > Cannon > Soldier).
- If same character rank, **Red beats Black**.

#### Pair Comparison
- Compare by character rank of the pair.
- If same character rank, **Red pair beats Black pair**.

#### Noble Set Comparison
- Both players must play the **same number of cards**.
- **Royal Noble** beats **War Noble** of **any color** (when same card count).
- Within the same noble group, **Red beats Black**.
- **More cards in a Noble Set does NOT automatically win** — sets are only compared when they have the **same card count** (since the leader specifies the count).
- Noble Sets **cannot** be compared with Soldier Sets (they are different play types).

#### Soldier Set Comparison
- Soldier Sets of the **same count** are compared by **color**: **Red beats Black**.
- Soldier Sets **cannot** be compared with Noble Sets (they are different play types).

#### Tie-breaking Rule
- In the event that multiple players play cards of the same rank and color (equal power), the tie is broken in favor of the **current Leader** of that turn, or the player closest to the Leader in the clockwise direction cycle: **Bottom (Player) → Left → Top → Right → Bottom**.
- *Example*: If Top is the Leader, the search order starts at Top, then goes to Right, then Bottom, and finally Left.

---

## 4. Special Rules

### 4.1 The "Perfect" Tactic 🏆

> [!CAUTION]
> This is a rare and powerful special rule.

If a player (as Leader) **wins 7 consecutive turns from the very beginning** of the round, they will have used 7 of their 8 cards. On their **8th and final turn**, if their last remaining card is a **Black Soldier**:

- That **Black Soldier can beat ANY card**, including the **General**.
- This is called the **"Perfect"** tactic.
- It overrides the normal card hierarchy for that final turn only.

**Conditions for Perfect:**
1. The player must have been the Leader for **all 7 previous turns** (won every single one).
2. The player's **last card must be a Black Soldier**.
3. It only applies on the player's **8th (final) turn**.

---

## 5. Round Progression

1. The **winner** of the current turn becomes the **Leader** of the **next turn**.
2. The winner **collects ALL played cards** from that turn — including their own cards, opponents' played cards, **and folded cards**.
3. Repeat the turn cycle until **all players have no cards left** in their hands.

---

## 6. Game Loop, Scoring, & Round Structure

### 6.1 The "Loop"
A **Loop** starts when 32 cards are shuffled and dealt (8 cards to each of the 4 players) and ends when **all players have no cards remaining in their hands**.
- Since a turn can involve playing multi-card combinations (Pairs = 2 cards, Noble Sets = 3-6 cards, Soldier Sets = 3-5 cards) or folding a matching number of cards, players will discard multiple cards in a single turn.
- A Loop is **not** a fixed 8 turns. It consists of a variable number of turns (maximum 8 turns, minimum 2-3 turns depending on the size of the play types announced by the Leaders).

### 6.2 Scoring (End of Loop)
When a Loop ends (hands are empty):
1. Each player counts the total number of cards (units) they have collected/won.
2. The score is calculated as: **Score = (Collected Cards) ÷ 4**. 
3. This division always yields an integer since all 32 cards are distributed among the 4 players.
4. *Example:* If a player wins every turn in a loop and collects all 32 cards, they get $32 \div 4 = 8$ points (the maximum score for a single loop).

### 6.3 The "Round"
A **Round** is composed of exactly **4 Loops**.
- At the end of each Loop, the scores are added to each player's cumulative total.
- At the end of 4 Loops, the Round is complete. The player with the highest total score across the 4 Loops wins the Round.
- After a Round ends, the cumulative scores reset and a new Round can begin.

---

## 7. Card Assets Reference

All card assets are located in `res://asset/card/default/`

| Card                         | Filename                        |
|------------------------------|---------------------------------|
| Red General (King)           | `TuiSkin_R_1King.png`           |
| Red Advisor (Plane)          | `TuiSkin_R_2Plane.png`          |
| Red Elephant                 | `TuiSkin_R_3Elephant.png`       |
| Red Rook (Boat)              | `TuiSkin_R_4Boat.png`           |
| Red Horse                    | `TuiSkin_R_5Horse.png`          |
| Red Cannon (House)           | `TuiSkin_R_6House.png`          |
| Red Soldier (Chip)           | `TuiSkin_R_7Chip.png`           |
| Black General (King)         | `TuiSkin_B_1King.png`           |
| Black Advisor (Plane)        | `TuiSkin_B_2Plane.png`          |
| Black Elephant               | `TuiSkin_B_3Elephant.png`       |
| Black Rook (Boat)            | `TuiSkin_B_4Boat.png`           |
| Black Horse                  | `TuiSkin_B_5Horse.png`          |
| Black Cannon (House)         | `TuiSkin_B_6House.png`          |
| Black Soldier (Chip)         | `TuiSkin_B_7Chip.png`           |

Character assets in `res://asset/character/default/`:
- `backhand.png` — card back
- `fronthand.png` — card front / hand visual
- `mezz_red.png` — red accent asset

---

## 8. Open Questions (Remaining)

> [!NOTE]
> Most questions have been resolved. One item remains for future discussion:

1. **Win condition across rounds:** Is there a target score to win the overall game, or do players just play indefinitely? *(To be discussed later)*

---

## 9. Game Flow Summary

```
┌─────────────────────────────────────────────┐
│              GAME START (NEW ROUND)          │
│  Shuffle 32 cards → Deal 8 to each player   │
└──────────────────┬──────────────────────────┘
				   │
				   ▼
		 ┌─────────────────┐
		 │  Random player   │
		 │  becomes Leader  │
		 └────────┬────────┘
				  │
				  ▼
	┌──────────────────────────┐
	│  Leader ANNOUNCES play   │◄─────────────┐
	│  type, then places cards │              │
	└────────────┬─────────────┘              │
				 │                            │
				 ▼                            │
	┌──────────────────────────┐              │
	│  Other players respond:  │              │
	│  • Match play type, OR   │              │
	│  • FOLD (sacrifice cards)│              │
	└────────────┬─────────────┘              │
				 │                            │
				 ▼                            │
	┌──────────────────────────┐              │
	│  All cards revealed      │              │
	│  simultaneously          │              │
	└────────────┬─────────────┘              │
				 │                            │
				 ▼                            │
	┌──────────────────────────┐              │
	│  Determine turn winner   │              │
	│  (highest card/set wins) │              │
	│  ★ Check Perfect tactic  │              │
	└────────────┬─────────────┘              │
				 │                            │
				 ▼                            │
	┌──────────────────────────┐    Yes       │
	│  Winner collects cards   ├──────────────┘
	│  Folded cards discarded  │  (cards remaining?)
	│  Winner = new Leader     │
	└────────────┬─────────────┘
				 │ No
				 ▼
	┌──────────────────────────┐
	│  ROUND OVER              │
	│  Score = units won ÷ 4   │
	└────────────┬─────────────┘
				 │
				 ▼
	┌──────────────────────────┐
	│  RESHUFFLE & NEW ROUND   │
	│  (Continue playing)      │
	└──────────────────────────┘
```
