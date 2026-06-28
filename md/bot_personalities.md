# TUI Bot Personalities & Play Styles

This document outlines the design and strategic logic for the three default bot personalities in TUI. These profiles dictate how bots behave during gameplay—specifically their card selection when leading, when responding, how they decide to fold, and which cards they choose to sacrifice.

---

## 1. Big Bobby ⚔️
> *“Attack is the only defense. A true leader never yields the field.”*

Big Bobby is a highly aggressive, high-risk, high-reward player. He believes that maintaining the **Leader** position is the key to winning the game. He will play his strongest cards early to force opponents into folding, trying to create an unbreakable chain of wins.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Highly Aggressive / Front-Runner |
| **Leader Play Selection** | Plays strong **Single** cards (General, Advisor) or high-ranking **Pairs** immediately to secure the next turn's lead. |
| **Response Threshold** | Will play his strongest matching card/set to win the turn even if he only beats the previous player by a tiny margin. He hates folding. |
| **Folding Behavior** | If forced to fold, he will sacrifice his lowest-ranking cards (Soldiers, Cannons) to keep his heavy hitters. |
| **Perfect Tactic Focus** | **High Priority.** If Big Bobby starts as the Leader and wins the first 3 turns, he will actively attempt the "Perfect" tactic if he has a Black Soldier in hand, playing aggressively to maintain 7 consecutive wins. |

> [!TIP]
> **Countering Big Bobby:** Big Bobby burns through his high-value cards (Generals, Advisors) very early. If you can force him to fold once or bait him into wasting a Red General on a low-value turn, he will be weak and defenseless in the late-game.

> [!NOTE]
> **King-Pair Endgame Strategy**: If Big Bobby's hand contains a General (King) and at least one Pair, he will protect and save those cards to play them when exactly 3 cards remain. He will lead the King to win the turn, and then play the Pair to finish the round.

---

## 2. Shadow 📜
> *“Let the river flow; the ocean waits at the end of the journey.”*

Shadow is a patient, defensive, and mathematically calculating player. He does not mind losing early turns. He focuses on card value conservation, frequently folding early to discard weak cards while hoarding a hand full of high-rank sets (Generals, Advisors, Elephants) to dominate the late-game.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Defensive / Late-Game Hoarder |
| **Leader Play Selection** | Plays complex **Noble Sets** or mid-value **Pairs** to force other players to break their hand structures or fold. If he has only singles, he plays low-rank cards first to flush out opponents' power cards. |
| **Response Threshold** | Highly conservative. He will fold even if he has a valid matching card, provided playing it would deplete his defensive resources (e.g., won't waste an Advisor to win a low-value pile). |
| **Folding Behavior** | Strategic folding. He uses folds to cleanly discard single Black Soldiers or Cannons that don't fit into sets, saving his high-ranking cards. |
| **Perfect Tactic Focus** | **Low Priority.** Shadow finds the "Perfect" tactic too risky and will almost never attempt it, preferring steady late-game value. |

> [!IMPORTANT]
> **Countering Shadow:** Shadow will play very passively in the first 4 turns. You should capitalize on this by winning those turns cheaply. Do not let him hoard cards indefinitely—force him into playing his high cards by leading with mid-tier sets (Pairs, Noble Sets) that he is forced to match.

> [!NOTE]
> **King-Pair Endgame Strategy**: If Shadow's hand contains a General (King) and at least one Pair, he will protect and save those cards to play them when exactly 3 cards remain. He will lead the King to win the turn, and then play the Pair to finish the round.

---

## 3. The Owl 🎭
> *“The card they see is never the card that wins.”*

The Owl is a deceptive, opportunistic, and unpredictable player. He specializes in baiting opponents into playing their best cards too early, or winning turns with the absolute minimum power required. He pays close attention to card colors and clockwise tie-breakers.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Deceptive / Opportunistic |
| **Leader Play Selection** | Loves announcing **Soldier Sets** or low-count **Noble Sets** to disrupt other players. He uses medium-strength leads (e.g. Red Rook or Black Elephant) to test opponents. |
| **Response Threshold** | Calculates the minimum card rank required to win based on what has already been played. If he cannot win cheaply, he folds immediately to deny points to the leader. |
| **Folding Behavior** | If he folds, he might intentionally throw away a mid-tier card (like a Rook or Horse) to mislead other players about his remaining hand strength. |
| **Perfect Tactic Focus** | **Medium Priority.** The Owl will only attempt the "Perfect" tactic if his starting hand is exceptionally strong (e.g., has both Generals and multiple Advisors). |

> [!WARNING]
> **Countering The Owl:** The Owl relies on player reactions and baiting. To beat The Owl, play predictably strong, solid sets. Do not try to out-bluff him; force him to match high-value pairs or Noble Sets where his trickery cannot override raw card hierarchy.

---

## 4. The Professor 🛡️
> *“A solid formation cannot be breached. We advance step by step.”*

The Professor is a highly balanced, defensive gatekeeper. He avoids high-risk moves and prefers high-probability outcomes. He focuses on protecting the team from runaway leaders by contesting plays just enough to keep the game tight, but without overcommitting his own high-value cards.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Balanced / Defensive Gatekeeper |
| **Leader Play Selection** | Prefers leading with mid-tier **Pairs** (Rooks, Horses, Cannons) or clean **Singles** (like Rooks or Elephants) to establish control without exposing his hand's weaknesses. |
| **Response Threshold** | Highly mathematical. He will match play types if he has a strong but not top-tier card/pair that guarantees a win or blocks a leader streak. If winning requires playing his only General, he will fold instead to keep his defense intact. |
| **Folding Behavior** | Highly consistent. Discards mid-value single cards (Horses, Cannons) that do not form pairs or sets, keeping his low cards for easy fodder and high cards for defense. |
| **Perfect Tactic Focus** | **None.** The Professor completely ignores the "Perfect" tactic, viewing it as too risky and systematically unsound. |

> [!TIP]
> **Countering The Professor:** The Professor plays very predictably and mathematically. Because he avoids overcommitting, he will rarely contest you if you play exceptionally high cards. You can win turns easily against him by raising the stakes slightly above his mid-tier comfort zone.

> [!NOTE]
> **King-Pair Endgame Strategy**: If The Professor's hand contains a General (King) and at least one Pair, he will protect and save those cards to play them when exactly 3 cards remain. He will lead the King to win the turn, and then play the Pair to finish the round.

---

## 5. Mrs. Jones 🏹
> *“Save the best for last, but never miss a chance to strike together.”*

Mrs. Jones plays strictly from the bottom-up, starting with her lowest-value cards to test opponents and conserve her strength. However, when she reaches the last 4 cards in her hand, she shifts strategies completely, playing her highest-value cards first. She is also highly opportunist and will always play a valid pair or set if she gets the chance.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Lowest-First / Late-Game Burst |
| **Leader Play Selection** | Plays a **Pair** or **Set** if available in her hand. If playing a **Single**, she plays her lowest-value card if she has 5 or more cards left; if she has 4 or fewer cards, she plays her highest-value card. |
| **Response Threshold** | Plays a pair/set if she gets a chance. For single plays: contests using her lowest-value winning card when holding >4 cards, or her highest-value winning card when holding <=4 cards. |
| **Folding Behavior** | Folds her lowest-value cards first if she has >4 cards left, but will fold her highest-value cards if she has <=4 cards left. |
| **Perfect Tactic Focus** | **Low Priority.** Her structured play style makes setting up a perfect 7-turn win sequence highly unlikely. |

> [!IMPORTANT]
> **Countering Mrs. Jones:** Keep track of her hand count. During the early game (hand size > 4), she will play very weak single cards, making it easy to win the lead. However, be prepared for her to drop her strongest remaining cards once she is down to her final 4 cards. Also, expect her to play pairs/sets immediately if she holds them.

---

## 6. Joker 👑
> *“Chaos is the only true pattern. Let the cards fall where they may.”*

Joker is a complete wildcard. He plays totally and utterly randomly. He can form and play sets or pairs, but he might just as easily decide to split a pair or set to play a single card or a smaller pair, completely ignoring standard strategic logic or turn value.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Total Chaos / Unpredictable |
| **Leader Play Selection** | Completely random. May play a Single, split a set to play a Pair, or play a full Set. There is no strategic consistency. |
| **Response Threshold** | Randomly decides whether to match the play or fold. When matching, he randomly picks any valid combination from his options. |
| **Folding Behavior** | Folds completely random cards from his hand, sometimes sacrificing high-value Generals or keeping low-value Soldiers. |
| **Perfect Tactic Focus** | **Random.** He does not plan for the "Perfect" tactic, but might end up triggering it purely by chance due to random actions. |

> [!WARNING]
> **Countering Joker:** Do not try to read or bait Joker, as his moves have no logical patterns or reasoning. Stick to your own optimal card play strategy and rely on the absolute mathematical strength of your hand to win turns.

---

## 7. Meta Mezz 🌀
> *“Adaptability is the ultimate strategy. To win, one must be like water—constantly changing form.”*

Meta Mezz is an adaptive mimic who changes his play style dynamically. Rather than sticking to one personality, he evaluates his dealt hand at the end of each loop (after hands are empty and a new loop starts) and switches to a different profile that best matches his hand configuration.

### 📋 Personality Switching Rules
At the start of each loop, Meta Mezz analyzes his new 8-card hand and adopts a style as follows:

1. **Both Generals (Red & Black)** ➔ Adopts the **Big Bobby** personality (aggressive front-runner).
2. **Single General (Red or Black)** ➔ Adopts the **Shadow** personality (patient, defensive hoarder).
3. **2 Pairs OR 1 Set (Noble/Soldier)** ➔ Adopts **The Owl** personality (deceptive and bait-oriented).
4. **First Loop of the Game** ➔ He always starts the round (the very first loop) using the **Joker** personality (total chaos).
5. **Fallback (None of the above)** ➔ If none of the conditions are met (e.g. low-power hand with 1 or 0 pairs and no sets), he defaults to **The Professor** personality (balanced gatekeeper).

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Adaptive Mimic / Shifting |
| **Leader Play Selection** | Matches the style of his currently adopted personality (Big Bobby, Shadow, The Owl, Joker, or The Professor). |
| **Response Threshold** | Matches the style of his currently adopted personality. |
| **Folding Behavior** | Matches the style of his currently adopted personality. |
| **Perfect Tactic Focus** | **Dynamic.** Only prioritizes the "Perfect" tactic if he has transitioned into the **Big Bobby** personality and conditions align. |

> [!TIP]
> **Countering Meta Mezz:** You must identify which personality he has shifted to for the current loop. Keep track of the cards played: if you see him playing a single General early, he has adopted the **Shadow** profile; if he plays huge Noble Sets, he has adopted **The Owl** or **Big Bobby**. Adapt your countermeasures to match his current stance.


