/* public/js/app.js - Bizz-Hunter Application Entry Point & Coordinator */

(function () {
  'use strict';

  console.log('BIZZ-HUNTER APP COORDINATOR LOADED v20260905_v2');

  const state = window.BizzState;

  document.addEventListener('DOMContentLoaded', async () => {
    window.cacheDomElements();
    initTheme();
    initNavigation();
    if (typeof window.initLocationSelectors === 'function') window.initLocationSelectors();
    if (typeof window.initBusinessTypeAutocomplete === 'function') window.initBusinessTypeAutocomplete();
    if (typeof window.initSearchForm === 'function') window.initSearchForm();
    if (typeof window.initModals === 'function') window.initModals();
    if (typeof window.initAuth === 'function') window.initAuth();

    // Determine initial tab from hash, localStorage, or state
    const hashTab = window.location.hash ? window.location.hash.replace('#', '') : null;
    const savedTab = localStorage.getItem('bizz_hunter_current_tab');
    const initialTab = hashTab || savedTab || state.currentTab || 'find-businesses';

    switchTab(initialTab);

    if (typeof window.checkAuthSession === 'function') await window.checkAuthSession();
    if (typeof window.fetchAndUpdateQuota === 'function') await window.fetchAndUpdateQuota();
  });

  window.addEventListener('hashchange', () => {
    const hashTab = window.location.hash.replace('#', '');
    if (hashTab && ['find-businesses', 'dashboard', 'saved-businesses', 'analysis', 'settings'].includes(hashTab)) {
      if (!state.currentUser && ['dashboard', 'saved-businesses', 'analysis'].includes(hashTab)) {
        if (typeof window.openAuthModal === 'function') {
          const tabTitle = window.capitalize ? window.capitalize(hashTab.replace('-', ' ')) : hashTab;
          window.openAuthModal('login', `Account required to access ${tabTitle}. Sign up or log in to continue!`);
        }
        switchTab('find-businesses');
        return;
      }
      switchTab(hashTab);
    }
  });

  // --- Theme Switcher Engine ---
  function initTheme() {
    applyTheme(state.theme);

    const dom = window.dom || state.dom;
    if (dom && dom.themeToggleBtn) {
      dom.themeToggleBtn.addEventListener('click', () => {
        const nextTheme = state.theme === 'dark' ? 'light' : 'dark';
        applyTheme(nextTheme);
        if (typeof window.renderDashboardAnalytics === 'function') window.renderDashboardAnalytics();
        if (typeof window.renderAnalysisWorkspace === 'function') window.renderAnalysisWorkspace();
      });
    }
  }

  function applyTheme(themeName) {
    state.theme = themeName;
    localStorage.setItem('bizz_hunter_theme', themeName);
    document.documentElement.setAttribute('data-theme', themeName);

    const dom = window.dom || state.dom;
    if (dom && dom.themeIcon) {
      dom.themeIcon.textContent = themeName === 'light' ? '☀️' : '🌙';
    }
  }

  // --- Navigation Controller ---
  function initNavigation() {
    const dom = window.dom || state.dom;
    if (dom && dom.navItems) {
      dom.navItems.forEach(item => {
        item.addEventListener('click', (e) => {
          e.preventDefault();
          const tab = item.getAttribute('data-tab');
          if (!tab) return;

          // Protected feature gating
          if (!state.currentUser && ['dashboard', 'saved-businesses', 'analysis'].includes(tab)) {
            if (typeof window.openAuthModal === 'function') {
              const tabTitle = window.capitalize ? window.capitalize(tab.replace('-', ' ')) : tab;
              window.openAuthModal('login', `Account required to access ${tabTitle}. Sign up or log in to continue!`);
            }
            return;
          }

          switchTab(tab);
        });
      });
    }

    if (dom && dom.prospectStatusTabs) {
      dom.prospectStatusTabs.querySelectorAll('.status-tab').forEach(tabBtn => {
        tabBtn.addEventListener('click', async () => {
          dom.prospectStatusTabs.querySelectorAll('.status-tab').forEach(b => b.classList.remove('active'));
          tabBtn.classList.add('active');
          state.activeProspectStatusFilter = tabBtn.getAttribute('data-status') || '';
          if (typeof window.loadUserProspects === 'function') await window.loadUserProspects();
        });
      });
    }
  }

  function switchTab(tabName) {
    if (!tabName) tabName = 'find-businesses';
    state.currentTab = tabName;
    localStorage.setItem('bizz_hunter_current_tab', tabName);

    if (window.location.hash !== `#${tabName}`) {
      try {
        history.replaceState(null, '', `#${tabName}`);
      } catch (e) {
        // Safe fallback
      }
    }

    const dom = window.dom || state.dom;

    if (dom && dom.navItems) {
      dom.navItems.forEach(nav => {
        if (nav.getAttribute('data-tab') === tabName) {
          nav.classList.add('active');
        } else {
          nav.classList.remove('active');
        }
      });
    }

    if (dom && dom.views) {
      dom.views.forEach(view => {
        if (view.id === `view-${tabName}`) {
          view.classList.add('active');
        } else {
          view.classList.remove('active');
        }
      });
    }

    if (tabName === 'dashboard') {
      if (typeof window.renderDashboardAnalytics === 'function') window.renderDashboardAnalytics();
    } else if (tabName === 'analysis') {
      if (typeof window.renderAnalysisWorkspace === 'function') window.renderAnalysisWorkspace();
    } else if (tabName === 'saved-businesses') {
      if (typeof window.loadUserProspects === 'function') window.loadUserProspects();
    }
  }

  // Global exports for navigation & theme
  window.initTheme = initTheme;
  window.applyTheme = applyTheme;
  window.initNavigation = initNavigation;
  window.switchTab = switchTab;
})();
