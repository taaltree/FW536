#!/usr/bin/env python3
"""Build one review page per day pairing every practice question with its answer.

The lab pages hide each worked answer behind a "Reveal worked solution" toggle, and
the standalone answer key lists answers without restating what was asked. Neither is
convenient for vetting the questions themselves, which needs both halves side by side
on a single page.

This generates DayX/answer_key_review.html from DayX/lab.html: every exercise block is
split at its <details class="answer"> boundary, and the two halves are re-emitted under
QUESTION and ANSWER labels with nothing collapsed.

The question and answer HTML are copied verbatim. That is deliberate -- the point is to
review the text students actually see, so paraphrasing here would defeat the exercise.

Regenerate after editing any lab:

    python3 _tools/build_answer_key_review.py
"""
import glob
import html
import os
import re
import sys

DAY_TITLES = {
    "Day1_Probability": "Day 1 · Probability &amp; discrete distributions",
    "Day2_GLM": "Day 2 · Continuous distributions, LMs &amp; GLMs",
    "Day3_MixedModels_ModelSelection": "Day 3 · Mixed models &amp; model selection",
    "Day4_Likelihood_BayesI": "Day 4 · Maximum likelihood &amp; Bayes I",
    "Day5_BayesII": "Day 5 · Bayesian hierarchical models",
}


def div_span(text, start):
    """Slice the <div> that starts at `start`, honouring nested divs."""
    depth = 0
    for m in re.finditer(r'<div\b|</div>', text[start:]):
        if m.group(0).startswith('<div'):
            depth += 1
        else:
            depth -= 1
            if depth == 0:
                return text[start:start + m.end()]
    return text[start:]


def strip_tags(s):
    return ' '.join(html.unescape(re.sub(r'<[^>]*>', ' ', s)).split())


def parse_exercises(lab_html):
    """Yield dicts of tag / meta / title / question / answer for each exercise."""
    out = []
    for m in re.finditer(r'<div class="exercise"', lab_html):
        block = div_span(lab_html, m.start())

        tag_m = re.search(r'<span class="ex-tag">(.*?)</span>', block, re.S)
        meta_m = re.search(r'<span class="difficulty[^"]*">(.*?)</span>', block, re.S)
        h3_m = re.search(r'<h3[^>]*>(.*?)</h3>', block, re.S)
        det_i = block.find('<details class="answer"')

        if not tag_m or det_i < 0:
            continue

        # question: from the end of the <h3> (or the tag line) up to the answer toggle
        q_start = h3_m.end() if h3_m else tag_m.end()
        question = block[q_start:det_i].strip()

        # answer: between the opening <details> and ITS matching </details>.
        # A few exercises carry a callout after the answer toggle -- that is visible
        # to students without revealing anything, so it belongs with the question,
        # not the answer. Match the close properly rather than assuming it ends the div.
        depth = 0
        close_i = None
        for dm in re.finditer(r'<details\b|</details>', block[det_i:]):
            if dm.group(0).startswith('<details'):
                depth += 1
            else:
                depth -= 1
                if depth == 0:
                    close_i = det_i + dm.start()
                    break
        if close_i is None:
            close_i = len(block)

        answer = block[det_i:close_i]
        answer = re.sub(r'^<details[^>]*>', '', answer).strip()
        answer = re.sub(r'<summary>.*?</summary>', '', answer, count=1, flags=re.S).strip()
        ab = re.match(r'<div class="answer-body">(.*)</div>\s*$', answer, re.S)
        if ab:
            answer = ab.group(1).strip()

        # anything after the answer toggle, minus the exercise div's own closing tag
        trailing = block[close_i + len('</details>'):]
        trailing = re.sub(r'</div>\s*$', '', trailing).strip()

        out.append({
            "tag": strip_tags(tag_m.group(1)),
            "meta": strip_tags(meta_m.group(1)) if meta_m else "",
            "title": h3_m.group(1).strip() if h3_m else "",
            "question": question,
            "trailing": trailing,
            "answer": answer,
        })
    return out


CSS = """
  .rv-intro{background:#11304A;color:#fff;border-radius:11px;padding:18px 22px;margin:0 0 26px;}
  .rv-intro h2{color:#fff;border:none;margin:0 0 7px;font-size:19px;}
  .rv-intro p{margin:0 0 8px;color:#dbe6ef;font-size:14.5px;}
  .rv-intro p:last-child{margin-bottom:0;}
  .rv-intro a{color:#FFE08A;}
  .rv-intro code{background:rgba(255,255,255,.14);color:#fff;
    padding:2px 7px;border-radius:5px;font-size:.92em;}

  .rv-item{border:1px solid var(--border);border-radius:10px;background:var(--panel);
    margin:0 0 22px;overflow:hidden;}
  .rv-head{background:var(--panel-alt);border-bottom:1px solid var(--border);padding:12px 18px;}
  .rv-head .rv-tag{display:inline-block;font-size:11.5px;font-weight:700;letter-spacing:.07em;
    text-transform:uppercase;color:#fff;background:var(--osu-orange);border-radius:5px;
    padding:3px 9px;margin-right:9px;}
  .rv-head .rv-meta{font-size:12.5px;color:var(--muted);}
  .rv-head h3{margin:9px 0 0;font-size:17px;}
  .rv-body{padding:4px 18px 14px;}
  .rv-label{font-size:11px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;
    margin:16px 0 8px;padding-bottom:5px;border-bottom:2px solid var(--border);}
  .rv-label.q{color:var(--osu-orange-dark);border-bottom-color:#F0C4B4;}
  .rv-label.a{color:var(--accent);border-bottom-color:#B6D4CD;}
  .rv-q > *:first-child, .rv-a > *:first-child{margin-top:0;}

  .rv-toc{border:1px solid var(--border);border-radius:10px;background:var(--panel-alt);
    padding:14px 18px;margin:0 0 26px;}
  .rv-toc h2{margin:0 0 9px;font-size:15px;border:none;}
  .rv-toc ol{margin:0;padding-left:22px;columns:2;column-gap:28px;}
  @media(max-width:700px){.rv-toc ol{columns:1;}}
  .rv-toc li{margin-bottom:4px;font-size:13.5px;}

  @media print{
    .sidebar{display:none!important;}
    .content{max-width:100%;}
    .rv-item{break-inside:avoid;border-color:#999;}
    .rv-intro{background:#fff;color:#000;border:1px solid #999;}
    .rv-intro p{color:#000;}
  }
"""


def build_page(day, exercises):
    nice = DAY_TITLES.get(day, day.replace('_', ' '))
    plain = re.sub(r'<[^>]*>', '', nice)

    toc = "\n".join(
        '   <li><a href="#rv{i}">{tag} &mdash; {title}</a></li>'.format(
            i=i, tag=html.escape(e["tag"]), title=strip_tags(e["title"])[:58])
        for i, e in enumerate(exercises, 1))

    items = []
    for i, e in enumerate(exercises, 1):
        items.append(
            '<div class="rv-item" id="rv{i}">\n'
            '  <div class="rv-head">\n'
            '    <span class="rv-tag">{tag}</span><span class="rv-meta">{meta}</span>\n'
            '    <h3>{title}</h3>\n'
            '  </div>\n'
            '  <div class="rv-body">\n'
            '    <div class="rv-label q">Question, as students see it</div>\n'
            '    <div class="rv-q">{q}</div>\n'
            '{extra}'
            '    <div class="rv-label a">Answer</div>\n'
            '    <div class="rv-a">{a}</div>\n'
            '  </div>\n'
            '</div>'.format(i=i, tag=html.escape(e["tag"]),
                            meta=html.escape(e["meta"]), title=e["title"],
                            q=e["question"], a=e["answer"],
                            extra=('    <div class="rv-label q">Also visible without revealing</div>\n'
                                   '    <div class="rv-q">' + e["trailing"] + '</div>\n')
                                  if e.get("trailing") else ''))

    return """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<title>Questions &amp; answers for review | {plain} | FW 536</title>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<link rel="stylesheet" href="../_Shared/css/lab.css" />
<script defer src="../_Shared/js/lab.js"></script>
<script>
MathJax = {{ tex: {{ inlineMath: [['$','$'], ['\\\\(','\\\\)']] }} }};
</script>
<script defer src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
<style>{css}</style>
</head>
<body>
<div class="shell">

<aside class="sidebar">
  <p class="brand"><a href="../index.html" title="Back to course home">FW 536</a></p>
  <div class="subtitle">Q &amp; A review</div>
  <nav>
    <div class="section">Exercises</div>
    <ul>
{navlist}
    </ul>
    <div class="section">This day</div>
    <ul>
      <li><a href="lab.html">Lab (in-class walkthrough)</a></li>
      <li><a href="answer_key.html">Answer key</a></li>
      <li><a href="problem_set.html">Graded problem set</a></li>
    </ul>
    <div class="section">Course</div>
    <ul><li><a href="../index.html">All days</a></li></ul>
  </nav>
</aside>

<main class="content">

<h1>Questions &amp; answers for review</h1>
<p class="lede">{nice} &mdash; every practice exercise on one page, each question written out
immediately above its answer, nothing collapsed. This view exists for vetting the exercises
themselves rather than for teaching from.</p>

<div class="rv-intro">
  <h2>What this page is</h2>
  <p>The <a href="lab.html">lab</a> hides each answer behind a toggle, and the
  <a href="answer_key.html">answer key</a> gives answers without restating the question. Neither
  is convenient for reading a question and its answer together, which is what checking the
  exercises actually requires.</p>
  <p>Question and answer text are copied verbatim from the lab, so what you read here is exactly
  what students read. Edit the lab, then regenerate:
  <code>python3 _tools/build_answer_key_review.py</code></p>
</div>

<div class="rv-toc">
  <h2>{n} exercises on this page</h2>
  <ol>
{toc}
  </ol>
</div>

{items}

<p style="margin-top:34px;font-size:14px;color:var(--muted)">
Generated from <code>lab.html</code>. Do not edit this file directly &mdash; edit the lab and regenerate.
</p>

</main>
</div>
</body>
</html>
""".format(plain=plain, nice=nice, css=CSS, n=len(exercises),
           navlist="\n".join(
               '      <li><a href="#rv{i}">{tag}</a></li>'.format(i=i, tag=html.escape(e["tag"]))
               for i, e in enumerate(exercises, 1)),
           toc=toc, items="\n\n".join(items))


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)
    total = 0
    for lab in sorted(glob.glob('Day*/lab.html')):
        day = os.path.dirname(lab)
        exercises = parse_exercises(open(lab, encoding='utf-8').read())
        if not exercises:
            print("  {}: no exercises found, skipped".format(day))
            continue
        out = os.path.join(day, 'answer_key_review.html')
        with open(out, 'w', encoding='utf-8') as fh:
            fh.write(build_page(day, exercises))
        total += len(exercises)
        print("  {:34s} {:2d} exercises -> {}".format(day, len(exercises), out))
    print("  {} exercises written across {} days".format(total, len(glob.glob('Day*/lab.html'))))
    return 0


if __name__ == '__main__':
    sys.exit(main())
