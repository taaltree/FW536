// FW 536 — Accessible helper script
// Adds ARIA wiring so tabs, quizzes, and reveal controls work with screen
// readers and keyboard only. Progressive enhancement: if JS is off, tabs
// render as stacked panels (none hidden) and details/summary still work.

document.addEventListener('DOMContentLoaded', () => {

  /* -------- Tabs: ARIA tablist with arrow-key support -------- */
  document.querySelectorAll('.tabs').forEach((tabs, ti) => {
    const btnWrap = tabs.querySelector('.tab-buttons');
    const buttons = Array.from(tabs.querySelectorAll('.tab-buttons button'));
    const panels  = Array.from(tabs.querySelectorAll('.tab-panel'));
    if (!btnWrap || buttons.length === 0) return;

    btnWrap.setAttribute('role', 'tablist');
    buttons.forEach((btn, i) => {
      const id = `tab-${ti}-${i}`;
      const panel = panels[i];
      btn.setAttribute('role', 'tab');
      btn.id = id;
      btn.setAttribute('aria-selected', i === 0 ? 'true' : 'false');
      btn.setAttribute('tabindex', i === 0 ? '0' : '-1');
      if (panel) {
        panel.setAttribute('role', 'tabpanel');
        panel.setAttribute('aria-labelledby', id);
        panel.hidden = (i !== 0);
        panel.setAttribute('tabindex', '0');
      }
      const select = () => {
        buttons.forEach((b, j) => {
          b.setAttribute('aria-selected', j === i ? 'true' : 'false');
          b.setAttribute('tabindex', j === i ? '0' : '-1');
          if (panels[j]) panels[j].hidden = (j !== i);
        });
        btn.focus();
      };
      btn.addEventListener('click', select);
      btn.addEventListener('keydown', (e) => {
        let target = null;
        if (e.key === 'ArrowRight' || e.key === 'ArrowDown') target = buttons[(i + 1) % buttons.length];
        else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') target = buttons[(i - 1 + buttons.length) % buttons.length];
        else if (e.key === 'Home') target = buttons[0];
        else if (e.key === 'End') target = buttons[buttons.length - 1];
        if (target) { e.preventDefault(); target.click(); }
      });
    });
  });

  /* -------- Quiz: live-region feedback -------- */
  document.querySelectorAll('.quiz').forEach(quiz => {
    const btn = quiz.querySelector('button.check');
    const fb = quiz.querySelector('.feedback');
    if (!btn || !fb) return;
    fb.setAttribute('role', 'status');
    fb.setAttribute('aria-live', 'polite');
    btn.addEventListener('click', () => {
      const choices = quiz.querySelectorAll('input[type="radio"], input[type="checkbox"]');
      let allCorrect = true, anySelected = false;
      choices.forEach(c => {
        if (c.checked) { anySelected = true; if (c.dataset.correct !== 'true') allCorrect = false; }
        else if (c.dataset.correct === 'true' && c.type === 'checkbox') allCorrect = false;
      });
      fb.classList.remove('correct', 'wrong');
      if (!anySelected) { fb.textContent = 'Select an option first.'; fb.classList.add('wrong'); }
      else if (allCorrect) { fb.classList.add('correct'); fb.innerHTML = fb.dataset.correctText || 'Correct.'; }
      else { fb.classList.add('wrong'); fb.innerHTML = fb.dataset.wrongText || 'Not quite — try again.'; }
    });
  });

  /* -------- Reveal-all / hide-all answers -------- */
  const ra = document.getElementById('reveal-all');
  const ha = document.getElementById('hide-all');
  if (ra) ra.addEventListener('click', () => document.querySelectorAll('details.answer').forEach(d => d.open = true));
  if (ha) ha.addEventListener('click', () => document.querySelectorAll('details.answer').forEach(d => d.open = false));
});
