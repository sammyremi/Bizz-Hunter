/* public/js/app.js - Bizz-Hunter Main Application Controller & Search Engine */

(function () {
  'use strict';

  // Popular Predefined Business Types for Autocomplete Suggestions
  const PREDEFINED_BUSINESS_TYPES = [
    'Restaurant', 'Restaurants', 'Fast Food Restaurant', 'Fine Dining Restaurant',
    'Chinese Restaurant', 'Italian Restaurant', 'Mexican Restaurant', 'African Restaurant',
    'Hotel', 'Hotels', 'Resort', 'Bed & Breakfast', 'Motel',
    'Cafe', 'Coffee Shop', 'Bakery',
    'Bar', 'Bars', 'Barber', 'Barbershop', 'Beauty Bar', 'Beauty Salon', 'Hair Salon', 'Spa', 'Nail Salon',
    'Gym', 'Fitness Center', 'Yoga Studio', 'CrossFit Gym',
    'Car Dealer', 'Car Rental', 'Car Repair', 'Car Wash', 'Auto Parts Store',
    'Hospital', 'Medical Clinic', 'Dental Clinic', 'Pharmacy',
    'School', 'College', 'University', 'Tutoring Center',
    'Real Estate Agency', 'Property Management', 'Real Estate Agent',
    'Solar Installation', 'Solar Company', 'Roofing Contractor', 'Construction Company',
    'Supermarket', 'Grocery Store', 'Boutique', 'Shopping Mall',
    'Law Firm', 'Lawyer', 'Accounting Firm', 'Consulting Agency',
    'Plumbing Service', 'Electrician', 'Pest Control Service'
  ];

  // Application State
  const state = {
    theme: localStorage.getItem('bizz_hunter_theme') || 'dark',
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
    isSearching: false,
    selectedBusinessTypeIndex: -1
  };

  // DOM Cache
  let dom = {};

  document.addEventListener('DOMContentLoaded', async () => {
    cacheDomElements();
    initTheme();
    initNavigation();
    initLocationSelectors();
    initBusinessTypeAutocomplete();
    initSearchForm();
    initModals();
    initAuth();

    await checkAuthSession();
    await fetchAndUpdateQuota();
  });

  function cacheDomElements() {
    dom = {
      navItems: document.querySelectorAll('.top-nav-item'),
      views: document.querySelectorAll('.view-section'),

      // Theme Switcher
      themeToggleBtn: document.getElementById('theme-toggle-btn'),
      themeIcon: document.getElementById('theme-icon'),

      // Auth Controls & Modal
      authModal: document.getElementById('auth-modal'),
      authModalTitle: document.getElementById('auth-modal-title'),
      authModalBanner: document.getElementById('auth-modal-banner'),
      authTabLogin: document.getElementById('auth-tab-login'),
      authTabRegister: document.getElementById('auth-tab-register'),
      navProfileBtn: document.getElementById('nav-profile-btn'),
      navSettingsBtn: document.getElementById('nav-settings-btn'),
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

      // Quota Widget Elements
      quotaLabelText: document.getElementById('quota-label-text'),
      quotaProgressFill: document.getElementById('quota-progress-fill'),
      errorQuotaSignupBtn: document.getElementById('error-quota-signup-btn'),

      // Form Controls & Smart Location Search
      locationSearchInput: document.getElementById('location-search-input'),
      locationSuggestionsDropdown: document.getElementById('location-suggestions-dropdown'),
      selectedLocationBadge: document.getElementById('selected-location-badge'),

      // Searchable Business Type Field
      businessTypeInput: document.getElementById('business-type-input'),
      businessTypeDropdown: document.getElementById('business-type-dropdown'),

      // Filter Selects
      minRatingSelect: document.getElementById('min-rating-select'),
      websiteFilterSelect: document.getElementById('website-filter-select'),
      phoneFilterSelect: document.getElementById('phone-filter-select'),
      searchBtn: document.getElementById('search-btn'),
      searchForm: document.getElementById('search-form'),

      // Results Containers
      resultsHeader: document.getElementById('results-header'),
      resultsCount: document.getElementById('results-count'),
      resultsContext: document.getElementById('results-context'),
      statMissingWebsite: document.getElementById('stat-missing-website'),
      statSavedCount: document.getElementById('stat-saved-count'),
      cardsGrid: document.getElementById('cards-grid'),
      loadingState: document.getElementById('loading-state'),
      emptyState: document.getElementById('empty-state'),
      errorState: document.getElementById('error-state'),
      errorMessage: document.getElementById('error-message'),

      // Saved Prospects & Status Tabs
      prospectStatusTabs: document.getElementById('prospect-status-tabs'),
      savedGrid: document.getElementById('saved-grid'),
      savedEmptyState: document.getElementById('saved-empty-state'),

      // Modals
      detailsModal: document.getElementById('details-modal'),
      detailsModalBody: document.getElementById('details-modal-body'),

      // Dashboard Elements
      dashDiscovered: document.getElementById('dash-discovered'),
      dashOpps: document.getElementById('dash-opps'),
      dashNoWebsite: document.getElementById('dash-nowebsite'),
      dashSaved: document.getElementById('dash-saved'),

      toastContainer: document.getElementById('toast-container')
    };
  }

  // --- Theme Switcher Engine ---
  function initTheme() {
    applyTheme(state.theme);

    if (dom.themeToggleBtn) {
      dom.themeToggleBtn.addEventListener('click', () => {
        const nextTheme = state.theme === 'dark' ? 'light' : 'dark';
        applyTheme(nextTheme);
      });
    }
  }

  function applyTheme(themeName) {
    state.theme = themeName;
    localStorage.setItem('bizz_hunter_theme', themeName);
    document.documentElement.setAttribute('data-theme', themeName);

    if (dom.themeIcon) {
      dom.themeIcon.textContent = themeName === 'light' ? '☀️' : '🌙';
    }
  }

  // --- Auth & Quota Controller ---
  function initAuth() {
    if (dom.navProfileBtn) {
      dom.navProfileBtn.addEventListener('click', () => {
        if (state.currentUser) {
          if (confirm(`Logged in as ${state.currentUser.email}. Do you want to log out?`)) {
            logoutUser();
          }
        } else {
          openAuthModal('login');
        }
      });
    }

    if (dom.navSettingsBtn) {
      dom.navSettingsBtn.addEventListener('click', () => {
        switchTab('settings');
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
    const used = quota.used;
    const limit = quota.limit;
    const percentage = Math.min(Math.round((used / limit) * 100), 100);

    if (dom.quotaLabelText) {
      dom.quotaLabelText.textContent = `${isGuest ? 'GUEST USAGE' : 'PRO USAGE'}: ${used}/${limit}`;
    }

    if (dom.quotaProgressFill) {
      dom.quotaProgressFill.style.width = `${percentage}%`;
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

        // Protected feature gating
        if (!state.currentUser && ['dashboard', 'saved-businesses'].includes(tab)) {
          openAuthModal('login', `Account required to access ${capitalize(tab.replace('-', ' '))}. Sign up or log in to continue!`);
          return;
        }

        switchTab(tab);
      });
    });

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

    if (tabName === 'dashboard') {
      updateDashboardMetrics();
    } else if (tabName === 'saved-businesses') {
      loadUserProspects();
    }
  }

  // ================= UNIFIED SEARCHABLE BUSINESS TYPE AUTOCOMPLETE =================
  function initBusinessTypeAutocomplete() {
    if (!dom.businessTypeInput || !dom.businessTypeDropdown) return;

    // Show suggestions ONLY if input has text typed in it
    dom.businessTypeInput.addEventListener('focus', () => {
      const val = dom.businessTypeInput.value.trim();
      if (val) filterAndShowBusinessTypes(val);
    });

    dom.businessTypeInput.addEventListener('click', () => {
      const val = dom.businessTypeInput.value.trim();
      if (val) filterAndShowBusinessTypes(val);
    });

    // Filter suggestions dynamically as user types
    dom.businessTypeInput.addEventListener('input', () => {
      filterAndShowBusinessTypes(dom.businessTypeInput.value.trim());
    });

    // Keyboard navigation (ArrowDown, ArrowUp, Enter, Escape)
    dom.businessTypeInput.addEventListener('keydown', (e) => {
      const items = dom.businessTypeDropdown.querySelectorAll('.suggestion-item');

      if (e.key === 'ArrowDown') {
        e.preventDefault();
        if (dom.businessTypeDropdown.style.display === 'none') {
          const val = dom.businessTypeInput.value.trim();
          if (val) filterAndShowBusinessTypes(val);
          return;
        }
        state.selectedBusinessTypeIndex = Math.min(state.selectedBusinessTypeIndex + 1, items.length - 1);
        highlightBusinessTypeItem(items);
      } else if (e.key === 'ArrowUp') {
        e.preventDefault();
        state.selectedBusinessTypeIndex = Math.max(state.selectedBusinessTypeIndex - 1, 0);
        highlightBusinessTypeItem(items);
      } else if (e.key === 'Enter') {
        if (state.selectedBusinessTypeIndex >= 0 && items[state.selectedBusinessTypeIndex]) {
          e.preventDefault();
          selectBusinessType(items[state.selectedBusinessTypeIndex].getAttribute('data-value'));
        } else {
          dom.businessTypeDropdown.style.display = 'none';
        }
      } else if (e.key === 'Escape') {
        dom.businessTypeDropdown.style.display = 'none';
      }
    });

    // Close dropdown on click outside
    document.addEventListener('click', (e) => {
      if (!dom.businessTypeInput.contains(e.target) && !dom.businessTypeDropdown.contains(e.target)) {
        dom.businessTypeDropdown.style.display = 'none';
      }
    });
  }

  function filterAndShowBusinessTypes(query) {
    const q = query.toLowerCase().trim();

    // REQUIRE AT LEAST 1 TYPED CHARACTER BEFORE SHOWING DROPDOWN
    if (!q) {
      dom.businessTypeDropdown.style.display = 'none';
      dom.businessTypeDropdown.innerHTML = '';
      return;
    }

    const matches = PREDEFINED_BUSINESS_TYPES.filter(type => type.toLowerCase().includes(q));

    if (matches.length === 0) {
      dom.businessTypeDropdown.style.display = 'none';
      dom.businessTypeDropdown.innerHTML = '';
      return;
    }

    state.selectedBusinessTypeIndex = -1;

    dom.businessTypeDropdown.innerHTML = matches.map((type, idx) => {
      const highlightedText = escapeHtml(type).replace(new RegExp(`(${escapeRegExp(q)})`, 'gi'), '<span class="highlight-match">$1</span>');
      return `
        <div class="suggestion-item" data-value="${escapeHtml(type)}" data-index="${idx}">
          <div><strong>${highlightedText}</strong></div>
          <span style="font-size: 0.75rem; background: var(--primary-light); color: var(--primary); padding: 2px 6px; border-radius: 4px; font-weight: 700;">Category</span>
        </div>
      `;
    }).join('');

    dom.businessTypeDropdown.style.display = 'block';

    // Use mousedown listener for immediate selection without blur conflicts
    dom.businessTypeDropdown.querySelectorAll('.suggestion-item').forEach(item => {
      item.addEventListener('mousedown', (e) => {
        e.preventDefault();
        selectBusinessType(item.getAttribute('data-value'));
      });
    });
  }

  function highlightBusinessTypeItem(items) {
    items.forEach((item, idx) => {
      if (idx === state.selectedBusinessTypeIndex) {
        item.classList.add('active');
        item.scrollIntoView({ block: 'nearest' });
      } else {
        item.classList.remove('active');
      }
    });
  }

  function selectBusinessType(value) {
    if (!value) return;
    dom.businessTypeInput.value = value;
    dom.businessTypeDropdown.style.display = 'none';
    state.selectedBusinessTypeIndex = -1;
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

    dom.locationSearchInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        if (dom.locationSuggestionsDropdown.style.display !== 'none') {
          dom.locationSuggestionsDropdown.style.display = 'none';
        }
      }
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
            <div class="suggestion-meta" style="font-size: 0.8rem; color: var(--text-muted);">${escapeHtml(p.secondary_text || p.formatted_address)}</div>
          </div>
          <span style="font-size: 0.75rem; background: var(--primary-light); color: var(--primary); padding: 2px 6px; border-radius: 4px; font-weight: 700;">Place</span>
        </div>
      `;
    }).join('');

    dom.locationSuggestionsDropdown.style.display = 'block';

    dom.locationSuggestionsDropdown.querySelectorAll('.suggestion-item').forEach(item => {
      item.addEventListener('mousedown', (e) => {
        e.preventDefault();
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
        <button type="button" class="remove-loc-btn" title="Clear Location" style="background: transparent; border: none; color: var(--text-muted); cursor: pointer;">&times;</button>
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

    let locationName = state.selectedLocationName || (dom.locationSearchInput ? dom.locationSearchInput.value.trim() : '');

    // Fallback prompt if location input is empty
    if (!locationName) {
      showToast('Please enter a city or location to search (e.g. Lagos, Abuja, London)', 'error');
      if (dom.locationSearchInput) dom.locationSearchInput.focus();
      return;
    }

    // Capture Business Type dynamically from input field
    const bTypeInput = document.getElementById('business-type-input');
    const businessType = bTypeInput ? bTypeInput.value.trim() : '';

    // Capture Combined Search Criteria
    const params = {
      place_id: state.selectedPlaceId,
      location_name: locationName,
      business_type: businessType,
      min_rating: dom.minRatingSelect ? dom.minRatingSelect.value : '',
      has_website: dom.websiteFilterSelect ? dom.websiteFilterSelect.value : '',
      has_phone: dom.phoneFilterSelect ? dom.phoneFilterSelect.value : ''
    };

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
    if (dom.resultsHeader) dom.resultsHeader.style.display = 'none';
    if (dom.cardsGrid) dom.cardsGrid.style.display = 'none';
    if (dom.emptyState) dom.emptyState.style.display = 'none';
    if (dom.errorState) dom.errorState.style.display = 'none';
    if (dom.loadingState) dom.loadingState.style.display = 'flex';

    if (dom.searchBtn) {
      dom.searchBtn.disabled = false;
      dom.searchBtn.innerHTML = 'Searching...';
    }
  }

  function renderResults(businesses, params) {
    if (dom.loadingState) dom.loadingState.style.display = 'none';
    if (dom.emptyState) dom.emptyState.style.display = 'none';
    if (dom.errorState) dom.errorState.style.display = 'none';
    if (dom.resultsHeader) dom.resultsHeader.style.display = 'flex';
    if (dom.cardsGrid) dom.cardsGrid.style.display = 'flex';

    if (dom.searchBtn) {
      dom.searchBtn.disabled = false;
      dom.searchBtn.innerHTML = 'Search →';
    }

    if (dom.resultsCount) dom.resultsCount.textContent = businesses.length;
    if (dom.resultsContext) dom.resultsContext.textContent = `Results for "${capitalize(params.business_type)} in ${params.location_name}"`;

    const noWebsiteCount = businesses.filter(b => !b.website).length;
    if (dom.statMissingWebsite) dom.statMissingWebsite.textContent = noWebsiteCount;
    if (dom.statSavedCount) dom.statSavedCount.textContent = state.savedBusinesses.length;

    // Render Business Cards with PERMANENT VISIBLE LARGE SCANNABLE QR CODES
    if (dom.cardsGrid) {
      dom.cardsGrid.innerHTML = businesses.map(b => createBusinessCardHtml(b)).join('');
      attachCardEventListeners();
    }
  }

  function showEmptyState() {
    if (dom.loadingState) dom.loadingState.style.display = 'none';
    if (dom.resultsHeader) dom.resultsHeader.style.display = 'none';
    if (dom.cardsGrid) dom.cardsGrid.style.display = 'none';
    if (dom.errorState) dom.errorState.style.display = 'none';
    if (dom.emptyState) dom.emptyState.style.display = 'block';

    if (dom.searchBtn) {
      dom.searchBtn.disabled = false;
      dom.searchBtn.innerHTML = 'Search →';
    }
  }

  function showErrorState(msg) {
    if (dom.loadingState) dom.loadingState.style.display = 'none';
    if (dom.resultsHeader) dom.resultsHeader.style.display = 'none';
    if (dom.cardsGrid) dom.cardsGrid.style.display = 'none';
    if (dom.emptyState) dom.emptyState.style.display = 'none';
    if (dom.errorState) dom.errorState.style.display = 'block';
    if (dom.errorMessage) dom.errorMessage.textContent = msg;

    if (dom.searchBtn) {
      dom.searchBtn.disabled = false;
      dom.searchBtn.innerHTML = 'Search →';
    }
  }

  // --- WhatsApp Phone Number Sanitizer & Link Formatter ---
  function buildWhatsAppUrl(b) {
    const rawIntl = b.phone || b.phone_number || '';
    const rawNat = b.national_phone || b.international_phone_number || '';
    const phoneStr = rawIntl || rawNat || '';
    if (!phoneStr) return null;

    // Strip everything except 0-9 digits
    let digits = phoneStr.replace(/\D/g, '');
    if (!digits) return null;

    // Handle Nigerian local format (e.g. 08032079169 -> 2348032079169)
    if (digits.startsWith('0') && digits.length === 11) {
      digits = '234' + digits.substring(1);
    } else if (digits.length === 10 && !digits.startsWith('234')) {
      digits = '234' + digits;
    }

    if (digits.length < 7) return null;

    // Format: https://wa.me/<FULL_INTERNATIONAL_PHONE_NUMBER>
    return `https://wa.me/${digits}`;
  }

  // ================= BUSINESS RESULT CARD WITH PERMANENT VISIBLE QR CODE =================
  function createBusinessCardHtml(b, isProspectView = false) {
    const placeId = b.google_place_id || b.id;
    const isSaved = state.savedBusinesses.some(saved => saved.google_place_id === placeId || saved.id === placeId);
    const hasWebsite = Boolean(b.website);
    const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';
    const hasPhone = Boolean(rawPhone);
    const formattedPhone = b.national_phone || b.international_phone_number || b.phone || b.phone_number || 'No Phone Number';

    // WhatsApp URL & Direct QR Code SVG Rendering
    const waUrl = buildWhatsAppUrl(b);

    // DIRECT PERMANENT LARGE SCANNABLE SVG QR CODE INJECTION
    let qrSvgHtml = '';
    if (waUrl && window.QRCodeGenerator) {
      qrSvgHtml = window.QRCodeGenerator(waUrl, { size: 144, colorDark: '#0b0f19', colorLight: '#ffffff' });
    }

    // Opportunity Signals & Score
    const oppLevel = b.opportunity_level || (!hasWebsite ? 'HIGH' : 'STANDARD');
    const categoryName = (b.category || b.types?.[0] || 'Business').replace(/_/g, ' ').toUpperCase();
    const ratingVal = b.rating ? Number(b.rating).toFixed(1) : 'N/A';
    const reviewCountText = b.review_count ? `(${Number(b.review_count).toLocaleString()})` : '';

    return `
      <div class="business-card" data-id="${placeId}" data-db-id="${b.id || ''}">
        
        <!-- Left Panel: Details, Badges, Tags, Actions -->
        <div class="card-left-content">
          <div>
            <div class="card-top-tags">
              <div class="category-tag">
                <span>${escapeHtml(categoryName)}</span>
                <span class="opp-badge ${oppLevel}">${oppLevel} OPPORTUNITY</span>
              </div>
              <div class="card-rating-badge">
                <span>★</span> ${ratingVal} <span style="font-size: 0.8rem; color: var(--text-muted); font-weight: 500;">${reviewCountText}</span>
              </div>
            </div>

            <h3 class="card-business-name">${escapeHtml(b.name || b.business_name)}</h3>

            <div class="card-info-rows">
              <div class="info-row">
                <span>📍</span>
                <span>${escapeHtml(b.address || 'Address unavailable')}</span>
              </div>
              <div class="info-row">
                <span>📞</span>
                <span>${escapeHtml(formattedPhone)}</span>
                ${hasPhone ? `<button class="copy-icon-btn" title="Copy Phone Number" data-phone="${escapeHtml(formattedPhone)}">📋</button>` : ''}
              </div>
              <div class="info-row">
                <span>🌐</span>
                ${hasWebsite ? `
                  <a href="${b.website}" target="_blank" rel="noopener" style="color: var(--primary); text-decoration: underline;">${escapeHtml(b.website)}</a>
                ` : `
                  <span class="badge-no-website">NO WEBSITE</span>
                  <span style="font-size: 0.85rem; color: var(--text-muted); font-weight: 600;">Direct lead opportunity</span>
                `}
              </div>
            </div>

            <div class="signal-tags-group">
              ${!hasWebsite ? '<span class="signal-tag">No website found</span>' : '<span class="signal-tag">Website active</span>'}
              ${b.rating >= 4.5 ? '<span class="signal-tag">High rating (4.5+)</span>' : ''}
              ${b.review_count >= 100 ? `<span class="signal-tag">${Number(b.review_count).toLocaleString()}+ reviews</span>` : ''}
              ${waUrl ? '<span class="signal-tag">WhatsApp reachable</span>' : ''}
            </div>

            ${isProspectView ? `
              <!-- Prospect Status & Notes Controls -->
              <div style="background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 0.75rem; margin-top: 0.75rem; display: flex; flex-direction: column; gap: 0.6rem;">
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
                  <button type="button" class="btn btn-secondary btn-sm save-notes-btn" data-id="${b.id}" style="white-space: nowrap;">Save Note</button>
                </div>
              </div>
            ` : ''}
          </div>

          <div class="card-actions-left">
            ${isProspectView ? `
              <button class="btn btn-secondary btn-sm remove-prospect-btn" data-id="${b.id}" style="color: #ef4444;">
                <span>🗑️</span> Remove
              </button>
            ` : `
              <button class="btn ${isSaved ? 'btn-secondary' : 'btn-primary'} btn-sm save-btn" data-id="${placeId}">
                <span>${isSaved ? '❤️ Saved' : '🔖 Save prospect'}</span>
              </button>
            `}

            <button class="btn btn-secondary btn-sm details-btn" data-id="${placeId}">
              <span>📞</span> Call / Details
            </button>
          </div>
        </div>

        <!-- Right Panel: PERMANENT VISIBLE LARGE SCANNABLE QR CODE -->
        <div class="card-right-panel" style="justify-content: center; gap: 0.75rem;">
          ${waUrl ? `
            <div class="qr-visible-box">
              ${qrSvgHtml}
            </div>
            <div class="qr-caption-subtext">Scan to WhatsApp</div>

            <a href="${waUrl}" target="_blank" rel="noopener" class="btn btn-whatsapp btn-sm btn-block">
              <span>💬</span> WhatsApp
            </a>
          ` : `
            <div style="padding: 2rem 0; color: var(--text-dim); font-size: 0.85rem;">
              <div>NO PHONE NUMBER</div>
              <div style="font-size: 0.75rem; margin-top: 4px;">QR unavailable</div>
            </div>
            <button class="btn btn-secondary btn-sm btn-block" disabled>No Phone Line</button>
          `}
        </div>

      </div>
    `;
  }

  function attachCardEventListeners() {
    // Copy Phone Number Button
    document.querySelectorAll('.copy-icon-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const phone = btn.getAttribute('data-phone');
        if (phone) {
          navigator.clipboard.writeText(phone);
          showToast(`Copied ${phone} to clipboard!`, 'success');
        }
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
      renderSavedBusinessesView();
      return;
    }

    try {
      const prospects = await window.BizzApi.getProspects(state.activeProspectStatusFilter);
      state.savedBusinesses = prospects;
      updateDashboardMetrics();

      if (state.currentTab === 'saved-businesses') {
        renderSavedBusinessesView();
      }
    } catch (err) {
      console.warn('Error loading user prospects', err);
    }
  }

  function renderSavedBusinessesView() {
    if (!dom.savedGrid) return;

    if (!state.currentUser) {
      dom.savedGrid.style.display = 'none';
      dom.savedEmptyState.style.display = 'block';
      return;
    }

    if (state.savedBusinesses.length === 0) {
      dom.savedGrid.style.display = 'none';
      dom.savedEmptyState.style.display = 'block';
    } else {
      dom.savedEmptyState.style.display = 'none';
      dom.savedGrid.style.display = 'flex';
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
  }

  function openDetailsModal(b) {
    const name = b.name || b.business_name;
    const waUrl = buildWhatsAppUrl(b);
    const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';

    dom.detailsModalBody.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem;">
        <div>
          <h2 style="font-size: 1.4rem; font-weight: 800; margin-bottom: 0.25rem;">${escapeHtml(name)}</h2>
          <div style="color: var(--text-muted); font-size: 0.9rem;">${b.types ? (Array.isArray(b.types) ? b.types.slice(0, 3).join(' • ') : b.types) : (b.category || 'Business')}</div>
        </div>
        <div class="card-rating-badge">
          ★ ${b.rating ? Number(b.rating).toFixed(1) : 'N/A'}
        </div>
      </div>

      <div style="background: var(--bg-surface); border: 1px solid var(--border-color); padding: 1rem; border-radius: var(--radius-md); margin-bottom: 1.25rem; font-size: 0.9rem; display: flex; flex-direction: column; gap: 0.5rem;">
        <div><strong>Address:</strong> ${escapeHtml(b.address || 'Unavailable')}</div>
        <div><strong>Phone (International):</strong> ${escapeHtml(b.phone || b.phone_number || 'Unavailable')}</div>
        <div><strong>Phone (National):</strong> ${escapeHtml(b.national_phone || b.international_phone_number || 'Unavailable')}</div>
        <div><strong>Website:</strong> ${b.website ? `<a href="${b.website}" target="_blank">${escapeHtml(b.website)}</a>` : '<span style="color: #ef4444; font-weight: 600;">No Website (Lead Opportunity)</span>'}</div>
      </div>

      <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
        ${waUrl ? `<a href="${waUrl}" target="_blank" class="btn btn-whatsapp btn-block">💬 Contact on WhatsApp</a>` : ''}
        ${rawPhone ? `<a href="tel:${rawPhone}" class="btn btn-secondary btn-block">📞 Direct Phone Call</a>` : ''}
        ${b.google_maps_url ? `<a href="${b.google_maps_url}" target="_blank" class="btn btn-secondary btn-block">🗺️ Open in Google Maps</a>` : ''}
      </div>
    `;

    dom.detailsModal.classList.add('active');
  }

  // --- Dashboard Metrics ---
  function updateDashboardMetrics() {
    const noWebsiteCount = state.searchResults.filter(b => !b.website).length;
    const oppsCount = state.searchResults.filter(b => !b.website || (b.phone || b.phone_number)).length;

    if (dom.dashDiscovered) dom.dashDiscovered.textContent = state.searchedCount;
    if (dom.dashOpps) dom.dashOpps.textContent = oppsCount;
    if (dom.dashNoWebsite) dom.dashNoWebsite.textContent = noWebsiteCount;
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

  function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  function capitalize(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

})();
