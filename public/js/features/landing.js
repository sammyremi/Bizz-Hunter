/* public/js/features/landing.js - Landing Page Controller, Interactions & Scroll Animations */

(function (window) {
  'use strict';

  function initLandingPage() {
    const heroCta    = document.getElementById('landing-hero-cta');
    const howItWorksCta = document.getElementById('landing-how-cta');
    const finalCta   = document.getElementById('landing-final-cta');
    const navLoginBtn    = document.getElementById('landing-nav-login');
    const navRegisterBtn = document.getElementById('landing-nav-register');

    if (heroCta) {
      heroCta.addEventListener('click', (e) => {
        e.preventDefault();
        navigateToAppOrRegister();
      });
    }

    if (howItWorksCta) {
      howItWorksCta.addEventListener('click', (e) => {
        e.preventDefault();
        const section = document.getElementById('landing-how-it-works');
        if (section) section.scrollIntoView({ behavior: 'smooth' });
      });
    }

    if (finalCta) {
      finalCta.addEventListener('click', (e) => {
        e.preventDefault();
        navigateToAppOrRegister();
      });
    }

    if (navLoginBtn) {
      navLoginBtn.addEventListener('click', (e) => {
        e.preventDefault();
        window.switchTab('login');
      });
    }

    if (navRegisterBtn) {
      navRegisterBtn.addEventListener('click', (e) => {
        e.preventDefault();
        window.switchTab('register');
      });
    }

    // Initialise scroll animations whenever the landing view is shown
    initScrollAnimations();
  }

  // ─── Scroll Animation Engine ────────────────────────────────────────────────

  function initScrollAnimations() {
    const landingView = document.getElementById('view-landing');
    if (!landingView) return;

    // Mark hero content so CSS animations fire immediately
    const heroContent = landingView.querySelector('.landing-hero-content');
    if (heroContent) {
      // Tiny delay so the class switch happens after the paint
      requestAnimationFrame(() => {
        requestAnimationFrame(() => heroContent.classList.add('hero-ready'));
      });
    }

    // Stamp reveal classes onto landing elements
    stampRevealClasses(landingView);

    // Build the observer — replay animation on every scroll in AND out
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('in-view');
          } else {
            // Remove so it re-animates next time it scrolls back into view
            entry.target.classList.remove('in-view');
          }
        });
      },
      { threshold: 0.12, rootMargin: '0px 0px -40px 0px' }
    );

    // Observe every stamped element
    landingView.querySelectorAll(
      '.reveal, .reveal-left, .reveal-right, .reveal-scale, .reveal-stagger'
    ).forEach((el) => observer.observe(el));
  }

  function stampRevealClasses(view) {
    // ── How It Works ──────────────────────────────────────────────────────────
    const sectionHeaders = view.querySelectorAll('.section-header');
    sectionHeaders.forEach((el) => el.classList.add('reveal'));

    const stepsGrid = view.querySelector('.steps-grid');
    if (stepsGrid) {
      stepsGrid.classList.add('reveal-stagger');
      // Give each step-number its own CSS-variable delay for the pop keyframe
      stepsGrid.querySelectorAll('.step-number').forEach((num, i) => {
        num.style.setProperty('--delay', `${i * 100}ms`);
      });
    }

    // ── Profiles Section (2-col) ──────────────────────────────────────────────
    const profilesSection = view.querySelector('#landing-profiles');
    if (profilesSection) {
      const sectionText = profilesSection.querySelector('.section-text');
      const sectionGraphic = profilesSection.querySelector('.section-graphic-card');
      if (sectionText)    sectionText.classList.add('reveal-left');
      if (sectionGraphic) sectionGraphic.classList.add('reveal-right');

      // Stagger the feature bullet items
      const bullets = profilesSection.querySelector('.feature-bullets');
      if (bullets) bullets.classList.add('reveal-stagger');
    }

    // ── AI Briefs Section (2-col reversed) ───────────────────────────────────
    const briefsSection = view.querySelector('#landing-briefs');
    if (briefsSection) {
      const sectionText = briefsSection.querySelector('.section-text');
      const sectionGraphic = briefsSection.querySelector('.section-graphic-card');
      // Reversed layout — graphic is on the left, text on the right
      if (sectionGraphic) sectionGraphic.classList.add('reveal-left');
      if (sectionText)    sectionText.classList.add('reveal-right');

      const bullets = briefsSection.querySelector('.feature-bullets');
      if (bullets) bullets.classList.add('reveal-stagger');
    }

    // ── Outreach Section ─────────────────────────────────────────────────────
    const outreachSection = view.querySelector('#landing-outreach');
    if (outreachSection) {
      const flowBar = outreachSection.querySelector('.outreach-flow-bar');
      if (flowBar) flowBar.classList.add('reveal-stagger');
    }

    // ── CTA Section ───────────────────────────────────────────────────────────
    const ctaSection = view.querySelector('.landing-cta-section');
    if (ctaSection) ctaSection.classList.add('reveal-scale');

    // ── Mini cards / graphic elements ────────────────────────────────────────
    view.querySelectorAll('.mini-profile-card, .brief-preview-box').forEach((el) => {
      // Already covered by the parent reveal-right/left but add scale for extra depth
      el.classList.add('reveal-scale');
    });
  }

  // ─── Navigation helper ───────────────────────────────────────────────────────

  function navigateToAppOrRegister() {
    const state = window.BizzState;
    if (state && state.currentUser) {
      window.switchTab('find-businesses');
    } else {
      window.switchTab('register');
    }
  }

  window.initLandingPage = initLandingPage;
  window.navigateToAppOrRegister = navigateToAppOrRegister;
  window.initScrollAnimations = initScrollAnimations;

})(window);
