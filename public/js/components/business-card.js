/* public/js/components/business-card.js - Business Card Generator & Event Handlers */

(function (window) {
  'use strict';

  function createBusinessCardHtml(b, isProspectView = false) {
    const state = window.BizzState;
    const placeId = b.google_place_id || b.id;
    const isSaved = state.savedBusinesses.some(saved => saved.google_place_id === placeId || saved.id === placeId);
    const hasWebsite = Boolean(b.website);
    const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';
    const hasPhone = Boolean(rawPhone);
    const formattedPhone = b.national_phone || b.international_phone_number || b.phone || b.phone_number || 'No Phone Number';

    // WhatsApp URL & Direct QR Code SVG Rendering
    const waUrl = window.buildWhatsAppUrl(b);

    // DIRECT PERMANENT LARGE SCANNABLE SVG QR CODE INJECTION
    let qrSvgHtml = '';
    if (waUrl && window.QRCodeGenerator) {
      qrSvgHtml = window.QRCodeGenerator(waUrl, { size: 144, colorDark: '#0b0f19', colorLight: '#ffffff' });
    }

    // Opportunity Signals & Score
    const oppLevel = b.opportunity_level || (!hasWebsite ? 'HIGH' : 'STANDARD');
    const categoryName = (b.category || b.types?.[0] || 'Business').replace(/_/g, ' ').toUpperCase();
    const ratingVal = b.rating ? Number(b.rating).toFixed(1) : 'N/A';
    const reviewCountText = b.review_count ? `(${Number(b.review_count).toLocaleString()})` : '';

    return `
      <div class="business-card" data-id="${placeId}" data-db-id="${b.id || ''}">
        
        <!-- Left Panel: Details, Badges, Tags, Actions -->
        <div class="card-left-content">
          <div>
            <div class="card-top-tags">
              <div class="category-tag">
                <span>${window.escapeHtml(categoryName)}</span>
                <span class="opp-badge ${oppLevel}">${oppLevel} OPPORTUNITY</span>
              </div>
              <div class="card-rating-badge">
                <span>★</span> ${ratingVal} <span style="font-size: 0.8rem; color: var(--text-muted); font-weight: 500;">${reviewCountText}</span>
              </div>
            </div>

            <h3 class="card-business-name">${window.escapeHtml(b.name || b.business_name)}</h3>

            <div class="card-info-rows">
              <div class="info-row">
                <span>📍</span>
                <span>${window.escapeHtml(b.address || 'Address unavailable')}</span>
              </div>
              <div class="info-row">
                <span>📞</span>
                <span>${window.escapeHtml(formattedPhone)}</span>
                ${hasPhone ? `<button class="copy-icon-btn" title="Copy Phone Number" data-phone="${window.escapeHtml(formattedPhone)}">📋</button>` : ''}
              </div>
              <div class="info-row">
                <span>🌐</span>
                ${hasWebsite ? `
                  <a href="${b.website}" target="_blank" rel="noopener" style="color: var(--primary); text-decoration: underline;">${window.escapeHtml(b.website)}</a>
                ` : `
                  <span class="badge-no-website">NO WEBSITE</span>
                  <span style="font-size: 0.85rem; color: var(--text-muted); font-weight: 600;">Direct lead opportunity</span>
                `}
              </div>
            </div>

            <div class="signal-tags-group">
              ${!hasWebsite ? '<span class="signal-tag">No website found</span>' : '<span class="signal-tag">Website active</span>'}
              ${b.rating >= 4.5 ? '<span class="signal-tag">High rating (4.5+)</span>' : ''}
              ${b.review_count >= 100 ? `<span class="signal-tag">${Number(b.review_count).toLocaleString()}+ reviews</span>` : ''}
              ${waUrl ? '<span class="signal-tag">WhatsApp reachable</span>' : ''}
            </div>

            ${isProspectView ? `
              <!-- Prospect Status & Notes Controls -->
              <div style="background: var(--bg-surface); border: 1px solid var(--border-color); border-radius: var(--radius-md); padding: 0.75rem; margin-top: 0.75rem; display: flex; flex-direction: column; gap: 0.6rem;">
                <div style="display: flex; align-items: center; justify-content: space-between; gap: 0.5rem;">
                  <label style="font-size: 0.8rem; font-weight: 700; color: var(--text-muted);">Status:</label>
                  <select class="form-select prospect-status-select" data-id="${b.id}" style="padding: 0.25rem 0.5rem; font-size: 0.825rem; width: auto;">
                    <option value="NEW" ${b.status === 'NEW' ? 'selected' : ''}>🆕 New</option>
                    <option value="CONTACTED" ${b.status === 'CONTACTED' ? 'selected' : ''}>💬 Contacted</option>
                    <option value="INTERESTED" ${b.status === 'INTERESTED' ? 'selected' : ''}>🔥 Interested</option>
                    <option value="CONVERTED" ${b.status === 'CONVERTED' ? 'selected' : ''}>🎉 Converted</option>
                    <option value="NOT_INTERESTED" ${b.status === 'NOT_INTERESTED' ? 'selected' : ''}>🚫 Not Interested</option>
                  </select>
                </div>

                <div style="display: flex; gap: 0.4rem;">
                  <input type="text" class="form-control prospect-notes-input" data-id="${b.id}" placeholder="Add notes (e.g. Spoke to manager)..." value="${window.escapeHtml(b.notes || '')}" style="font-size: 0.8rem; padding: 0.35rem 0.5rem;">
                  <button type="button" class="btn btn-secondary btn-sm save-notes-btn" data-id="${b.id}" style="white-space: nowrap;">Save Note</button>
                </div>
              </div>
            ` : ''}
          </div>

          <div class="card-actions-left">
            ${isProspectView ? `
              <button class="btn btn-secondary btn-sm remove-prospect-btn" data-id="${b.id}" style="color: #ef4444;">
                <span>🗑️</span> Remove
              </button>
            ` : `
              <button class="btn ${isSaved ? 'btn-secondary' : 'btn-primary'} btn-sm save-btn" data-id="${placeId}">
                <span>${isSaved ? '❤️ Saved' : '🔖 Save prospect'}</span>
              </button>
            `}

            <button class="btn btn-secondary btn-sm details-btn" data-id="${placeId}">
              <span>📞</span> Call / Details
            </button>
          </div>
        </div>

        <!-- Right Panel: PERMANENT VISIBLE LARGE SCANNABLE QR CODE -->
        <div class="card-right-panel" style="justify-content: center; gap: 0.75rem;">
          ${waUrl ? `
            <div class="qr-visible-box">
              ${qrSvgHtml}
            </div>
            <div class="qr-caption-subtext">Scan to WhatsApp</div>

            <a href="${waUrl}" target="_blank" rel="noopener" class="btn btn-whatsapp btn-sm btn-block">
              <span>💬</span> WhatsApp
            </a>
          ` : `
            <div style="padding: 2rem 0; color: var(--text-dim); font-size: 0.85rem;">
              <div>NO PHONE NUMBER</div>
              <div style="font-size: 0.75rem; margin-top: 4px;">QR unavailable</div>
            </div>
            <button class="btn btn-secondary btn-sm btn-block" disabled>No Phone Line</button>
          `}
        </div>

      </div>
    `;
  }

  function attachCardEventListeners() {
    const state = window.BizzState;

    // Copy Phone Number Button
    document.querySelectorAll('.copy-icon-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const phone = btn.getAttribute('data-phone');
        if (phone) {
          navigator.clipboard.writeText(phone);
          window.showToast(`Copied ${phone} to clipboard!`, 'success');
        }
      });
    });

    // Save prospect button
    document.querySelectorAll('.save-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        const id = btn.getAttribute('data-id');
        const b = state.searchResults.find(item => item.id === id || item.google_place_id === id);
        if (b) await window.toggleSaveBusiness(b);
      });
    });

    // Details modal
    document.querySelectorAll('.details-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const b = state.searchResults.find(item => item.id === id || item.google_place_id === id) ||
                  state.savedBusinesses.find(item => item.google_place_id === id || String(item.id) === String(id));
        if (b) window.openDetailsModal(b);
      });
    });

    // Prospect Status Dropdown Change
    document.querySelectorAll('.prospect-status-select').forEach(select => {
      select.addEventListener('change', async () => {
        const dbId = select.getAttribute('data-id');
        const newStatus = select.value;
        try {
          await window.BizzApi.updateProspect(dbId, { status: newStatus });
          window.showToast(`Status updated to ${newStatus}`, 'success');
          await window.loadUserProspects();
        } catch (err) {
          window.showToast(err.message || 'Failed to update status', 'error');
        }
      });
    });

    // Prospect Notes Save
    document.querySelectorAll('.save-notes-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        const dbId = btn.getAttribute('data-id');
        const input = document.querySelector(`.prospect-notes-input[data-id="${dbId}"]`);
        const notes = input ? input.value.trim() : '';

        try {
          await window.BizzApi.updateProspect(dbId, { notes: notes });
          window.showToast('Note saved successfully', 'success');
        } catch (err) {
          window.showToast(err.message || 'Failed to save note', 'error');
        }
      });
    });

    // Delete Prospect
    document.querySelectorAll('.remove-prospect-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        const dbId = btn.getAttribute('data-id');
        if (confirm('Are you sure you want to delete this prospect?')) {
          try {
            await window.BizzApi.deleteProspect(dbId);
            window.showToast('Prospect deleted', 'info');
            await window.loadUserProspects();
          } catch (err) {
            window.showToast(err.message || 'Failed to delete prospect', 'error');
          }
        }
      });
    });
  }

  window.createBusinessCardHtml = createBusinessCardHtml;
  window.attachCardEventListeners = attachCardEventListeners;

})(window);
