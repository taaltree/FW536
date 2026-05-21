// FW599 Enhanced Lab – tiny helper script
// Provides: tab switching, quiz checking, smooth ToC active highlight.

document.addEventListener('DOMContentLoaded', () => {

  // -------- Tabs --------
  document.querySelectorAll('.tabs').forEach(tabs => {
    const buttons = tabs.querySelectorAll('.tab-buttons button');
    const panels = tabs.querySelectorAll('.tab-panel');
    buttons.forEach((btn, i) => {
      btn.addEventListener('click', () => {
        buttons.forEach(b => b.classList.remove('active'));
        panels.forEach(p => p.classList.remove('active'));
        btn.classList.add('active');
        panels[i].classList.add('active');
      });
    });
  });

  // -------- Quiz --------
  document.querySelectorAll('.quiz').forEach(quiz => {
    const btn = quiz.querySelector('button.check');
    if (!btn) return;
    btn.addEventListener('click', () => {
      const choices = quiz.querySelectorAll('input[type="radio"], input[type="checkbox"]');
      let allCorrect = true;
      let anySelected = false;
      choices.forEach(c => {
        if (c.checked) {
          anySelected = true;
          if (c.dataset.correct !== 'true') allCorrect = false;
        } else if (c.dataset.correct === 'true' && c.type === 'checkbox') {
          allCorrect = false;
        }
      });
      const fb = quiz.querySelector('.feedback');
      fb.classList.remove('correct', 'wrong');
      fb.classList.add('show');
      if (!anySelected) {
        fb.textContent = 'Select an option first.';
        fb.classList.add('wrong');
      } else if (allCorrect) {
        fb.classList.add('correct');
        fb.innerHTML = fb.dataset.correctText || 'Correct!';
      } else {
        fb.classList.add('wrong');
        fb.innerHTML = fb.dataset.wrongText || 'Not quite — try again.';
      }
    });
  });

  // -------- ToC active highlight --------
  const navLinks = document.querySelectorAll('.sidebar nav a[href^="#"]');
  if (navLinks.length === 0) return;
  const sections = Array.from(navLinks).map(a => document.querySelector(a.getAttribute('href'))).filter(Boolean);
  const obs = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        navLinks.forEach(a => a.style.background = '');
        const link = document.querySelector(`.sidebar nav a[href="#${entry.target.id}"]`);
        if (link) link.style.background = 'rgba(215,63,9,0.25)';
      }
    });
  }, { rootMargin: '-30% 0px -55% 0px' });
  sections.forEach(s => obs.observe(s));

  // -------- Reveal-all / hide-all answers --------
  const ra = document.getElementById('reveal-all');
  const ha = document.getElementById('hide-all');
  if (ra) ra.addEventListener('click', () => document.querySelectorAll('details.answer').forEach(d => d.open = true));
  if (ha) ha.addEventListener('click', () => document.querySelectorAll('details.answer').forEach(d => d.open = false));
});
