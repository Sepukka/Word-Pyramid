# Word Pyramid UI Style Guide For Godot

This file is the Godot companion to the real design source:

```text
C:\Users\paavo\Downloads\Word Pyramid Game UI\guidelines\Guidelines.md
```

Always consult that file first before editing Word Pyramid UI. It is the single source of truth for colors, spacing, fonts, animations, component patterns, and result-screen behavior.

The React prototype remains useful for implementation examples:

```text
C:\Users\paavo\Downloads\Word Pyramid Game UI\src\App.tsx
```

## Non-Negotiables

- Style: Memphis-inspired puzzle game UI.
- Tone: focused, rewarding, clean.
- Phone-first target: 390x844.
- The pyramid is the hero. UI chrome should support it, not compete with it.
- Do not invent a new style when `Guidelines.md` already specifies one.
- Do not use thin text for important UI. Important UI uses Fredoka 600-700.
- Do not swap pyramid level colors.
- Do not use soft shadows for cards/buttons where the guide specifies hard Memphis offset shadows.

## Fonts

Use only:

```text
Fredoka: headings, tile labels, button text, streak numbers, stat values
DM Sans: body copy, metadata, supporting labels
```

Godot mapping:

```text
Fredoka 600 -> _font_fredoka_semibold
Fredoka 700 -> _font_fredoka_bold or stronger FontVariation
DM Sans 400-600 -> FONT_DM_SANS or semibold variation
```

Type scale from `Guidelines.md`:

```text
Hero: 44px Fredoka 600
H2/result headings: 24-28px Fredoka 600
H3/game header: 19-22px Fredoka 600
Tile words: 13-15px Fredoka 600, tracking about 0.03em
Streak number: 64px Fredoka 700
Body: 13-14px DM Sans 400
Meta labels: 11-12px DM Sans 600
```

Uppercase labels use `0.10-0.14em` spacing. Body copy uses default spacing.

## Colors

Use exact values from `Guidelines.md`.

```text
--bg           #FFFDF5
--bg-outer     #E8E0F0
--navy         #1A0A5E
--navy-light   #EEE9FA
--muted        #9B8CD4
--muted-light  #D6CFEF
--border       #D6CFEF
--error        #FF5533
--error-bg     #FFF0ED
--error-tint   #FFE8E3
--win          #FFD600
--streak       #FFD600
```

Level colors are fixed:

```text
Level 1 APEX, 1 tile: #B939FF, text #FFFFFF, tint #F5E0FF
Level 2 PAIR, 2 tiles: #FF5533, text #FFFFFF, tint #FFE8E3
Level 3 TRIO, 3 tiles: #00BFA5, text #FFFFFF, tint #CCFAF4
Level 4 BASE, 4 tiles: #FFD600, text #1A0A5E, tint #FFFBCC
```

Note: the current Godot game has a 5-row/15-word pyramid. Preserve the same color identity principles when mapping the extra row, and do not make adjacent lower rows visually indistinguishable.

Confetti colors for win result:

```text
#FFD600, #B939FF, #FF5533, #00BFA5, #1A0A5E, #FF88CC
```

## Spacing And Radius

Screen padding:

```text
Game horizontal: 16px
Home horizontal: 20px
Top: 16px
Bottom: 24-36px
```

Gap scale:

```text
xs: 4px
sm: 6-7px
md: 10-12px
lg: 16-20px
xl: 24-28px
2xl: 32-36px
```

Radius scale:

```text
Mini blocks/confetti rects: 3-4px
Tiles/back button/chips: 8-9px
Action buttons/category slots: 12-13px
Home primary buttons: 14px
Cards/result sheet: 20-22px
Home daily card: 24-28px
Date badge/language pills: 20px
Circle dots: 50%
```

## Shadows

Use Memphis hard offset shadows for major cards/buttons.

```text
Home challenge card: 7px 7px 0 #B939FF
Win result sheet: 8px 8px 0 #FFD600
Loss result sheet: 8px 8px 0 #FF5533
Play button rest: 3px 3px 0 rgba(0,0,0,0.18)
Play button hover: 5px 5px 0 rgba(0,0,0,0.24)
Submit button rest: 3px 3px 0 rgba(26,10,94,0.22)
Submit button hover: 6px 6px 0 rgba(26,10,94,0.28)
```

Soft shadows are only for floating elements like idle tiles, selected tiles, settings icon, and settings sheet. Do not use generic soft card shadows for primary surfaces.

## Godot Mapping

Translate Figma/React patterns to Godot like this:

```text
flex column -> VBoxContainer
flex row -> HBoxContainer
padding -> MarginContainer
background + radius + border -> PanelContainer with StyleBoxFlat
button -> Button with theme overrides
text -> Label or RichTextLabel
CSS keyframes -> Tween
overlay/sheet -> full-screen Control + ColorRect backdrop + PanelContainer sheet
```

Prefer responsive containers. Avoid absolute positioning unless building overlay decoration, confetti, or animation ghosts.

## Pyramid Tiles

Spec from `Guidelines.md`:

```text
Width: 72px baseline, same width in every row
Height: 48px baseline
Radius: 9px
Font: Fredoka 13px / 600 / tracking 0.03em
Border: 2px
Transition: about 0.14s
Row gap: 7px, clamp 6-10px
Tile gap: 7px
```

Tile states:

```text
Idle: white bg, navy text, #D6CFEF border, soft tile shadow
Hover: white bg, navy text, #A89DD4 border, lift -2px
Selected: navy bg, white text, navy border, lift -3px
Hinted: level tint bg, navy text, dashed/strong border, hint dot badge
Wrong: #FFF0ED bg, #FF5533 text/border
Solved: level solid bg, level text color, no shadow
```

Do not stretch tiles into a different shape. If text does not fit, reduce font size while preserving tile shape.

## Home Screen

Must follow the guideline/prototype:

- App title is Fredoka, large, thick, navy.
- Daily challenge card uses the Memphis card feel.
- Date badge is compact and yellow.
- Metadata should be theme + `15 words` + `4 categories`.
- Play button is bold and thick.
- Once the daily is completed, the play button becomes `View result`.
- Infinity uses the infinity symbol before the label.
- Gear icon must be centered in its button.

## Game Board

- Keep the pyramid centered in the playable area.
- Preserve tile shape and uniform tile width.
- Action buttons must be large enough for phone taps.
- Selected text must stay readable.
- The bottom area should not look empty, but the pyramid should not collide with buttons.

## Result / Aftermath Screen

Use the result overlay rules from `Guidelines.md`.

Overlay:

```text
Full-screen absolute Control
Backdrop: rgba navy, about 0.5 opacity
Sheet: #1A0A5E
Sheet radius: 28px 28px 0 0
Max height: about 88%
Handle: 40x4px, rgba(255,255,255,0.2), radius 2
```

Top accent:

```text
Win: gradient/sequence using #FFD600, #B939FF, #00BFA5, #FF5533
Loss: #FF5533
```

Win copy:

```text
0 mistakes: Flawless solve - no mistakes!
1 mistake: Solved with 1 mistake
2-3 mistakes: Solved with N mistakes
```

Loss copy:

```text
4 mistakes - better luck tomorrow
```

Streak:

- Win daily: flame pulses, streak number changes after about 700ms.
- Loss daily: flame/streak breaks or greys out.
- Streak increases only after a fully correct daily solve.

Stats row:

Use StatPill styling exactly:

```text
Container: equal width, rgba(255,255,255,0.07), radius 14, padding 12px 8px
Value: Fredoka 24px 700, accent color
Label: 11px, uppercase, white 45%, semibold, 0.08em feel
```

Stats:

```text
0
Mistakes

4 / 4
Groups

0
Hints used
```

Accent colors:

```text
Mistakes: #FFD600 when 0, #FF8066 when mistakes > 0
Groups: #00BFA5
Hints used: #B939FF
```

Do not show a separate `Result: 15/15` button in aftermath unless the user explicitly asks for it. The stats row is the result presentation.

## Interaction Timing

Follow timings from `Guidelines.md`:

```text
Wrong guess: shake pyramid, flash wrong tiles, revert after ~620ms
Loss overlay: about 820ms after final wrong submit
Win overlay: about 600ms after final solved group
Streak number changes/animates: about 700ms after overlay appears
```

## Implementation Checklist

Before editing UI:

1. Read `C:\Users\paavo\Downloads\Word Pyramid Game UI\guidelines\Guidelines.md`.
2. Check `C:\Users\paavo\Downloads\Word Pyramid Game UI\src\App.tsx` for the matching component.
3. Copy the relevant color, font, spacing, radius, and animation values.
4. Use Fredoka for important UI.
5. Keep level colors fixed.
6. Preserve phone-first layout.

After editing UI:

1. Check that text is not thin compared with the prototype.
2. Check that mobile text does not clip or overlap.
3. Check that tile shapes remain stable.
4. Check that aftermath stats match StatPill style.
5. Check that daily streak only increases on a perfect daily solve.
