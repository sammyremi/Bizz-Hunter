/* public/js/utils/toast.js - Notification Toast System */

(function (window) {
  'use strict';

  function showToast(message, type = 'info') {
    const toastContainer = window.dom ? window.dom.toastContainer : document.getElementById('toast-container');
    if (!toastContainer) return;
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    const iconSvg = window.BizzIcons ? 
      (type === 'success' ? window.BizzIcons.check : (type === 'error' ? window.BizzIcons.alert : window.BizzIcons.sparkles)) 
      : '';
    toast.innerHTML = `<span style="display: inline-flex; align-items: center; justify-content: center; width: 16px; height: 16px;">${iconSvg}</span> <span>${window.escapeHtml(message)}</span>`;

    toastContainer.appendChild(toast);
    setTimeout(() => {
      toast.remove();
    }, 4000);
  }

  window.showToast = showToast;

})(window);
