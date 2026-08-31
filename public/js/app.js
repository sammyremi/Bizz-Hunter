/* public/js/app.js - Bizz-Hunter Main Application Controller */

(function () {
  'use strict';

  // Application State
  const state = {
    currentTab: 'find-businesses',
    searchResults: [],
    savedBusinesses: JSON.parse(localStorage.getItem('bizz_hunter_saved') || '[]'),
    searchedCount: parseInt(localStorage.getItem('bizz_hunter_searched_count') || '0', 10),
    activeFilters: {},
    selectedPlaceId: null,
    selectedLocationName: '',
    selectedBusinessForModal: null,
    isSearching: false
  };

  // DOM Cache
  let dom = {};

  document.addEventListener('DOMContentLoaded', () => {
    cacheDomElements();
    initNavigation();
    initLocationSelectors();
    initSearchForm();
    initModals();
    renderSavedCountBadge();
    updateDashboardMetrics();
  });

  function cacheDomElements() {
    dom = {
      navItems: document.querySelectorAll('.nav-item'),
      views: document.querySelectorAll('.view-section'),
      currentNavTitle: document.getElementById('current-nav-title'),
      mobileToggle: document.getElementById('mobile-nav-toggle'),
      sidebar: document.querySelector('.sidebar'),

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
      savedBadge: document.getElementById('saved-badge'),
      savedGrid: document.getElementById('saved-grid'),
      savedEmptyState: document.getElementById('saved-empty-state'),

      toastContainer: document.getElementById('toast-container')
    };
  }

  // --- Navigation Controller ---
  function initNavigation() {
    dom.navItems.forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault();
        const tab = item.getAttribute('data-tab');
        if (!tab) return;

        switchTab(tab);
      });
    });

    if (dom.mobileToggle) {
      dom.mobileToggle.addEventListener('click', () => {
        dom.sidebar.classList.toggle('open');
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
      'saved-businesses': 'Saved Businesses',
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
      renderSavedBusinesses();
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
      const results = await window.BizzApi.searchBusinesses(params);
      state.searchResults = results;
      state.searchedCount += results.length;
      localStorage.setItem('bizz_hunter_searched_count', state.searchedCount.toString());

      if (results.length === 0) {
        showEmptyState();
      } else {
        renderResults(results, params);
      }
    } catch (err) {
      showErrorState(err.message || 'Unable to connect to Google Places API backend.');
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
  function createBusinessCardHtml(b) {
    const isSaved = state.savedBusinesses.some(saved => saved.id === b.id);
    const hasWebsite = Boolean(b.website);
    const hasPhone = Boolean(b.phone || b.national_phone);
    const rawPhone = b.phone || b.national_phone || '';
    const formattedPhone = b.national_phone || b.phone || 'Phone unavailable';

    // WhatsApp URL generation
    const cleanPhone = rawPhone.replace(/[^\d+]/g, '').replace('+', '');
    const waText = encodeURIComponent(`Hello ${b.name}, I found your business on Bizz-Hunter and wanted to get in touch.`);
    const waUrl = cleanPhone ? `https://wa.me/${cleanPhone}?text=${waText}` : null;

    // Badges
    const oppBadges = [];
    if (!hasWebsite) {
      oppBadges.push(`<span class="opp-badge no-website">🚨 NO WEBSITE</span>`);
    } else {
      oppBadges.push(`<span class="opp-badge website">🌐 Website Found</span>`);
    }

    if (hasPhone) {
      oppBadges.push(`<span class="opp-badge phone-available">📞 PHONE AVAILABLE</span>`);
    }

    if (b.rating && b.rating >= 4.5) {
      oppBadges.push(`<span class="opp-badge high-rating">⭐ HIGH RATING</span>`);
    }

    return `
      <div class="business-card" data-id="${b.id}">
        <div class="card-top">
          <div class="card-title-row">
            <h3 class="business-name">${escapeHtml(b.name)}</h3>
            <div class="rating-badge">
              <span>★</span> ${b.rating ? b.rating.toFixed(1) : 'N/A'}
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
            <span>${hasWebsite ? `<a href="${b.website}" target="_blank" rel="noopener">${escapeHtml(b.website)}</a>` : 'No website found'}</span>
          </div>
        </div>

        <div class="opportunity-tags">
          ${oppBadges.join('')}
        </div>

        <div class="card-actions">
          ${waUrl ? `
            <a href="${waUrl}" target="_blank" rel="noopener" class="btn btn-whatsapp btn-sm">
              <span>💬</span> WhatsApp
            </a>
            <button class="icon-btn qr-btn" title="Scan WhatsApp QR Code" data-id="${b.id}">
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

          <button class="icon-btn save-btn ${isSaved ? 'saved' : ''}" title="${isSaved ? 'Remove from Saved' : 'Save Business'}" data-id="${b.id}">
            <span>${isSaved ? '❤️' : '🤍'}</span>
          </button>

          <button class="btn btn-secondary btn-sm details-btn" style="margin-left: auto;" data-id="${b.id}">
            Details
          </button>
        </div>
      </div>
    `;
  }

  function attachCardEventListeners() {
    document.querySelectorAll('.qr-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const b = state.searchResults.find(item => item.id === id) || state.savedBusinesses.find(item => item.id === id);
        if (b) openQrModal(b);
      });
    });

    document.querySelectorAll('.save-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const b = state.searchResults.find(item => item.id === id) || state.savedBusinesses.find(item => item.id === id);
        if (b) toggleSaveBusiness(b);
      });
    });

    document.querySelectorAll('.details-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const b = state.searchResults.find(item => item.id === id) || state.savedBusinesses.find(item => item.id === id);
        if (b) openDetailsModal(b);
      });
    });
  }

  // --- Saved Businesses Storage ---
  function toggleSaveBusiness(business) {
    const index = state.savedBusinesses.findIndex(b => b.id === business.id);
    if (index >= 0) {
      state.savedBusinesses.splice(index, 1);
      showToast(`Removed "${business.name}" from saved list`, 'info');
    } else {
      state.savedBusinesses.push(business);
      showToast(`Saved "${business.name}" to prospects list!`, 'success');
    }

    localStorage.setItem('bizz_hunter_saved', JSON.stringify(state.savedBusinesses));
    renderSavedCountBadge();
    updateDashboardMetrics();

    if (state.currentTab === 'find-businesses' && state.searchResults.length > 0) {
      renderResults(state.searchResults, state.activeFilters);
    } else if (state.currentTab === 'saved-businesses') {
      renderSavedBusinesses();
    }
  }

  function renderSavedCountBadge() {
    if (dom.savedBadge) {
      dom.savedBadge.textContent = state.savedBusinesses.length;
    }
  }

  function renderSavedBusinesses() {
    if (!dom.savedGrid) return;

    if (state.savedBusinesses.length === 0) {
      dom.savedGrid.style.display = 'none';
      dom.savedEmptyState.style.display = 'block';
    } else {
      dom.savedEmptyState.style.display = 'none';
      dom.savedGrid.style.display = 'grid';
      dom.savedGrid.innerHTML = state.savedBusinesses.map(b => createBusinessCardHtml(b)).join('');
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
    dom.detailsModal.classList.remove('active');
    dom.qrModal.classList.remove('active');
  }

  function openDetailsModal(b) {
    const rawPhone = b.phone || b.national_phone || '';
    const cleanPhone = rawPhone.replace(/[^\d+]/g, '').replace('+', '');
    const waText = encodeURIComponent(`Hello ${b.name}, I found your business on Bizz-Hunter and wanted to get in touch.`);
    const waUrl = cleanPhone ? `https://wa.me/${cleanPhone}?text=${waText}` : null;

    dom.detailsModalBody.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem;">
        <div>
          <h2 style="font-size: 1.4rem; font-weight: 800; margin-bottom: 0.25rem;">${escapeHtml(b.name)}</h2>
          <div style="color: var(--text-muted); font-size: 0.9rem;">${b.types ? b.types.slice(0, 3).join(' • ') : 'Business'}</div>
        </div>
        <div class="rating-badge" style="font-size: 1rem; padding: 4px 10px;">
          ★ ${b.rating ? b.rating.toFixed(1) : 'N/A'}
        </div>
      </div>

      <div style="background: var(--bg-surface); border: 1px solid var(--border-color); padding: 1rem; border-radius: var(--radius-md); margin-bottom: 1.25rem; font-size: 0.9rem; display: flex; flex-direction: column; gap: 0.5rem;">
        <div><strong>Address:</strong> ${escapeHtml(b.address || 'Unavailable')}</div>
        <div><strong>Phone (International):</strong> ${escapeHtml(b.phone || 'Unavailable')}</div>
        <div><strong>Phone (National):</strong> ${escapeHtml(b.national_phone || 'Unavailable')}</div>
        <div><strong>Website:</strong> ${b.website ? `<a href="${b.website}" target="_blank">${escapeHtml(b.website)}</a>` : '<span style="color: var(--opp-nowebsite-text);">No Website (Lead Opportunity)</span>'}</div>
        ${b.latitude && b.longitude ? `<div><strong>Coordinates:</strong> ${b.latitude.toFixed(5)}, ${b.longitude.toFixed(5)}</div>` : ''}
      </div>

      <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
        ${waUrl ? `<a href="${waUrl}" target="_blank" class="btn btn-whatsapp btn-block">💬 Contact on WhatsApp</a>` : ''}
        ${b.phone ? `<a href="tel:${b.phone}" class="btn btn-secondary btn-block">📞 Direct Phone Call</a>` : ''}
        ${b.google_maps_url ? `<a href="${b.google_maps_url}" target="_blank" class="btn btn-secondary btn-block">🗺️ Open in Google Maps</a>` : ''}
      </div>
    `;

    dom.detailsModal.classList.add('active');
  }

  function openQrModal(b) {
    const rawPhone = b.phone || b.national_phone || '';
    const cleanPhone = rawPhone.replace(/[^\d+]/g, '').replace('+', '');
    const waText = encodeURIComponent(`Hello ${b.name}, I found your business on Bizz-Hunter.`);
    const waUrl = `https://wa.me/${cleanPhone}?text=${waText}`;

    const svgQr = window.QRCodeGenerator ? window.QRCodeGenerator(waUrl, { size: 240, colorDark: '#0b0f19', colorLight: '#ffffff' }) : '';

    dom.qrModalBody.innerHTML = `
      <div style="text-align: center;">
        <h3 style="font-size: 1.2rem; font-weight: 700; margin-bottom: 0.25rem;">${escapeHtml(b.name)}</h3>
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
    const phoneCount = state.searchResults.filter(b => b.phone || b.national_phone).length;
    const oppsCount = state.searchResults.filter(b => !b.website || (b.phone || b.national_phone)).length;

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

})();
