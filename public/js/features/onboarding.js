/* public/js/features/onboarding.js - First-Time Prospecting Profile Onboarding Controller */

(function (window) {
  'use strict';

  const SKIP_STORAGE_KEY = 'bizz_hunter_onboarding_skipped';
  const DISMISS_BANNER_KEY = 'bizz_hunter_discovery_banner_dismissed';

  function initOnboarding() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);

    // Onboarding Modal CTAs
    const createBtn = (dom && dom.onboardingCreateBtn) || document.getElementById('onboarding-create-btn');
    if (createBtn) {
      createBtn.addEventListener('click', () => {
        closeOnboardingModal();
        if (typeof window.openProfileModal === 'function') {
          window.openProfileModal();
        }
      });
    }

    const skipBtn = (dom && dom.onboardingSkipBtn) || document.getElementById('onboarding-skip-btn');
    if (skipBtn) {
      skipBtn.addEventListener('click', () => {
        handleSkipOnboarding();
      });
    }

    // Success Modal CTAs
    const startDiscoveringBtn = (dom && dom.successStartDiscoveringBtn) || document.getElementById('success-start-discovering-btn');
    if (startDiscoveringBtn) {
      startDiscoveringBtn.addEventListener('click', () => {
        closeProfileSuccessModal();
        if (typeof window.switchTab === 'function') {
          window.switchTab('find-businesses');
        }
      });
    }

    const viewProfilesBtn = (dom && dom.successViewProfilesBtn) || document.getElementById('success-view-profiles-btn');
    if (viewProfilesBtn) {
      viewProfilesBtn.addEventListener('click', () => {
        closeProfileSuccessModal();
        if (typeof window.switchTab === 'function') {
          window.switchTab('prospecting-profiles');
        }
      });
    }

    // Discovery Prompt Banner Actions
    const bannerCreateBtn = (dom && dom.discoveryBannerCreateBtn) || document.getElementById('discovery-banner-create-btn');
    if (bannerCreateBtn) {
      bannerCreateBtn.addEventListener('click', () => {
        if (typeof window.openProfileModal === 'function') {
          window.openProfileModal();
        }
      });
    }

    const bannerDismissBtn = (dom && dom.discoveryBannerDismissBtn) || document.getElementById('discovery-banner-dismiss-btn');
    if (bannerDismissBtn) {
      bannerDismissBtn.addEventListener('click', () => {
        sessionStorage.setItem(DISMISS_BANNER_KEY, 'true');
        hideDiscoveryBanner();
      });
    }
  }

  async function checkAndRunOnboarding() {
    const state = window.BizzState;
    if (!state || !state.currentUser) return;

    // Ensure profiles are loaded in state
    try {
      if (!Array.isArray(state.prospectingProfiles) || state.prospectingProfiles.length === 0) {
        const profiles = await window.BizzApi.getProspectingProfiles();
        state.prospectingProfiles = Array.isArray(profiles) ? profiles : [];
      }
    } catch (err) {
      console.warn('Could not check profiles during onboarding validation:', err);
    }

    const hasProfiles = Array.isArray(state.prospectingProfiles) && state.prospectingProfiles.length > 0;

    if (hasProfiles) {
      // User has profiles -> No onboarding needed
      closeOnboardingModal();
      sessionStorage.removeItem(SKIP_STORAGE_KEY);
      hideDiscoveryBanner();
      return;
    }

    // User has NO profiles
    const isSkipped = sessionStorage.getItem(SKIP_STORAGE_KEY) === 'true';

    if (isSkipped) {
      closeOnboardingModal();
      updateDiscoveryBannerVisibility();
    } else {
      openOnboardingModal();
    }
  }

  function openOnboardingModal() {
    const modal = document.getElementById('onboarding-modal');
    if (modal) modal.classList.add('active');
  }

  function closeOnboardingModal() {
    const modal = document.getElementById('onboarding-modal');
    if (modal) modal.classList.remove('active');
  }

  function handleSkipOnboarding() {
    sessionStorage.setItem(SKIP_STORAGE_KEY, 'true');
    closeOnboardingModal();
    if (typeof window.switchTab === 'function') {
      window.switchTab('find-businesses');
    }
    updateDiscoveryBannerVisibility();
    if (window.showToast) {
      window.showToast('Skipped for now. You can create a Prospecting Profile anytime!', 'info');
    }
  }

  function showProfileSuccessModal(profile = null) {
    // Clear skip state since user now has a profile
    sessionStorage.removeItem(SKIP_STORAGE_KEY);
    hideDiscoveryBanner();

    const modal = document.getElementById('profile-success-modal');
    if (modal) modal.classList.add('active');
  }

  function closeProfileSuccessModal() {
    const modal = document.getElementById('profile-success-modal');
    if (modal) modal.classList.remove('active');
  }

  function updateDiscoveryBannerVisibility() {
    const state = window.BizzState;
    const banner = document.getElementById('discovery-profile-banner');
    if (!banner) return;

    const isAuthenticated = !!(state && state.currentUser);
    const hasProfiles = Array.isArray(state.prospectingProfiles) && state.prospectingProfiles.length > 0;
    const isDismissed = sessionStorage.getItem(DISMISS_BANNER_KEY) === 'true';
    const isDiscoveryTab = state ? state.currentTab === 'find-businesses' : true;

    if (isAuthenticated && !hasProfiles && !isDismissed && isDiscoveryTab) {
      banner.style.display = 'flex';
    } else {
      banner.style.display = 'none';
    }
  }

  function hideDiscoveryBanner() {
    const banner = document.getElementById('discovery-profile-banner');
    if (banner) banner.style.display = 'none';
  }

  window.initOnboarding = initOnboarding;
  window.checkAndRunOnboarding = checkAndRunOnboarding;
  window.openOnboardingModal = openOnboardingModal;
  window.closeOnboardingModal = closeOnboardingModal;
  window.handleSkipOnboarding = handleSkipOnboarding;
  window.showProfileSuccessModal = showProfileSuccessModal;
  window.closeProfileSuccessModal = closeProfileSuccessModal;
  window.updateDiscoveryBannerVisibility = updateDiscoveryBannerVisibility;

})(window);
