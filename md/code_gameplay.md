# TUI - Code Gameplay Design & Workflow

> Technical reference for the gameplay implementation in Godot 4.x.
> For game rules and card mechanics, see [gameplay.md](file:///d:/01_Working/07_Project/TUI/md/gameplay.md).
> For bot AI personalities, see [bot_personalities.md](file:///d:/01_Working/07_Project/TUI/md/bot_personalities.md).

---

## 1. Project File Structure

| File | Purpose |
|------|---------|
| `scene/test_gameplay.tscn` | Main gameplay scene layout (UI nodes, slots, areas) |
| `script/test_gameplay.gd` | Core gameplay controller — state machine, animations, turn flow |
| `script/card_rules.gd` | Pure logic: deck generation, play type detection, card comparison |
| `script/bot_ai.gd` | Bot AI: personality-based card selection strategies |
| `script/test_card.gd` | Individual card node behavior (hover, select, visuals) |
| `script/test_gameplay_scene.gd` | Headless unit test runner |

---

## 2. Scene Node Hierarchy

```
Control (test_gameplay.gd)
├── BackHand              # Player's backhand sprite (TextureRect)
├── Left_Player           # Left bot hand sprite (TextureRect)
├── Right_Player          # Right bot hand sprite (TextureRect)
├── Top_Player            # Top bot hand sprite (TextureRect)
│
├── HandArea              # Player's card hand container
│   ├── PlayerHand        # Visual hand background
│   └── CardSlot0..7      # 8 card slots for player's hand cards
│
├── TableArea             # Center table for player's played cards
│   └── TableSlot0..7     # 8 table slots for player cards on table
├── Left_TableArea        # Left bot's played card area
│   └── TableSlot0..7
├── Right_TableArea       # Right bot's played card area
│   └── TableSlot0..7
├── Top_TableArea         # Top bot's played card area
│   └── TableSlot0..7
│
├── PlayerWinArea         # Player's won card stacks (CardIcon_1..8)
├── LeftWinArea           # Left bot's won card stacks
├── RightWinArea          # Right bot's won card stacks
├── TopWinArea            # Top bot's won card stacks
│
├── PlayerName            # Player name label
├── LeftName              # Left bot name label
├── TopName               # Top bot name label
├── RightName             # Right bot name label
│
├── ConfirmButton         # Player's card confirmation button
├── Time                  # Countdown timer label
├── Annoucement           # Full-screen announcement overlay
│   └── AnnoucementText   # Announcement text label
│
└── ScorePanel            # Hold-Tab scoreboard overlay
    └── ScoreContainer
        ├── TitleLabel
        └── ScoreGrid     # 6-column GridContainer
```

---

## 3. Player Index Mapping

All gameplay arrays and state tracking use a consistent **4-player index**:

| Index | Position | Hand Data | Table Data | Won Data | Hand Sprite | Name Label |
|-------|----------|-----------|------------|----------|-------------|------------|
| 0 | Bottom (Human Player) | `player_hand` | `player_table_cards` | `player_won_cards` | `back_hand` | `player_name_label` |
| 1 | Left Bot | `left_hand` | `left_table_cards` | `left_won_cards` | `left_player` | `left_name_label` |
| 2 | Top Bot | `top_hand` | `top_table_cards` | `top_won_cards` | `top_player` | `top_name_label` |
| 3 | Right Bot | `right_hand` | `right_table_cards` | `right_won_cards` | `right_player` | `right_name_label` |

**Clockwise turn order** (for tie-breaking): `0 → 1 → 2 → 3 → 0`

---

## 4. Card Data Format

Each card in the game is represented as a **Dictionary**:

```gdscript
{
    "id": "R_1King",                                        # Unique identifier (Color_RankName_Instance)
    "rank": 1,                                              # 1=General, 2=Advisor, ..., 7=Soldier
    "color": "R",                                           # "R" = Red, "B" = Black
    "texture_path": "res://asset/card/default/TuiSkin_R_1King.png"
}
```

Cards with multiple copies include an instance suffix in the ID: `R_2Plane_1`, `R_2Plane_2`.

---

## 5. State Variables

### Turn State
| Variable | Type | Description |
|----------|------|-------------|
| `current_leader` | `int` | Index (0-3) of the current turn leader |
| `active_play_type` | `String` | `""` (not set), `"Single"`, `"Pair"`, `"Noble Set"`, `"Soldier Set"` |
| `active_card_count` | `int` | Number of cards required for this turn (0 when leader hasn't played) |
| `has_played` | `Array[bool]` | `[false, false, false, false]` — tracks which players have completed their play animations |

### Round/Loop State
| Variable | Type | Description |
|----------|------|-------------|
| `loop_count` | `int` | Current loop number within the round (1-indexed, incremented in `_initialize_loop_personalities`) |
| `loop_scores` | `Array[Dict]` | Stores `{player, left, top, right}` score dicts for each completed loop |
| `bot_personalities` | `Dict` | Assigned unique personality name per bot index (persists across match loops) |
| `bots_thinking` | `Array[bool]` | Tracks whether a bot's auto-play timer is already scheduled |

### Timer State
| Variable | Type | Description |
|----------|------|-------------|
| `state_time_left` | `float` | Seconds remaining on the current countdown |
| `is_timer_running` | `bool` | Whether the countdown is actively ticking |
| `current_timer_state` | `String` | `""`, `"leader"`, or `"responder"` |
| `leader_select_time` | `float` | Configurable timeout for leader selection (default: 20s) |
| `responder_select_time` | `float` | Configurable timeout for responder selection (default: 20s) |

### Input Configuration Variables (set externally or preset)
| Variable | Type | Description |
|----------|------|-------------|
| `game_mode` | `String` | Selected game mode (default: `"Mass Mode"`) |
| `select_time_preset` | `String` | Select time preset: `"Fast"` (10s), `"Normal"` (20s), or `"Long"` (30s) |
| `round_preset` | `String` | Rounds preset: `"Short"` (1 round / 4 loops), `"Normal"` (2 rounds / 8 loops), or `"Long"` (4 rounds / 16 loops) |
| `rounds_completed` | `int` | Number of completed rounds in the current match |

---

## 6. Z-Index Layering

| Z-Index | Elements | Purpose |
|---------|----------|---------|
| 20 | Name labels, ConfirmButton, Announcement overlay | Always on top UI layer |
| 10 | Winner cards (temporary during `_show_winner` scaling) | Scale showcase above hands |
| 5 | All hand sprites (`back_hand`, `left_player`, `right_player`, `top_player`) | Hands above table/flying cards |
| 0 | Table cards, reparented flying cards | Base layer |

---

## 7. Game Flow State Machine

### 7.1 Initialization (`_ready`)

```
_ready()
├── Configure z-indices and mouse filters
├── Setup announcement overlay and font
├── Connect ConfirmButton signals
├── Start breathing animations
├── Start background music
├── Initialize scoreboard fonts
├── Hide time label
├── Position bot hands off-screen (invisible)
├── Initialize presets (select_time_preset, round_preset)
├── Await first process_frame drawing pass (fade-in tween compatibility)
├── Show game configuration announcement (Mode + Rounds, 3.0s)
└── Call _get_cards(false)  ← Auto-start first deal after announcement
```

### 7.2 Deal Phase (`_get_cards`)

```
_get_cards(keep_leader)
├── If loop_count >= 4: reset scoreboard data
├── [Animation] Slide all hands + HandArea off-screen (0.4s parallel)
├── Hide all hands (visible = false) while dealing and showing announcement
├── Clear all slot visuals and internal card arrays
├── Reset bot textures and positions off-screen (remain invisible)
├── Clear won areas
├── If not keep_leader: randomize current_leader
├── Generate deck (32 cards), shuffle, deal 8 to each
├── Call _initialize_loop_personalities()
│   ├── If first loop: randomly assign unique bot base personalities
│   ├── Increment loop_count
│   ├── Resolve active personalities (assign base directly)
│   └── Call _update_leader_name_labels()
├── Create visual card nodes for player hand
├── Show "Start Round / Leader: [Name]" announcement (2.5s) and wait for completion
├── Make all hands visible (visible = true)
├── [Animation] Slide all hands + HandArea back on-screen (0.8s parallel)
├── Start all breathing animations
└── Call _update_button_states_for_turn()
```

### 7.3 Turn Phase — Leader Plays

**If Leader is Human Player (index 0):**
```
User selects cards → clicks ConfirmButton → _on_confirm_pressed()
├── Validate selection: detect play type (must be valid)
├── Set active_play_type and active_card_count
├── Show "Play Type: [type]" announcement
├── Move card data: player_hand → player_table_cards
├── [Animation] HandArea slides down (0.6s)
├── Reparent cards to TableSlots as Backcards
├── [Animation] BackHand slides up to table center (0.8s)
├── [Animation] Cards scale in from 0 (0.35s pop)
├── [Animation] BackHand slides back down (0.6s)
├── Mark has_played[0] = true
├── Call _update_button_states_for_turn()
└── If everyone played → _start_reveal_and_scoring_sequence()
```

**If Leader is Bot (index 1/2/3):**
```
_update_button_states_for_turn()
├── Detects no active_play_type and leader is a bot
└── Calls _trigger_auto_bot_play(leader_idx)
    ├── Random delay (2.0 – 7.0 seconds)
    └── Calls _play_ready_sequence(...)
```

### 7.4 Turn Phase — Responders Play

After the leader plays, `_update_button_states_for_turn()` enables:
- **Human player**: ConfirmButton enabled, responder timer starts
- **Bots**: Each unplayed bot gets `_trigger_auto_bot_play()` scheduled

**Bot Play Sequence (`_play_ready_sequence`):**
```
_play_ready_sequence(player, table_area, slots_list, thinking_tex, direction)
├── BotAI.select_play() → card selection based on personality
├── Set active_play_type if bot is leader
├── Move card data: hand → table_cards
├── [Animation] Bot hand slides off-screen (0.6s)
├── Change texture to backhand
├── [Animation] Bot hand slides to table area center (0.8s)
├── Spawn Backcard nodes in slots
├── [Animation] Cards scale in from 0 (0.35s pop)
├── Play click SFX
├── [Animation] Bot hand slides back off-screen (0.6s)
├── Mark has_played[bot_idx] = true
├── Call _update_button_states_for_turn()
└── If everyone played → _start_reveal_and_scoring_sequence()
```

> [!NOTE]
> Players can confirm their cards **concurrently** while bot animations are running. The reveal only triggers when `_has_everyone_played()` returns `true` (checks `has_played[]` flags, which are only set at the *end* of each animation sequence).

### 7.5 Reveal & Scoring Sequence (`_start_reveal_and_scoring_sequence`)

```
_start_reveal_and_scoring_sequence()
├── Disable ConfirmButton
├── Show "Revealing The Card!" announcement (2.0s)
├── Wait 2.0 seconds
│
├── [Animation] All 4 hands slide from off-screen to table positions (0.8s parallel)
├── Reveal real card textures (folded cards stay as Backcard)
├── Play click SFX
├── [Animation] All 4 hands slide back off-screen (0.6s parallel)
├── Hide all hand sprites
├── Wait 2.0 seconds (view revealed cards)
│
├── _determine_turn_winner() → winner_idx
│   ├── Check valid plays for each player
│   ├── Compare valid plays pairwise
│   └── Tie-break by clockwise distance from leader
│
├── _show_winner(winner_idx)
│   ├── [Animation] Winner's cards scale to 1.4x (0.3s)
│   ├── Hold at 1.4x for 2.0 seconds
│   ├── [Animation] Shrink back to 1.0x (0.3s)
│   └── Show "Winner: [Name]" announcement (2.0s)
│
├── _collect_cards_to_winner(winner_idx)
│   ├── [Animation] Winner's hand slides from off-screen to table (0.6s)
│   ├── Play click SFX
│   ├── Transfer card data to winner's won_cards array
│   ├── Reparent all table card nodes to root
│   ├── [Animation] Cards fly to WinArea + hand slides to WinArea (0.8s parallel)
│   │   Cards shrink to 0.5x and fade to 0.0 alpha
│   ├── Free card nodes
│   ├── Update WinArea icon visibility
│   └── [Animation] Winner's hand returns off-screen (0.6s)
│
├── Set current_leader = winner_idx
├── Update leader name labels (Gold + bold for leader)
├── Reset turn state (active_play_type, active_card_count, has_played)
│
├── If hands are empty (loop ends):
│   ├── Calculate scores: won_cards.size() / 4
│   ├── Store in loop_scores[]
│   └── Call _finish_loop_and_transition()
│
└── Else (cards remain):
    ├── Call _update_button_states_for_turn()
    ├── [Animation] Restore hands to thinking positions (0.6s parallel)
    └── Restart all breathing animations
```

### 7.6 Loop & Round Transitions (`_finish_loop_and_transition`)

```
_finish_loop_and_transition()
├── Show ScorePanel for 5.0 seconds
├── Hide ScorePanel
│
├── If loop_count < 4:
│   └── Call _get_cards(true)  ← keep_leader = true (last winner leads)
│
└── If loop_count == 4 (round complete):
    ├── Increment rounds_completed
    ├── Calculate cumulative totals per player
    ├── Determine round winner(s) or tie
    ├── Show "Round Winner: [Name]" announcement (10.0 seconds)
    ├── Await announcement fadeout
    ├── If rounds_completed >= max_rounds:
    │   ├── Calculate all-time totals across all played rounds
    │   ├── If all player scores are equal:
    │   │   └── Show "Match Completed!\nYOU PLAYED FOR NOTHING!"
    │   │   Else:
    │   │   ├── Identify highest scoring player(s)
    │   │   └── Show "Match Completed!\nWinner(s): [Names]"
    │   ├── Reset rounds_completed = 0
    │   └── Show "Exit to Main Menu" button (stays visible until clicked)
    └── Else:
        ├── Call _reset() ← clears scoreboard/states
        └── Call _get_cards(false) ← deal next round
```

---

## 8. Timer System

The countdown timer uses `_process(delta)` for per-frame updates:

```
_process(delta)
├── Skip if is_test_mode or timer not running
├── Pause countdown while announcement is visible
├── Decrement state_time_left by delta
├── If time <= 0: call _on_state_timer_timeout()
└── Update time label text and color (yellow < 10s)
```

**On timeout:**
```
_on_state_timer_timeout()
├── Stop timer
├── Show "Time Out!" announcement (2.0s)
├── If leader state:
│   ├── Player leader → auto-select first card and confirm
│   └── Bot leader → trigger bot play sequence
└── If responder state:
    └── Auto-play all remaining unplayed responders
```

---

## 9. Card Rules Engine (`card_rules.gd`)

Static helper class `CardRules` with pure functions:

| Function | Description |
|----------|-------------|
| `generate_deck() → Array` | Creates the 32-card deck with proper quantities and texture paths |
| `detect_play_type(cards) → String` | Detects `"Single"`, `"Pair"`, `"Noble Set"`, `"Soldier Set"`, or `""` |
| `is_valid_play(cards, play_type, count) → bool` | Validates if cards match the required play type and count |
| `compare_valid_plays(a, b, type) → int` | Returns `1` (a wins), `-1` (b wins), or `0` (tie) |
| `find_combinations(hand, type, count) → Array` | Finds all valid card combinations from a hand for a given play type |

---

## 10. Bot AI System (`bot_ai.gd`)

Entry point: `BotAI.select_play(gameplay, hand, play_type, count, bot_idx) → Array`

The bot AI selects cards based on the active personality resolved for the current loop. Personalities are selected uniquely at the start of a round and persist through the match.

---

## 11. Animation Timing Summary

| Animation | Duration | Easing |
|-----------|----------|--------|
| Hand/bots slide off-screen (deal phase) | 0.4s | Cubic In-Out |
| Hand/bots slide on-screen (deal phase) | 0.8s | Cubic Out |
| Player HandArea slides down (confirm) | 0.6s | Cubic In-Out |
| BackHand slides up to table | 0.8s | Cubic Out |
| Card pop-in (scale 0→1) | 0.35s | Back Out |
| BackHand slides back down | 0.6s | Cubic In-Out |
| Bot hand slides off-screen | 0.6s | Cubic In-Out |
| Bot hand slides to table center | 0.8s | Cubic Out |
| All hands reveal slide-in | 0.8s | Cubic Out |
| All hands reveal slide-out | 0.6s | Cubic In-Out |
| Winner card scale up (1.0→1.4x) | 0.3s | Cubic Out |
| Winner card hold at 1.4x | 2.0s | — |
| Winner card scale down (1.4→1.0x) | 0.3s | Cubic Out |
| Cards fly to WinArea + hand | 0.8s | Cubic In-Out |
| Winner hand return off-screen | 0.6s | Cubic In-Out |
| Breathing idle cycle | 3.0s loop | Sine In-Out (6px) |
| Announcement fade in | 0.3s | Cubic Out |
| Announcement fade out | 0.4s | Cubic In |

---

## 12. Scoreboard System

**Trigger**: Press `Tab` key to toggle visibility. Also auto-displayed for 5 seconds at the end of each loop.

**Round Navigation Panel**: An `RoundNav` HBoxContainer added to the ScorePanel allows switching between round scorecards using `PrevRoundBtn` and `NextRoundBtn` controls. The active round title is displayed in `RoundNumLabel`.

**Dimensions**: `ScorePanel` is sized at `840x480` centered to accommodate navigation elements and score columns without overlaps.

**Grid layout**: 6-column `GridContainer` — `[PLAYER, LOOP 1, LOOP 2, LOOP 3, LOOP 4, TOTAL]`

**Rows**:
- 4 player rows (Player, Left Bot, Top Bot, Right Bot) showing the selected round's loop scores (Loops 1–4). The row label header for the last turn winner (leader of the next loop/turn) is uniquely styled in bold (`**Name**`) and highlighted in Gold color.
- 1 **Check Sum** row (equals `8` per completed loop, or `-` for unplayed loops)

**TOTAL Columns**:
- Player and bot row `TOTAL` columns show the all-time cumulative score summed across **all rounds** played so far since the start of the match.
- Check Sum row `TOTAL` column shows the all-time check sum total.

**Score formula**: `Score = won_cards.size() / 4` (always an integer since 32 cards ÷ 4 players)

---

## 13. Headless Testing (`test_gameplay_scene.gd`)

Tests run without a display window using `--headless` flag:

```powershell
& "path/to/godot_console.exe" --headless --script res://script/test_gameplay_scene.gd
```

The `is_test_mode = true` flag:
- Skips all `await` timer delays and animation tweens
- Skips bot thinking delays
- Disables keyboard input handling
- Snaps hand positions instantly instead of tweening

**Test suites**:
1. `run_basic_checks` — Verifies node bindings exist
2. `run_deal_checks` — Verifies deck shuffle and deal produces 8 cards per player
3. `run_winner_logic_checks` — Verifies card comparison, tie-breaking, and folding logic across 9 scenarios
4. `run_timer_timeout_checks` — Verifies auto-play triggers for player timeout
