/* public/js/features/auth.js - Authentication and Quota Controller */

(function (window) {
  'use strict';

  function initAuth() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    const state = window.BizzState;

    if (dom && dom.navProfileBtn) {
      dom.navProfileBtn.addEventListener('click', () => {
        if (state.currentUser) {
          if (confirm(`Logged in as ${state.currentUser.email}. Do you want to log out?`)) {
            logoutUser();
          }
        } else {
          window.openAuthModal('login');
        }
      });
    }

    if (dom && dom.navSettingsBtn) {
      dom.navSettingsBtn.addEventListener('click', () => {
        window.switchTab('settings');
      });
    }

    if (dom && dom.errorQuotaSignupBtn) {
      dom.errorQuotaSignupBtn.addEventListener('click', () => {
        window.openAuthModal('register', 'Sign up for a free account to get 50 searches per day!');
      });
    }

    if (dom && dom.authTabLogin) {
      dom.authTabLogin.addEventListener('click', () => window.toggleAuthTab('login'));
    }

    if (dom && dom.authTabRegister) {
      dom.authTabRegister.addEventListener('click', () => window.toggleAuthTab('register'));
    }

    const loginForm = (dom && dom.modalLoginForm) || document.getElementById('modal-login-form');
    if (loginForm) {
      loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleModalLogin();
      });
    }

    const registerForm = (dom && dom.modalRegisterForm) || document.getElementById('modal-register-form');
    if (registerForm) {
      registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleModalRegister();
      });
    }
  }

  async function checkAuthSession() {
    const state = window.BizzState;
    const user = await window.BizzApi.getMe();
    
    const hashTab = window.location.hash ? window.location.hash.replace('#', '') : null;
    const savedTab = localStorage.getItem('bizz_hunter_current_tab');
    const targetTab = hashTab || savedTab || state.currentTab || 'find-businesses';

    if (user) {
      setCurrentUser(user);
      await window.loadUserProspects();
      window.switchTab(targetTab);
    } else {
      setCurrentUser(null);
      if (['dashboard', 'saved-businesses', 'analysis'].includes(targetTab)) {
        window.switchTab('find-businesses');
      } else {
        window.switchTab(targetTab);
      }
    }
  }

  function setCurrentUser(user) {
    window.BizzState.currentUser = user;
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    if (dom && dom.navProfileBtn) {
      if (user) {
        dom.navProfileBtn.setAttribute('title', `Logged in as ${user.name} (${user.email})`);
      } else {
        dom.navProfileBtn.setAttribute('title', 'User Account / Log In');
      }
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

    if (dom && dom.quotaLabelText) {
      dom.quotaLabelText.textContent = `${isGuest ? 'GUEST USAGE' : 'PRO USAGE'}: ${used}/${limit}`;
    }

    if (dom && dom.quotaProgressFill) {
      dom.quotaProgressFill.style.width = `${percentage}%`;
    }
  }

  async function handleModalLogin() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    const state = window.BizzState;
    window.clearAuthModalErrors();

    const emailEl = (dom && dom.modalLoginEmail) || document.getElementById('modal-login-email');
    const passwordEl = (dom && dom.modalLoginPassword) || document.getElementById('modal-login-password');
    const submitBtn = (dom && dom.modalLoginSubmit) || document.getElementById('modal-login-btn');

    const email = emailEl ? emailEl.value.trim() : '';
    const password = passwordEl ? passwordEl.value : '';

    if (!email || !password) {
      window.showAuthModalError('Please fill out all fields.');
      return;
    }

    if (submitBtn) submitBtn.disabled = true;

    try {
      const res = await window.BizzApi.login({ email, password });
      if (res.success && res.user) {
        setCurrentUser(res.user);
        window.closeModals();
        window.showToast(`Welcome back, ${res.user.name}!`, 'success');
        if (emailEl) emailEl.value = '';
        if (passwordEl) passwordEl.value = '';
        await fetchAndUpdateQuota();
        await window.loadUserProspects();
        await window.renderDashboardAnalytics();
        if (state.currentTab === 'analysis') {
          await window.renderAnalysisWorkspace();
        }
      } else {
        window.showAuthModalError(res.message || 'Invalid email or password');
      }
    } catch (err) {
      window.showAuthModalError(err.message || 'Login failed.');
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  }

  async function handleModalRegister() {
    const dom = window.dom || (window.BizzState ? window.BizzState.dom : null);
    const state = window.BizzState;
    window.clearAuthModalErrors();

    const nameEl = (dom && dom.modalRegisterName) || document.getElementById('modal-register-name');
    const emailEl = (dom && dom.modalRegisterEmail) || document.getElementById('modal-register-email');
    const passwordEl = (dom && dom.modalRegisterPassword) || document.getElementById('modal-register-password');
    const submitBtn = (dom && dom.modalRegisterSubmit) || document.getElementById('modal-register-btn');

    const name = nameEl ? nameEl.value.trim() : '';
    const email = emailEl ? emailEl.value.trim() : '';
    const password = passwordEl ? passwordEl.value : '';

    if (!name || !email || !password) {
      window.showAuthModalError('Please fill out all fields.');
      return;
    }

    if (password.length < 6) {
      window.showAuthModalError('Password must be at least 6 characters.');
      return;
    }

    if (submitBtn) submitBtn.disabled = true;

    try {
      const res = await window.BizzApi.register({ name, email, password });
      if (res.success && res.user) {
        setCurrentUser(res.user);
        window.closeModals();
        window.showToast(`Account created! Welcome, ${res.user.name}!`, 'success');
        if (nameEl) nameEl.value = '';
        if (emailEl) emailEl.value = '';
        if (passwordEl) passwordEl.value = '';
        await fetchAndUpdateQuota();
        await window.loadUserProspects();
        await window.renderDashboardAnalytics();
        if (state.currentTab === 'analysis') {
          await window.renderAnalysisWorkspace();
        }
      } else {
        window.showAuthModalError(res.message || 'Registration failed.');
      }
    } catch (err) {
      window.showAuthModalError(err.message || 'Registration failed.');
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  }

  async function logoutUser() {
    await window.BizzApi.logout();
    setCurrentUser(null);
    window.showToast('Logged out successfully', 'info');
    await fetchAndUpdateQuota();
    window.switchTab('find-businesses');
  }

  window.initAuth = initAuth;
  window.checkAuthSession = checkAuthSession;
  window.setCurrentUser = setCurrentUser;
  window.fetchAndUpdateQuota = fetchAndUpdateQuota;
  window.updateQuotaUI = updateQuotaUI;
  window.handleModalLogin = handleModalLogin;
  window.handleModalRegister = handleModalRegister;
  window.logoutUser = logoutUser;

})(window);
