# FW 536 — Statistical Modeling for Ecology and Conservation

Course materials for the 5-day pre-fall workshop at Oregon State University.

Start with [`index.html`](index.html) in any browser — it links to every artifact.
The [`syllabus.html`](syllabus.html) has the course information, schedule, grading,
and policies.

## Course at a glance

- **Format:** 5-day intensive, two sessions per day (morning + afternoon).
- **Each session** has a 3-hour lecture followed by a hands-on lab.
- **Each lab** is a 20-point graded assignment, submitted as an R Markdown HTML on Canvas.
- **Pre-course exam** at the start of Day 1 morning.
- **Post-course exam** at the end of Day 5 afternoon.
- **Total:** 9 labs × 20 + 2 exams × 50 = 280 points.

## Top-level files

| File | Purpose |
|---|---|
| [`index.html`](index.html) | Landing page with links to everything. |
| [`syllabus.html`](syllabus.html) | Full course syllabus. |
| [`rmarkdown_tutorial.html`](rmarkdown_tutorial.html) | Install + knit + photo-embed tutorial. Complete before Day 1. |
| [`rmarkdown_tutorial_starter.Rmd`](rmarkdown_tutorial_starter.Rmd) | Working starter `.Rmd` file. |
| [`pre_course_exam.html`](pre_course_exam.html) + `.Rmd` + `_KEY.html` | Day 1 morning diagnostic exam. |
| [`post_course_exam.html`](post_course_exam.html) + `.Rmd` + `_KEY.html` | Day 5 afternoon assessment exam. |

## Day folders

Each day has the same structure:

```
DayN_Topic/
  lab.html                    — practice problem set with answers visible (in-class walkthrough)
  plain_language_summary.html — non-technical companion document
  answer_key.html             — instructor answer key for the practice lab
  problem_set_v2.html         — assessed problem set (no answers)
  problem_set_v2_KEY.html     — instructor-only answer key
  problem_set_v3.html         — alternate assessed problem set (no answers)
  problem_set_v3_KEY.html     — instructor-only answer key
  morning_lab_template_v2.Rmd, morning_lab_template_v3.Rmd
  afternoon_lab_template_v2.Rmd, afternoon_lab_template_v3.Rmd
  data/                       — all datasets used by the lab and problem sets
  *.R                         — supporting R / Nimble scripts (Days 2, 4, 5)
```

Each lab page has anchored `#morning` and `#afternoon` sections so the practice
and assessed problem sets clearly separate the morning topic from the afternoon
topic.

## Choosing v2 vs v3

For each session, the two assessed problem sets cover the **same statistical
concepts** in **different ecological themes**. Students pick whichever theme
fits their interests. The themes are:

| Day | Session | v2 theme | v3 theme |
|---|---|---|---|
| 1 | morning + afternoon | marine & fisheries | terrestrial wildlife & disease |
| 2 | morning + afternoon | forest & songbird | aquatic & fisheries |
| 3 | morning + afternoon | terrestrial wildlife | aquatic & fisheries |
| 4 | morning + afternoon | avian / songbird | marine & stock assessment |
| 5 | morning | forest carnivore | anadromous fish & freshwater |

A student who wants a coherent thread could pick all v2s or all v3s; one who
wants exposure to many systems could mix them. Grading is identical across the
two versions.

## How students use the materials

1. **Before Day 1.** Install R, RStudio, JAGS, Nimble, and the `rmarkdown` /
   `knitr` packages. Walk through [`rmarkdown_tutorial.html`](rmarkdown_tutorial.html)
   to confirm everything knits.
2. **Day 1 morning.** Pre-course exam first (download
   `pre_course_exam.Rmd`, fill in, knit, upload `.html` to Canvas). Then morning
   lecture. After lecture, work through `Day1_Probability/lab.html#morning` as a
   group with the instructor. The morning lab hand-in is either
   `problem_set_v2.html#morning` or `problem_set_v3.html#morning` — **you pick
   whichever theme fits your interests** (each Day's two versions cover the
   same statistical concepts in different ecological scenarios). Use `morning_lab_template.Rmd` to write up
   your answers; knit and upload the `.html` to Canvas.
3. **Day 1 afternoon.** Same pattern with the afternoon material.
4. **Repeat for Days 2 through 5 morning.** Each morning and each afternoon is
   its own 20-point lab.
5. **Day 5 afternoon.** Post-course exam.

## How instructors use the materials

- Each lab folder has a separate instructor `_KEY.html` file for each assessed
  problem set. Do not share these with students.
- The `answer_key.html` file in each Day folder is the practice-lab answer key
  — fine to share, since the practice lab has visible answers anyway.
- The pre-course and post-course exam keys (`pre_course_exam_KEY.html` and
  `post_course_exam_KEY.html`) are at the top level. Use them to grade and to
  compute per-student and class-wide pre/post gain.
- The lecture PowerPoints (`FW536_DayN_*.pptx`) live inside each Day folder
  alongside the labs. `index.html` and the day-folder lab pages link to them
  directly.

## Editing the materials

The HTML files use a shared stylesheet
([`_Shared/css/lab.css`](_Shared/css/lab.css)) and a small JavaScript helper
([`_Shared/js/lab.js`](_Shared/js/lab.js)). Edit the CSS once and all pages
update.

Math is rendered with MathJax (loaded from CDN). Code blocks use simple
class-based syntax coloring defined in the stylesheet.

To regenerate the R Markdown templates students fill in, copy
[`rmarkdown_tutorial_starter.Rmd`](rmarkdown_tutorial_starter.Rmd) and modify
the YAML title.

## Credits

Course design and content by **Taal Levi**, Department of Fisheries, Wildlife,
and Conservation Sciences, Oregon State University.
