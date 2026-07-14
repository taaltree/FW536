# FW 536 — course review & recommendations for further improvement

This document is a structured review of the course as it now stands, plus
concrete, prioritized recommendations. It is written for the instructor and is
not part of the student-facing site.

## What is working well

- **One coherent lab per session.** The morning/afternoon split with a single
  graded problem set (down from two themed versions) is clearer for students and
  simpler to grade.
- **Real data in the labs.** Most analysis problems now load actual datasets
  (salmon eDNA, Titanic, fish trophic position, ants, island lizards, growth and
  recruitment data), so students practice the whole workflow.
- **Practice → assessment separation.** In-class practice labs with reveal-able
  answers, then a separate graded problem set whose key is released only after
  grading.
- **Interactive visualizations.** Distribution explorer, link/logit visualizer,
  shrinkage demo, and a live Metropolis sampler make abstract ideas tangible.
- **Accessibility.** A full screen-reader edition with accessible lecture notes,
  navigable math, and (increasingly) described figures.

## Recommendations, prioritized

### High priority

1. **Publish a data dictionary.** Several datasets have non-obvious schemas that
   already caused code mismatches during this revision:
   - `sockeye_adult.csv` is long-format with a `Sockeyetype` column and
     `Count`/`Qcorr_qPCR` fields — not `Sockeye_Adults`/`Year`. Any lab prose or
     legacy code assuming the latter will fail.
   - `mixed1a.txt` holds **100 streams × 3 observations = 300 rows**; the old
     `scan(..., n=3*18)` call silently read only 6 streams.
   Add a short `data/README.md` per day listing each file's columns, units, and a
   one-line `read.*` example that actually works. This prevents a whole class of
   "it won't run" support requests.

2. **Add automated R checks.** Put every code block from the labs, problem sets,
   and answer keys into runnable `.R` files and run them in CI (GitHub Actions
   with `r-lib/actions`) so a broken example is caught before students hit it.
   During this revision, agents found and fixed several numeric errors by running
   the code; a CI harness makes that permanent.

3. **Grading rubrics.** Each 20-point problem set and the 50-point pre-course
   exam should ship with a rubric (points per problem, partial-credit guidance).
   This makes grading consistent and transparent.

4. **Reproducible environment.** Add an `renv.lock` (or a documented
   `install.packages` list with versions) so students and graders run the same
   package versions. Pair it with the new `install_jags_nimble.html` page.

### Medium priority

5. **A short capstone / integrative problem.** Days 1–5 build a toolkit; a
   half-day open-ended analysis (pick a dataset, state a model, fit it, interpret,
   communicate uncertainty) would consolidate the week and is exactly the skill
   the course is training.

6. **Solution walkthroughs.** For the two or three hardest problems per day, a
   3–5 minute screen-recorded walkthrough (released with the key) helps students
   who got stuck. Captions make them accessible.

7. **A glossary / notation sheet.** One page mapping symbols to meaning
   (η, μ, θ, φ, γ, ψ, τ, λ, k) and R/Nimble names. Notation drift between lectures
   and labs is a common friction point.

8. **Diagnostics checklist for Bayesian labs.** A reusable box: check R-hat < 1.01,
   effective sample size, trace plots, posterior predictive checks. Students tend
   to report posteriors without convergence checks.

9. **Datasets for Day 1.** Day 1 is mostly analytic/simulation. Two small real
   datasets were added during this revision (eDNA replicates, coyote scat counts);
   consider one more for the multinomial section (e.g., real age/sex classification
   counts) so Day 1 also has a "load and analyze" moment.

### Lower priority / polish

10. **Consistent problem numbering** across the practice lab and the graded set so
    students can map "practice problem 3" to "graded problem 3" by topic.

11. **A one-page "how models connect" map** — probability → distribution →
    likelihood → GLM → mixed model → Bayes — shown on Day 1 and revisited each day.
    The plain-language summaries gesture at this; a single diagram would anchor it.

12. **Link the interactive widgets from the lecture notes**, not just the labs, so
    they surface during lecture too.

13. **Accessibility maintenance.** Keep the `_tools/` scripts as the single source
    of truth: regenerate the accessible edition and lecture notes from the standard
    site rather than editing both by hand. Re-run `build_accessible_pptx.py` and
    `build_lecture_notes.py` whenever slides change.

14. **Retire dead assets.** Remove the `_nosoln` PowerPoint variants from the
    published site if they are not used, to reduce repo size and confusion.

## Known content items to verify before teaching

- Confirm the practice `lab.html` code on Day 2 uses the real `sockeye_adult.csv`
  schema (the graded problem set and key already do; the practice lab's exercise
  A1 may still assume the old column names).
- Spot-check that every Nimble example actually compiles on a fresh machine that
  followed the install guide (the single most common day-of failure).

## Suggested cadence

Treat the `_tools/` scripts, a `data/README.md` per day, and a CI check as the
"infrastructure" layer; everything else (capstone, walkthroughs, glossary) is
content that can be added incrementally between offerings.
