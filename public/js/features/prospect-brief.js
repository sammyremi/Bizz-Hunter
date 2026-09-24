/* public/js/features/prospect-brief.js - Inline AI Prospect Brief Feature Module */

(function (window) {
  'use strict';

  // In-memory session cache for AI Prospect Briefs to prevent redundant API calls
  // Key format: `${placeId}:${profileId}`
  const briefCache = new Map();

  // Tracks in-flight requests to prevent duplicate API calls while one is running
  const inFlight = new Set();

  function getBriefCacheKey(b) {
    if (!b) return '';
    const placeId = b.google_place_id || b.id;
    const profileId = b.prospecting_profile_id ||
                      (window.BizzState && (window.BizzState.selectedProspectingProfileId ||
                       (window.BizzState.activeSearchProfile && window.BizzState.activeSearchProfile.id))) ||
                      'default';
    return `${placeId}:${profileId}`;
  }

  function getResolvedBriefEntry(b) {
    if (!b) return null;
    const exactKey = getBriefCacheKey(b);
    if (briefCache.has(exactKey)) {
      return { key: exactKey, data: briefCache.get(exactKey) };
    }

    const placeId = b.google_place_id || b.id;
    const currentProfileId = b.prospecting_profile_id ||
                             (window.BizzState && (window.BizzState.selectedProspectingProfileId ||
                              (window.BizzState.activeSearchProfile && window.BizzState.activeSearchProfile.id)));

    for (const [key, data] of briefCache.entries()) {
      if (key.startsWith(`${placeId}:`)) {
        if (currentProfileId && data.prospecting_profile_id) {
          if (String(data.prospecting_profile_id) === String(currentProfileId)) {
            return { key, data };
          }
        } else if (!currentProfileId) {
          return { key, data };
        }
      }
    }

    return null;
  }

  function hasCachedBrief(b) {
    return getResolvedBriefEntry(b) !== null;
  }

  function getCachedBrief(b) {
    const entry = getResolvedBriefEntry(b);
    return entry ? entry.data : null;
  }

  async function toggleInlineProspectBrief(b, triggerBtn) {
    if (!b) return;

    const isGuest = !(window.BizzState && window.BizzState.currentUser);
    const placeId = b.google_place_id || b.id;
    const containerEl = document.getElementById(`brief-container-${placeId}`);
    if (!containerEl) return;

    const cacheKey = getBriefCacheKey(b);
    const resolvedEntry = getResolvedBriefEntry(b);

    // Scenario 1: If currently visible, collapse it!
    if (containerEl.style.display !== 'none') {
      containerEl.style.display = 'none';
      if (triggerBtn) {
        triggerBtn.innerHTML = resolvedEntry ? '<span>Show Brief</span>' : '<span>AI Prospect Brief</span>';
        triggerBtn.classList.remove('btn-secondary');
        triggerBtn.classList.add('btn-primary');
      }
      return;
    }

    // Scenario 2: If a cached brief ALREADY exists, reveal it INSTANTLY without API calls or spinners!
    if (resolvedEntry) {
      containerEl.style.display = 'block';
      renderInlineBriefContent(containerEl, b, resolvedEntry.data, triggerBtn);
      containerEl.setAttribute('data-loaded', 'true');
      return;
    }

    // Scenario 3: Guest Limit check for first-time AI Brief generation
    if (isGuest && window.GuestLimits && !window.GuestLimits.canGenerateBrief()) {
      if (window.openFeatureUnlockModal) {
        window.openFeatureUnlockModal(
          "Free preview limit reached",
          "Create a free account to continue.",
          'register'
        );
      }
      return;
    }

    // Scenario 4: First-time generation request
    if (inFlight.has(cacheKey)) return;
    inFlight.add(cacheKey);

    // Set loading state on the trigger button immediately
    if (triggerBtn) {
      triggerBtn.disabled = true;
      triggerBtn.innerHTML = '<span>Generating...</span>';
    }

    // Expand container and render inline loading state
    containerEl.style.display = 'block';
    containerEl.innerHTML = `
      <div style="padding: 1.25rem; text-align: center;">
        <div class="spinner" style="margin: 0.5rem auto 1rem auto; width: 32px; height: 32px; border: 3px solid var(--border-color, #334155); border-top-color: var(--primary, #38bdf8); border-radius: 50%; animation: spin 0.8s linear infinite;"></div>
        <h4 style="font-size: 0.95rem; font-weight: 700; color: var(--text-main, #f8fafc); margin: 0 0 0.35rem 0;">AI Prospect Brief</h4>
        <p style="font-size: 0.825rem; color: var(--text-muted, #94a3b8); margin: 0;">Generating prospect brief... Evaluating signals against your Prospecting Profile...</p>
      </div>
    `;

    try {
      const isProspect = Boolean(b.status && window.BizzState && window.BizzState.currentTab === 'saved-businesses');
      const payload = {
        search_result_id: !isProspect ? (b.search_result_id || b.id) : null,
        prospect_id: isProspect ? b.id : null,
        google_place_id: b.google_place_id || b.id,
        search_id: b.search_id || (window.BizzState && window.BizzState.activeSearchId) || null,
        prospecting_profile_id: b.prospecting_profile_id || (window.BizzState && window.BizzState.selectedProspectingProfileId) || null,
        business: b
      };
      const briefData = await window.BizzApi.generateProspectBrief(payload);
      if (briefData) {
        const resolvedProfileId = briefData.prospecting_profile_id || b.prospecting_profile_id || (window.BizzState && window.BizzState.selectedProspectingProfileId) || 'default';
        const key = `${placeId}:${resolvedProfileId}`;
        briefCache.set(key, briefData);
        b.prospecting_profile_id = resolvedProfileId;
        if (isGuest && window.GuestLimits) {
          window.GuestLimits.incrementBrief();
        }
        renderInlineBriefContent(containerEl, b, briefData, triggerBtn);
        containerEl.setAttribute('data-loaded', 'true');
      }
    } catch (err) {
      console.error('[ProspectBrief] Error generating brief:', err);
      containerEl.innerHTML = `
        <div style="padding: 1rem; text-align: center;">
          <h4 style="color: #ef4444; font-weight: 700; font-size: 0.95rem; margin-bottom: 0.35rem;">Unable to Generate Prospect Brief</h4>
          <p style="font-size: 0.825rem; color: var(--text-muted); margin-bottom: 1rem;">${window.escapeHtml(err.message || 'An error occurred while generating the brief.')}</p>
          <button type="button" class="btn btn-secondary btn-sm close-inline-brief-btn">Close</button>
        </div>
      `;
      const closeBtn = containerEl.querySelector('.close-inline-brief-btn');
      if (closeBtn) {
        closeBtn.addEventListener('click', () => {
          containerEl.style.display = 'none';
        });
      }
      if (triggerBtn) {
        triggerBtn.innerHTML = '<span>AI Prospect Brief</span>';
        triggerBtn.classList.remove('btn-secondary');
        triggerBtn.classList.add('btn-primary');
      }
    } finally {
      inFlight.delete(cacheKey);
      if (triggerBtn) {
        triggerBtn.disabled = false;
      }
    }
  }

  function renderInlineBriefContent(containerEl, b, data, triggerBtn) {
    const placeId = b.google_place_id || b.id;
    const profileName = data.prospecting_profile_name || 'Prospecting Profile';
    const summaryText = data.summary || '';
    const whyText = data.why_this_is_a_prospect || 'This business matches your target profile criteria based on available signals.';
    const approachText = data.recommended_approach || 'Lead with a conversation about their business goals.';
    const angleText = data.outreach_angle || 'Service Discussion';
    const waUrl = b.whatsapp_url || (window.buildWhatsAppUrl ? window.buildWhatsAppUrl(b) : null);

    containerEl.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 0.85rem; text-align: left;">
        
        <!-- Header: Profile Context (Non-duplicative, concise) -->
        <div style="display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; flex-wrap: wrap; border-bottom: 1px solid var(--border-color, #334155); padding-bottom: 0.65rem;">
          <div style="font-size: 0.775rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; color: var(--primary, #38bdf8);">
            PROSPECT BRIEF • ${window.escapeHtml(profileName)}
          </div>
          ${summaryText ? `<div style="font-size: 0.825rem; font-weight: 600; color: var(--text-main, #f8fafc);">${window.escapeHtml(summaryText)}</div>` : ''}
        </div>

        <!-- Section 1: Why This Business Is a Prospect -->
        <div class="brief-section-card" style="margin-bottom: 0;">
          <div class="brief-section-title">
            Why This Business Is a Prospect
          </div>
          <p class="brief-section-body">
            ${window.escapeHtml(whyText)}
          </p>
        </div>

        <!-- Section 2: Recommended Approach -->
        <div class="brief-section-card" style="margin-bottom: 0; border-left: 4px solid var(--primary, #38bdf8);">
          <div class="brief-section-title">
            Recommended Approach
          </div>
          <p class="brief-section-body">
            ${window.escapeHtml(approachText)}
          </p>

          <div style="margin-top: 0.75rem; display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap;">
            <span style="font-size: 0.75rem; font-weight: 700; color: var(--text-muted, #94a3b8); text-transform: uppercase;">Suggested Angle:</span>
            <span style="background: #0284c7; color: #ffffff; font-size: 0.75rem; font-weight: 700; padding: 0.2rem 0.5rem; border-radius: 4px;">
              ${window.escapeHtml(angleText)}
            </span>
          </div>
        </div>

        <!-- Section 3: Footer Actions & Collapse Button -->
        <div style="display: flex; gap: 0.65rem; flex-wrap: wrap; margin-top: 0.4rem; justify-content: flex-end; align-items: center;">
          <button type="button" class="btn btn-primary btn-sm inline-generate-msg-btn" data-place-id="${placeId}">
            Generate Message
          </button>

          ${waUrl ? `
            <a href="${waUrl}" target="_blank" rel="noopener" class="btn btn-whatsapp btn-sm" style="text-decoration: none;">
              WhatsApp
            </a>
          ` : ''}

          <button type="button" class="btn btn-secondary btn-sm inline-hide-brief-btn" data-place-id="${placeId}">
            Hide Brief ▲
          </button>
        </div>

      </div>
    `;

    // Update trigger button text to Hide Brief
    if (triggerBtn) {
      triggerBtn.innerHTML = '<span>Hide Brief ▲</span>';
      triggerBtn.classList.remove('btn-primary');
      triggerBtn.classList.add('btn-secondary');
    }

    // Bind inline Hide Brief button
    const hideBtn = containerEl.querySelector('.inline-hide-brief-btn');
    if (hideBtn) {
      hideBtn.addEventListener('click', () => {
        containerEl.style.display = 'none';
        if (triggerBtn) {
          triggerBtn.innerHTML = '<span>Show Brief</span>';
          triggerBtn.classList.remove('btn-secondary');
          triggerBtn.classList.add('btn-primary');
        }
      });
    }

    // Bind inline Generate Message button
    const generateBtn = containerEl.querySelector('.inline-generate-msg-btn');
    if (generateBtn) {
      generateBtn.addEventListener('click', () => {
        const existingBtn = document.querySelector(`.wa-generate-msg-btn[data-place-id="${placeId}"]`);
        if (existingBtn) {
          existingBtn.click();
        } else {
          triggerDirectOutreachMessage(placeId);
        }
      });
    }
  }

  async function triggerDirectOutreachMessage(placeId) {
    if (!window.BizzApi.getToken()) {
      if (window.openAuthModal) {
        window.openAuthModal('login', 'Please log in or create an account to generate outreach messages.');
      }
      return;
    }

    const newWindow = window.open('about:blank', '_blank');
    try {
      const res = await window.BizzApi.generateOutreachMessage(placeId);
      if (res && res.whatsapp_url) {
        window.showToast('Message generated! Opening WhatsApp...', 'success');
        if (newWindow && !newWindow.closed) newWindow.location.href = res.whatsapp_url;
      } else {
        if (newWindow && !newWindow.closed) newWindow.close();
        throw new Error('WhatsApp URL not returned.');
      }
    } catch (e) {
      if (newWindow && !newWindow.closed) newWindow.close();
      window.showToast(e.message || 'Unable to generate outreach message', 'error');
    }
  }

  window.hasCachedBrief = hasCachedBrief;
  window.getCachedBrief = getCachedBrief;
  window.toggleInlineProspectBrief = toggleInlineProspectBrief;
  window.openProspectBriefModal = toggleInlineProspectBrief;

})(window);
