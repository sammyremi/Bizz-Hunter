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
    let qrWaUrl = b.whatsapp_url || window.buildWhatsAppUrl(b);

    // Fallback: If whatsapp_url was not prebuilt on backend, compute personalized QR WhatsApp URL using search template
    if (!b.whatsapp_url && hasPhone) {
      const template = window.BizzState ? (window.BizzState.qrMessageTemplate || '') : '';
      if (template) {
        const bName = b.name || b.business_name || 'there';
        const personalizedMsg = template.replace(/\{\{\s*business_name\s*\}\}/g, bName);
        qrWaUrl = window.buildWhatsAppUrl(b, personalizedMsg) || window.buildWhatsAppUrl(b);
      }
    }

    // DIRECT PERMANENT LARGE SCANNABLE SVG QR CODE INJECTION
    let qrSvgHtml = '';
    if (qrWaUrl && window.QRCodeGenerator) {
      // DEV: log first QR payload so it can be independently verified in browser devtools
      if (!window._qrPayloadLogged) {
        window._qrPayloadLogged = true;
        const template = window.BizzState ? (window.BizzState.qrMessageTemplate || '') : '';
        console.group('[QR DEBUG] First business card QR payload');
        console.log('Business:', b.name || b.business_name);
        console.log('Raw phone:', b.phone || b.phone_number || b.international_phone_number || '(none)');
        console.log('Template present:', Boolean(template));
        if (template) {
          const bName = b.name || b.business_name || 'there';
          const personalizedMsg = template.replace(/\{\{\s*business_name\s*\}\}/g, bName);
          console.log('Personalized message:', personalizedMsg);
        }
        console.log('QR payload:', qrWaUrl);
        console.log('Has ?text=:', qrWaUrl.includes('?text='));
        console.groupEnd();
      }
      qrSvgHtml = window.QRCodeGenerator(qrWaUrl);
    }

    // Opportunity Score & Tier (from backend)
    const oppLevel = b.opportunity_level || (b.opportunity_tier ? b.opportunity_tier.toUpperCase() : (!hasWebsite ? 'HIGH' : 'STANDARD'));
    const oppScore = (typeof b.opportunity_score === 'number') ? b.opportunity_score : null;
    const isPersonalized = Boolean(b.personalized_score);
    const categoryName = (b.category || b.types?.[0] || 'Business').replace(/_/g, ' ').toUpperCase();
    const ratingVal = b.rating ? Number(b.rating).toFixed(1) : 'N/A';
    const reviewCountText = b.review_count ? `(${Number(b.review_count).toLocaleString()})` : '';
    const opportunityFactors = Array.isArray(b.opportunity_factors) ? b.opportunity_factors : [];

    return `
      <div class="business-card" data-id="${placeId}" data-db-id="${b.id || ''}">
        
        <!-- Left Panel: Details, Badges, Tags, Actions -->
        <div class="card-left-content">
          <div>
            <div class="card-top-tags">
              <div class="category-tag">
                <span>${window.escapeHtml(categoryName)}</span>
                <span class="opp-badge ${oppLevel}">
                  ${oppScore !== null ? `<span class="opp-score-num">${oppScore}</span>` : ''}
                  ${oppLevel} OPPORTUNITY
                  ${isPersonalized ? '<span class="opp-personalized-dot" title="Personalized score">●</span>' : ''}
                </span>
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
              ${opportunityFactors.length > 0
                ? opportunityFactors.map(f => `<span class="signal-tag">✓ ${window.escapeHtml(f)}</span>`).join('')
                : `
                  ${!hasWebsite ? '<span class="signal-tag">No website found</span>' : '<span class="signal-tag">Website active</span>'}
                  ${b.rating >= 4.5 ? '<span class="signal-tag">High rating (4.5+)</span>' : ''}
                  ${b.review_count >= 100 ? `<span class="signal-tag">${Number(b.review_count).toLocaleString()}+ reviews</span>` : ''}
                  ${waUrl ? '<span class="signal-tag">WhatsApp reachable</span>' : ''}
                `
              }
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

            <div class="whatsapp-dropdown-container" style="position: relative; width: 100%;">
              <button type="button" class="btn btn-whatsapp btn-sm btn-block whatsapp-dropdown-trigger" data-place-id="${placeId}">
                <span>💬</span> WhatsApp <span style="font-size: 0.75rem; margin-left: 2px;">▼</span>
              </button>
              <div class="whatsapp-dropdown-menu" id="wa-menu-${placeId}" style="display: none; position: absolute; bottom: 100%; left: 0; width: 100%; background: var(--bg-surface, #1e293b); border: 1px solid var(--border-color, #334155); border-radius: var(--radius-md, 8px); box-shadow: 0 10px 25px rgba(0,0,0,0.5); z-index: 100; margin-bottom: 6px; overflow: hidden;">
                <a href="${qrWaUrl}" target="_blank" rel="noopener" class="wa-open-link" style="display: flex; align-items: center; gap: 0.5rem; padding: 0.65rem 0.8rem; color: var(--text-main, #f8fafc); font-size: 0.825rem; text-decoration: none; font-weight: 600; border-bottom: 1px solid var(--border-color, #334155);">
                  <span>📱</span> Open WhatsApp
                </a>
                <button type="button" class="wa-generate-msg-btn" data-place-id="${placeId}" style="display: flex; align-items: center; gap: 0.5rem; padding: 0.65rem 0.8rem; color: #38bdf8; font-size: 0.825rem; background: transparent; border: none; width: 100%; text-align: left; cursor: pointer; font-weight: 700;">
                  <span>✨</span> Generate Message
                </button>
              </div>
            </div>
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
    // WhatsApp Dropdown Trigger Toggle
    document.querySelectorAll('.whatsapp-dropdown-trigger').forEach(trigger => {
      trigger.addEventListener('click', (e) => {
        e.stopPropagation();
        const placeId = trigger.getAttribute('data-place-id');
        const menu = document.getElementById(`wa-menu-${placeId}`);
        if (!menu) return;

        // Close all other open menus first
        document.querySelectorAll('.whatsapp-dropdown-menu').forEach(m => {
          if (m !== menu) m.style.display = 'none';
        });

        menu.style.display = (menu.style.display === 'block') ? 'none' : 'block';
      });
    });

    // Close WhatsApp dropdown menus on click outside
    document.addEventListener('click', () => {
      document.querySelectorAll('.whatsapp-dropdown-menu').forEach(menu => {
        menu.style.display = 'none';
      });
    });

    // Generate AI WhatsApp Message Action
    document.querySelectorAll('.wa-generate-msg-btn').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        e.stopPropagation();
        const placeId = btn.getAttribute('data-place-id');
        const menu = document.getElementById(`wa-menu-${placeId}`);
        if (menu) menu.style.display = 'none';

        if (!window.BizzApi.getToken()) {
          window.openAuthModal('login', 'Please log in or create an account to generate personalized AI outreach messages.');
          return;
        }

        const triggerBtn = document.querySelector(`.whatsapp-dropdown-trigger[data-place-id="${placeId}"]`);
        if (triggerBtn && triggerBtn.disabled) return; // Prevent duplicate request while generating

        const b = state.searchResults.find(item => item.id === placeId || item.google_place_id === placeId) ||
                  state.savedBusinesses.find(item => item.google_place_id === placeId || String(item.id) === String(placeId));

        const resultId = (b && (b.id || b.google_place_id)) || placeId;

        // Synchronously open blank window during user gesture to bypass browser popup blockers
        const newWindow = window.open('about:blank', '_blank');

        // Immediate Loading State on dropdown trigger button
        if (triggerBtn) {
          triggerBtn.disabled = true;
          triggerBtn.innerHTML = '<span>⏳</span> Generating...';
        }
        btn.disabled = true;

        try {
          const res = await window.BizzApi.generateOutreachMessage(resultId);

          if (res && res.whatsapp_url) {
            window.showToast('Message generated! Opening WhatsApp...', 'success');
            if (newWindow && !newWindow.closed) {
              newWindow.location.href = res.whatsapp_url;
            } else {
              window.open(res.whatsapp_url, '_blank', 'noopener,noreferrer') || (window.location.href = res.whatsapp_url);
            }
          } else {
            if (newWindow && !newWindow.closed) newWindow.close();
            throw new Error('WhatsApp URL was not returned.');
          }
        } catch (err) {
          if (newWindow && !newWindow.closed) newWindow.close();
          window.showToast(err.message || 'Unable to generate the WhatsApp message. Please try again.', 'error');
        } finally {
          if (triggerBtn) {
            triggerBtn.disabled = false;
            triggerBtn.innerHTML = '<span>💬</span> WhatsApp <span style="font-size: 0.75rem; margin-left: 2px;">▼</span>';
          }
          btn.disabled = false;
        }
      });
    });
  }

  window.createBusinessCardHtml = createBusinessCardHtml;
  window.attachCardEventListeners = attachCardEventListeners;

})(window);
