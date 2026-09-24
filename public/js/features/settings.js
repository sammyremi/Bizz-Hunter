/* public/js/features/settings.js - Settings View & Preferences Controller */

(function (window) {
  'use strict';

  function initSettingsPage() {
    const settingsNavBtns = document.querySelectorAll('.settings-nav-item');
    const settingsPanels = document.querySelectorAll('.settings-panel');
    const logoutBtn = document.getElementById('settings-logout-btn');

    settingsNavBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        const targetSection = btn.getAttribute('data-settings-section');
        if (!targetSection) return;

        settingsNavBtns.forEach(b => b.classList.remove('active'));
        settingsPanels.forEach(p => p.classList.remove('active'));

        btn.classList.add('active');
        const targetPanel = document.getElementById(`settings-panel-${targetSection}`);
        if (targetPanel) targetPanel.classList.add('active');
      });
    });

    if (logoutBtn) {
      logoutBtn.addEventListener('click', (e) => {
        e.preventDefault();
        if (confirm('Are you sure you want to sign out of Bizz-Hunter?')) {
          if (typeof window.logoutUser === 'function') window.logoutUser();
        }
      });
    }

    loadUserSettingsData();
    bindSettingsFormSubmits();
  }

  async function loadUserSettingsData() {
    const toneSelect = document.getElementById('settings-ai-tone');
    const lengthSelect = document.getElementById('settings-ai-length');
    const briefStyleSelect = document.getElementById('settings-brief-style');
    const briefFocusSelect = document.getElementById('settings-brief-focus');
    const accNameEl = document.getElementById('settings-acc-name');
    const accEmailEl = document.getElementById('settings-acc-email');

    const state = window.BizzState;
    if (state && state.currentUser) {
      if (accNameEl) accNameEl.textContent = state.currentUser.name || 'User';
      if (accEmailEl) accEmailEl.textContent = state.currentUser.email || 'User';
    }

    try {
      const data = await window.BizzApi.getSettings();
      if (data) {
        if (toneSelect && data.ai_tone) toneSelect.value = data.ai_tone;
        if (lengthSelect && data.ai_length) lengthSelect.value = data.ai_length;
        if (briefStyleSelect && data.brief_style) briefStyleSelect.value = data.brief_style;
        if (briefFocusSelect && data.brief_focus) briefFocusSelect.value = data.brief_focus;
      }
    } catch (e) {
      console.warn('[Settings] Unable to fetch user settings preferences:', e);
    }
  }

  function bindSettingsFormSubmits() {
    const waForm = document.getElementById('settings-wa-form');
    const briefForm = document.getElementById('settings-brief-form');

    if (waForm && !waForm.dataset.bound) {
      waForm.dataset.bound = 'true';
      waForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const toneSelect = document.getElementById('settings-ai-tone');
        const lengthSelect = document.getElementById('settings-ai-length');
        const btn = document.getElementById('save-wa-settings-btn');

        if (btn) { btn.disabled = true; btn.innerHTML = 'Saving...'; }
        try {
          await window.BizzApi.updateSettings({
            ai_tone: toneSelect ? toneSelect.value : 'Professional',
            ai_length: lengthSelect ? lengthSelect.value : 'Short'
          });
          window.showToast('WhatsApp outreach preferences saved successfully!', 'success');
        } catch (err) {
          window.showToast(err.message || 'Failed to save outreach settings', 'error');
        } finally {
          if (btn) { btn.disabled = false; btn.innerHTML = 'Save Preferences'; }
        }
      });
    }

    if (briefForm && !briefForm.dataset.bound) {
      briefForm.dataset.bound = 'true';
      briefForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const briefStyleSelect = document.getElementById('settings-brief-style');
        const briefFocusSelect = document.getElementById('settings-brief-focus');
        const btn = document.getElementById('save-brief-settings-btn');

        if (btn) { btn.disabled = true; btn.innerHTML = 'Saving...'; }
        try {
          await window.BizzApi.updateSettings({
            brief_style: briefStyleSelect ? briefStyleSelect.value : 'Professional',
            brief_focus: briefFocusSelect ? briefFocusSelect.value : 'Why this business may be relevant'
          });
          window.showToast('AI Prospect Brief preferences saved successfully!', 'success');
        } catch (err) {
          window.showToast(err.message || 'Failed to save brief settings', 'error');
        } finally {
          if (btn) { btn.disabled = false; btn.innerHTML = 'Save Brief Preferences'; }
        }
      });
    }
  }

  window.initSettingsPage = initSettingsPage;
  window.loadUserSettingsData = loadUserSettingsData;

})(window);
