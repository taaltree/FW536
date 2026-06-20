# FW 536 — Accessible edition

This is a screen-reader-optimized copy of the FW 536 course site, built for a
blind student who uses a screen reader (VoiceOver / NVDA / JAWS). It contains
the same content as the standard site (`../FW536_2026/`) — labs, problem sets,
answer keys, plain-language summaries, R Markdown templates, datasets, exams —
re-presented for accessibility.

**Students and instructors should start at [`accessibility.html`](accessibility.html)**,
which explains page layout, screen-reader navigation, and how to read the math.

## What is different from the standard site

- **Single-column reading order** so audio order matches page order.
- **Skip-to-main-content link** as the first focusable element on every page.
- **ARIA landmarks and labels**: each page has a labeled navigation region, one
  `<main id="main-content">`, and a footer.
- **One Heading level 1 per page** (the page title); sections use Heading level 2.
- **Accessible math**: MathJax is configured with assistive MathML plus the
  expression Explorer, so every equation is spoken and can be explored by
  subexpression.
- **Real text labels on callouts** (e.g. "Key idea", "Watch out") instead of
  color/CSS-only cues — nothing is conveyed by color alone.
- **Tables** have `scope="col"` headers and render with high-contrast borders.
- **Tabs and quizzes** are wired with ARIA roles, keyboard support, and live
  regions (`_Shared/js/accessible.js`).
- **High-contrast, user-scalable styling** (`_Shared/css/accessible.css`); text
  scales with the browser font setting, helping low-vision users too.
- **Lecture notes**: each lecture has an accessible HTML transcript
  (`Day*/lecture_*.html`) generated from the slides, because the original
  PowerPoint files are hard to navigate by ear. (The original `.pptx` slides
  remain in the standard course site.)

## Lecture notes and figure descriptions

The lecture-notes pages include all slide **text**, **tables**, and **speaker
notes**. They cannot auto-describe images (plots, diagrams, R-output
screenshots, equation graphics), so each image is flagged with a
"Figure N.k — needs description" note.

[`FIGURE_DESCRIPTIONS_TODO.md`](FIGURE_DESCRIPTIONS_TODO.md) lists every flagged
figure (400 total across the 9 lectures) with a per-lecture count and a
fill-in checklist. To complete a description, open the lecture-notes file, find
the figure note, and replace it with a sentence or two describing the figure
(or, for an equation image, write the equation in `$...$` so it renders as
navigable math).

## Accommodations baked into the materials

- Lecture content is available as accessible text, not only as slides.
- All math is screen-reader navigable.
- Where a problem says to "plot and inspect," the student may report and
  interpret the **numeric** results instead (see the accessibility guide,
  "Doing and submitting the work").
- The student chooses the same v2 / v3 theme options as everyone else.

## Files

```
accessibility.html            — the accessibility guide (start here)
index.html                    — accessible landing page (single column)
FIGURE_DESCRIPTIONS_TODO.md   — checklist of lecture figures needing description
_Shared/css/accessible.css    — screen-reader-first stylesheet
_Shared/js/accessible.js      — ARIA tabs / quiz / reveal controls
DayN_Topic/
  lecture_*.html              — accessible lecture-notes transcripts
  lab.html                    — practice lab (answers visible)
  plain_language_summary.html — non-technical companion
  problem_set_v2/v3.html       — assessed problem sets (answers in *_KEY.html)
  *_lab_template_v2/v3.Rmd     — hand-in templates
  data/                        — datasets
  *.R                          — Nimble / R scripts (Days 2, 4, 5)
```

## Maintenance

The accessible pages were produced by transforming the standard site, so if you
update content in `../FW536_2026/`, regenerate this edition rather than editing
both by hand.

## Note on the post-course exam filename

The student-facing post-course exam is `post_course_exam_off.html`. (In the
standard repo, a few pages link to `post_course_exam.html`, which does not
exist — those links are corrected here.)

## Credits

Course design and content by **Taal Levi**, Department of Fisheries, Wildlife,
and Conservation Sciences, Oregon State University. Accessible edition built
alongside the standard site.
