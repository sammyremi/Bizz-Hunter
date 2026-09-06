/* public/js/components/modal.js - Modals and Auth Dialog Controller */

(function (window) {
  'use strict';

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
    const dom = window.dom;
    if (dom.authModal) dom.authModal.classList.remove('active');
    if (dom.detailsModal) dom.detailsModal.classList.remove('active');
  }

  function openAuthModal(mode = 'login', bannerMsg = null) {
    const dom = window.dom;
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
    const dom = window.dom;
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
    const dom = window.dom;
    if (dom.modalAuthError) {
      dom.modalAuthError.textContent = msg;
      dom.modalAuthError.style.display = 'block';
    }
  }

  function clearAuthModalErrors() {
    const dom = window.dom;
    if (dom.modalAuthError) {
      dom.modalAuthError.textContent = '';
      dom.modalAuthError.style.display = 'none';
    }
  }

  function openDetailsModal(b) {
    const dom = window.dom;
    const name = b.name || b.business_name;
    const waUrl = window.buildWhatsAppUrl(b);
    const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';

    dom.detailsModalBody.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 1rem;">
        <div>
          <h2 style="font-size: 1.4rem; font-weight: 800; margin-bottom: 0.25rem;">${window.escapeHtml(name)}</h2>
          <div style="color: var(--text-muted); font-size: 0.9rem;">${b.types ? (Array.isArray(b.types) ? b.types.slice(0, 3).join(' • ') : b.types) : (b.category || 'Business')}</div>
        </div>
        <div class="card-rating-badge">
          ★ ${b.rating ? Number(b.rating).toFixed(1) : 'N/A'}
        </div>
      </div>

      <div style="background: var(--bg-surface); border: 1px solid var(--border-color); padding: 1rem; border-radius: var(--radius-md); margin-bottom: 1.25rem; font-size: 0.9rem; display: flex; flex-direction: column; gap: 0.5rem;">
        <div><strong>Address:</strong> ${window.escapeHtml(b.address || 'Unavailable')}</div>
        <div><strong>Phone (International):</strong> ${window.escapeHtml(b.phone || b.phone_number || 'Unavailable')}</div>
        <div><strong>Phone (National):</strong> ${window.escapeHtml(b.national_phone || b.international_phone_number || 'Unavailable')}</div>
        <div><strong>Website:</strong> ${b.website ? `<a href="${b.website}" target="_blank">${window.escapeHtml(b.website)}</a>` : '<span style="color: #ef4444; font-weight: 600;">No Website (Lead Opportunity)</span>'}</div>
      </div>

      <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
        ${waUrl ? `<a href="${waUrl}" target="_blank" class="btn btn-whatsapp btn-block">💬 Contact on WhatsApp</a>` : ''}
        ${rawPhone ? `<a href="tel:${rawPhone}" class="btn btn-secondary btn-block">📞 Direct Phone Call</a>` : ''}
        ${b.google_maps_url ? `<a href="${b.google_maps_url}" target="_blank" class="btn btn-secondary btn-block">🗺️ Open in Google Maps</a>` : ''}
      </div>
    `;

    dom.detailsModal.classList.add('active');
  }

  window.initModals = initModals;
  window.closeModals = closeModals;
  window.openAuthModal = openAuthModal;
  window.toggleAuthTab = toggleAuthTab;
  window.showAuthModalError = showAuthModalError;
  window.clearAuthModalErrors = clearAuthModalErrors;
  window.openDetailsModal = openDetailsModal;

})(window);
