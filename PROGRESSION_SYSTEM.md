# Progression and puzzle difficulty

## Current behavior

- Every authored puzzle has a fixed `tier` (1-5) and `rating` (500-1600) in
  `data/puzzle_difficulty.json`.
- XP never has a maximum. Level thresholds use `100 * (level - 1)^1.6`.
- A first clear awards more XP than a replay. Losing still awards a small
  amount when the player solved part of the board.
- Infinity mode maintains a hidden player skill rating. Results account for
  completion, solved rows, mistakes, hints, puzzle rating, and repeat attempts.
- New players are offered easier Infinity puzzles first. Established players
  are offered unsolved puzzles near a target that should feel achievable.
- Daily Challenge selection remains date-based, but Daily results still award
  XP and use the same fixed difficulty metadata.

## Future population adjustment

Puzzle ratings are not changed from player data yet. A future backend can
calculate population-adjusted ratings and pass a `{puzzle_id: rating}` map to
`PuzzleLoader.set_difficulty_overrides()`. Clearing the overrides restores the
authored local metadata. This keeps remote balancing optional and allows the
game to work offline.

When that backend is added, aggregate only completed attempt events and keep
the authored rating as a prior. Useful event fields are puzzle ID, player skill
before the attempt, won, solved rows, mistakes, hints, and whether the attempt
was a replay. Require a meaningful sample size before allowing an override to
move far from the authored rating.
