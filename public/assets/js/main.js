(() => {
  const toggle = document.querySelector('.menu-toggle');
  const nav = document.querySelector('.main-nav');
  if (toggle && nav) {
    toggle.addEventListener('click', () => {
      const open = nav.classList.toggle('open');
      toggle.setAttribute('aria-expanded', String(open));
    });
    nav.querySelectorAll('a').forEach(link => link.addEventListener('click', () => {
      nav.classList.remove('open');
      toggle.setAttribute('aria-expanded', 'false');
    }));
  }
  document.querySelectorAll('[data-year]').forEach(el => { el.textContent = new Date().getFullYear(); });
  document.querySelectorAll('form[data-demo-form]').forEach(form => {
    form.addEventListener('submit', event => {
      event.preventDefault();
      const status = form.querySelector('[data-form-status]');
      if (status) status.textContent = 'This is a design preview. Authentication and banking services are not connected yet. No information has been sent or stored.';
    });
  });
})();