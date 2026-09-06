/* public/js/features/search.js - Business Discovery Search and Autocomplete Engine */

(function (window) {
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

  let searchTimeout = null;

  // ================= UNIFIED SEARCHABLE BUSINESS TYPE AUTOCOMPLETE =================
  function initBusinessTypeAutocomplete() {
    const dom = window.dom;
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
      const state = window.BizzState;
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
    const dom = window.dom;
    const state = window.BizzState;
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
      const highlightedText = window.escapeHtml(type).replace(new RegExp(`(${window.escapeRegExp(q)})`, 'gi'), '<span class="highlight-match">$1</span>');
      return `
        <div class="suggestion-item" data-value="${window.escapeHtml(type)}" data-index="${idx}">
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
    const state = window.BizzState;
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
    const dom = window.dom;
    const state = window.BizzState;
    if (!value) return;
    dom.businessTypeInput.value = value;
    dom.businessTypeDropdown.style.display = 'none';
    state.selectedBusinessTypeIndex = -1;
  }

  // --- Google Places Smart Location Search Controller ---
  function initLocationSelectors() {
    const dom = window.dom;
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
    const dom = window.dom;
    if (!predictions || predictions.length === 0) {
      dom.locationSuggestionsDropdown.innerHTML = `<div class="suggestion-item"><span style="color: var(--text-dim);">No place predictions found</span></div>`;
      dom.locationSuggestionsDropdown.style.display = 'block';
      return;
    }

    dom.locationSuggestionsDropdown.innerHTML = predictions.map(p => {
      return `
        <div class="suggestion-item" data-id="${p.place_id}" data-address="${window.escapeHtml(p.formatted_address)}" data-name="${window.escapeHtml(p.name)}">
          <div>
            <strong>${window.escapeHtml(p.main_text || p.name)}</strong>
            <div class="suggestion-meta" style="font-size: 0.8rem; color: var(--text-muted);">${window.escapeHtml(p.secondary_text || p.formatted_address)}</div>
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
    const dom = window.dom;
    const state = window.BizzState;
    state.selectedPlaceId = placeId;
    state.selectedLocationName = formattedAddress;

    dom.locationSearchInput.value = formattedAddress;
    dom.locationSuggestionsDropdown.style.display = 'none';

    if (dom.selectedLocationBadge) {
      dom.selectedLocationBadge.innerHTML = `
        <span>📍 ${window.escapeHtml(formattedAddress)}</span>
        <button type="button" class="remove-loc-btn" title="Clear Location" style="background: transparent; border: none; color: var(--text-muted); cursor: pointer;">&times;</button>
      `;
      dom.selectedLocationBadge.style.display = 'inline-flex';

      dom.selectedLocationBadge.querySelector('.remove-loc-btn').addEventListener('click', () => {
        clearSelectedLocation();
      });
    }
  }

  function clearSelectedLocation() {
    const dom = window.dom;
    const state = window.BizzState;
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
    const dom = window.dom;
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
    const dom = window.dom;
    const state = window.BizzState;
    if (state.isSearching) return;

    let locationName = state.selectedLocationName || (dom.locationSearchInput ? dom.locationSearchInput.value.trim() : '');

    // Fallback prompt if location input is empty
    if (!locationName) {
      window.showToast('Please enter a city or location to search (e.g. Lagos, Abuja, London)', 'error');
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

      if (res.search_id) {
        state.activeSearchId = res.search_id;
      }

      if (res.quota) {
        window.updateQuotaUI(res.quota);
      }

      if (res.data.length === 0) {
        showEmptyState();
      } else {
        renderResults(res.data, params);
      }
    } catch (err) {
      if (err.status === 429) {
        if (err.quota) window.updateQuotaUI(err.quota);
        showErrorState(err.message || 'Daily guest search limit reached.');
        if (dom.errorQuotaSignupBtn) dom.errorQuotaSignupBtn.style.display = 'block';
        window.openAuthModal('register', 'Daily guest search limit reached (5/5). Create a free account for 50 searches per day!');
      } else {
        showErrorState(err.message || 'Unable to connect to Google Places API backend.');
        if (dom.errorQuotaSignupBtn) dom.errorQuotaSignupBtn.style.display = 'none';
      }
    } finally {
      state.isSearching = false;
    }
  }

  function showLoadingState() {
    const dom = window.dom;
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
    const dom = window.dom;
    const state = window.BizzState;

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
    if (dom.resultsContext) dom.resultsContext.textContent = `Results for "${window.capitalize(params.business_type)} in ${params.location_name}"`;

    const noWebsiteCount = businesses.filter(b => !b.website).length;
    if (dom.statMissingWebsite) dom.statMissingWebsite.textContent = noWebsiteCount;
    if (dom.statSavedCount) dom.statSavedCount.textContent = state.savedBusinesses.length;

    // Render Business Cards with PERMANENT VISIBLE LARGE SCANNABLE QR CODES
    if (dom.cardsGrid) {
      dom.cardsGrid.innerHTML = businesses.map(b => window.createBusinessCardHtml(b)).join('');
      window.attachCardEventListeners();
    }

    window.renderDashboardAnalytics();
    if (state.currentTab === 'analysis') {
      window.renderAnalysisWorkspace();
    }
  }

  function showEmptyState() {
    const dom = window.dom;
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
    const dom = window.dom;
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

  window.initBusinessTypeAutocomplete = initBusinessTypeAutocomplete;
  window.initLocationSelectors = initLocationSelectors;
  window.initSearchForm = initSearchForm;
  window.executeSearch = executeSearch;
  window.renderResults = renderResults;

})(window);
