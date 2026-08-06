# Word Ascent

Developer content editing is available through the [Puzzle Workshop](PUZZLE_WORKSHOP.md).

Word Ascent is a complete Godot word-connection game. Select words that belong together, check your guess, and climb a word mountain formed from groups of 2, 3, 4, and 5 words. The fifteenth word is the one-word Summit Word. The responsive game board uses five centered mountain levels.

## Run

1. Open `project.godot` in Godot 4.4 or newer.
2. Press **F6** or **F5** to play.

No plugins, imported art, or external audio assets are required.

## Controls

- Click/tap word buttons to select or deselect them.
- Press **Check** or **Space / Enter** to submit the selection.
- Standard UI focus navigation also supports keyboard-only play.

## Project structure

```
data/daily_puzzles.json           Ten date-selected Daily Challenge puzzles.
data/unlimited_puzzles.json       Ten separate non-repeating Unlimited puzzles.
scenes/main.tscn                  Application entry point.
scenes/game_board.tscn            Play screen scene.
scripts/data/puzzle_loader.gd     Per-mode JSON loading, validation, and selection.
scripts/game/game_state.gd        Rules, selection, attempts, solved groups, and signals.
scripts/systems/save_manager.gd   Session-only settings, active-game state, and statistics (reset at launch).
scripts/systems/sound_manager.gd  Lightweight generated UI sound effects.
scripts/ui/main.gd                Daily Challenge home screen, settings, statistics, and screen routing.
scripts/ui/game_board.gd          Responsive gameplay presentation and animations.
```

## Puzzle pools

The home screen has two independent pools:

- **Daily Challenge** selects one of the ten daily puzzles from the current date.
- **Unlimited** randomly serves an unplayed puzzle from its own ten-puzzle pool.

Finishing a puzzle marks it played for that mode, including a puzzle the game auto-solves after the final mistake. After all ten in a mode have been completed, the game displays a congratulations message and that pool is unavailable until the app is restarted.

## Puzzle JSON format

Each puzzle requires an `id`, `title`, four groups with sizes exactly `2`, `3`, `4`, and `5`, plus one unique `top_word`. The loader rejects malformed, duplicate, incomplete, or incorrectly sized puzzles before they can be played.

## Session behavior

The game starts from a clean default state whenever it is launched. Settings, statistics, hint usage, and the active puzzle stay available only for the current running session and are not written to disk.

Each daily challenge includes two free category hints. A third, rewarded-ad hint requires an advertising provider SDK and verified reward callback before release.

Unlimited puzzles include exactly two hints per puzzle; no rewarded third hint is offered in that mode.

## Extending the game

Add objects to either `data/daily_puzzles.json` or `data/unlimited_puzzles.json` using the supplied format. No code changes are necessary; valid entries are automatically included in that mode's pool.
