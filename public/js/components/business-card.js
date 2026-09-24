/* public/js/components/business-card.js - Business Card Generator & Event Handlers */

(function (window) {
  'use strict';

  // Inline SVG icon constants for clean, professional rendering without emojis
  const ICONS = {
    star: '<svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor" style="color: #f59e0b;"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>',
    pin: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 1 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>',
    phone: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>',
    globe: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>',
    sparkles: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2l2.4 7.2L22 12l-7.6 2.8L12 22l-2.4-7.2L2 12l7.6-2.8L12 2z"/></svg>',
    bookmark: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/></svg>',
    copy: '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>',
    trash: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>'
  };

  function createBusinessCardHtml(b, isProspectView = false) {
    const state = window.BizzState;
    const placeId = b.google_place_id || b.id;
    const isSaved = state.savedBusinesses.some(saved => saved.google_place_id === placeId || saved.id === placeId);
    const hasWebsite = Boolean(b.website);
    const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';
    const hasPhone = Boolean(rawPhone);
    const formattedPhone = b.national_phone || b.international_phone_number || b.phone || b.phone_number || 'No Phone Number';

    // WhatsApp URL Link
    const waUrl = b.whatsapp_url || (window.buildWhatsAppUrl ? window.buildWhatsAppUrl(b) : null);

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
        
        <!-- Main Card Content Flow -->
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
              <div class="card-rating-badge" style="display: flex; align-items: center; gap: 0.35rem;">
                ${ICONS.star} <span>${ratingVal}</span> <span style="font-size: 0.8rem; color: var(--text-muted); font-weight: 500;">${reviewCountText}</span>
              </div>
            </div>

            <h3 class="card-business-name">${window.escapeHtml(b.name || b.business_name)}</h3>

            <div class="card-info-rows">
              <div class="info-row">
                <span style="display: inline-flex; align-items: center; color: var(--text-muted);">${ICONS.pin}</span>
                <span>${window.escapeHtml(b.address || 'Address unavailable')}</span>
              </div>
              <div class="info-row">
                <span style="display: inline-flex; align-items: center; color: var(--text-muted);">${ICONS.phone}</span>
                <span>${window.escapeHtml(formattedPhone)}</span>
                ${hasPhone ? `<button class="copy-icon-btn" title="Copy Phone Number" data-phone="${window.escapeHtml(formattedPhone)}" style="background: transparent; border: none; cursor: pointer; color: var(--text-muted); padding: 0 4px;">${ICONS.copy}</button>` : ''}
              </div>
              <div class="info-row">
                <span style="display: inline-flex; align-items: center; color: var(--text-muted);">${ICONS.globe}</span>
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
                    <option value="NEW" ${b.status === 'NEW' ? 'selected' : ''}>New</option>
                    <option value="CONTACTED" ${b.status === 'CONTACTED' ? 'selected' : ''}>Contacted</option>
                    <option value="INTERESTED" ${b.status === 'INTERESTED' ? 'selected' : ''}>Interested</option>
                    <option value="CONVERTED" ${b.status === 'CONVERTED' ? 'selected' : ''}>Converted</option>
                    <option value="NOT_INTERESTED" ${b.status === 'NOT_INTERESTED' ? 'selected' : ''}>Not Interested</option>
                  </select>
                </div>

                <div style="display: flex; gap: 0.4rem;">
                  <input type="text" class="form-control prospect-notes-input" data-id="${b.id}" placeholder="Add notes (e.g. Spoke to manager)..." value="${window.escapeHtml(b.notes || '')}" style="font-size: 0.8rem; padding: 0.35rem 0.5rem;">
                  <button type="button" class="btn btn-secondary btn-sm save-notes-btn" data-id="${b.id}" style="white-space: nowrap;">Save Note</button>
                </div>
              </div>
            ` : ''}
          </div>

          <!-- Unified Action Bar -->
          <div class="card-actions-bar">
            ${isProspectView ? `
              <button class="btn btn-secondary btn-sm remove-prospect-btn" data-id="${b.id}" style="color: #ef4444;">
                ${ICONS.trash} <span>Remove</span>
              </button>
            ` : `
              <button class="btn ${isSaved ? 'btn-secondary' : 'btn-primary'} btn-sm save-btn" data-id="${placeId}">
                ${ICONS.bookmark} <span>${isSaved ? 'Saved' : 'Save prospect'}</span>
              </button>
            `}

            <button class="btn btn-secondary btn-sm details-btn" data-id="${placeId}">
              ${ICONS.phone} <span>Call / Details</span>
            </button>

            <!-- Primary Action: AI Prospect Brief -->
            <button type="button" class="btn btn-primary btn-sm brief-btn" data-id="${placeId}" style="font-weight: 700;">
              ${ICONS.sparkles} <span>${(window.hasCachedBrief && window.hasCachedBrief(b)) ? 'Show Brief' : 'AI Prospect Brief'}</span>
            </button>

            <!-- WhatsApp Dropdown Trigger -->
            ${waUrl ? `
              <div class="whatsapp-dropdown-container" style="position: relative; display: inline-block;">
                <button type="button" class="btn btn-whatsapp btn-sm whatsapp-dropdown-trigger" data-place-id="${placeId}">
                  <span>WhatsApp</span> <span style="font-size: 0.7rem; margin-left: 2px;">▼</span>
                </button>
                <div class="whatsapp-dropdown-menu" id="wa-menu-${placeId}" style="display: none; position: absolute; bottom: 100%; left: 0; min-width: 170px; background: var(--bg-surface, #1e293b); border: 1px solid var(--border-color, #334155); border-radius: var(--radius-md, 8px); box-shadow: 0 10px 25px rgba(0,0,0,0.5); z-index: 100; margin-bottom: 6px; overflow: hidden;">
                  <a href="${waUrl}" target="_blank" rel="noopener" class="wa-open-link" style="display: flex; align-items: center; gap: 0.5rem; padding: 0.65rem 0.8rem; color: var(--text-main, #f8fafc); font-size: 0.825rem; text-decoration: none; font-weight: 600; border-bottom: 1px solid var(--border-color, #334155);">
                    Open WhatsApp
                  </a>
                  <button type="button" class="wa-generate-msg-btn" data-place-id="${placeId}" style="display: flex; align-items: center; gap: 0.5rem; padding: 0.65rem 0.8rem; color: #38bdf8; font-size: 0.825rem; background: transparent; border: none; width: 100%; text-align: left; cursor: pointer; font-weight: 700;">
                    Generate Message
                  </button>
                </div>
              </div>
            ` : `
              <button class="btn btn-secondary btn-sm" disabled style="opacity: 0.6;">No Phone Line</button>
            `}
          </div>
        </div>

        <!-- Inline AI Prospect Brief Container (Full Width) -->
        <div class="inline-brief-container" id="brief-container-${placeId}" style="display: none;"></div>

      </div>
    `;
  }

  function attachCardEventListeners() {
    const state = window.BizzState;

    // AI Prospect Brief Button (Inline Toggle)
    document.querySelectorAll('.brief-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        const id = btn.getAttribute('data-id');
        const isSavedTab = (state.currentTab === 'saved-businesses');
        const b = isSavedTab
          ? (state.savedBusinesses.find(item => String(item.id) === String(id) || item.google_place_id === id) ||
             state.searchResults.find(item => item.id === id || item.google_place_id === id))
          : (state.searchResults.find(item => item.id === id || item.google_place_id === id) ||
             state.savedBusinesses.find(item => item.google_place_id === id || String(item.id) === String(id)));
        if (b && window.toggleInlineProspectBrief) {
          window.toggleInlineProspectBrief(b, btn);
        } else if (b && window.openProspectBriefModal) {
          window.openProspectBriefModal(b, btn);
        }
      });
    });

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

        const isGuest = !state.currentUser;
        if (isGuest && window.GuestLimits && !window.GuestLimits.canGenerateMessage()) {
          if (window.openFeatureUnlockModal) {
            window.openFeatureUnlockModal(
              "Free preview limit reached",
              "Create a free account to continue.",
              'register'
            );
          }
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
          triggerBtn.innerHTML = '<span>Generating...</span>';
        }
        btn.disabled = true;

        try {
          const res = await window.BizzApi.generateOutreachMessage(resultId);

          if (res && res.whatsapp_url) {
            if (isGuest && window.GuestLimits) {
              window.GuestLimits.incrementMessage();
            }
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
            triggerBtn.innerHTML = '<span>WhatsApp</span> <span style="font-size: 0.7rem; margin-left: 2px;">▼</span>';
          }
          btn.disabled = false;
        }
      });
    });
  }

  window.createBusinessCardHtml = createBusinessCardHtml;
  window.attachCardEventListeners = attachCardEventListeners;

})(window);
