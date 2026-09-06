/* public/js/features/dashboard.js - Dashboard Metrics & Analytics Summary Component */

(function (window) {
  'use strict';

  function updateDashboardMetrics() {
    const dom = window.dom;
    const state = window.BizzState;

    if (dom.dashKpiSaved) dom.dashKpiSaved.textContent = state.savedBusinesses.length;
    window.renderDashboardAnalytics();
  }

  async function renderDashboardAnalytics() {
    const dom = window.dom;
    const state = window.BizzState;

    let dbAnalytics = null;
    if (state.currentUser) {
      dbAnalytics = await window.BizzApi.getAnalytics();
    }

    const localAnalytics = window.calculateAnalytics(state.searchResults);
    const hasDbData = dbAnalytics && dbAnalytics.businesses_found > 0;
    
    const totalFound = hasDbData ? dbAnalytics.businesses_found : (localAnalytics.totalFound || state.searchedCount);
    const highOpp = hasDbData ? dbAnalytics.high_opportunity : localAnalytics.highOppCount;
    const medOpp = hasDbData ? dbAnalytics.medium_opportunity : localAnalytics.medOppCount;
    const lowOpp = hasDbData ? dbAnalytics.low_opportunity : localAnalytics.lowOppCount;
    const noWebsite = hasDbData ? dbAnalytics.no_website : localAnalytics.noWebsiteCount;
    const whatsapp = hasDbData ? dbAnalytics.whatsapp_available : localAnalytics.whatsappCount;
    const saved = (dbAnalytics && dbAnalytics.saved_prospects !== undefined) ? dbAnalytics.saved_prospects : state.savedBusinesses.length;

    if (dom.dashKpiFound) dom.dashKpiFound.textContent = totalFound;
    if (dom.dashKpiHighOpp) dom.dashKpiHighOpp.textContent = highOpp;
    if (dom.dashKpiNoWebsite) dom.dashKpiNoWebsite.textContent = noWebsite;
    if (dom.dashKpiWhatsapp) dom.dashKpiWhatsapp.textContent = whatsapp;
    if (dom.dashKpiSaved) dom.dashKpiSaved.textContent = saved;

    const colors = window.getChartColors();

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
    const topTypes = (hasDbData && dbAnalytics.top_business_types && dbAnalytics.top_business_types.length > 0) 
      ? dbAnalytics.top_business_types.slice(0, 5) 
      : localAnalytics.sortedTypes.slice(0, 5);

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

  window.updateDashboardMetrics = updateDashboardMetrics;
  window.renderDashboardAnalytics = renderDashboardAnalytics;

})(window);
