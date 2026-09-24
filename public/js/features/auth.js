/* public/js/features/auth.js - Authentication and Quota Controller */

(function (window) {
  'use strict';

  function initAuth() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    const state = window.BizzState;

    const loginForm = document.getElementById('dedicated-login-form');
    if (loginForm && !loginForm.dataset.bound) {
      loginForm.dataset.bound = 'true';
      loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleDedicatedLogin();
      });
    }

    const registerForm = document.getElementById('dedicated-register-form');
    if (registerForm && !registerForm.dataset.bound) {
      registerForm.dataset.bound = 'true';
      registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleDedicatedRegister();
      });
    }

    const googleLoginBtn = document.getElementById('google-oauth-login-btn');
    if (googleLoginBtn && !googleLoginBtn.dataset.bound) {
      googleLoginBtn.dataset.bound = 'true';
      googleLoginBtn.addEventListener('click', () => {
        window.showToast('Google OAuth backend integration ready! Connect callback endpoint to complete.', 'info');
      });
    }

    const googleRegisterBtn = document.getElementById('google-oauth-register-btn');
    if (googleRegisterBtn && !googleRegisterBtn.dataset.bound) {
      googleRegisterBtn.dataset.bound = 'true';
      googleRegisterBtn.addEventListener('click', () => {
        window.showToast('Google OAuth backend integration ready! Connect callback endpoint to complete.', 'info');
      });
    }
  }

  async function checkAuthSession() {
    const state = window.BizzState;
    const loadingEl = document.getElementById('app-auth-loading');

    let user = null;
    try {
      user = await window.BizzApi.getMe();
    } catch (err) {
      console.warn('Session check error:', err);
      user = null;
    }

    setCurrentUser(user);

    const rawHash = window.location.hash ? window.location.hash.replace('#', '') : null;
    const mappedHash = window.mapRouteAlias ? window.mapRouteAlias(rawHash) : rawHash;
    const savedTab = localStorage.getItem('bizz_hunter_current_tab');
    const targetTab = mappedHash || savedTab || state.currentTab || (user ? 'find-businesses' : 'landing');

    let destTab = targetTab;
    if (user) {
      // Authenticated user MUST NOT access landing, login, or register
      if (['landing', 'login', 'register'].includes(targetTab)) {
        destTab = 'find-businesses';
      }
    } else {
      // Unauthenticated user MUST NOT access protected views
      if (['prospecting-profiles', 'dashboard', 'saved-businesses', 'analysis', 'settings', 'find-businesses'].includes(targetTab)) {
        destTab = (mappedHash === 'login' || mappedHash === 'register') ? mappedHash : 'landing';
      }
    }

    window.switchTab(destTab || (user ? 'find-businesses' : 'landing'));

    // Dismiss loading overlay immediately so UI is responsive
    if (loadingEl) {
      loadingEl.style.opacity = '0';
      setTimeout(() => { loadingEl.style.display = 'none'; }, 150);
    }

    // Secondary background data loading (does not block initial view render)
    if (user) {
      Promise.allSettled([
        typeof window.loadUserProspects === 'function' ? window.loadUserProspects() : Promise.resolve(),
        typeof window.loadProfiles === 'function' ? window.loadProfiles() : Promise.resolve(),
        typeof window.initProfileSelector === 'function' ? window.initProfileSelector() : Promise.resolve()
      ]).then(() => {
        if (typeof window.checkAndRunOnboarding === 'function') {
          window.checkAndRunOnboarding();
        }
      });
    } else {
      if (typeof window.initProfileSelector === 'function') {
        window.initProfileSelector();
      }
    }
  }

  function setCurrentUser(user) {
    window.BizzState.currentUser = user;
    const userAvatarEl = document.getElementById('user-avatar');
    const userNameEl = document.getElementById('user-name');
    const userPillEl = document.getElementById('user-profile-pill');
    const authNavEl = document.getElementById('authenticated-nav');
    const publicNavEl = document.getElementById('public-nav');
    const brandLinkEl = document.getElementById('brand-link');

    if (user) {
      const name = user.name || 'User Account';
      const initials = name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase() || 'US';

      if (userNameEl) userNameEl.textContent = name;
      if (userAvatarEl) userAvatarEl.textContent = initials;

      if (userPillEl) userPillEl.style.display = 'inline-flex';
      if (authNavEl) authNavEl.style.display = 'flex';
      if (publicNavEl) publicNavEl.style.display = 'none';
      if (brandLinkEl) brandLinkEl.setAttribute('href', '#discovery');
    } else {
      if (userNameEl) userNameEl.textContent = 'Guest';
      if (userAvatarEl) userAvatarEl.textContent = 'GU';

      if (userPillEl) userPillEl.style.display = 'none';
      if (authNavEl) authNavEl.style.display = 'none';
      if (publicNavEl) publicNavEl.style.display = 'flex';
      if (brandLinkEl) brandLinkEl.setAttribute('href', '#landing');
    }
  }

  async function fetchAndUpdateQuota() {
    const quota = await window.BizzApi.getSearchQuota();
    if (quota) {
      updateQuotaUI(quota);
    }
  }

  function updateQuotaUI(quota) {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    if (!quota) return;
    window.BizzState.currentQuota = quota;

    const isGuest = quota.user_type === 'guest';
    const used = quota.used;
    const limit = quota.limit;
    const percentage = Math.min(Math.round((used / limit) * 100), 100);

    const quotaLabel = document.getElementById('quota-label-text');
    const quotaFill = document.getElementById('quota-progress-fill');

    if (quotaLabel) {
      quotaLabel.textContent = `${isGuest ? 'GUEST' : 'PRO'} USAGE: ${used}/${limit}`;
    }

    if (quotaFill) {
      quotaFill.style.width = `${percentage}%`;
    }
  }

  async function handleDedicatedLogin() {
    const errorBox = document.getElementById('login-error-box');
    const emailEl = document.getElementById('login-email');
    const passwordEl = document.getElementById('login-password');
    const submitBtn = document.getElementById('login-submit-btn');

    if (errorBox) { errorBox.style.display = 'none'; errorBox.textContent = ''; }

    const email = emailEl ? emailEl.value.trim() : '';
    const password = passwordEl ? passwordEl.value : '';

    if (!email || !password) {
      if (errorBox) { errorBox.textContent = 'Please fill out all fields.'; errorBox.style.display = 'block'; }
      return;
    }

    if (submitBtn) submitBtn.disabled = true;

    try {
      const res = await window.BizzApi.login({ email, password });
      if (res.success && res.user) {
        setCurrentUser(res.user);
        window.showToast(`Welcome back, ${res.user.name}!`, 'success');
        if (emailEl) emailEl.value = '';
        if (passwordEl) passwordEl.value = '';
        await fetchAndUpdateQuota();
        await window.loadUserProspects();
        if (typeof window.loadProfiles === 'function') await window.loadProfiles();
        if (typeof window.initProfileSelector === 'function') await window.initProfileSelector();
        window.switchTab('find-businesses');
        if (typeof window.checkAndRunOnboarding === 'function') await window.checkAndRunOnboarding();
      } else {
        if (errorBox) { errorBox.textContent = res.message || 'Invalid email or password'; errorBox.style.display = 'block'; }
      }
    } catch (err) {
      if (errorBox) { errorBox.textContent = err.message || 'Login failed.'; errorBox.style.display = 'block'; }
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  }

  async function handleDedicatedRegister() {
    const errorBox = document.getElementById('register-error-box');
    const nameEl = document.getElementById('register-name');
    const emailEl = document.getElementById('register-email');
    const passwordEl = document.getElementById('register-password');
    const confirmEl = document.getElementById('register-confirm-password');
    const submitBtn = document.getElementById('register-submit-btn');

    if (errorBox) { errorBox.style.display = 'none'; errorBox.textContent = ''; }

    const name = nameEl ? nameEl.value.trim() : '';
    const email = emailEl ? emailEl.value.trim() : '';
    const password = passwordEl ? passwordEl.value : '';
    const confirmPassword = confirmEl ? confirmEl.value : '';

    if (!name || !email || !password) {
      if (errorBox) { errorBox.textContent = 'Please fill out all fields.'; errorBox.style.display = 'block'; }
      return;
    }

    if (password !== confirmPassword) {
      if (errorBox) { errorBox.textContent = 'Passwords do not match.'; errorBox.style.display = 'block'; }
      return;
    }

    if (password.length < 6) {
      if (errorBox) { errorBox.textContent = 'Password must be at least 6 characters.'; errorBox.style.display = 'block'; }
      return;
    }

    if (submitBtn) submitBtn.disabled = true;

    try {
      const res = await window.BizzApi.register({ name, email, password });
      if (res.success && res.user) {
        setCurrentUser(res.user);
        window.showToast(`Account created! Welcome, ${res.user.name}!`, 'success');
        if (nameEl) nameEl.value = '';
        if (emailEl) emailEl.value = '';
        if (passwordEl) passwordEl.value = '';
        if (confirmEl) confirmEl.value = '';
        await fetchAndUpdateQuota();
        await window.loadUserProspects();
        if (typeof window.loadProfiles === 'function') await window.loadProfiles();
        if (typeof window.initProfileSelector === 'function') await window.initProfileSelector();
        window.switchTab('find-businesses');
        if (typeof window.checkAndRunOnboarding === 'function') await window.checkAndRunOnboarding();
      } else {
        if (errorBox) { errorBox.textContent = res.message || 'Registration failed.'; errorBox.style.display = 'block'; }
      }
    } catch (err) {
      if (errorBox) { errorBox.textContent = err.message || 'Registration failed.'; errorBox.style.display = 'block'; }
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  }

  async function logoutUser() {
    await window.BizzApi.logout();
    setCurrentUser(null);
    window.BizzState.prospectingProfiles = [];
    window.BizzState.selectedProspectingProfileId = null;
    if (typeof window.initProfileSelector === 'function') window.initProfileSelector();
    if (typeof window.closeOnboardingModal === 'function') window.closeOnboardingModal();
    if (typeof window.updateDiscoveryBannerVisibility === 'function') window.updateDiscoveryBannerVisibility();
    window.showToast('Signed out successfully', 'info');
    await fetchAndUpdateQuota();
    window.switchTab('landing');
  }

  window.initAuth = initAuth;
  window.checkAuthSession = checkAuthSession;
  window.setCurrentUser = setCurrentUser;
  window.fetchAndUpdateQuota = fetchAndUpdateQuota;
  window.updateQuotaUI = updateQuotaUI;
  window.handleDedicatedLogin = handleDedicatedLogin;
  window.handleDedicatedRegister = handleDedicatedRegister;
  window.logoutUser = logoutUser;

})(window);
