/* public/js/utils/toast.js - Notification Toast System */

(function (window) {
  'use strict';

  function showToast(message, type = 'info') {
    const toastContainer = window.dom ? window.dom.toastContainer : document.getElementById('toast-container');
    if (!toastContainer) return;
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `<span>${type === 'success' ? '✅' : (type === 'error' ? '⚠️' : 'ℹ️')}</span> <span>${window.escapeHtml(message)}</span>`;

    toastContainer.appendChild(toast);
    setTimeout(() => {
      toast.remove();
    }, 4000);
  }

  window.showToast = showToast;

})(window);
