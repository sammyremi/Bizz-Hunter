/* public/js/app.js - Bizz-Hunter Main Application Controller */

(function () {
  'use strict';

  // Application State
  const state = {
    currentTab: 'find-businesses',
    currentUser: null,
    currentQuota: null,
    searchResults: [],
    savedBusinesses: [],
    activeProspectStatusFilter: '',
    searchedCount: parseInt(localStorage.getItem('bizz_hunter_searched_count') || '0', 10),
    activeFilters: {},
    selectedPlaceId: null,
    selectedLocationName: '',
    selectedBusinessForModal: null,
    isSearching: false
  };

  // DOM Cache
  let dom = {};

  document.addEventListener('DOMContentLoaded', async () => {
    cacheDomElements();
    initNavigation();
    initLocationSelectors();
    initSearchForm();
    initModals();
    initAuth();

    await checkAuthSession();
    await fetchAndUpdateQuota();
  });

  function cacheDomElements() {
    dom = {
      navItems: document.querySelectorAll('.nav-item'),
      views: document.querySelectorAll('.view-section'),
      currentNavTitle: document.getElementById('current-nav-title'),
      mobileToggle: document.getElementById('mobile-nav-toggle'),
      sidebar: document.querySelector('.sidebar'),
      appWorkspace: document.getElementById('app-workspace'),

      // Auth Controls & Modal
      authModal: document.getElementById('auth-modal'),
      authModalTitle: document.getElementById('auth-modal-title'),
      authModalBanner: document.getElementById('auth-modal-banner'),
      authTabLogin: document.getElementById('auth-tab-login'),
      authTabRegister: document.getElementById('auth-tab-register'),
      authLoginBtn: document.getElementById('auth-login-btn'),
      authLogoutBtn: document.getElementById('auth-logout-btn'),
      loggedInUserContainer: document.getElementById('logged-in-user-container'),
      authUserName: document.getElementById('auth-user-name'),
      modalLoginForm: document.getElementById('modal-login-form'),
      modalRegisterForm: document.getElementById('modal-register-form'),
      modalLoginEmail: document.getElementById('modal-login-email'),
      modalLoginPassword: document.getElementById('modal-login-password'),
      modalRegisterName: document.getElementById('modal-register-name'),
      modalRegisterEmail: document.getElementById('modal-register-email'),
      modalRegisterPassword: document.getElementById('modal-register-password'),
      modalLoginSubmit: document.getElementById('modal-login-btn'),
      modalRegisterSubmit: document.getElementById('modal-register-btn'),
      modalAuthError: document.getElementById('modal-auth-error'),

      // Sidebar Profile Elements
      workspaceSidebarAvatar: document.getElementById('workspace-sidebar-avatar'),
      workspaceSidebarName: document.getElementById('workspace-sidebar-name'),
      workspaceSidebarEmail: document.getElementById('workspace-sidebar-email'),

      // Quota Elements
      headerQuotaBadge: document.getElementById('header-quota-badge'),
      headerQuotaText: document.getElementById('header-quota-text'),
      panelQuotaCard: document.getElementById('panel-quota-card'),
      panelQuotaCount: document.getElementById('panel-quota-count'),
      quotaUpgradeLink: document.getElementById('quota-upgrade-link'),
      errorQuotaSignupBtn: document.getElementById('error-quota-signup-btn'),

      // Form Controls & Smart Location Search
      locationSearchInput: document.getElementById('location-search-input'),
      locationSuggestionsDropdown: document.getElementById('location-suggestions-dropdown'),
      selectedLocationBadge: document.getElementById('selected-location-badge'),
      categorySelect: document.getElementById('category-select'),
      minRatingSelect: document.getElementById('min-rating-select'),
      phoneFilterSelect: document.getElementById('phone-filter-select'),
      websiteFilterSelect: document.getElementById('website-filter-select'),
      searchBtn: document.getElementById('search-btn'),
      searchForm: document.getElementById('search-form'),

      // Results Containers
      resultsHeader: document.getElementById('results-header'),
      resultsCount: document.getElementById('results-count'),
      resultsContext: document.getElementById('results-context'),
      activePills: document.getElementById('active-pills'),
      cardsGrid: document.getElementById('cards-grid'),
      loadingState: document.getElementById('loading-state'),
      emptyState: document.getElementById('empty-state'),
      errorState: document.getElementById('error-state'),
      errorMessage: document.getElementById('error-message'),

      // Saved Prospects & Status Tabs
      prospectStatusTabs: document.getElementById('prospect-status-tabs'),
      savedGrid: document.getElementById('saved-grid'),
      savedEmptyState: document.getElementById('saved-empty-state'),
      savedBadge: document.getElementById('saved-badge'),
      lockDashboard: document.getElementById('lock-dashboard'),
      lockSaved: document.getElementById('lock-saved'),

      // Modals
      detailsModal: document.getElementById('details-modal'),
      qrModal: document.getElementById('qr-modal'),
      detailsModalBody: document.getElementById('details-modal-body'),
      qrModalBody: document.getElementById('qr-modal-body'),

      // Dashboard Elements
      dashDiscovered: document.getElementById('dash-discovered'),
      dashOpps: document.getElementById('dash-opps'),
      dashNoWebsite: document.getElementById('dash-nowebsite'),
      dashPhoneAvailable: document.getElementById('dash-phone'),
      dashSaved: document.getElementById('dash-saved'),

      toastContainer: document.getElementById('toast-container')
    };
  }

  // --- Auth & Quota Controller ---
  function initAuth() {
    if (dom.authLoginBtn) {
      dom.authLoginBtn.addEventListener('click', () => {
        openAuthModal('login');
      });
    }

    if (dom.quotaUpgradeLink) {
      dom.quotaUpgradeLink.addEventListener('click', (e) => {
        e.preventDefault();
        openAuthModal('register', 'Sign up for a free account to unlock 50 searches per day!');
      });
    }

    if (dom.errorQuotaSignupBtn) {
      dom.errorQuotaSignupBtn.addEventListener('click', () => {
        openAuthModal('register', 'Sign up for a free account to get 50 searches per day!');
      });
    }

    if (dom.authTabLogin) {
      dom.authTabLogin.addEventListener('click', () => toggleAuthTab('login'));
    }

    if (dom.authTabRegister) {
      dom.authTabRegister.addEventListener('click', () => toggleAuthTab('register'));
    }

    if (dom.modalLoginForm) {
      dom.modalLoginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleModalLogin();
      });
    }

    if (dom.modalRegisterForm) {
      dom.modalRegisterForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleModalRegister();
      });
    }

    if (dom.authLogoutBtn) {
      dom.authLogoutBtn.addEventListener('click', () => {
        if (confirm('Are you sure you want to log out?')) {
          logoutUser();
        }
      });
    }
  }

  function openAuthModal(mode = 'login', bannerMsg = null) {
    toggleAuthTab(mode);
    clearAuthModalErrors();

    if (bannerMsg && dom.authModalBanner) {
      dom.authModalBanner.textContent = bannerMsg;
      dom.authModalBanner.style.display = 'block';
    } else if (dom.authModalBanner) {
      dom.authModalBanner.style.display = 'none';
    }

    if (dom.authModal) dom.authModal.classList.add('active');
  }

  function toggleAuthTab(mode) {
    clearAuthModalErrors();
    if (mode === 'login') {
      if (dom.authTabLogin) dom.authTabLogin.classList.add('active');
      if (dom.authTabRegister) dom.authTabRegister.classList.remove('active');
      if (dom.modalLoginForm) dom.modalLoginForm.style.display = 'block';
      if (dom.modalRegisterForm) dom.modalRegisterForm.style.display = 'none';
      if (dom.authModalTitle) dom.authModalTitle.textContent = 'Log In';
    } else {
      if (dom.authTabRegister) dom.authTabRegister.classList.add('active');
      if (dom.authTabLogin) dom.authTabLogin.classList.remove('active');
      if (dom.modalRegisterForm) dom.modalRegisterForm.style.display = 'block';
      if (dom.modalLoginForm) dom.modalLoginForm.style.display = 'none';
      if (dom.authModalTitle) dom.authModalTitle.textContent = 'Sign-Up';
    }
  }

  function showAuthModalError(msg) {
    if (dom.modalAuthError) {
      dom.modalAuthError.textContent = msg;
      dom.modalAuthError.style.display = 'block';
    }
  }

  function clearAuthModalErrors() {
    if (dom.modalAuthError) {
      dom.modalAuthError.textContent = '';
      dom.modalAuthError.style.display = 'none';
    }
  }

  async function checkAuthSession() {
    const user = await window.BizzApi.getMe();
    if (user) {
      setCurrentUser(user);
      await loadUserProspects();
    } else {
      setCurrentUser(null);
    }
  }

  function setCurrentUser(user) {
    state.currentUser = user;
    if (user) {
      if (dom.authLoginBtn) dom.authLoginBtn.style.display = 'none';
      if (dom.loggedInUserContainer) dom.loggedInUserContainer.style.display = 'flex';
      if (dom.authUserName) dom.authUserName.textContent = user.name;

      if (dom.workspaceSidebarName) dom.workspaceSidebarName.textContent = user.name;
      if (dom.workspaceSidebarEmail) dom.workspaceSidebarEmail.textContent = user.email;
      if (dom.workspaceSidebarAvatar) dom.workspaceSidebarAvatar.textContent = getInitials(user.name);

      if (dom.lockDashboard) dom.lockDashboard.style.display = 'none';
      if (dom.lockSaved) dom.lockSaved.style.display = 'none';
    } else {
      if (dom.authLoginBtn) dom.authLoginBtn.style.display = 'flex';
      if (dom.loggedInUserContainer) dom.loggedInUserContainer.style.display = 'none';

      if (dom.workspaceSidebarName) dom.workspaceSidebarName.textContent = 'Guest User';
      if (dom.workspaceSidebarEmail) dom.workspaceSidebarEmail.textContent = 'Sign in for 50 searches/day';
      if (dom.workspaceSidebarAvatar) dom.workspaceSidebarAvatar.textContent = 'BH';

      if (dom.lockDashboard) dom.lockDashboard.style.display = 'inline';
      if (dom.lockSaved) dom.lockSaved.style.display = 'inline';

      state.savedBusinesses = [];
      renderSavedCountBadge();
      updateDashboardMetrics();
    }
  }

  async function fetchAndUpdateQuota() {
    const quota = await window.BizzApi.getSearchQuota();
    if (quota) {
      updateQuotaUI(quota);
    }
  }

  function updateQuotaUI(quota) {
    if (!quota) return;
    state.currentQuota = quota;

    const isGuest = quota.user_type === 'guest';
    const remaining = quota.remaining;
    const limit = quota.limit;

    if (dom.headerQuotaBadge) {
      dom.headerQuotaBadge.className = `quota-badge ${isGuest ? 'guest' : 'user'}`;
    }

    if (dom.headerQuotaText) {
      dom.headerQuotaText.textContent = `${isGuest ? 'Guest' : 'Pro'}: ${remaining}/${limit} Left`;
    }

    if (dom.panelQuotaCount) {
      dom.panelQuotaCount.textContent = `${remaining}/${limit} Remaining`;
    }

    if (dom.quotaUpgradeLink) {
      dom.quotaUpgradeLink.style.display = isGuest ? 'inline' : 'none';
    }
  }

  async function handleModalLogin() {
    clearAuthModalErrors();
    const email = dom.modalLoginEmail.value.trim();
    const password = dom.modalLoginPassword.value;

    if (!email || !password) {
      showAuthModalError('Please fill out all fields.');
      return;
    }

    if (dom.modalLoginSubmit) dom.modalLoginSubmit.disabled = true;

    try {
      const res = await window.BizzApi.login({ email, password });
      if (res.success && res.user) {
        setCurrentUser(res.user);
        closeModals();
        showToast(`Welcome back, ${res.user.name}!`, 'success');
        await fetchAndUpdateQuota();
        await loadUserProspects();
      } else {
        showAuthModalError(res.message || 'Invalid email or password');
      }
    } catch (err) {
      showAuthModalError(err.message || 'Login failed.');
    } finally {
      if (dom.modalLoginSubmit) dom.modalLoginSubmit.disabled = false;
    }
  }

  async function handleModalRegister() {
    clearAuthModalErrors();
    const name = dom.modalRegisterName.value.trim();
    const email = dom.modalRegisterEmail.value.trim();
    const password = dom.modalRegisterPassword.value;

    if (!name || !email || !password) {
      showAuthModalError('Please fill out all fields.');
      return;
    }

    if (password.length < 6) {
      showAuthModalError('Password must be at least 6 characters.');
      return;
    }

    if (dom.modalRegisterSubmit) dom.modalRegisterSubmit.disabled = true;

    try {
      const res = await window.BizzApi.register({ name, email, password });
      if (res.success && res.user) {
        setCurrentUser(res.user);
        closeModals();
        showToast(`Account created! Welcome, ${res.user.name}!`, 'success');
        await fetchAndUpdateQuota();
        await loadUserProspects();
      } else {
        showAuthModalError(res.message || 'Registration failed.');
      }
    } catch (err) {
      showAuthModalError(err.message || 'Registration failed.');
    } finally {
      if (dom.modalRegisterSubmit) dom.modalRegisterSubmit.disabled = false;
    }
  }

  async function logoutUser() {
    await window.BizzApi.logout();
    setCurrentUser(null);
    showToast('Logged out successfully', 'info');
    await fetchAndUpdateQuota();
    switchTab('find-businesses');
  }

  // --- Navigation Controller ---
  function initNavigation() {
    dom.navItems.forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const tab = item.getAttribute('data-tab');
        if (!tab) return;

        // Protected feature gating: check auth requirement
        if (!state.currentUser && ['dashboard', 'saved-businesses', 'leads', 'analytics'].includes(tab)) {
          openAuthModal('login', `Account required to access ${capitalize(tab.replace('-', ' '))}. Sign up or log in to continue!`);
          return;
        }

        switchTab(tab);
      });
    });

    if (dom.mobileToggle) {
      dom.mobileToggle.addEventListener('click', () => {
        dom.sidebar.classList.toggle('open');
      });
    }

    if (dom.prospectStatusTabs) {
      dom.prospectStatusTabs.querySelectorAll('.status-tab').forEach(tabBtn => {
        tabBtn.addEventListener('click', async () => {
          dom.prospectStatusTabs.querySelectorAll('.status-tab').forEach(b => b.classList.remove('active'));
          tabBtn.classList.add('active');
          state.activeProspectStatusFilter = tabBtn.getAttribute('data-status') || '';
          await loadUserProspects();
        });
      });
    }
  }

  function switchTab(tabName) {
    state.currentTab = tabName;

    dom.navItems.forEach(nav => {
      if (nav.getAttribute('data-tab') === tabName) {
        nav.classList.add('active');
      } else {
        nav.classList.remove('active');
      }
    });

    dom.views.forEach(view => {
      if (view.id === `view-${tabName}`) {
        view.classList.add('active');
      } else {
        view.classList.remove('active');
      }
    });

    const titles = {
      'find-businesses': 'Find Businesses',
      'dashboard': 'Dashboard',
      'saved-businesses': 'My Prospects',
      'leads': 'Leads Pipeline',
      'analytics': 'Analytics',
      'settings': 'Settings'
    };

    if (dom.currentNavTitle) {
      dom.currentNavTitle.textContent = titles[tabName] || 'Find Businesses';
    }

    if (tabName === 'dashboard') {
      updateDashboardMetrics();
    } else if (tabName === 'saved-businesses') {
      loadUserProspects();
    }

    if (window.innerWidth <= 768 && dom.sidebar) {
      dom.sidebar.classList.remove('open');
    }
  }

  // --- Google Places Smart Location Search Controller ---
  let searchTimeout = null;

  function initLocationSelectors() {
    if (!dom.locationSearchInput || !dom.locationSuggestionsDropdown) return;

    dom.locationSearchInput.addEventListener('input', () => {
      clearTimeout(searchTimeout);
      const query = dom.locationSearchInput.value.trim();

      if (query.length < 2) {
        dom.locationSuggestionsDropdown.style.display = 'none';
        dom.locationSuggestionsDropdown.innerHTML = '';
        return;
      }

      searchTimeout = setTimeout(async () => {
        const predictions = await window.BizzApi.getAutocompleteLocations(query);
        renderLocationSuggestions(predictions);
      }, 250);
    });

    document.addEventListener('click', (e) => {
      if (!dom.locationSearchInput.contains(e.target) && !dom.locationSuggestionsDropdown.contains(e.target)) {
        dom.locationSuggestionsDropdown.style.display = 'none';
      }
    });
  }

  function renderLocationSuggestions(predictions) {
    if (!predictions || predictions.length === 0) {
      dom.locationSuggestionsDropdown.innerHTML = `<div class="suggestion-item"><span style="color: var(--text-dim);">No place predictions found</span></div>`;
      dom.locationSuggestionsDropdown.style.display = 'block';
      return;
    }

    dom.locationSuggestionsDropdown.innerHTML = predictions.map(p => {
      return `
        <div class="suggestion-item" data-id="${p.place_id}" data-address="${escapeHtml(p.formatted_address)}" data-name="${escapeHtml(p.name)}">
          <div>
            <strong>${escapeHtml(p.main_text || p.name)}</strong>
            <div class="suggestion-meta">${escapeHtml(p.secondary_text || p.formatted_address)}</div>
          </div>
          <span style="font-size: 0.8rem; background: var(--primary-light); color: var(--primary); padding: 2px 6px; border-radius: 4px;">Place</span>
        </div>
      `;
    }).join('');

    dom.locationSuggestionsDropdown.style.display = 'block';

    dom.locationSuggestionsDropdown.querySelectorAll('.suggestion-item').forEach(item => {
      item.addEventListener('click', () => {
        const placeId = item.getAttribute('data-id');
        const formattedAddress = item.getAttribute('data-address');

        selectLocation(placeId, formattedAddress);
      });
    });
  }

  function selectLocation(placeId, formattedAddress) {
    state.selectedPlaceId = placeId;
    state.selectedLocationName = formattedAddress;

    dom.locationSearchInput.value = formattedAddress;
    dom.locationSuggestionsDropdown.style.display = 'none';

    if (dom.selectedLocationBadge) {
      dom.selectedLocationBadge.innerHTML = `
        <span>📍 ${escapeHtml(formattedAddress)}</span>
        <button type="button" class="remove-loc-btn" title="Clear Location">&times;</button>
      `;
      dom.selectedLocationBadge.style.display = 'inline-flex';

      dom.selectedLocationBadge.querySelector('.remove-loc-btn').addEventListener('click', () => {
        clearSelectedLocation();
      });
    }
  }

  function clearSelectedLocation() {
    state.selectedPlaceId = null;
    state.selectedLocationName = '';
    dom.locationSearchInput.value = '';
    if (dom.selectedLocationBadge) {
      dom.selectedLocationBadge.style.display = 'none';
      dom.selectedLocationBadge.innerHTML = '';
    }
  }

  // --- Search Controller ---
  function initSearchForm() {
    if (dom.searchForm) {
      dom.searchForm.addEventListener('submit', (e) => {
        e.preventDefault();
        executeSearch();
      });
    }

    if (dom.searchBtn) {
      dom.searchBtn.addEventListener('click', (e) => {
        e.preventDefault();
        executeSearch();
      });
    }
  }

  async function executeSearch() {
    if (state.isSearching) return;

    const locationName = state.selectedLocationName || dom.locationSearchInput.value.trim();

    if (!locationName) {
      showToast('Please search and select a location first', 'error');
      return;
    }

    const params = {
      place_id: state.selectedPlaceId,
      location_name: locationName,
      business_type: dom.categorySelect.value,
      min_rating: dom.minRatingSelect.value,
      has_phone: dom.phoneFilterSelect.value,
      has_website: dom.websiteFilterSelect.value
    };

    if (!params.business_type) {
      showToast('Please select or enter a business category', 'error');
      return;
    }

    state.isSearching = true;
    state.activeFilters = params;
    showLoadingState();

    try {
      const res = await window.BizzApi.searchBusinesses(params);
      state.searchResults = res.data;
      state.searchedCount += res.data.length;
      localStorage.setItem('bizz_hunter_searched_count', state.searchedCount.toString());

      if (res.quota) {
        updateQuotaUI(res.quota);
      }

      if (res.data.length === 0) {
        showEmptyState();
      } else {
        renderResults(res.data, params);
      }
    } catch (err) {
      if (err.status === 429) {
        if (err.quota) updateQuotaUI(err.quota);
        showErrorState(err.message || 'Daily guest search limit reached.');
        if (dom.errorQuotaSignupBtn) dom.errorQuotaSignupBtn.style.display = 'block';
        openAuthModal('register', 'Daily guest search limit reached (5/5). Create a free account for 50 searches per day!');
      } else {
        showErrorState(err.message || 'Unable to connect to Google Places API backend.');
        if (dom.errorQuotaSignupBtn) dom.errorQuotaSignupBtn.style.display = 'none';
      }
    } finally {
      state.isSearching = false;
    }
  }

  function showLoadingState() {
    dom.resultsHeader.style.display = 'none';
    dom.cardsGrid.style.display = 'none';
    dom.emptyState.style.display = 'none';
    dom.errorState.style.display = 'none';
    dom.loadingState.style.display = 'grid';

    dom.searchBtn.disabled = true;
    dom.searchBtn.innerHTML = '<span class="spinner"></span> Searching...';
  }

  function renderResults(businesses, params) {
    dom.loadingState.style.display = 'none';
    dom.emptyState.style.display = 'none';
    dom.errorState.style.display = 'none';
    dom.resultsHeader.style.display = 'flex';
    dom.cardsGrid.style.display = 'grid';

    dom.searchBtn.disabled = false;
    dom.searchBtn.innerHTML = '🔍 Find Businesses';

    dom.resultsCount.textContent = businesses.length;
    dom.resultsContext.textContent = `${capitalize(params.business_type)}s in ${params.location_name}`;

    // Render Pills
    const pills = [];
    pills.push(`📍 ${params.location_name}`);
    if (params.min_rating) pills.push(`★ ${params.min_rating}+ Rating`);
    if (params.has_phone === 'true') pills.push('📞 Phone Available');
    if (params.has_website === 'false') pills.push('🌐 No Website (Opportunity)');
    if (params.has_website === 'true') pills.push('🌐 Has Website');

    dom.activePills.innerHTML = pills.map(p => `<span class="filter-pill">${p}</span>`).join('');

    // Render Cards
    dom.cardsGrid.innerHTML = businesses.map(b => createBusinessCardHtml(b)).join('');
    attachCardEventListeners();
  }

  function showEmptyState() {
    dom.loadingState.style.display = 'none';
    dom.resultsHeader.style.display = 'none';
    dom.cardsGrid.style.display = 'none';
    dom.errorState.style.display = 'none';
    dom.emptyState.style.display = 'block';

    dom.searchBtn.disabled = false;
    dom.searchBtn.innerHTML = '🔍 Find Businesses';
  }

  function showErrorState(msg) {
    dom.loadingState.style.display = 'none';
    dom.resultsHeader.style.display = 'none';
    dom.cardsGrid.style.display = 'none';
    dom.emptyState.style.display = 'none';
    dom.errorState.style.display = 'block';
    dom.errorMessage.textContent = msg;

    dom.searchBtn.disabled = false;
    dom.searchBtn.innerHTML = '🔍 Find Businesses';
  }

  // --- Business Card Component HTML ---
  function createBusinessCardHtml(b, isProspectView = false) {
    const placeId = b.google_place_id || b.id;
    const isSaved = state.savedBusinesses.some(saved => saved.google_place_id === placeId || saved.id === placeId);
    const hasWebsite = Boolean(b.website);
    const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';
    const hasPhone = Boolean(rawPhone);
    const formattedPhone = b.national_phone || b.international_phone_number || b.phone || b.phone_number || 'Phone unavailable';

    // WhatsApp URL generation
    const cleanPhone = rawPhone.replace(/[^\d+]/g, '').replace('+', '');
    const waText = encodeURIComponent(`Hello ${b.name || b.business_name}, I found your business on Bizz-Hunter and wanted to get in touch.`);
    const waUrl = cleanPhone ? `https://wa.me/${cleanPhone}?text=${waText}` : null;

    // Opportunity Signals & Score
    const oppLevel = b.opportunity_level || 'HIGH';
    const oppSignals = b.opportunity_signals || [
      !hasWebsite ? '🚨 No website (Direct digital opportunity)' : '🌐 Website active',
      hasPhone ? '📞 Direct phone line available' : 'Phone line unavailable'
    ];

    const levelColor = oppLevel === 'HIGH' ? '#ef4444' : (oppLevel === 'MEDIUM' ? '#f59e0b' : '#3b82f6');

    return `
      <div class="business-card" data-id="${placeId}" data-db-id="${b.id || ''}">
        <div class="card-top">
          <div class="card-title-row">
            <h3 class="business-name">${escapeHtml(b.name || b.business_name)}</h3>
            <div class="rating-badge">
              <span>★</span> ${b.rating ? Number(b.rating).toFixed(1) : 'N/A'}
            </div>
          </div>
          <div class="review-count">${b.review_count ? `${b.review_count} Google reviews` : 'No reviews yet'}</div>
        </div>

        <div class="business-meta">
          <div class="meta-item">
            <span class="icon">📍</span>
            <span>${escapeHtml(b.address || 'Address unavailable')}</span>
          </div>
          <div class="meta-item">
            <span class="icon">📞</span>
            <span>${escapeHtml(formattedPhone)}</span>
          </div>
          <div class="meta-item">
            <span class="icon">🌐</span>
            <span>${hasWebsite ? `<a href="${b.website}" target="_blank" rel="noopener">${escapeHtml(b.website)}</a>` : '<span style="color: #ef4444; font-weight: 600;">No website found</span>'}</span>
          </div>
        </div>

        <!-- Opportunity Signals Box -->
        <div style="background: rgba(255, 255, 255, 0.03); border: 1px solid var(--border-color); border-radius: var(--radius-sm); padding: 0.6rem 0.75rem; margin-bottom: 0.85rem;">
          <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.35rem;">
            <span style="font-size: 0.75rem; font-weight: 700; color: var(--text-muted); text-transform: uppercase;">Opportunity Signal</span>
            <span style="font-size: 0.75rem; font-weight: 800; color: ${levelColor}; background: rgba(255, 255, 255, 0.08); padding: 1px 6px; border-radius: 4px;">${oppLevel}</span>
          </div>
          <div style="font-size: 0.8rem; color: var(--text-main); display: flex; flex-direction: column; gap: 2px;">
            ${oppSignals.slice(0, 3).map(sig => `<div>• ${escapeHtml(sig)}</div>`).join('')}
          </div>
        </div>

        ${isProspectView ? `
          <!-- Prospect Status & Notes Controls -->
          <div style="background: var(--bg-surface-elevated); border: 1px solid var(--border-color); border-radius: var(--radius-sm); padding: 0.75rem; margin-bottom: 0.85rem; display: flex; flex-direction: column; gap: 0.6rem;">
            <div style="display: flex; align-items: center; justify-content: space-between; gap: 0.5rem;">
              <label style="font-size: 0.8rem; font-weight: 700; color: var(--text-muted);">Status:</label>
              <select class="form-select prospect-status-select" data-id="${b.id}" style="padding: 0.25rem 0.5rem; font-size: 0.825rem; width: auto;">
                <option value="NEW" ${b.status === 'NEW' ? 'selected' : ''}>🆕 New</option>
                <option value="CONTACTED" ${b.status === 'CONTACTED' ? 'selected' : ''}>💬 Contacted</option>
                <option value="INTERESTED" ${b.status === 'INTERESTED' ? 'selected' : ''}>🔥 Interested</option>
                <option value="CONVERTED" ${b.status === 'CONVERTED' ? 'selected' : ''}>🎉 Converted</option>
                <option value="NOT_INTERESTED" ${b.status === 'NOT_INTERESTED' ? 'selected' : ''}>🚫 Not Interested</option>
              </select>
            </div>

            <div style="display: flex; gap: 0.4rem;">
              <input type="text" class="form-control prospect-notes-input" data-id="${b.id}" placeholder="Add notes (e.g. Spoke to manager)..." value="${escapeHtml(b.notes || '')}" style="font-size: 0.8rem; padding: 0.35rem 0.5rem;">
              <button type="button" class="btn btn-secondary btn-sm save-notes-btn" data-id="${b.id}" style="white-space: nowrap; padding: 0.35rem 0.6rem;">Save Note</button>
            </div>
          </div>
        ` : ''}

        <div class="card-actions">
          ${waUrl ? `
            <a href="${waUrl}" target="_blank" rel="noopener" class="btn btn-whatsapp btn-sm wa-link-btn" data-id="${b.id || ''}">
              <span>💬</span> WhatsApp
            </a>
            <button class="icon-btn qr-btn" title="Scan WhatsApp QR Code" data-id="${placeId}">
              <span>📱</span>
            </button>
          ` : `
            <button class="btn btn-secondary btn-sm" disabled>No Phone</button>
          `}

          ${b.google_maps_url ? `
            <a href="${b.google_maps_url}" target="_blank" rel="noopener" class="icon-btn" title="Open Google Maps">
              <span>🗺️</span>
            </a>
          ` : ''}

          ${isProspectView ? `
            <button class="icon-btn remove-prospect-btn" title="Delete Prospect" data-id="${b.id}" style="color: #ef4444;">
              <span>🗑️</span>
            </button>
          ` : `
            <button class="icon-btn save-btn ${isSaved ? 'saved' : ''}" title="${isSaved ? 'Saved in Prospects' : 'Save Prospect'}" data-id="${placeId}">
              <span>${isSaved ? '❤️' : '🤍'}</span>
            </button>
          `}

          <button class="btn btn-secondary btn-sm details-btn" style="margin-left: auto;" data-id="${placeId}">
            Details
          </button>
        </div>
      </div>
    `;
  }

  function attachCardEventListeners() {
    // QR Code modal
    document.querySelectorAll('.qr-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const b = state.searchResults.find(item => item.id === id || item.google_place_id === id) ||
                  state.savedBusinesses.find(item => item.google_place_id === id || item.id === id);
        if (b) openQrModal(b);
      });
    });

    // Save prospect button
    document.querySelectorAll('.save-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        const id = btn.getAttribute('data-id');
        const b = state.searchResults.find(item => item.id === id || item.google_place_id === id);
        if (b) await toggleSaveBusiness(b);
      });
    });

    // Details modal
    document.querySelectorAll('.details-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const b = state.searchResults.find(item => item.id === id || item.google_place_id === id) ||
                  state.savedBusinesses.find(item => item.google_place_id === id || String(item.id) === String(id));
        if (b) openDetailsModal(b);
      });
    });

    // Prospect Status Dropdown Change
    document.querySelectorAll('.prospect-status-select').forEach(select => {
      select.addEventListener('change', async () => {
        const dbId = select.getAttribute('data-id');
        const newStatus = select.value;
        try {
          await window.BizzApi.updateProspect(dbId, { status: newStatus });
          showToast(`Status updated to ${newStatus}`, 'success');
          await loadUserProspects();
        } catch (err) {
          showToast(err.message || 'Failed to update status', 'error');
        }
      });
    });

    // Prospect Notes Save
    document.querySelectorAll('.save-notes-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        const dbId = btn.getAttribute('data-id');
        const input = document.querySelector(`.prospect-notes-input[data-id="${dbId}"]`);
        const notes = input ? input.value.trim() : '';

        try {
          await window.BizzApi.updateProspect(dbId, { notes: notes });
          showToast('Note saved successfully', 'success');
        } catch (err) {
          showToast(err.message || 'Failed to save note', 'error');
        }
      });
    });

    // Delete Prospect
    document.querySelectorAll('.remove-prospect-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        const dbId = btn.getAttribute('data-id');
        if (confirm('Are you sure you want to delete this prospect?')) {
          try {
            await window.BizzApi.deleteProspect(dbId);
            showToast('Prospect deleted', 'info');
            await loadUserProspects();
          } catch (err) {
            showToast(err.message || 'Failed to delete prospect', 'error');
          }
        }
      });
    });
  }

  // --- Prospects Backend Persistence Controller ---
  async function toggleSaveBusiness(business) {
    if (!state.currentUser) {
      openAuthModal('login', 'Sign in or create a free account to save prospects to your list!');
      return;
    }

    const placeId = business.id || business.google_place_id;
    const existing = state.savedBusinesses.find(p => p.google_place_id === placeId);

    if (existing) {
      try {
        await window.BizzApi.deleteProspect(existing.id);
        showToast(`Removed "${business.name || business.business_name}" from prospects`, 'info');
        await loadUserProspects();
      } catch (err) {
        showToast(err.message || 'Failed to remove prospect', 'error');
      }
    } else {
      try {
        await window.BizzApi.saveProspect(business);
        showToast(`Saved "${business.name || business.business_name}" to your prospects!`, 'success');
        await loadUserProspects();
      } catch (err) {
        showToast(err.message || 'Failed to save prospect', 'error');
      }
    }

    if (state.currentTab === 'find-businesses' && state.searchResults.length > 0) {
      renderResults(state.searchResults, state.activeFilters);
    }
  }

  async function loadUserProspects() {
    if (!state.currentUser) {
      state.savedBusinesses = [];
      renderSavedCountBadge();
      renderSavedBusinessesView();
      return;
    }

    try {
      const prospects = await window.BizzApi.getProspects(state.activeProspectStatusFilter);
      state.savedBusinesses = prospects;
      renderSavedCountBadge();
      updateDashboardMetrics();

      if (state.currentTab === 'saved-businesses') {
        renderSavedBusinessesView();
      }
    } catch (err) {
      console.warn('Error loading user prospects', err);
    }
  }

  function renderSavedCountBadge() {
    if (dom.savedBadge) {
      dom.savedBadge.textContent = state.savedBusinesses.length;
    }
  }

  function renderSavedBusinessesView() {
    if (!dom.savedGrid) return;

    if (!state.currentUser) {
      dom.savedGrid.style.display = 'none';
      dom.savedEmptyState.style.display = 'block';
      dom.savedEmptyState.querySelector('.empty-title').textContent = 'Account Required';
      dom.savedEmptyState.querySelector('.empty-desc').textContent = 'Sign up or log in to view and manage your saved business prospects.';
      return;
    }

    if (state.savedBusinesses.length === 0) {
      dom.savedGrid.style.display = 'none';
      dom.savedEmptyState.style.display = 'block';
      dom.savedEmptyState.querySelector('.empty-title').textContent = 'No Saved Prospects Found';
      dom.savedEmptyState.querySelector('.empty-desc').textContent = 'When discovering businesses, click the ❤️ icon on any card to save it here.';
    } else {
      dom.savedEmptyState.style.display = 'none';
      dom.savedGrid.style.display = 'grid';
      dom.savedGrid.innerHTML = state.savedBusinesses.map(b => createBusinessCardHtml(b, true)).join('');
      attachCardEventListeners();
    }
  }

  // --- Modals Controller ---
  function initModals() {
    document.querySelectorAll('.modal-close, .modal-overlay').forEach(el => {
      el.addEventListener('click', (e) => {
        if (e.target === el || el.classList.contains('modal-close')) {
          closeModals();
        }
      });
    });
  }

  function closeModals() {
    if (dom.authModal) dom.authModal.classList.remove('active');
    if (dom.detailsModal) dom.detailsModal.classList.remove('active');
    if (dom.qrModal) dom.qrModal.classList.remove('active');
  }

  function openDetailsModal(b) {
    const name = b.name || b.business_name;
    const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';
    const cleanPhone = rawPhone.replace(/[^\d+]/g, '').replace('+', '');
    const waText = encodeURIComponent(`Hello ${name}, I found your business on Bizz-Hunter and wanted to get in touch.`);
    const waUrl = cleanPhone ? `https://wa.me/${cleanPhone}?text=${waText}` : null;

    dom.detailsModalBody.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem;">
        <div>
          <h2 style="font-size: 1.4rem; font-weight: 800; margin-bottom: 0.25rem;">${escapeHtml(name)}</h2>
          <div style="color: var(--text-muted); font-size: 0.9rem;">${b.types ? (Array.isArray(b.types) ? b.types.slice(0, 3).join(' • ') : b.types) : (b.category || 'Business')}</div>
        </div>
        <div class="rating-badge" style="font-size: 1rem; padding: 4px 10px;">
          ★ ${b.rating ? Number(b.rating).toFixed(1) : 'N/A'}
        </div>
      </div>

      <div style="background: var(--bg-surface); border: 1px solid var(--border-color); padding: 1rem; border-radius: var(--radius-md); margin-bottom: 1.25rem; font-size: 0.9rem; display: flex; flex-direction: column; gap: 0.5rem;">
        <div><strong>Address:</strong> ${escapeHtml(b.address || 'Unavailable')}</div>
        <div><strong>Phone (International):</strong> ${escapeHtml(b.phone || b.phone_number || 'Unavailable')}</div>
        <div><strong>Phone (National):</strong> ${escapeHtml(b.national_phone || b.international_phone_number || 'Unavailable')}</div>
        <div><strong>Website:</strong> ${b.website ? `<a href="${b.website}" target="_blank">${escapeHtml(b.website)}</a>` : '<span style="color: #ef4444; font-weight: 600;">No Website (Lead Opportunity)</span>'}</div>
        ${b.latitude && b.longitude ? `<div><strong>Coordinates:</strong> ${Number(b.latitude).toFixed(5)}, ${Number(b.longitude).toFixed(5)}</div>` : ''}
      </div>

      <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
        ${waUrl ? `<a href="${waUrl}" target="_blank" class="btn btn-whatsapp btn-block">💬 Contact on WhatsApp</a>` : ''}
        ${rawPhone ? `<a href="tel:${rawPhone}" class="btn btn-secondary btn-block">📞 Direct Phone Call</a>` : ''}
        ${b.google_maps_url ? `<a href="${b.google_maps_url}" target="_blank" class="btn btn-secondary btn-block">🗺️ Open in Google Maps</a>` : ''}
      </div>
    `;

    dom.detailsModal.classList.add('active');
  }

  function openQrModal(b) {
    const name = b.name || b.business_name;
    const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';
    const cleanPhone = rawPhone.replace(/[^\d+]/g, '').replace('+', '');
    const waText = encodeURIComponent(`Hello ${name}, I found your business on Bizz-Hunter.`);
    const waUrl = `https://wa.me/${cleanPhone}?text=${waText}`;

    const svgQr = window.QRCodeGenerator ? window.QRCodeGenerator(waUrl, { size: 240, colorDark: '#0b0f19', colorLight: '#ffffff' }) : '';

    dom.qrModalBody.innerHTML = `
      <div style="text-align: center;">
        <h3 style="font-size: 1.2rem; font-weight: 700; margin-bottom: 0.25rem;">${escapeHtml(name)}</h3>
        <p style="color: var(--text-muted); font-size: 0.85rem; margin-bottom: 1rem;">Scan to open WhatsApp contact link</p>

        <div class="qr-container">
          ${svgQr}
          <div class="qr-caption">Scan with Phone Camera or WhatsApp</div>
        </div>

        <div style="font-size: 0.85rem; color: var(--text-dim); margin-top: 1rem; word-break: break-all;">
          ${waUrl}
        </div>
      </div>
    `;

    dom.qrModal.classList.add('active');
  }

  // --- Dashboard Metrics ---
  function updateDashboardMetrics() {
    const noWebsiteCount = state.searchResults.filter(b => !b.website).length;
    const phoneCount = state.searchResults.filter(b => b.phone || b.phone_number || b.national_phone).length;
    const oppsCount = state.searchResults.filter(b => !b.website || (b.phone || b.phone_number)).length;

    if (dom.dashDiscovered) dom.dashDiscovered.textContent = state.searchedCount;
    if (dom.dashOpps) dom.dashOpps.textContent = oppsCount;
    if (dom.dashNoWebsite) dom.dashNoWebsite.textContent = noWebsiteCount;
    if (dom.dashPhoneAvailable) dom.dashPhoneAvailable.textContent = phoneCount;
    if (dom.dashSaved) dom.dashSaved.textContent = state.savedBusinesses.length;
  }

  // --- Toast System ---
  function showToast(message, type = 'info') {
    if (!dom.toastContainer) return;
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `<span>${type === 'success' ? '✅' : (type === 'error' ? '⚠️' : 'ℹ️')}</span> <span>${escapeHtml(message)}</span>`;

    dom.toastContainer.appendChild(toast);
    setTimeout(() => {
      toast.remove();
    }, 4000);
  }

  // Helpers
  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function capitalize(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  function getInitials(name) {
    if (!name) return 'U';
    const parts = name.trim().split(' ');
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return parts[0][0].toUpperCase();
  }

})();
