# gt-lecture

Slide setup (Touying stargazer, purple palette, 4:3) and game-theory helpers for Game Theory I.

## Install (Windows)

Copy this folder so the files sit at:

    %APPDATA%\typst\packages\local\gt-lecture\0.1.0\lib.typ

Then in any lecture file:

```typst
#import "@local/gt-lecture:0.1.0": *
#show: lecture.with(subtitle: [Dominance & Rationalizability], date: [20261027])
```

For a new version, copy to `...\gt-lecture\0.2.0\` and change the import; old lectures keep working on 0.1.0.

## Build

    typst compile s08.typ
    typst compile --input handout=true s08.typ s08-handout.pdf

## What's exported

- Everything from Touying and the stargazer theme (`title-slide`, `pause`, `only`, ...).
- `lecture.with(...)`: the template. Options: `title`, `subtitle`, `author`, `date`, `institution`,
  `aspect-ratio`, `size` (22pt), `bar-height` (2.6em), `colors` (dictionary, overrides the purple palette),
  `fonts`.
- `attendance-slide(url)`: QR slide, lecture version only.
- `handout`: true when compiled with `--input handout=true`.
- `E`, `BR`, `MBR`; `small[...]`, `footnotesize[...]`.
- `game(...)`: payoff matrix, short syntax (see below). `matrixgame(...)`: the same with explicit arrays.

## game (short syntax)

```typst
#game("A, B, C, D", "a, b, c, d", "
  1,3 & 3,1 & 0,2 & 1,1;
  1,2 & 1,2 & 2,3 & 1,1;
  3,2 & 2,1 & 1,3 & 0,3;
  2,0 & 3,0 & 1,1 & 2,2
")

#game("C, D", "C, D", "-1,-1 & -9,0 ; 0,-9 & -6,-6", br: true, highlight: "D,D")
```

- Arguments: row strategies, column strategies, payoffs.
- Strategies are comma-separated. Single letters and `s_1`, `s'_i` are math; plain words like
  `II` or `Hawk` are upright text; wrap in dollars (`$theta$`) to force math.
- Payoffs: rows split by `;`, cells by `&`, the two payoffs by `,`. Each payoff is math:
  `-1`, `1/2`, `v-c`, `theta` all work. Numbers and fractions count as numeric for `br`.
- `br: true` underlines best responses; rows/columns with symbolic payoffs are skipped.
- `highlight: "D,D"` shades cells by strategy name; several: `"A,a; B,b"`.
- `players: "Firm, Union"` renames the players.
- `strike-rows: "M, D"`, `strike-cols: "C"` cross out strategies all at once, labels included (red, 2pt).
- `eliminate: "col C; row M, D; col R"`: iterated elimination in order. Steps are separated by `;`,
  each starts with `row` or `col`. A later line stops at earlier lines instead of crossing them.
  `upto: k` shows only the first k steps.
- `game-steps(...)`: same arguments as `game`, reveals one elimination step per click:

  ```typst
  #game-steps("U, M, D", "L, C, R", "4,3 & 5,1 & 6,2; 2,1 & 8,4 & 3,6; 3,0 & 9,6 & 2,8",
    eliminate: "col C; row M, D; col R")
  ```
- Centred by default (`align: left` to turn off). Also takes `w`, `h`, `colors`, `stroke`.

## matrixgame (explicit arrays)

```typst
#matrixgame(
  players: ([Player 1], [Player 2]),   // default
  rows: ([A], [B]),
  cols: ([a], [b]),
  payoffs: (
    ((1, 3), (3, 1)),
    ((1, 2), (1, 2)),
  ),
  br: true,               // underline best responses (numeric payoffs only)
  highlight: ((0, 1),),   // shade cells (row, col), 0-indexed
)
```

Other options: `w` (cell width, default fits the widest payoff), `h` (cell height, 1.7em),
`colors` (two colours; default dark teal and blue), `highlight-fill`, `stroke`,
`strike-rows` / `strike-cols` (0-indexed), `strike-stroke`.
Payoffs can be numbers or content (e.g. `($a$, $b$)`); best-response underlining is skipped for
columns/rows that contain non-numeric payoffs.
