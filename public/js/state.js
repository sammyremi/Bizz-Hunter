/* public/js/state.js - Global Application State and DOM Cache */

(function (window) {
  'use strict';

  // Shared DOM Cache Reference
  window.dom = {};

  const initialHash = window.location.hash ? window.location.hash.replace('#', '') : null;
  const initialSavedTab = localStorage.getItem('bizz_hunter_current_tab');

  // Shared Application State
  window.BizzState = {
    theme: localStorage.getItem('bizz_hunter_theme') || 'dark',
    currentTab: initialHash || initialSavedTab || 'find-businesses',
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
    selectedBusinessTypeIndex: -1,
    activeSearchId: null,
    prospectingProfiles: [],
    dom: window.dom
  };

  window.cacheDomElements = function () {
    const elements = {
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
      dashKpiFound: document.getElementById('dash-kpi-found'),
      dashKpiHighOpp: document.getElementById('dash-kpi-high-opp'),
      dashKpiNoWebsite: document.getElementById('dash-kpi-no-website'),
      dashKpiWhatsapp: document.getElementById('dash-kpi-whatsapp'),
      dashKpiSaved: document.getElementById('dash-kpi-saved'),
      dashChartOpportunity: document.getElementById('dash-chart-opportunity'),
      dashChartTypes: document.getElementById('dash-chart-types'),
      dashBtnViewAnalysis: document.getElementById('dash-btn-view-analysis'),
      dashBtnViewHighOpps: document.getElementById('dash-btn-view-high-opps'),
      dashBtnViewSaved: document.getElementById('dash-btn-view-saved'),

      // Dedicated Analysis Workspace Elements
      analysisSearchContextLabel: document.getElementById('analysis-search-context-label'),
      analysisBtnBackResults: document.getElementById('analysis-btn-back-results'),
      analysisBtnExportCsv: document.getElementById('analysis-btn-export-csv'),
      analysisKpiFound: document.getElementById('analysis-kpi-found'),
      analysisKpiNoWebsite: document.getElementById('analysis-kpi-no-website'),
      analysisKpiPhone: document.getElementById('analysis-kpi-phone'),
      analysisKpiWhatsapp: document.getElementById('analysis-kpi-whatsapp'),
      analysisKpiHighOpp: document.getElementById('analysis-kpi-high-opp'),

      analysisChartOpportunity: document.getElementById('analysis-chart-opportunity'),
      analysisChartWebsite: document.getElementById('analysis-chart-website'),
      analysisChartContactability: document.getElementById('analysis-chart-contactability'),
      analysisChartRatings: document.getElementById('analysis-chart-ratings'),
      analysisChartBusinessTypes: document.getElementById('analysis-chart-business-types'),
      analysisChartLocations: document.getElementById('analysis-chart-locations'),

      filterBtnHighOpp: document.getElementById('filter-btn-high-opp'),
      filterBtnMedOpp: document.getElementById('filter-btn-med-opp'),
      filterBtnLowOpp: document.getElementById('filter-btn-low-opp'),
      filterBtnNoWebsite: document.getElementById('filter-btn-no-website'),
      filterBtnWhatsappOnly: document.getElementById('filter-btn-whatsapp-only'),

      topProspectsList: document.getElementById('top-prospects-list'),
      analysisEmptyState: document.getElementById('analysis-empty-state'),
      analysisEmptySearchBtn: document.getElementById('analysis-empty-search-btn'),
      analysisAuthGate: document.getElementById('analysis-auth-gate'),
      analysisLoginBtn: document.getElementById('analysis-login-btn'),
      searchHistoryContainer: document.getElementById('search-history-container'),
      searchHistoryList: document.getElementById('search-history-list'),

      // Prospecting Profiles Elements
      profilesGrid: document.getElementById('profiles-grid'),
      profilesLoadingState: document.getElementById('profiles-loading-state'),
      profilesEmptyState: document.getElementById('profiles-empty-state'),
      profilesErrorState: document.getElementById('profiles-error-state'),
      createProfileBtn: document.getElementById('create-profile-btn'),
      profilesEmptyCreateBtn: document.getElementById('profiles-empty-create-btn'),
      profilesRetryBtn: document.getElementById('profiles-retry-btn'),
      profileModal: document.getElementById('profile-modal'),
      profileForm: document.getElementById('profile-form'),

      // Onboarding & Discovery Prompt Banner
      onboardingModal: document.getElementById('onboarding-modal'),
      onboardingCreateBtn: document.getElementById('onboarding-create-btn'),
      onboardingSkipBtn: document.getElementById('onboarding-skip-btn'),
      profileSuccessModal: document.getElementById('profile-success-modal'),
      successStartDiscoveringBtn: document.getElementById('success-start-discovering-btn'),
      successViewProfilesBtn: document.getElementById('success-view-profiles-btn'),
      discoveryProfileBanner: document.getElementById('discovery-profile-banner'),
      discoveryBannerCreateBtn: document.getElementById('discovery-banner-create-btn'),
      discoveryBannerDismissBtn: document.getElementById('discovery-banner-dismiss-btn'),

      toastContainer: document.getElementById('toast-container')
    };

    Object.assign(window.dom, elements);
    window.BizzState.dom = window.dom;
    return window.dom;
  };

})(window);
