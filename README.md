# FW 536 — Statistical Modeling for Ecology and Conservation

Course materials for the 5-day pre-fall workshop at Oregon State University.

Open [`index.html`](index.html) in any browser — it links to every artifact.
[`syllabus.html`](syllabus.html) has the schedule, grading, and policies. A
screen-reader-optimized edition lives in [`accessible/`](accessible/index.html).

## Course at a glance

- **Format:** 5-day intensive, two sessions per day (morning + afternoon).
- **Each session** has a lecture followed by a hands-on lab.
- **Each session's graded work** is a single 20-point problem set, submitted as a
  knitted R Markdown HTML on Canvas.
- **Pre-course exam** at the start of Day 1 morning; **post-course exam** at the
  end of Day 5 afternoon (parallel exams to measure learning gain).

## Before the course

Students complete two setup steps first, linked from the landing page:

1. [`install_jags_nimble.html`](install_jags_nimble.html) — install R, RStudio,
   the compiler toolchain, JAGS, and Nimble on Windows or Mac, with a
   verification step.
2. [`rmarkdown_tutorial.html`](rmarkdown_tutorial.html) — the R Markdown workflow
   used for every hand-in.

## Each day folder

```
DayN_Topic/
  lab.html                       — in-class practice lab (answers reveal-able)
  problem_set.html               — the single graded problem set (morning + afternoon)
  morning_lab_template.Rmd        — R Markdown hand-in template (morning)
  afternoon_lab_template.Rmd      — R Markdown hand-in template (afternoon)
  plain_language_summary.html    — non-technical companion
  answer_key.html                — practice-lab answer key (public by design)
  explore_*.html                 — interactive visualization for the day
  data/                          — datasets the problems analyze
  *.R                            — supporting R / Nimble scripts (Days 2, 4, 5)
  FW536_DayN_*.pptx              — lecture slides (+ *_accessible.pptx with alt text)
```

The practice lab and the graded problem set both use anchored `#morning` and
`#afternoon` sections so the two sessions stay clearly separated.

## Interactive visualizations

Each day links a self-contained browser widget (no install needed):

- Day 1 — discrete distribution explorer (Binomial / Poisson / Negative Binomial).
- Day 2 — link-function & logit visualizer (identity / log / logit).
- Day 3 — shrinkage / partial-pooling demo.
- Day 4 — likelihood curve + live Metropolis MCMC sampler.

## Answer keys (instructor-only)

Graded problem-set keys (`problem_set_KEY.html`) and exam keys
(`*_exam_KEY.html`) are **git-ignored** — they stay on the instructor's local
copy and are never published. Release them via Canvas after grading. The
practice-lab `answer_key.html` files are public by design (the practice lab
already shows its answers).

## Accessible edition

[`accessible/`](accessible/index.html) is a screen-reader-first copy: single-column
reading order, skip links, ARIA landmarks, MathJax with navigable MathML, text
labels on callouts, and accessible lecture-notes transcripts with figure
descriptions. See [`accessible/README.md`](accessible/README.md).

## Maintenance tools

The `_tools/` scripts regenerate derived artifacts so the two editions stay in
sync — run them after changing slides or standard-site content:

- `build_accessible_pptx.py` — write image alt text into `*_accessible.pptx`.
- `build_lecture_notes.py` — regenerate accessible lecture-notes transcripts.
- `update_accessible.py` — regenerate the accessible content pages from the
  standard site.

See [`RECOMMENDATIONS.md`](RECOMMENDATIONS.md) for a course review and prioritized
suggestions for further improvement.

## Credits

Course design and content by **Taal Levi**, Department of Fisheries, Wildlife,
and Conservation Sciences, Oregon State University.
