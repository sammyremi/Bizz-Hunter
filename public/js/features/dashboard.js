/* public/js/features/dashboard.js - Dashboard Metrics & Analytics Summary Component */

(function (window) {
  'use strict';

  function updateDashboardMetrics() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    const state = window.BizzState;

    if (dom && dom.dashKpiSaved) dom.dashKpiSaved.textContent = state.savedBusinesses ? state.savedBusinesses.length : 0;
    window.renderDashboardAnalytics();
  }

  async function renderDashboardAnalytics() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    const state = window.BizzState;

    let dbAnalytics = null;
    if (state.currentUser) {
      dbAnalytics = await window.BizzApi.getAnalytics();
    }

    const localAnalytics = window.calculateAnalytics(state.searchResults || []);
    const isUserLoggedIn = !!state.currentUser && !!dbAnalytics;

    const totalFound = isUserLoggedIn
      ? (dbAnalytics.businesses_found || 0)
      : (localAnalytics.totalFound || (state.searchResults ? state.searchResults.length : 0));

    const highOpp = isUserLoggedIn
      ? (dbAnalytics.high_opportunity || 0)
      : (localAnalytics.highOppCount || 0);

    const medOpp = isUserLoggedIn
      ? (dbAnalytics.medium_opportunity || 0)
      : (localAnalytics.medOppCount || 0);

    const lowOpp = isUserLoggedIn
      ? (dbAnalytics.low_opportunity || 0)
      : (localAnalytics.lowOppCount || 0);

    const noWebsite = isUserLoggedIn
      ? (dbAnalytics.no_website || 0)
      : (localAnalytics.noWebsiteCount || 0);

    const whatsapp = isUserLoggedIn
      ? (dbAnalytics.whatsapp_available || 0)
      : (localAnalytics.whatsappCount || 0);

    const saved = isUserLoggedIn
      ? (dbAnalytics.saved_prospects !== undefined ? dbAnalytics.saved_prospects : 0)
      : (state.savedBusinesses ? state.savedBusinesses.length : 0);

    if (dom) {
      if (dom.dashKpiFound) dom.dashKpiFound.textContent = totalFound;
      if (dom.dashKpiHighOpp) dom.dashKpiHighOpp.textContent = highOpp;
      if (dom.dashKpiNoWebsite) dom.dashKpiNoWebsite.textContent = noWebsite;
      if (dom.dashKpiWhatsapp) dom.dashKpiWhatsapp.textContent = whatsapp;
      if (dom.dashKpiSaved) dom.dashKpiSaved.textContent = saved;
    }

    const colors = window.getChartColors ? window.getChartColors() : {
      highOpp: '#ef4444', medOpp: '#f59e0b', lowOpp: '#10b981',
      borderColor: '#374151', textColor: '#f3f4f6', primary: '#3b82f6'
    };

    // 1. Dashboard Donut Chart
    window.createChart('dash-chart-opportunity', {
      type: 'doughnut',
      data: {
        labels: ['High Opportunity', 'Medium Opportunity', 'Low Opportunity'],
        datasets: [{
          data: [highOpp, medOpp, lowOpp],
          backgroundColor: [colors.highOpp, colors.medOpp, colors.lowOpp],
          borderWidth: 2,
          borderColor: colors.borderColor
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { labels: { color: colors.textColor, font: { weight: '600' } } }
        }
      }
    });

    // 2. Dashboard Top Types Chart
    const topTypes = (isUserLoggedIn && dbAnalytics.top_business_types && dbAnalytics.top_business_types.length > 0)
      ? dbAnalytics.top_business_types.slice(0, 5)
      : (localAnalytics.sortedTypes ? localAnalytics.sortedTypes.slice(0, 5) : []);

    window.createChart('dash-chart-types', {
      type: 'bar',
      data: {
        labels: topTypes.length > 0 ? topTypes.map(t => t.type) : ['No Data'],
        datasets: [{
          label: 'Businesses',
          data: topTypes.length > 0 ? topTypes.map(t => t.count) : [0],
          backgroundColor: colors.primary,
          borderRadius: 6
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: colors.textColor }, grid: { color: colors.borderColor } },
          y: { ticks: { color: colors.textColor }, grid: { display: false } }
        }
      }
    });

    // Setup Quick Action Buttons on Dashboard
    if (dom) {
      if (dom.dashBtnViewAnalysis) {
        dom.dashBtnViewAnalysis.onclick = () => window.switchTab('analysis');
      }
      if (dom.dashBtnViewHighOpps) {
        dom.dashBtnViewHighOpps.onclick = () => window.filterResultsBy('high_opp');
      }
      if (dom.dashBtnViewSaved) {
        dom.dashBtnViewSaved.onclick = () => window.switchTab('saved-businesses');
      }
    }
  }

  window.updateDashboardMetrics = updateDashboardMetrics;
  window.renderDashboardAnalytics = renderDashboardAnalytics;

})(window);
