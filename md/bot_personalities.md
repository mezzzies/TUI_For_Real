# TUI Bot Personalities & Play Styles

This document outlines the design and strategic logic for the default bot personalities in TUI. These profiles dictate how bots behave during gameplay—specifically their card selection when leading, when responding, how they decide to fold, and which cards they choose to sacrifice.

---

## 🛡️ Global Bot Rules
All bot players strictly respect high-value card conservation when folding and execute optimized endgame plans:
- **General & Advisor Conservation**: A bot will never choose to fold an Advisor (Plane, rank 2) or General (King, rank 1) unless it holds no other lower-ranking cards.
- **Thinking Time**: Each bot takes a short delay before placing their card on the table to mimic natural play.
- **King-Pair-King Endgame (4 cards)**: If a bot has exactly 2 Kings and 1 Pair, they lead the weaker King first to win the turn, then play the Pair, and then play the final King to win.
- **King-For-Set Endgame (Variable size)**: If a bot has exactly 1 Red King and 1 Set (Noble Set or Soldier Set of any size), they lead the Red King first to secure the lead, followed by the Set to sweep.

---

## 1. Big Bobby ⚔️
> *"Give me the card! ...or some snack, thank you!"*

Big Bobby is a highly aggressive, high-risk, high-reward player. He believes that maintaining the **Leader** position is the key to winning the game. He will play his strongest cards early to force opponents into folding, trying to create an unbreakable chain of wins.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Highly Aggressive / Front-Runner |
| **Thinking Time** | **Short**: Places cards within 2 to 3 seconds. |
| **Leader Play Selection** | Plays strong **Single** cards (General, Advisor) or high-ranking **Pairs** immediately to secure the next turn's lead. |
| **Response Threshold** | Will play his strongest matching card/set to win the turn even if he only beats the previous player by a tiny margin. He hates folding. |
| **Folding Behavior** | If forced to fold, he will sacrifice his lowest-ranking cards (Soldiers, Cannons) to keep his heavy hitters, strictly protecting Advisors and Generals. |
| **Perfect Tactic Focus** | **High Priority.** If Big Bobby starts as the Leader and wins the first 3 turns, he will actively attempt the "Perfect" tactic if he has a Black Soldier in hand, playing aggressively to maintain 7 consecutive wins. |

> [!TIP]
> **Countering Big Bobby:** Big Bobby burns through his high-value cards (Generals, Advisors) very early. If you can force him to fold once or bait him into wasting a Red General on a low-value turn, he will be weak and defenseless in the late-game.

> [!NOTE]
> **Endgame Strategies**:
> - **King-Pair**: Protects 1 King + 1 Pair to play when exactly 3 cards remain (King -> Pair).
> - **King-Pair-King**: Protects 2 Kings + 1 Pair to play when exactly 4 cards remain (weaker King -> Pair -> final King).
> - **King-For-Set**: Protects 1 Red King + 1 Set of any size to play at the end (Red King -> Set).

---

## 2. Shadow 📜
> *"...did I play? You didn't even notice."*

Shadow is a patient, defensive, and mathematically calculating player. He does not mind losing early turns. He focuses on card value conservation, frequently folding early to discard weak cards while hoarding a hand full of high-rank sets (Generals, Advisors, Elephants) to dominate the late-game.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Defensive / Late-Game Hoarder |
| **Thinking Time** | **Normal**: Takes 3 to 4 seconds. |
| **Leader Play Selection** | Plays complex **Noble Sets** or mid-value **Pairs** to force other players to break their hand structures or fold. If he has only singles, he plays low-rank cards first to flush out opponents' power cards. |
| **Response Threshold** | Highly conservative. He will fold even if he has a valid matching card, provided playing it would deplete his defensive resources (e.g., won't waste an Advisor to win a low-value pile). |
| **Folding Behavior** | Strategic folding. Folds low-value cards (rank > 3) first to preserve Elephants, Advisors, and Generals. |
| **Perfect Tactic Focus** | **Low Priority.** Shadow finds the "Perfect" tactic too risky and will almost never attempt it, preferring steady late-game value. |

> [!IMPORTANT]
> **Countering Shadow:** Shadow will play very passively in the first 4 turns. You should capitalize on this by winning those turns cheaply. Do not let him hoard cards indefinitely—force him into playing his high cards by leading with mid-tier sets (Pairs, Noble Sets) that he is forced to match.

> [!NOTE]
> **Endgame Strategies**:
> - **King-Pair**: Protects 1 King + 1 Pair to play when exactly 3 cards remain (King -> Pair).
> - **King-Pair-King**: Protects 2 Kings + 1 Pair to play when exactly 4 cards remain (weaker King -> Pair -> final King).
> - **King-For-Set**: Protects 1 Red King + 1 Set of any size to play at the end (Red King -> Set).

---

## 3. Dr. Lu Yerf 🎭
> *"Ah yes, precisely as I miscalculated. On purpose."*

Dr. Lu Yerf is a deceptive, opportunistic, and unpredictable player. He specializes in baiting opponents into playing their best cards too early, or winning turns with the absolute minimum power required. He pays close attention to card colors and clockwise tie-breakers.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Deceptive / Opportunistic |
| **Thinking Time** | **Long**: Takes 4 to 5 seconds. |
| **Leader Play Selection** | Loves announcing **Soldier Sets** or low-count **Noble Sets** to disrupt other players. He uses medium-strength leads (e.g. Red Rook or Black Elephant) to test opponents. |
| **Response Threshold** | Calculates the minimum card rank required to win based on what has already been played. If he cannot win cheaply, he folds immediately to deny points to the leader. |
| **Folding Behavior** | If he folds, he might intentionally throw away a mid-tier card (like a Rook or Horse) to mislead other players about his remaining hand strength, keeping Generals/Advisors conserved. |
| **Perfect Tactic Focus** | **Medium Priority.** Dr. Lu Yerf will only attempt the "Perfect" tactic if his starting hand is exceptionally strong (e.g., has both Generals and multiple Advisors). |

> [!WARNING]
> **Countering Dr. Lu Yerf:** Dr. Lu Yerf relies on player reactions and baiting. To beat Dr. Lu Yerf, play predictably strong, solid sets. Do not try to out-bluff him; force him to match high-value pairs or Noble Sets where his trickery cannot override raw card hierarchy.

---

## 4. Professor Jim 🛡️
> *"Page 47, paragraph 3. The optimal move is... PAIR!"*

Professor Jim is a highly balanced, defensive gatekeeper. He avoids high-risk moves and prefers high-probability outcomes. He focuses on protecting the team from runaway leaders by contesting plays just enough to keep the game tight, but without overcommitting his own high-value cards.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Balanced / Defensive Gatekeeper |
| **Card Memory** | **Moderate Memory**: Remembers exactly half of the cards played in the current loop. |
| **Thinking Time** | **Long**: Takes 4 to 5 seconds. |
| **Leader Play Selection** | Prefers leading with mid-tier **Pairs** (Rooks, Horses, Cannons) or clean **Singles** (like Rooks or Elephants) to establish control without exposing his hand's weaknesses. |
| **Response Threshold** | Highly mathematical. He will match play types if he has a strong but not top-tier card/pair that guarantees a win or blocks a leader streak. If winning requires playing his only General, he will fold instead to keep his defense intact. |
| **Folding Behavior** | Highly consistent. Discards mid-value single cards (Horses, Cannons) first, protecting low-value fodder for easy throws and hoarding Advisors and Generals. |
| **Double-Red-Plane-Split** | **Conditional.** If he holds 2 Red Advisors, he can split and play them separately as singles, but ONLY if he remembers that all Kings have been played. |
| **Perfect Tactic Focus** | **None.** Professor Jim completely ignores the "Perfect" tactic, viewing it as too risky and systematically unsound. |

> [!TIP]
> **Countering Professor Jim:** Professor Jim plays very predictably and mathematically. Because he avoids overcommitting, he will rarely contest you if you play exceptionally high cards. You can win turns easily against him by raising the stakes slightly above his mid-tier comfort zone.

> [!NOTE]
> **Endgame Strategies**:
> - **King-Pair**: Protects 1 King + 1 Pair to play when exactly 3 cards remain (King -> Pair).
> - **King-Pair-King**: Protects 2 Kings + 1 Pair to play when exactly 4 cards remain (weaker King -> Pair -> final King).
> - **King-For-Set**: Protects 1 Red King + 1 Set of any size to play at the end (Red King -> Set).

---

## 5. Mrs. Jones 🏹
> *"Oh sweetie, I was saving this just for you."*

Mrs. Jones plays strictly from the bottom-up, starting with her lowest-value cards to test opponents and conserve her strength. However, when she reaches the last 4 cards in her hand, she shifts strategies completely, playing her highest-value cards first. She is also highly opportunist and will always play a valid pair or set if she gets the chance.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Lowest-First / Late-Game Burst |
| **Thinking Time** | **Normal**: Takes 3 to 4 seconds. |
| **Leader Play Selection** | Plays a **Pair** or **Set** if available in her hand. If playing a **Single**, she plays her lowest-value card if she has 5 or more cards left; if she has 4 or fewer cards, she plays her highest-value card. |
| **Response Threshold** | Plays a pair/set if she gets a chance. For single plays: contests using her lowest-value winning card when holding >4 cards, or her highest-value winning card when holding <=4 cards. |
| **Folding Behavior** | Folds her lowest-value cards first if she has >4 cards left, but will fold her highest-value cards if she has <=4 cards left, while keeping Generals and Advisors strictly conserved. |
| **Perfect Tactic Focus** | **Low Priority.** Her structured play style makes setting up a perfect 7-turn win sequence highly unlikely. |

> [!IMPORTANT]
> **Countering Mrs. Jones:** Keep track of her hand count. During the early game (hand size > 4), she will play very weak single cards, making it easy to win the lead. However, be prepared for her to drop her strongest remaining cards once she is down to her final 4 cards. Also, expect her to play pairs/sets immediately if she holds them.

---

## 6. Dum Dum 👑
> *"Hehe, card go brrr!"*

Dum Dum is a complete wildcard. He plays totally and utterly randomly. He can form and play sets or pairs, but he might just as easily decide to split a pair or set to play a single card or a smaller pair, completely ignoring standard strategic logic or turn value.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Total Chaos / Unpredictable |
| **Thinking Time** | **Random**: Takes between 2 to 5 seconds. |
| **Leader Play Selection** | Completely random. May play a Single, split a set to play a Pair, or play a full Set. There is no strategic consistency. |
| **Response Threshold** | Randomly decides whether to match the play or fold. When matching, he randomly picks any valid combination from his options. |
| **Folding Behavior** | Folds completely random cards from his hand, but still respects the global rule of preserving Generals and Advisors if other cards exist. |
| **Perfect Tactic Focus** | **Random.** He does not plan for the "Perfect" tactic, but might end up triggering it purely by chance due to random actions. |

> [!WARNING]
> **Countering Dum Dum:** Do not try to read or bait Dum Dum, as his moves have no logical patterns or reasoning. Stick to your own optimal card play strategy and rely on the absolute mathematical strength of your hand to win turns.

---

## 7. Sammy 🔥
> *"Less talking, more winning. Next!"*

Sammy is a smart and ferociously aggressive player. Unlike Big Bobby who brute-forces every turn, Sammy combines raw aggression with sharp intelligence—she always plays her strongest hand but structures her plays efficiently. She prefers Noble Sets and Pairs to clear cards in bulk, and when forced to play singles, she always drops her heaviest hitter.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Smart Aggressive / Power Player |
| **Thinking Time** | **Short**: Places cards within 2 to 3 seconds. |
| **Leader Play Selection** | Prioritizes **Noble Sets** (largest available), then **strongest Pair**, then her **highest-value Single**. She never wastes a turn on a weak lead. |
| **Response Threshold** | Always plays her strongest valid combination. She never voluntarily folds when she can play. |
| **Folding Behavior** | If forced to fold, sacrifices lowest-ranking cards first (Soldiers, Cannons), strictly conserving Generals and Advisors. |
| **Perfect Tactic Focus** | **High Priority.** Her aggressive and structured play makes her a natural contender for the Perfect tactic. |

> [!CAUTION]
> **Countering Sammy:** Sammy is extremely dangerous because she plays both hard and smart. She always drops her best cards, making every contested turn expensive for you. The best strategy is to force her into folding early (play Noble Sets she can't match), draining her hand of fodder cards while she hoards her big guns.

> [!NOTE]
> **Endgame Strategies**:
> - **King-Pair**: Protects 1 King + 1 Pair to play when exactly 3 cards remain (King -> Pair).
> - **King-Pair-King**: Protects 2 Kings + 1 Pair to play when exactly 4 cards remain (weaker King -> Pair -> final King).
> - **King-For-Set**: Protects 1 Red King + 1 Set of any size to play at the end (Red King -> Set).

---

## 8. Max May 🧠
> *"I already know what you're going to play. I knew yesterday."*

Max May is the most intelligent and powerful player in the game. He plays with near-perfect optimization, leveraging Noble Sets to dominate, conserving Generals for maximum impact, probing opponents with calculated mid-range singles, and folding strategically when winning a turn would cost more than it's worth. He never wastes a General on a low-stakes turn—he waits for the moment when it matters most.

### 📋 Strategic Profile
| Aspect | Behavior & Rules |
|---|---|
| **Primary Style** | Optimal / Calculated Domination |
| **Card Memory** | **Perfect Memory**: Remembers every single card played in the current loop. |
| **Thinking Time** | **Long**: Takes 4 to 5 seconds. He thinks deeply before every play. |
| **Leader Play Selection** | Prioritizes **Noble Sets** (largest available) > **Soldier Sets (4+)** > **strong Pairs** (rank 1–3). When leading singles, plays **mid-range probing cards** (rank 3–5) to test opponents without exposing his power cards. Never leads with a General or Advisor as a single unless no other option exists. |
| **Response Threshold** | Plays his strongest valid combo but with a critical guard: if his hand has more than 5 cards and ALL valid responses require using a General (rank 1), he folds instead. He also prefers non-General combos over General-using combos even when both are available. |
| **Folding Behavior** | Folds mid-value cards (rank 4–6) first, then low-value, strictly protecting Advisors and Generals. Ensures pair structures are preserved. |
| **Double-Red-Plane-Split** | **Conditional.** If he holds 2 Red Advisors, he can split and play them separately as singles, but ONLY if he remembers that all Kings have been played. |
| **Perfect Tactic Focus** | **High Priority.** Max May's structured dominance makes him the most likely bot to achieve a Perfect tactic when conditions align. |

> [!CAUTION]
> **Countering Max May:** Max May is extremely difficult to beat. His mid-range probing leads are designed to bait you into revealing your hand strength without him committing his best cards. To counter him: (1) Don't overcommit to his probing singles—fold cheap and let him waste turns. (2) Save your own Generals for the endgame when he's forced to play his. (3) Lead with Noble Sets to force him to either match (depleting his reserves) or fold (losing points).

> [!NOTE]
> **Endgame Strategies**:
> - **King-Pair**: Protects 1 King + 1 Pair to play when exactly 3 cards remain (King -> Pair).
> - **King-Pair-King**: Protects 2 Kings + 1 Pair to play when exactly 4 cards remain (weaker King -> Pair -> final King).
> - **King-For-Set**: Protects 1 Red King + 1 Set of any size to play at the end (Red King -> Set).

---