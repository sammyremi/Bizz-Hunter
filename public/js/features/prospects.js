/* public/js/features/prospects.js - Prospects Backend Persistence Controller */

(function (window) {
  'use strict';

  async function toggleSaveBusiness(business) {
    const state = window.BizzState;
    if (!state.currentUser) {
      window.openAuthModal('login', 'Sign in or create a free account to save prospects to your list!');
      return;
    }

    const placeId = business.id || business.google_place_id;
    const existing = state.savedBusinesses.find(p => p.google_place_id === placeId);

    if (existing) {
      try {
        await window.BizzApi.deleteProspect(existing.id);
        window.showToast(`Removed "${business.name || business.business_name}" from prospects`, 'info');
        await loadUserProspects();
      } catch (err) {
        window.showToast(err.message || 'Failed to remove prospect', 'error');
      }
    } else {
      try {
        await window.BizzApi.saveProspect(business);
        window.showToast(`Saved "${business.name || business.business_name}" to your prospects!`, 'success');
        await loadUserProspects();
      } catch (err) {
        window.showToast(err.message || 'Failed to save prospect', 'error');
      }
    }

    if (state.currentTab === 'find-businesses' && state.searchResults.length > 0) {
      window.renderResults(state.searchResults, state.activeFilters);
    } else {
      await window.renderDashboardAnalytics();
    }
  }

  async function loadUserProspects() {
    const state = window.BizzState;
    if (!state.currentUser) {
      state.savedBusinesses = [];
      renderSavedBusinessesView();
      return;
    }

    try {
      const prospects = await window.BizzApi.getProspects(state.activeProspectStatusFilter);
      state.savedBusinesses = prospects;
      window.updateDashboardMetrics();
      await window.renderDashboardAnalytics();

      if (state.currentTab === 'saved-businesses') {
        renderSavedBusinessesView();
      }
    } catch (err) {
      console.warn('Error loading user prospects', err);
    }
  }

  function renderSavedBusinessesView() {
    const dom = window.dom;
    const state = window.BizzState;
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
      dom.savedGrid.innerHTML = state.savedBusinesses.map(b => window.createBusinessCardHtml(b, true)).join('');
      window.attachCardEventListeners();
    }
  }

  window.toggleSaveBusiness = toggleSaveBusiness;
  window.loadUserProspects = loadUserProspects;
  window.renderSavedBusinessesView = renderSavedBusinessesView;

})(window);
