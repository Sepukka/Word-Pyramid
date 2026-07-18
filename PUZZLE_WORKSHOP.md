# Puzzle Workshop

Puzzle Workshop is a developer-only content editor for the four Word Pyramid
puzzle pools. It is not linked from the game and is not intended for exported
Android builds.

## Open it

1. Open `scenes/tools/puzzle_workshop.tscn` in Godot.
2. Run the current scene with **F6**.
3. Pick a language and game mode from the left-hand panel.

The workshop uses three readable tabs (puzzle library, editor, and preview) so
it works at the project's 390 x 844 viewport size and inside Godot's embedded
Game view without scaling the interface down.

## Editing workflow

1. Select an existing puzzle, create a new one, or duplicate one.
2. Fill the top word and all fixed-size groups (2, 3, 4, and 5 words).
3. Set the initial difficulty tier and rating.
4. Check the phone preview and validation messages.
5. Save only when the validation panel is green.

For deliberate display breaks, add one mapping per line:

```text
AALLONMURTAJA=AALLON|MURTAJA
MACHINE LEARNING=MACHINE|LEARNING
```

The `|` character is stored as a line break. It does not change the actual word
used by game logic.

## Files and backups

Saving updates the selected puzzle pool and `data/puzzle_difficulty.json`.
Before writing, the workshop copies both original files into:

```text
user://puzzle_workshop_backups/<timestamp>/
```

In Godot, **Project > Open User Data Folder** opens the `user://` location.
Switching puzzles is blocked while the form has unsaved changes; use **Save** or
**Revert** first.
