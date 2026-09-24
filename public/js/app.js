/* public/js/app.js - Bizz-Hunter Application Entry Point & Coordinator */

(function () {
  'use strict';

  console.log('BIZZ-HUNTER APP COORDINATOR LOADED v20260908_v2');

  const state = window.BizzState;

  document.addEventListener('DOMContentLoaded', async () => {
    window.cacheDomElements();
    initTheme();
    initNavigation();
    if (typeof window.initLandingPage === 'function') window.initLandingPage();
    if (typeof window.initLocationSelectors === 'function') window.initLocationSelectors();
    if (typeof window.initBusinessTypeAutocomplete === 'function') window.initBusinessTypeAutocomplete();
    if (typeof window.initSearchForm === 'function') window.initSearchForm();
    if (typeof window.initModals === 'function') window.initModals();
    if (typeof window.initAuth === 'function') window.initAuth();
    if (typeof window.initProfiles === 'function') window.initProfiles();
    if (typeof window.initOnboarding === 'function') window.initOnboarding();
    if (typeof window.initProfileSelector === 'function') window.initProfileSelector();
    if (typeof window.initSettingsPage === 'function') window.initSettingsPage();

    // Check Auth Session first to determine auth state & destination view
    if (typeof window.checkAuthSession === 'function') {
      await window.checkAuthSession();
    } else {
      const rawHash = window.location.hash ? window.location.hash.replace('#', '') : null;
      const initialTab = mapRouteAlias(rawHash) || 'landing';
      switchTab(initialTab);
    }

    if (typeof window.fetchAndUpdateQuota === 'function') await window.fetchAndUpdateQuota();
  });

  function mapRouteAlias(route) {
    if (!route) return null;
    if (route === 'discovery') return 'find-businesses';
    if (route === 'prospects') return 'saved-businesses';
    if (route === 'profiles') return 'prospecting-profiles';
    if (route === 'analytics') return 'analysis';
    return route;
  }

  window.addEventListener('hashchange', () => {
    const rawHash = window.location.hash ? window.location.hash.replace('#', '') : null;
    const hashTab = mapRouteAlias(rawHash);
    if (!hashTab) return;

    const validTabs = ['landing', 'login', 'register', 'find-businesses', 'prospecting-profiles', 'dashboard', 'saved-businesses', 'analysis', 'settings'];
    if (validTabs.includes(hashTab)) {
      if (state.currentUser && ['landing', 'login', 'register'].includes(hashTab)) {
        switchTab('find-businesses');
        return;
      }
      if (!state.currentUser && ['prospecting-profiles', 'dashboard', 'saved-businesses', 'analysis', 'settings', 'find-businesses'].includes(hashTab)) {
        const dest = (hashTab === 'login' || hashTab === 'register') ? hashTab : 'landing';
        switchTab(dest);
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

    const thumb = document.getElementById('theme-switch-thumb');
    if (thumb) {
      thumb.style.transform = themeName === 'light' ? 'translateX(16px)' : 'translateX(0)';
    }
  }

  // --- Navigation Controller ---
  function initNavigation() {
    const dom = window.dom || state.dom;
    
    // Bind all top nav items
    document.querySelectorAll('.top-nav-item, [data-tab]').forEach(item => {
      item.addEventListener('click', (e) => {
        const tab = item.getAttribute('data-tab') || item.getAttribute('href')?.replace('#', '');
        if (!tab || tab.startsWith('landing-')) return;
        e.preventDefault();

        const mapped = mapRouteAlias(tab) || tab;
        if (!state.currentUser && ['prospecting-profiles', 'dashboard', 'saved-businesses', 'analysis', 'settings', 'find-businesses'].includes(mapped)) {
          switchTab('login');
          return;
        }

        switchTab(mapped);
        const authNav = document.getElementById('authenticated-nav');
        if (authNav) authNav.classList.remove('mobile-open');
      });
    });

    if (dom && dom.mobileMenuTrigger) {
      dom.mobileMenuTrigger.addEventListener('click', () => {
        const authNav = document.getElementById('authenticated-nav');
        const publicNav = document.getElementById('public-nav');
        if (state.currentUser && authNav) {
          authNav.classList.toggle('mobile-open');
        } else if (publicNav) {
          publicNav.classList.toggle('mobile-open');
        }
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
    tabName = mapRouteAlias(tabName) || tabName || 'landing';

    const isAuthenticated = Boolean(state.currentUser);

    // Strict authentication route guards
    if (isAuthenticated && ['landing', 'login', 'register'].includes(tabName)) {
      tabName = 'find-businesses';
    } else if (!isAuthenticated && ['find-businesses', 'saved-businesses', 'prospecting-profiles', 'dashboard', 'analysis', 'settings'].includes(tabName)) {
      tabName = (tabName === 'login' || tabName === 'register') ? tabName : 'landing';
    }

    state.currentTab = tabName;
    localStorage.setItem('bizz_hunter_current_tab', tabName);

    let routeHash = tabName;
    if (tabName === 'find-businesses') routeHash = 'discovery';
    if (tabName === 'saved-businesses') routeHash = 'prospects';
    if (tabName === 'prospecting-profiles') routeHash = 'profiles';
    if (tabName === 'analysis') routeHash = 'analytics';

    if (window.location.hash !== `#${routeHash}`) {
      try {
        history.replaceState(null, '', `#${routeHash}`);
      } catch (e) {
        // Safe fallback
      }
    }

    // Update Top Navigation Bar Link Active Classes
    document.querySelectorAll('.top-nav-item').forEach(nav => {
      const navTab = nav.getAttribute('data-tab');
      if (navTab === tabName || mapRouteAlias(navTab) === tabName) {
        nav.classList.add('active');
      } else {
        nav.classList.remove('active');
      }
    });

    // Toggle Section View Visibility (Only the active section is rendered)
    document.querySelectorAll('.view-section').forEach(view => {
      if (view.id === `view-${tabName}`) {
        view.classList.add('active');
        view.style.display = 'block';
      } else {
        view.classList.remove('active');
        view.style.display = 'none';
      }
    });

    // Trigger tab-specific initialization hooks
    if (tabName === 'dashboard') {
      if (typeof window.renderDashboardAnalytics === 'function') window.renderDashboardAnalytics();
    } else if (tabName === 'analysis') {
      if (typeof window.renderAnalysisWorkspace === 'function') window.renderAnalysisWorkspace();
    } else if (tabName === 'saved-businesses') {
      if (typeof window.loadUserProspects === 'function') window.loadUserProspects();
    } else if (tabName === 'prospecting-profiles') {
      if (typeof window.loadProfiles === 'function') window.loadProfiles();
    } else if (tabName === 'settings') {
      if (typeof window.loadUserSettingsData === 'function') window.loadUserSettingsData();
    }

    if (typeof window.updateDiscoveryBannerVisibility === 'function') {
      window.updateDiscoveryBannerVisibility();
    }
  }

  function updateHeaderTitles(tabName) {
    const dom = window.dom || state.dom;
    if (!dom || !dom.headerViewTitle || !dom.headerViewSub) return;

    const titles = {
      'find-businesses': { title: 'Discovery', sub: 'Find businesses that match your prospecting profile' },
      'saved-businesses': { title: 'My Prospects', sub: 'Track saved prospects, review briefs, and execute outreach' },
      'prospecting-profiles': { title: 'Prospecting Profiles', sub: 'Define what you offer and what makes a business worth contacting' },
      'analysis': { title: 'Business Intelligence & Analytics', sub: 'Calculated metrics and opportunity scoring overview' },
      'dashboard': { title: 'Dashboard Overview', sub: 'High-level lead opportunity analytics' },
      'settings': { title: 'Settings', sub: 'Manage account details, AI outreach preferences, appearance, and sign out' }
    };

    const info = titles[tabName] || { title: 'Workspace', sub: 'Bizz-Hunter B2B SaaS Platform' };
    dom.headerViewTitle.textContent = info.title;
    dom.headerViewSub.textContent = info.sub;
  }

  // Global exports for navigation & theme
  window.initTheme = initTheme;
  window.applyTheme = applyTheme;
  window.initNavigation = initNavigation;
  window.switchTab = switchTab;
  window.mapRouteAlias = mapRouteAlias;
})();
