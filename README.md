# FW 536 · Statistical Modeling for Ecology and Conservation

Course materials for the 5-day pre-fall workshop at Oregon State University.

Open [`index.html`](index.html) in any browser. It links to every artifact.
[`syllabus.html`](syllabus.html) has the schedule, grading, and policies.

## Course at a glance

- **Format:** 5-day intensive, two sessions per day (morning + afternoon).
- **Each session** has a lecture followed by a hands-on lab.
- **Each session's graded work** is a single 20-point problem set, submitted as a
  knitted R Markdown HTML on Canvas.
- **Day 5 afternoon** is open lab time to finish any unfinished problem sets.

## Before the course

Students complete two setup steps first, linked from the landing page:

1. [`install_jags_nimble.html`](install_jags_nimble.html) installs R, RStudio,
   the compiler toolchain, and Nimble on Windows or Mac (JAGS optional), with a
   verification step.
2. [`rmarkdown_tutorial.html`](rmarkdown_tutorial.html) teaches the R Markdown workflow
   used for every hand-in.

## Each day folder

```
DayN_Topic/
  lab.html                       — in-class practice lab (answers reveal-able)
  problem_set.html               — the single graded problem set (morning + afternoon)
  morning_lab_template.Rmd       — R Markdown hand-in template (morning)
  afternoon_lab_template.Rmd     — R Markdown hand-in template (afternoon; Days 1–4)
  plain_language_summary.html    — non-technical companion
  answer_key.html                — practice-lab answer key (public by design)
  explore_*.html                 — interactive visualization (Days 1–4)
  data/                          — datasets the problems analyze
  *.R                            — supporting R / Nimble scripts (Days 2, 4, 5)
  FW536_DayN_*.pptx              — lecture slides (+ *_nosoln.pptx, the no-solution copy students get, Days 1–2)
```

The practice lab and the graded problem set both use anchored `#morning` and
`#afternoon` sections so the two sessions stay clearly separated.

**Day 5 is the exception.** Its afternoon is open lab time rather than a new
topic, so `Day5_BayesII/` has only a `#morning` section, with no `afternoon_lab_template.Rmd` and no `explore_*.html` of its own.

## Interactive visualizations

Days 1–4 each link a self-contained browser widget (no install needed):

- Day 1: discrete distribution explorer (Binomial / Poisson / Negative Binomial).
- Day 2: link-function & logit visualizer (identity / log / logit).
- Day 3: shrinkage / partial-pooling demo.
- Day 4: likelihood curve + live Metropolis MCMC sampler.

Day 5 has no widget of its own; its lab reuses the Day 4 MCMC and conjugate
explorers.

## Answer keys (instructor-only)

Graded problem-set keys (`problem_set_KEY.html`) are **git-ignored**. They stay on the instructor's local
copy and are never published. Release them via Canvas after grading. The
practice-lab `answer_key.html` files are public by design (the practice lab
already shows its answers).

## Maintenance tools

- `_tools/check_deck_sync.py` checks that each no-solution deck (`*_nosoln.pptx`) still agrees
  with its master. Run it after editing either one; it exits 1 if they have drifted.
- `_tools/build_answer_key_review.py` builds one-page question-and-answer review pages for vetting
  exercises. It currently reads the practice labs.

The accessible edition (the `accessible/` screen-reader mirror, the `*_accessible.pptx` decks, and
the three scripts that built them) was retired in September 2026 and archived outside the repo, in
`../FW536_2026_Accessible/`.

See [`RECOMMENDATIONS.md`](RECOMMENDATIONS.md) for a course review and prioritized
suggestions for further improvement.

## Credits

Course design and content by **Taal Levi**, Department of Fisheries, Wildlife,
and Conservation Sciences, Oregon State University.
