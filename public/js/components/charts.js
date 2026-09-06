/* public/js/components/charts.js - Chart.js Wrapper Component */

(function (window) {
  'use strict';

  const activeCharts = {};

  function getChartColors() {
    const isLight = window.BizzState.theme === 'light';
    return {
      textColor: isLight ? '#0f172a' : '#f8fafc',
      textMuted: isLight ? '#64748b' : '#94a3b8',
      borderColor: isLight ? '#e2e8f0' : '#1e293b',
      primary: isLight ? '#2563eb' : '#3b82f6',
      primaryLight: isLight ? 'rgba(37, 99, 235, 0.15)' : 'rgba(59, 130, 246, 0.15)',
      highOpp: '#10b981',
      medOpp: '#f59e0b',
      lowOpp: '#94a3b8',
      noWebsite: '#ef4444',
      hasWebsite: isLight ? '#2563eb' : '#3b82f6',
      phone: '#3b82f6',
      whatsapp: '#25d366',
      noPhone: '#64748b'
    };
  }

  function createChart(canvasId, config) {
    if (!window.Chart) return null;
    const canvas = document.getElementById(canvasId);
    if (!canvas) return null;

    if (activeCharts[canvasId]) {
      activeCharts[canvasId].destroy();
    }

    activeCharts[canvasId] = new window.Chart(canvas.getContext('2d'), config);
    return activeCharts[canvasId];
  }

  window.getChartColors = getChartColors;
  window.createChart = createChart;

})(window);
