# TUI - Chinese Chess Card Game

[![Godot Version](https://img.shields.io/badge/Godot-4.x-blue?style=flat-square&logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey?style=flat-square)](https://godotengine.org/)

**TUI** is a 4-player trick-taking card game built in **Godot 4**. It uses Chinese Chess (Xiangqi) characters as the card theme but features its own distinct gameplay, strategic play types, folding constraints, and dynamic AI bot personalities.

---

## 📖 Table of Contents

- [1. Game Overview](#1-game-overview)
- [2. Card Deck & Power Hierarchy](#2-card-deck--power-hierarchy)
- [3. Gameplay Rules](#3-gameplay-rules)
  - [3.1 Play Types](#31-play-types)
  - [3.2 Folding Constraints](#32-folding-constraints)
  - [3.3 Winner & Tie-Breaking Rules](#33-winner--tie-breaking-rules)
  - [3.4 The "Perfect" Tactic](#34-the-perfect-tactic)
- [4. Scoring & Game Structure](#4-scoring--game-structure)
- [5. AI Bot Personalities](#5-ai-bot-personalities)
- [6. Project & Directory Structure](#6-project--directory-structure)
- [7. Running Headless Tests](#7-running-headless-tests)

---

## 1. Game Overview

In TUI, four players are dealt 8 cards each from a shuffled deck of 32 themed cards. One player is designated as the **Leader** for each turn, announcing a specific play type (Single, Pair, Noble Set, or Soldier Set). All other players must match that play type exactly or **fold** their cards. The player who plays the strongest combination wins all cards in that turn and becomes the Leader for the next turn.

---

## 2. Card Deck & Power Hierarchy

The deck consists of **32 cards** divided equally into **Red** (16 cards) and **Black** (16 cards). 

### Card Distribution per Color
| Rank | Character (Themed) | Units per Color | Total (Both Colors) |
| :---: | :--- | :---: | :---: |
| **1** | **General** (King) | 1 | 2 |
| **2** | **Advisor** (Plane) | 2 | 4 |
| **3** | **Elephant** | 2 | 4 |
| **4** | **Rook** (Boat) | 2 | 4 |
| **5** | **Horse** | 2 | 4 |
| **6** | **Cannon** (House) | 2 | 4 |
| **7** | **Soldier** (Chip) | 5 | 10 |

### Power Hierarchy (Highest → Lowest)
```
Red General > Black General > Red Advisor > Black Advisor > Red Elephant > Black Elephant 
> Red Rook > Black Rook > Red Horse > Black Horse > Red Cannon > Black Cannon 
> Red Soldier > Black Soldier
```
* **Lower rank numbers** beat higher rank numbers.
* Within the same rank, **Red always beats Black**.

---

## 3. Gameplay Rules

For a detailed explanation of the rules, please refer to the complete [gameplay.md](file:///d:/01_Working/07_Project/TUI/md/gameplay.md) guide.

### 3.1 Play Types
* **Single**: Play any 1 card.
* **Pair**: Play 2 cards of the **same character AND same color** (e.g., Red Advisor + Red Advisor).
* **Noble Set**: Play 3–6 cards of the **same color**, containing at least one of each card type in the category:
  * **Royal Noble**: General + Advisor + Elephant (Max 5 cards due to duplicate limits)
  * **War Noble**: Rook + Horse + Cannon (Max 6 cards due to duplicate limits)
* **Soldier Set**: Play 3–5 cards of the **same color**, all of which must be **Soldiers**.

### 3.2 Folding Constraints
* **Singles Cannot Be Folded**: If the Leader plays a Single, other players *must* play a valid single card from their hand.
* **Pairs & Sets**: Players may fold by playing cards that do not match the announced play type (e.g., mismatched ranks or colors).
* **Leader Constraint**: The Leader of the turn *cannot* fold since they must initiate with a valid play type.
* **Face-down Reveal**: Folded cards remain face-down during the reveal phase and cannot win the turn. They are collected as won units by the turn's winner.

### 3.3 Winner & Tie-Breaking Rules
* The strongest valid combination of the announced play type wins the turn.
* If there is a tie in card rank and color, the winner is determined by proximity to the current turn's Leader in clockwise order:
  $$\text{Bottom (Player)} \rightarrow \text{Left} \rightarrow \text{Top} \rightarrow \text{Right} \rightarrow \text{Bottom}$$

### 3.4 The "Perfect" Tactic
A player who wins 7 consecutive turns from the start of a loop and holds a **Black Soldier** as their 8th and final card triggers the **"Perfect"** tactic. On that final turn, the Black Soldier wins against any card, including a General, overriding the normal power hierarchy.

---

## 4. Scoring & Game Structure
* **Loop**: A single dealing round. Shuffling and dealing 8 cards to each of the 4 players, played until hands are empty.
* **Scoring**: At the end of a loop, players sum up their won cards. The score is calculated as $\text{Score} = \text{Won Cards} \div 4$.
* **Round**: Consists of exactly **4 Loops**. The player with the highest total score across 4 loops wins the round.

---

## 5. AI Bot Personalities

The AI players exhibit distinct profiles, detailed in [bot_personalities.md](file:///d:/01_Working/07_Project/TUI/md/bot_personalities.md):
1. **Big Bobby**: Aggressive front-runner. Plays top cards early, aims for the "Perfect" tactic, and saves a General-Pair endgame combination.
2. **Shadow**: Defensive late-game hoarder. Conserves high-value cards, folds weak cards strategicially, and saves a General-Pair combination.
3. **The Owl**: Deceptive and opportunistic. Prefers Soldier Sets and low-value Pairs to bait opponents.
4. **The Professor**: Balanced mathematical gatekeeper. Avoids overcommitting, protects against runaway leads, and saves a General-Pair combination.
5. **Mrs. Jones**: Structured bottom-up player. Plays lowest cards first while holding $>4$ cards, and shifts to highest first when holding $\le 4$ cards.
6. **Joker**: Wildcard. Plays completely randomly.
7. **Meta Mezz**: Adaptive mimic. Evaluates its dealt hand at the start of each loop to switch between **Big Bobby**, **Shadow**, **The Owl**, and **The Professor** profiles.

> [!NOTE]
> **King-Pair Endgame Strategy**: Big Bobby, Shadow, and The Professor protect a General (King) and a Pair in their hands. They save them to play when exactly 3 cards remain—leading the King first to win the lead, then the Pair to empty their hand.

---

## 6. Project & Directory Structure

* **[scene/](file:///d:/01_Working/07_Project/TUI/scene/)**: Contains the Godot 2D scene structures:
  * [test_gameplay.tscn](file:///d:/01_Working/07_Project/TUI/scene/test_gameplay.tscn) — The primary game table scene.
  * [lobby.tscn](file:///d:/01_Working/07_Project/TUI/scene/lobby.tscn) — Multi-player lobby GUI.
  * [main_menu.tscn](file:///d:/01_Working/07_Project/TUI/scene/main_menu.tscn) — Primary game main menu.
* **[script/](file:///d:/01_Working/07_Project/TUI/script/)**: GDScript implementation files:
  * [test_gameplay.gd](file:///d:/01_Working/07_Project/TUI/script/test_gameplay.gd) — Core gameplay manager handling turn flow, card layouts, scores, and visual reveals.
  * [bot_ai.gd](file:///d:/01_Working/07_Project/TUI/script/bot_ai.gd) — Core bot logic and decision-making for all AI personalities.
  * [lobby.gd](file:///d:/01_Working/07_Project/TUI/script/lobby.gd) & [main_menu.gd](file:///d:/01_Working/07_Project/TUI/script/main_menu.gd) — Menu screen UI navigation handlers.
  * [test_gameplay_scene.gd](file:///d:/01_Working/07_Project/TUI/script/test_gameplay_scene.gd) — Automatic scenario unit tests runner.
* **[md/](file:///d:/01_Working/07_Project/TUI/md/)**: Game rule documents:
  * [gameplay.md](file:///d:/01_Working/07_Project/TUI/md/gameplay.md) — Comprehensive rules and card hierarchies.
  * [bot_personalities.md](file:///d:/01_Working/07_Project/TUI/md/bot_personalities.md) — Custom bot playstyle architectures.

---

## 7. Running Headless Tests

You can execute the automated gameplay tests using Godot in headless mode. Run the following command from PowerShell in the project workspace:

```powershell
& "Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe" --headless --script res://script/test_gameplay_scene.gd
```
