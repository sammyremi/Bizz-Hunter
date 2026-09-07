/* public/js/features/profiles.js - Prospecting Profiles Feature Controller */

(function (window) {
  'use strict';

  let profileToDelete = null;

  const formTags = {
    'target-businesses': [],
    'opportunity-signals': [],
    'contact-signals': []
  };

  function initProfiles() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);

    // Header & Empty State Create Buttons
    const createBtn = (dom && dom.createProfileBtn) || document.getElementById('create-profile-btn');
    if (createBtn) {
      createBtn.addEventListener('click', () => openProfileModal());
    }

    const emptyCreateBtn = (dom && dom.profilesEmptyCreateBtn) || document.getElementById('profiles-empty-create-btn');
    if (emptyCreateBtn) {
      emptyCreateBtn.addEventListener('click', () => openProfileModal());
    }

    // Retry Button
    const retryBtn = (dom && dom.profilesRetryBtn) || document.getElementById('profiles-retry-btn');
    if (retryBtn) {
      retryBtn.addEventListener('click', () => loadProfiles());
    }

    // Modal Close / Cancel Buttons
    const modalCloseBtn = document.getElementById('profile-modal-close');
    const modalCancelBtn = document.getElementById('profile-modal-cancel-btn');
    [modalCloseBtn, modalCancelBtn].forEach(btn => {
      if (btn) {
        btn.addEventListener('click', () => closeProfileModal());
      }
    });

    // Form Submit Handler
    const profileForm = (dom && dom.profileForm) || document.getElementById('profile-form');
    if (profileForm) {
      profileForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleSaveProfile();
      });
    }

    // Tag Chip Input setup for Target Businesses, Opportunity Signals, Contact Signals
    setupTagInput('target-businesses', 'target-businesses-input', 'target-businesses-add-btn');
    setupTagInput('opportunity-signals', 'opportunity-signals-input', 'opportunity-signals-add-btn');
    setupTagInput('contact-signals', 'contact-signals-input', 'contact-signals-add-btn');

    // AI Profile Generation Sparkle Button
    const aiBtn = document.getElementById('btn-generate-ai-profile');
    if (aiBtn) {
      aiBtn.addEventListener('click', () => handleGenerateAiProfile());
    }

    // Suggestion Chips Click Handling
    document.querySelectorAll('.btn-suggestion-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        const category = chip.getAttribute('data-target');
        const val = chip.getAttribute('data-value');
        if (category && val) {
          addTag(category, val);
        }
      });
    });

    // Delete Confirmation Modal Event Listeners
    const deleteModalClose = document.getElementById('confirm-delete-modal-close');
    const deleteCancelBtn = document.getElementById('confirm-delete-cancel-btn');
    const deleteSubmitBtn = document.getElementById('confirm-delete-submit-btn');

    [deleteModalClose, deleteCancelBtn].forEach(btn => {
      if (btn) {
        btn.addEventListener('click', () => closeDeleteModal());
      }
    });

    if (deleteSubmitBtn) {
      deleteSubmitBtn.addEventListener('click', async () => {
        if (profileToDelete) {
          await executeDeleteProfile(profileToDelete.id);
        }
      });
    }
  }

  function setupTagInput(categoryKey, inputId, addBtnId) {
    const inputEl = document.getElementById(inputId);
    const addBtn = document.getElementById(addBtnId);

    if (inputEl) {
      inputEl.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          const val = inputEl.value.trim();
          if (val) {
            addTag(categoryKey, val);
            inputEl.value = '';
          }
        }
      });
    }

    if (addBtn) {
      addBtn.addEventListener('click', (e) => {
        e.preventDefault();
        if (inputEl) {
          const val = inputEl.value.trim();
          if (val) {
            addTag(categoryKey, val);
            inputEl.value = '';
          }
        }
      });
    }
  }

  function addTag(categoryKey, val) {
    if (!val || !formTags[categoryKey]) return;
    const trimmed = val.trim();
    if (!trimmed) return;

    // Avoid exact duplicate case-insensitive tag in category
    const exists = formTags[categoryKey].some(item => item.toLowerCase() === trimmed.toLowerCase());
    if (!exists) {
      formTags[categoryKey].push(trimmed);
      renderTagChips(categoryKey);
    }
  }

  function removeTag(categoryKey, index) {
    if (formTags[categoryKey] && formTags[categoryKey][index] !== undefined) {
      formTags[categoryKey].splice(index, 1);
      renderTagChips(categoryKey);
    }
  }

  function renderTagChips(categoryKey) {
    const container = document.getElementById(`${categoryKey}-chips`);
    if (!container) return;

    const tags = formTags[categoryKey] || [];
    if (tags.length === 0) {
      container.innerHTML = '';
      return;
    }

    container.innerHTML = tags.map((tag, idx) => `
      <span class="chip-tag">
        ${window.escapeHtml(tag)}
        <span class="chip-remove" onclick="window.removeProfileTag('${categoryKey}', ${idx})">&times;</span>
      </span>
    `).join('');
  }

  window.removeProfileTag = removeTag;

  async function loadProfiles() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    const state = window.BizzState;

    showProfilesLoading();

    try {
      const profiles = await window.BizzApi.getProspectingProfiles();
      state.prospectingProfiles = Array.isArray(profiles) ? profiles : [];
      renderProfilesView();
      if (typeof window.updateDiscoveryBannerVisibility === 'function') {
        window.updateDiscoveryBannerVisibility();
      }
    } catch (err) {
      console.error('Error loading prospecting profiles:', err);
      showProfilesError(err.message || 'Failed to load prospecting profiles');
    }
  }

  function showProfilesLoading() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    if (dom.profilesLoadingState) dom.profilesLoadingState.style.display = 'block';
    if (dom.profilesEmptyState) dom.profilesEmptyState.style.display = 'none';
    if (dom.profilesErrorState) dom.profilesErrorState.style.display = 'none';
    if (dom.profilesGrid) dom.profilesGrid.style.display = 'none';
  }

  function showProfilesError(msg) {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    if (dom.profilesLoadingState) dom.profilesLoadingState.style.display = 'none';
    if (dom.profilesEmptyState) dom.profilesEmptyState.style.display = 'none';
    if (dom.profilesGrid) dom.profilesGrid.style.display = 'none';

    if (dom.profilesErrorState) {
      dom.profilesErrorState.style.display = 'block';
      const errMsgEl = document.getElementById('profiles-error-message');
      if (errMsgEl) errMsgEl.textContent = msg || 'Unable to load your prospecting profiles.';
    }
  }

  function renderProfilesView() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    const profiles = window.BizzState.prospectingProfiles || [];

    if (dom.profilesLoadingState) dom.profilesLoadingState.style.display = 'none';
    if (dom.profilesErrorState) dom.profilesErrorState.style.display = 'none';

    if (profiles.length === 0) {
      if (dom.profilesEmptyState) dom.profilesEmptyState.style.display = 'block';
      if (dom.profilesGrid) dom.profilesGrid.style.display = 'none';
      return;
    }

    if (dom.profilesEmptyState) dom.profilesEmptyState.style.display = 'none';
    if (dom.profilesGrid) {
      dom.profilesGrid.style.display = 'grid';
      dom.profilesGrid.innerHTML = profiles.map(profile => createProfileCardHtml(profile)).join('');
      attachCardActionListeners();
    }
  }

  function createProfileCardHtml(profile) {
    const targets = Array.isArray(profile.target_businesses) ? profile.target_businesses : [];
    const oppSignals = Array.isArray(profile.opportunity_signals) ? profile.opportunity_signals : [];
    const contactSignals = Array.isArray(profile.contact_signals) ? profile.contact_signals : [];

    return `
      <div class="profile-card" data-profile-id="${profile.id}">
        <div style="display: flex; flex-direction: column; gap: 1rem;">
          
          <!-- Card Top Header -->
          <div class="profile-card-header">
            <div>
              <h2 class="profile-title">${window.escapeHtml(profile.name)}</h2>
              <div class="profile-service">${window.escapeHtml(profile.service)}</div>
            </div>
            ${profile.is_default ? '<span class="badge-default">Default</span>' : ''}
          </div>

          <!-- Description if present -->
          ${profile.service_description ? `
            <p style="color: var(--text-muted); font-size: 0.88rem; line-height: 1.45;">
              ${window.escapeHtml(profile.service_description)}
            </p>
          ` : ''}

          <!-- Target Businesses -->
          <div>
            <div class="profile-section-title">Target Businesses</div>
            <div class="profile-chips-group">
              ${targets.length > 0 ? targets.map(t => `<span class="chip-tag">${window.escapeHtml(t)}</span>`).join('') : '<span style="color: var(--text-dim); font-size: 0.8rem;">None specified</span>'}
            </div>
          </div>

          <!-- Opportunity Signals -->
          <div>
            <div class="profile-section-title">Opportunity Signals</div>
            <div class="profile-chips-group">
              ${oppSignals.length > 0 ? oppSignals.map(s => `<span class="chip-tag" style="border-color: rgba(59,130,246,0.3); color: var(--text-main);">${window.escapeHtml(s)}</span>`).join('') : '<span style="color: var(--text-dim); font-size: 0.8rem;">None specified</span>'}
            </div>
          </div>

          <!-- Contact Signals -->
          <div>
            <div class="profile-section-title">Contact Signals</div>
            <div class="profile-chips-group">
              ${contactSignals.length > 0 ? contactSignals.map(c => `<span class="chip-tag" style="border-color: rgba(37,211,102,0.3); color: var(--text-main);">${window.escapeHtml(c)}</span>`).join('') : '<span style="color: var(--text-dim); font-size: 0.8rem;">None specified</span>'}
            </div>
          </div>

        </div>

        <!-- Actions Bar -->
        <div class="profile-card-actions">
          <button type="button" class="btn btn-secondary btn-sm btn-edit-profile" data-id="${profile.id}">
            ✏️ Edit
          </button>
          ${!profile.is_default ? `
            <button type="button" class="btn btn-secondary btn-sm btn-default-profile" data-id="${profile.id}">
              ⭐ Set as Default
            </button>
          ` : ''}
          <button type="button" class="btn btn-secondary btn-sm btn-delete-profile" data-id="${profile.id}" data-name="${window.escapeHtml(profile.name)}" style="color: #ef4444; border-color: rgba(239,68,68,0.3);">
            🗑️ Delete
          </button>
        </div>
      </div>
    `;
  }

  function attachCardActionListeners() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    if (!dom.profilesGrid) return;

    // Edit button click
    dom.profilesGrid.querySelectorAll('.btn-edit-profile').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const profile = (window.BizzState.prospectingProfiles || []).find(p => String(p.id) === String(id));
        if (profile) {
          openProfileModal(profile);
        }
      });
    });

    // Set Default button click
    dom.profilesGrid.querySelectorAll('.btn-default-profile').forEach(btn => {
      btn.addEventListener('click', async () => {
        const id = btn.getAttribute('data-id');
        if (id) {
          await handleSetDefaultProfile(id);
        }
      });
    });

    // Delete button click
    dom.profilesGrid.querySelectorAll('.btn-delete-profile').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.getAttribute('data-id');
        const name = btn.getAttribute('data-name');
        if (id && name) {
          openDeleteModal(id, name);
        }
      });
    });
  }

  function openProfileModal(profileToEdit = null, initialAiInput = null) {
    clearProfileFormErrors();

    const modal = document.getElementById('profile-modal');
    const titleEl = document.getElementById('profile-modal-title');
    const idEl = document.getElementById('profile-form-id');
    const nameEl = document.getElementById('profile-form-name');
    const serviceEl = document.getElementById('profile-form-service');
    const descEl = document.getElementById('profile-form-description');
    const defaultEl = document.getElementById('profile-form-is-default');

    const aiDescInput = document.getElementById('ai-description-input');
    const aiBtn = document.getElementById('btn-generate-ai-profile');
    if (aiBtn) aiBtn.innerHTML = '✨ Generate Profile with AI';

    if (profileToEdit) {
      if (titleEl) titleEl.textContent = 'Edit Prospecting Profile';
      if (idEl) idEl.value = profileToEdit.id;
      if (nameEl) nameEl.value = profileToEdit.name || '';
      if (serviceEl) serviceEl.value = profileToEdit.service || '';
      if (descEl) descEl.value = profileToEdit.service_description || '';
      if (defaultEl) defaultEl.checked = !!profileToEdit.is_default;
      if (aiDescInput) aiDescInput.value = '';

      formTags['target-businesses'] = Array.isArray(profileToEdit.target_businesses) ? [...profileToEdit.target_businesses] : [];
      formTags['opportunity-signals'] = Array.isArray(profileToEdit.opportunity_signals) ? [...profileToEdit.opportunity_signals] : [];
      formTags['contact-signals'] = Array.isArray(profileToEdit.contact_signals) ? [...profileToEdit.contact_signals] : [];
    } else {
      if (titleEl) titleEl.textContent = 'Create Prospecting Profile';
      if (idEl) idEl.value = '';
      if (nameEl) nameEl.value = '';
      if (serviceEl) serviceEl.value = '';
      if (descEl) descEl.value = '';
      if (defaultEl) defaultEl.checked = false;
      if (aiDescInput) aiDescInput.value = initialAiInput || '';

      formTags['target-businesses'] = [];
      formTags['opportunity-signals'] = [];
      formTags['contact-signals'] = [];
    }

    renderTagChips('target-businesses');
    renderTagChips('opportunity-signals');
    renderTagChips('contact-signals');

    if (modal) modal.classList.add('active');

    if (initialAiInput && !profileToEdit) {
      handleGenerateAiProfile(initialAiInput);
    }
  }

  function closeProfileModal() {
    const modal = document.getElementById('profile-modal');
    if (modal) modal.classList.remove('active');
    clearProfileFormErrors();
  }

  function showProfileFormError(msg) {
    const errBox = document.getElementById('profile-form-error');
    if (errBox) {
      errBox.textContent = msg;
      errBox.style.display = 'block';
    }
  }

  function clearProfileFormErrors() {
    const errBox = document.getElementById('profile-form-error');
    if (errBox) {
      errBox.textContent = '';
      errBox.style.display = 'none';
    }
  }

  async function handleSaveProfile() {
    clearProfileFormErrors();

    const idEl = document.getElementById('profile-form-id');
    const nameEl = document.getElementById('profile-form-name');
    const serviceEl = document.getElementById('profile-form-service');
    const descEl = document.getElementById('profile-form-description');
    const defaultEl = document.getElementById('profile-form-is-default');
    const submitBtn = document.getElementById('profile-form-submit-btn');

    const id = idEl ? idEl.value : '';
    const name = nameEl ? nameEl.value.trim() : '';
    const service = serviceEl ? serviceEl.value.trim() : '';
    const service_description = descEl ? descEl.value.trim() : '';
    const is_default = defaultEl ? defaultEl.checked : false;

    // Basic frontend validation
    if (!name) {
      showProfileFormError('Profile Name is required.');
      return;
    }

    if (!service) {
      showProfileFormError('Service is required.');
      return;
    }

    const payload = {
      name,
      service,
      service_description,
      target_businesses: formTags['target-businesses'],
      opportunity_signals: formTags['opportunity-signals'],
      contact_signals: formTags['contact-signals'],
      is_default
    };

    if (submitBtn) submitBtn.disabled = true;

    try {
      let savedProfile;
      const isNew = !id;

      if (id) {
        savedProfile = await window.BizzApi.updateProspectingProfile(id, payload);
        window.showToast(`Updated profile "${savedProfile.name}"!`, 'success');
      } else {
        savedProfile = await window.BizzApi.createProspectingProfile(payload);
        window.showToast(`Created profile "${savedProfile.name}"!`, 'success');
      }

      closeProfileModal();
      await loadProfiles();

      if (isNew && typeof window.showProfileSuccessModal === 'function') {
        window.showProfileSuccessModal(savedProfile);
      }
    } catch (err) {
      console.error('Error saving profile:', err);
      let errMsg = err.message || 'Failed to save prospecting profile.';
      if (err.errors && Array.isArray(err.errors)) {
        errMsg = err.errors.join(', ');
      }
      showProfileFormError(errMsg);
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  }

  async function handleSetDefaultProfile(id) {
    try {
      const updated = await window.BizzApi.updateProspectingProfile(id, { is_default: true });
      window.showToast(`"${updated.name}" set as default profile!`, 'success');
      await loadProfiles();
    } catch (err) {
      console.error('Error setting default profile:', err);
      window.showToast(err.message || 'Failed to set default profile', 'error');
    }
  }

  function openDeleteModal(id, name) {
    profileToDelete = { id, name };
    const modal = document.getElementById('confirm-delete-profile-modal');
    const nameEl = document.getElementById('delete-profile-name-text');
    if (nameEl) nameEl.textContent = `"${name}"`;
    if (modal) modal.classList.add('active');
  }

  function closeDeleteModal() {
    profileToDelete = null;
    const modal = document.getElementById('confirm-delete-profile-modal');
    if (modal) modal.classList.remove('active');
  }

  async function executeDeleteProfile(id) {
    const submitBtn = document.getElementById('confirm-delete-submit-btn');
    if (submitBtn) submitBtn.disabled = true;

    try {
      await window.BizzApi.deleteProspectingProfile(id);
      closeDeleteModal();
      window.showToast('Prospecting profile deleted', 'info');
      await loadProfiles();
    } catch (err) {
      console.error('Error deleting profile:', err);
      window.showToast(err.message || 'Failed to delete profile', 'error');
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  }

  async function handleGenerateAiProfile(overrideDesc = null) {
    clearProfileFormErrors();

    const aiDescInput = document.getElementById('ai-description-input');
    const aiBtn = document.getElementById('btn-generate-ai-profile');
    const loadingBox = document.getElementById('ai-generator-loading');

    const description = overrideDesc || (aiDescInput ? aiDescInput.value.trim() : '');

    if (!description || description.length < 3) {
      showProfileFormError('Please describe what you sell or offer in a few words.');
      return;
    }

    if (aiBtn) aiBtn.disabled = true;
    if (loadingBox) loadingBox.style.display = 'flex';

    try {
      const proposal = await window.BizzApi.generateProspectingProfile(description);
      
      if (!proposal) {
        throw new Error('No proposal received from AI service.');
      }

      // Populate form fields with AI proposal
      const nameEl = document.getElementById('profile-form-name');
      const serviceEl = document.getElementById('profile-form-service');
      const descEl = document.getElementById('profile-form-description');

      if (nameEl) nameEl.value = proposal.name || '';
      if (serviceEl) serviceEl.value = proposal.service || '';
      if (descEl) descEl.value = proposal.service_description || '';

      // Populate tag chip arrays
      formTags['target-businesses'] = Array.isArray(proposal.target_businesses) ? [...proposal.target_businesses] : [];
      formTags['opportunity-signals'] = Array.isArray(proposal.opportunity_signals) ? [...proposal.opportunity_signals] : [];
      formTags['contact-signals'] = Array.isArray(proposal.contact_signals) ? [...proposal.contact_signals] : [];

      renderTagChips('target-businesses');
      renderTagChips('opportunity-signals');
      renderTagChips('contact-signals');

      if (aiBtn) aiBtn.innerHTML = '✨ Regenerate with AI';
      if (window.showToast) {
        window.showToast('✨ AI generated candidate profile! Review fields below and click Save Profile.', 'success');
      }
    } catch (err) {
      console.error('Error generating AI profile:', err);
      showProfileFormError(err.message || 'Failed to generate profile with AI. Please try again.');
    } finally {
      if (aiBtn) aiBtn.disabled = false;
      if (loadingBox) loadingBox.style.display = 'none';
    }
  }

  window.initProfiles = initProfiles;
  window.loadProfiles = loadProfiles;
  window.openProfileModal = openProfileModal;
  window.handleSetDefaultProfile = handleSetDefaultProfile;
  window.handleGenerateAiProfile = handleGenerateAiProfile;

})(window);
