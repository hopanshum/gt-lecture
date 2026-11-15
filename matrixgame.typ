// matrixgame — two-player normal-form game table (replacement for xgames' matrixgame)
//
// #matrixgame(
//   players: ([Player 1], [Player 2]),
//   rows: ([A], [B]),                // player 1 (row) strategies
//   cols: ([a], [b]),                // player 2 (column) strategies
//   payoffs: (
//     ((1, 3), (3, 1)),              // one tuple (u1, u2) per cell, row by row
//     ((1, 2), (1, 2)),
//   ),
//   br: true,                        // underline best-response payoffs (numeric payoffs only)
//   highlight: ((0, 1),),            // shade cells (row, col), 0-indexed, e.g. Nash equilibria
// )

// Dark teal / blue, matching \setplayercolors{named}{teal;blue}
#let player-colors = (rgb("#007a7a"), rgb("#1f3fbf"))

// A payoff is a number, content, or (disp: content, value: number-or-none) from `game`.
// Numbers go through math mode so negatives get a proper minus sign.
#let _fmt(x) = if type(x) == dictionary { x.disp } else if type(x) in (int, float) {
  math.equation(str(x).replace("-", "−"))
} else { x }

#let _num(x) = if type(x) == dictionary { x.value } else if type(x) in (int, float) { x } else { none }
#let _is-num(x) = _num(x) != none

#let matrixgame(
  players: ([Player 1], [Player 2]),
  rows: (),
  cols: (),
  payoffs: (),
  w: auto, // cell width; auto = fit the widest payoff
  h: 1.7em, // cell height
  colors: player-colors,
  br: false,
  highlight: (),
  highlight-fill: luma(225),
  stroke: 0.6pt,
  strike-rows: (), // row indices to cross out (0-indexed)
  strike-cols: (), // column indices to cross out
  strike-stroke: 2pt + rgb("#c0392b"),
  eliminate: (), // ordered steps: (("col", (1,)), ("row", (1, 2))) — later lines don't cross earlier ones
  upto: none, // show only the first `upto` elimination steps (none = all)
) = {
  let (c1, c2) = colors
  let m = rows.len()
  let n = cols.len()

  // Step at which each row / column is struck (none = never).
  // strike-rows / strike-cols are step 0 (all cross each other); `eliminate` entries are steps 1, 2, ...
  let rstep = range(m).map(i => if i in strike-rows { 0 } else { none })
  let cstep = range(n).map(j => if j in strike-cols { 0 } else { none })
  for (k, (axis, idxs)) in eliminate.enumerate() {
    if upto != none and k >= upto { break }
    for x in idxs {
      if axis == "row" { rstep.at(x) = k + 1 } else { cstep.at(x) = k + 1 }
    }
  }
  // A line is drawn through a cell unless the crossing strategy was eliminated strictly earlier
  let h-on(i, j) = rstep.at(i) != none and (cstep.at(j) == none or cstep.at(j) >= rstep.at(i))
  let v-on(i, j) = cstep.at(j) != none and (rstep.at(i) == none or rstep.at(i) >= cstep.at(j))
  assert(payoffs.len() == m, message: "matrixgame: need one payoff row per row strategy")
  for r in payoffs {
    assert(r.len() == n, message: "matrixgame: each payoff row needs one cell per column strategy")
  }

  // Best responses: player 1 maximises within each column, player 2 within each row
  let br1(i, j) = {
    if not br { return false }
    let col = range(m).map(k => payoffs.at(k).at(j).at(0))
    if not col.all(_is-num) { return false }
    _num(payoffs.at(i).at(j).at(0)) == calc.max(..col.map(_num))
  }
  let br2(i, j) = {
    if not br { return false }
    let row = range(n).map(k => payoffs.at(i).at(k).at(1))
    if not row.all(_is-num) { return false }
    _num(payoffs.at(i).at(j).at(1)) == calc.max(..row.map(_num))
  }
  // Underline drawn as a box border: Typst's `underline` skips some math glyphs (e.g. a lone 0)
  let mark(on, color, body) = if on {
    // bottom-edge "bounds" puts the line below descenders and fraction denominators
    box(text(bottom-edge: "bounds", body), stroke: (bottom: 0.06em + color), outset: (bottom: 0.12em))
  } else { body }

  let payoff-body(i, j) = {
    let (a, b) = payoffs.at(i).at(j)
    mark(br1(i, j), c1, text(fill: c1, _fmt(a)))
    [, ]
    mark(br2(i, j), c2, text(fill: c2, _fmt(b)))
  }

  let inset-x = 0.35em
  let inset-y = 0.3em

  context {
    // Uniform cell width: widest payoff or column label, plus padding
    let cell-w = if w == auto {
      let widths = range(m).map(i => range(n).map(j => measure(payoff-body(i, j)).width)).flatten()
      widths += cols.map(s => measure(s).width)
      calc.max(..widths) + 1em
    } else { w }

    // Player 1's name is rotated; fix its width so it never wraps
    let p1 = text(fill: c1, players.at(0))
    let p1-name = rotate(-90deg, reflow: true, box(width: measure(p1).width, p1))

    // Strike lines span the full cell (undoing the cell inset) so they join up across cells.
    // Vertical lengths are absolute: relative heights inside table cells are unreliable.
    let h-line = place(left + horizon, dx: -inset-x, line(length: 100% + 2 * inset-x, stroke: strike-stroke))
    let v-line = place(top + center, dy: -inset-y, line(start: (0pt, 0pt), end: (0pt, h), stroke: strike-stroke))
    // label versions start at the label itself, not at the cell edge
    let h-line-label = place(left + horizon, line(length: 100% + inset-x, stroke: strike-stroke))
    let v-line-label(s) = place(top + center,
      line(start: (0pt, 0pt), end: (0pt, measure(s).height + inset-y), stroke: strike-stroke))

    let cells = ()
    // Row 0: player 2's name over the payoff columns
    cells.push(table.cell(colspan: 2, []))
    cells.push(table.cell(colspan: n, align(center, text(fill: c2, players.at(1)))))
    // Row 1: column strategy labels
    cells.push(table.cell(colspan: 2, []))
    for (j, s) in cols.enumerate() {
      cells.push(align(center, text(fill: c2, s)) + if cstep.at(j) != none { v-line-label(text(fill: c2, s)) })
    }
    // Payoff rows
    for i in range(m) {
      if i == 0 {
        cells.push(table.cell(rowspan: m, align(horizon, p1-name)))
      }
      cells.push(align(right + horizon, text(fill: c1, rows.at(i))) + if rstep.at(i) != none { h-line-label })
      for j in range(n) {
        let shaded = highlight.any(p => p.at(0) == i and p.at(1) == j)
        cells.push(table.cell(
          fill: if shaded { highlight-fill },
          align(center + horizon, payoff-body(i, j))
            + if h-on(i, j) { h-line }
            + if v-on(i, j) { v-line },
        ))
      }
    }

    table(
      columns: (auto, auto) + (cell-w,) * n,
      rows: (auto, auto) + (h,) * m,
      inset: (x: inset-x, y: inset-y),
      // grid lines only around the payoff cells
      stroke: (x, y) => if x >= 2 and y >= 2 { stroke } else { none },
      ..cells,
    )
  }
}

// ---------------------------------------------------------------------------
// game — short syntax, xgames style
//
// #game("A, B", "a, b", "1,3 & 3,1 ; 1,2 & 1,2")
// #game("C, D", "C, D", "-1,-1 & -9,0 ; 0,-9 & -6,-6", br: true, highlight: "D,D")
//
// - strategies: comma-separated; single letters and s_1, s'_i are math, plain words (II, Hawk)
//   are upright text, "$theta$" forces math
// - payoffs: rows separated by `;`, cells by `&`, the two payoffs by `,`
//   each payoff is typeset as math (-1, 1/2, v-c, theta all work);
//   plain numbers and fractions count as numeric for best-response underlining
// - highlight: "row,col" by strategy name, several separated by `;`
// - strike-rows: "D" / strike-cols: "b, c": cross out eliminated strategies (all at once)
// - eliminate: "col C; row M; row D": iterated elimination in order; later lines stop at
//   earlier ones. `upto: k` shows only the first k steps (see game-steps in lib.typ)
// - centred by default; pass `align: left` to turn that off
// ---------------------------------------------------------------------------

#let _split(s, sep) = s.split(sep).map(str.trim).filter(x => x != "")

// Strategy labels: plain multi-letter words (II, Hawk, Left) are upright text, since Typst math
// would read them as variable names; "$...$" forces math; everything else (A, s_1, s'_i) is math.
// If any label in a list is a word, single letters in that list go upright too (I, II, III, IV).
#let _is-word(x) = type(x) == str and x.trim().match(regex("^[A-Za-z]{2,}$")) != none
#let _label(x, words: false) = if type(x) != str { x } else {
  let x = x.trim()
  if x.starts-with("$") and x.ends-with("$") and x.len() > 1 {
    math.equation(eval(x.slice(1, -1), mode: "math"))
  } else if x.match(regex("^[A-Za-z]{2,}$")) != none or (words and x.match(regex("^[A-Za-z]$")) != none) {
    text(x)
  } else {
    math.equation(eval(x, mode: "math"))
  }
}

#let _payoff(s) = {
  let s = s.trim()
  let value = if s.match(regex("^-?\\d+(\\.\\d+)?(/\\d+(\\.\\d+)?)?$")) != none {
    float(eval(s))
  } else { none }
  (disp: math.equation(eval(s, mode: "math")), value: value)
}

#let _strategies(x) = if type(x) == str { _split(x, ",") } else { x }

#let game(
  rows,
  cols,
  payoffs,
  players: ("Player 1", "Player 2"),
  highlight: none,
  strike-rows: none,
  strike-cols: none,
  eliminate: none,
  align: center,
  ..options,
) = {
  let row-names = _strategies(rows)
  let col-names = _strategies(cols)

  let table-rows = _split(payoffs, ";").map(r => _split(r, "&").map(cell => {
    let parts = cell.split(",")
    assert(parts.len() == 2, message: "game: each cell needs two payoffs separated by a comma, got: " + cell)
    (_payoff(parts.at(0)), _payoff(parts.at(1)))
  }))

  // highlight by strategy names: "D,D" or "A,b; C,c"
  let marks = if highlight == none { () } else if type(highlight) == str {
    _split(highlight, ";").map(p => {
      let (r, c) = p.split(",").map(str.trim)
      let i = row-names.position(x => x == r)
      let j = col-names.position(x => x == c)
      assert(i != none and j != none, message: "game: unknown strategy in highlight: " + p)
      (i, j)
    })
  } else { highlight }

  // strike by strategy names: strike-rows: "D", strike-cols: "b, c"
  let find(names, list, what) = if list == none { () } else {
    _split(list, ",").map(x => {
      let k = names.position(y => y == x)
      assert(k != none, message: "game: unknown " + what + " strategy to strike: " + x)
      k
    })
  }
  let sr = find(row-names, strike-rows, "row")
  let sc = find(col-names, strike-cols, "column")

  // ordered elimination: "col C; row M; row D" (one step per `;`, several strategies per step allowed)
  let elim = if eliminate == none { () } else {
    _split(eliminate, ";").map(step => {
      let parts = step.trim().split(" ")
      let axis = lower(parts.at(0))
      let names = parts.slice(1).join(" ")
      if axis in ("row", "r") { ("row", find(row-names, names, "row")) }
      else if axis in ("col", "c", "column") { ("col", find(col-names, names, "column")) }
      else { panic("game: each eliminate step must start with `row` or `col`, got: " + step) }
    })
  }

  let players = if type(players) == str { _split(players, ",") } else { players }

  std.align(align, matrixgame(
    players: players.map(p => if type(p) == str { [#p] } else { p }),
    rows: row-names.map(x => _label(x, words: row-names.any(_is-word))),
    cols: col-names.map(x => _label(x, words: col-names.any(_is-word))),
    payoffs: table-rows,
    highlight: marks,
    strike-rows: sr,
    strike-cols: sc,
    eliminate: elim,
    ..options,
  ))
}
