// gt-lecture — slide setup and game-theory helpers for Game Theory I
//
// Usage in a lecture file:
//   #import "@local/gt-lecture:0.1.0": *
//   #show: lecture.with(subtitle: [Dominance & Rationalizability], date: [20261027])
//   #title-slide()
//   ...
//   #attendance-slide("https://forms.gle/...")
//
// Build:
//   typst compile s08.typ
//   typst compile --input handout=true s08.typ s08-handout.pdf

// Re-export Touying + stargazer so lecture files need only one import
#import "@preview/touying:0.8.0": *
#import themes.stargazer: *
#import "@preview/tiaoma:0.3.0"
#import "matrixgame.typ": game, matrixgame, player-colors
#import "@preview/theorion:0.6.0": *
#import cosmos.clouds: *

// Theorem numbering with #pause: the counter steps only on a slide's first
// subslide; later subslides reuse the same number.
#let _shared-kinds = ("theorem", "lemma", "definition", "axiom", "postulate",
  "proposition", "assumption", "property", "conjecture", "remark", "note",
  "example", "exercise", "problem")
#let _anim-number(self) = context {
  let pg = here().page()
  let first = pg - (self.subslide - 1)
  let before = query(label("richer-counter:step:theorem"))
    .filter(m => m.location().page() < first).len()
  let idx = query(selector(figure).before(here()))
    .filter(f => f.location().page() == pg and f.kind in _shared-kinds).len()
  str(before + idx)
}
#let _animated(env) = (..args) => touying-fn-wrapper(
  (self: none, start: 1) => {
    let body = if self.handout or self.subslide == 1 { env(..args) }
      else { env(number: _anim-number(self), ..args) }
    // Respect #pause: hide until the subslide where it was placed
    if self.subslide >= start { body } else { (self.methods.cover)(self: self, body) }
  },
  // Touying passes the current pause position in; hand it to `start`
  last-subslide: reps => (reps, (start: reps)),
)
#let theorem = _animated(theorem)
#let lemma = _animated(lemma)
#let proposition = _animated(proposition)
#let definition = _animated(definition)
#let example = _animated(example)
// ---------------------------------------------------------------------------
// Handout switch: `typst compile --input handout=true ...`
// ---------------------------------------------------------------------------
#let handout = sys.inputs.at("handout", default: "false") == "true"

// ---------------------------------------------------------------------------
// Shorthands
// ---------------------------------------------------------------------------
#let E = math.op("E")
#let BR = $upright(B R)$
#let MBR = $upright(M B R)$
#let small(body) = text(size: 0.9em, body)
#let footnotesize(body) = text(size: 0.8em, body)

// ---------------------------------------------------------------------------
// Default palette (purple). Override with `lecture.with(colors: (...))`.
// ---------------------------------------------------------------------------
#let default-colors = (
  primary: rgb("#87008b"),
  primary-dark: rgb("#5e0051"),
  secondary: rgb("#ffffff"),
  tertiary: rgb("#a72ea750"),
  neutral-lightest: rgb("#ffffff"),
  neutral-darkest: rgb("#1e0027"),
)

// ---------------------------------------------------------------------------
// The lecture template
// ---------------------------------------------------------------------------
#let lecture(
  title: [Game Theory I],
  subtitle: none,
  author: [Peter Shum],
  date: none,
  institution: [National Chung Cheng University \ Slides will be uploaded],
  aspect-ratio: "4-3",
  size: 22pt,
  bar-height: 2.6em,
  colors: (:),
  fonts: ("Noto Sans","Noto Sans TC", "New Computer Modern"),
  section-slides: true,
  body,
) = {
  let c = default-colors + colors

  show: stargazer-theme.with(
    aspect-ratio: aspect-ratio,
    config-common(
      handout: handout, 
      frozen-counters: (theorem-counter,),
      new-section-slide-fn: if section-slides { new-section-slide } else { none },
      ),
    config-store(
      navigation: none,
      // Taller title bar (theme default 1.8em); skipped on slides without a title
      header: self => if self.store.title != none {
        block(
          width: 100%,
          height: bar-height,
          fill: gradient.linear(self.colors.primary, self.colors.neutral-darkest),
          place(left + horizon, dx: 1.5em, text(
            fill: self.colors.neutral-lightest,
            weight: "bold",
            size: 1.3em,
            utils.call-or-display(self, self.store.title),
          )),
        )
      },
    ),
    config-page(margin: (top: bar-height + 1.9em, bottom: 2em, x: 2.5em)),
    config-info(
      title: title,
      subtitle: subtitle,
      author: author,
      date: date,
      institution: institution,
    ),
    config-methods(init: (self: none, body) => {
      set text(size: size)
      set par(leading: 0.65em) // between wrapped lines
      set list(spacing: 1em) // between bullet items
      set enum(spacing: 1em) // between numbered items
      show: show-theorion
      set-inherited-levels(0)
      set-theorion-numbering("1")
      body
    }),
    config-colors(..c),
  )

  set text(font: fonts)
  body
}

// ---------------------------------------------------------------------------
// game-steps: iterated elimination revealed one step per click
//   #game-steps("U, M, D", "L, C, R", "...", eliminate: "col C; row M, D")
// ---------------------------------------------------------------------------
#let game-steps(..args) = {
  let e = args.named().at("eliminate", default: none)
  let n = if e == none { 0 } else { e.split(";").filter(x => x.trim() != "").len() }
  for k in range(n + 1) {
    only(k + 1, game(..args, upto: k))
  }
}

// ---------------------------------------------------------------------------
// Attendance slide: shown in the lecture version only
// ---------------------------------------------------------------------------
#let attendance-slide(link-url, title: [Attendance (Time-limited)], width: 12cm) = {
  if not handout [
    == #title

    #align(center)[
      Note: Comments are optional!

      #tiaoma.qrcode(link-url, width: width)

      #link(link-url)
    ]
  ]
}
