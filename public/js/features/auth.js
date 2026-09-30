/* public/js/features/auth.js - Authentication and Quota Controller */

(function (window) {
  'use strict';

  function initAuth() {
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

    // Password strength hint on register form
    const regPwdInput = document.getElementById('register-password');
    const regPwdHint = document.getElementById('register-password-hint');
    if (regPwdInput && regPwdHint && !regPwdInput.dataset.hintBound) {
      regPwdInput.dataset.hintBound = 'true';
      regPwdInput.addEventListener('focus', () => { regPwdHint.style.display = 'block'; });
      regPwdInput.addEventListener('blur', () => { regPwdHint.style.display = 'none'; });
    }

    const googleLoginBtn = document.getElementById('google-oauth-login-btn');
    if (googleLoginBtn && !googleLoginBtn.dataset.bound) {
      googleLoginBtn.dataset.bound = 'true';
      googleLoginBtn.addEventListener('click', () => handleGoogleSignIn(googleLoginBtn));
    }

    const googleRegisterBtn = document.getElementById('google-oauth-register-btn');
    if (googleRegisterBtn && !googleRegisterBtn.dataset.bound) {
      googleRegisterBtn.dataset.bound = 'true';
      googleRegisterBtn.addEventListener('click', () => handleGoogleSignIn(googleRegisterBtn));
    }

    // Forgot Password Form
    const forgotForm = document.getElementById('forgot-password-form');
    if (forgotForm && !forgotForm.dataset.bound) {
      forgotForm.dataset.bound = 'true';
      forgotForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleForgotPassword();
      });
    }

    // Reset Password Form
    const resetForm = document.getElementById('reset-password-form');
    if (resetForm && !resetForm.dataset.bound) {
      resetForm.dataset.bound = 'true';
      resetForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleResetPasswordSubmit();
      });
    }

    // Change Password Form (Settings > Security panel)
    const changeForm = document.getElementById('change-password-form');
    if (changeForm && !changeForm.dataset.bound) {
      changeForm.dataset.bound = 'true';
      changeForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await handleChangePassword();
      });
    }

    // Bind auth-page internal navigation links directly to switchTab.
    // These links use href="#forgot-password", "#login", etc. but we intercept
    // the click and call switchTab immediately so there is no page-reload delay.
    const authNavLinks = [
      { id: 'forgot-password-link',   tab: 'forgot-password' },
      { id: 'forgot-back-to-login',   tab: 'login' },
      { id: 'reset-back-to-login',    tab: 'login' },
      { id: 'login-go-to-register',   tab: 'register' },
      { id: 'register-go-to-login',   tab: 'login' },
    ];
    authNavLinks.forEach(({ id, tab }) => {
      const el = document.getElementById(id);
      if (el && !el.dataset.bound) {
        el.dataset.bound = 'true';
        el.addEventListener('click', (e) => {
          e.preventDefault();
          // Reset forgot-password form state when navigating away
          if (tab !== 'forgot-password') {
            const formWrap = document.getElementById('forgot-password-form-wrap');
            const successEl = document.getElementById('forgot-password-success');
            const fpEmail = document.getElementById('forgot-password-email');
            if (formWrap) formWrap.style.display = '';
            if (successEl) successEl.style.display = 'none';
            if (fpEmail) fpEmail.value = '';
          }
          if (typeof window.switchTab === 'function') {
            window.switchTab(tab);
          }
        });
      }
    });

    // User Profile Dropdown Menu Handlers
    const userPill = document.getElementById('user-profile-pill');
    const userDropdown = document.getElementById('user-profile-dropdown');
    const logoutBtn = document.getElementById('dropdown-logout-btn');

    if (userPill && !userPill.dataset.bound) {
      userPill.dataset.bound = 'true';
      userPill.addEventListener('click', (e) => {
        e.stopPropagation();
        const isHidden = !userDropdown || userDropdown.style.display === 'none';
        if (userDropdown) {
          userDropdown.style.display = isHidden ? 'block' : 'none';
          userPill.setAttribute('aria-expanded', isHidden ? 'true' : 'false');
        }
      });
    }

    if (logoutBtn && !logoutBtn.dataset.bound) {
      logoutBtn.dataset.bound = 'true';
      logoutBtn.addEventListener('click', async (e) => {
        e.stopPropagation();
        if (userDropdown) userDropdown.style.display = 'none';
        if (userPill) userPill.setAttribute('aria-expanded', 'false');
        await logoutUser();
      });
    }

    // Close user dropdown when clicking outside
    if (!document.dataset || !document.dataset.userDropdownBound) {
      if (document.dataset) document.dataset.userDropdownBound = 'true';
      document.addEventListener('click', (e) => {
        const wrapper = document.getElementById('user-profile-wrapper');
        const dropdown = document.getElementById('user-profile-dropdown');
        const pill = document.getElementById('user-profile-pill');
        if (wrapper && !wrapper.contains(e.target) && dropdown) {
          dropdown.style.display = 'none';
          if (pill) pill.setAttribute('aria-expanded', 'false');
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------
  function handleGoogleSignIn(btn) {
    if (btn) {
      btn.disabled = true;
      btn.innerHTML = '<span style="opacity:0.7">Redirecting to Google…</span>';
    }
    window.location.href = '/api/v1/auth/google';
  }

  function dismissLoadingOverlay() {
    const loadingEl = document.getElementById('app-auth-loading');
    if (loadingEl) {
      loadingEl.style.opacity = '0';
      setTimeout(() => { loadingEl.style.display = 'none'; }, 150);
    }
  }

  // ---------------------------------------------------------------------------
  // Google OAuth callback handler — called on every page load.
  // Rails redirects back to /#oauth_token=<JWT> or /#oauth_error=<message>
  // ---------------------------------------------------------------------------
  async function handleGoogleOAuthCallback() {
    const hash = window.location.hash;
    if (!hash) return false;

    if (hash.startsWith('#oauth_error=')) {
      const errorMsg = decodeURIComponent(hash.replace('#oauth_error=', ''));
      window.history.replaceState(null, '', window.location.pathname);
      window.showToast(errorMsg || 'Google sign-in failed. Please try again.', 'error');
      window.switchTab('login');
      dismissLoadingOverlay();
      return true;
    }

    if (hash.startsWith('#oauth_token=')) {
      const token = decodeURIComponent(hash.replace('#oauth_token=', ''));
      window.history.replaceState(null, '', window.location.pathname);

      if (!token) {
        window.showToast('Google sign-in failed: no token received.', 'error');
        window.switchTab('login');
        dismissLoadingOverlay();
        return true;
      }

      window.BizzApi.setToken(token);

      try {
        const user = await window.BizzApi.getMe();
        if (user) {
          setCurrentUser(user);
          window.showToast(`Welcome, ${user.name}!`, 'success');
          await fetchAndUpdateQuota();
          await window.loadUserProspects();
          if (typeof window.loadProfiles === 'function') await window.loadProfiles();
          if (typeof window.initProfileSelector === 'function') await window.initProfileSelector();
          window.switchTab('find-businesses');
          if (typeof window.checkAndRunOnboarding === 'function') await window.checkAndRunOnboarding();
        } else {
          window.BizzApi.removeToken();
          window.showToast('Google sign-in failed. Please try again.', 'error');
          window.switchTab('login');
        }
      } catch (err) {
        window.BizzApi.removeToken();
        window.showToast('Google sign-in failed. Please try again.', 'error');
        window.switchTab('login');
      } finally {
        dismissLoadingOverlay();
      }
      return true;
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // Email Verification Token Handler
  // Called from app.js when #verify_email=<token> is in the URL
  // ---------------------------------------------------------------------------
  async function handleEmailVerificationToken(token) {
    window.history.replaceState(null, '', window.location.pathname);
    dismissLoadingOverlay();

    if (!token) {
      window.showToast('Invalid verification link.', 'error');
      window.switchTab('login');
      return;
    }

    try {
      const res = await window.BizzApi.verifyEmail(token);
      if (res.success) {
        window.showToast('Email verified successfully! You can now sign in.', 'success');
        // If server returns a token, log user in directly
        if (res.token) {
          window.BizzApi.setToken(res.token);
          const user = await window.BizzApi.getMe();
          if (user) {
            setCurrentUser(user);
            await fetchAndUpdateQuota();
            await window.loadUserProspects();
            if (typeof window.loadProfiles === 'function') await window.loadProfiles();
            if (typeof window.initProfileSelector === 'function') await window.initProfileSelector();
            window.switchTab('find-businesses');
            if (typeof window.checkAndRunOnboarding === 'function') await window.checkAndRunOnboarding();
            return;
          }
        }
        window.switchTab('login');
      } else {
        window.showToast(res.message || 'Verification failed. The link may have expired.', 'error');
        window.switchTab('login');
      }
    } catch (err) {
      window.showToast('Verification failed. Please try again.', 'error');
      window.switchTab('login');
    }
  }

  // ---------------------------------------------------------------------------
  // Reset Password Token Handler (called from app.js on page load)
  // ---------------------------------------------------------------------------
  function handleResetPasswordToken(token) {
    window.history.replaceState(null, '', window.location.pathname);
    const tokenInput = document.getElementById('reset-password-token');
    if (tokenInput) tokenInput.value = token;
    window.switchTab('reset-password');
  }

  // ---------------------------------------------------------------------------
  // Auth Session Check
  // ---------------------------------------------------------------------------
  async function checkAuthSession() {
    const state = window.BizzState;

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
      if (['landing', 'login', 'register', 'forgot-password', 'reset-password'].includes(targetTab)) {
        destTab = 'find-businesses';
      }
    } else {
      if (['prospecting-profiles', 'dashboard', 'saved-businesses', 'analysis', 'settings'].includes(targetTab)) {
        destTab = (mappedHash === 'login' || mappedHash === 'register') ? mappedHash : 'find-businesses';
      }
    }

    window.switchTab(destTab || (user ? 'find-businesses' : 'landing'));
    dismissLoadingOverlay();

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

  // ---------------------------------------------------------------------------
  // User State
  // ---------------------------------------------------------------------------
  function setCurrentUser(user) {
    window.BizzState.currentUser = user;
    const userAvatarEl = document.getElementById('user-avatar');
    const userNameEl = document.getElementById('user-name');
    const userPillEl = document.getElementById('user-profile-pill');
    const dropdownUserNameEl = document.getElementById('dropdown-user-name');
    const dropdownUserEmailEl = document.getElementById('dropdown-user-email');
    const userDropdownEl = document.getElementById('user-profile-dropdown');
    const authNavEl = document.getElementById('authenticated-nav');
    const publicNavEl = document.getElementById('public-nav');
    const brandLinkEl = document.getElementById('brand-link');

    if (user) {
      const name = user.name || 'User Account';
      const email = user.email || '';
      const initials = name.split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase() || 'US';

      if (userNameEl) userNameEl.textContent = name;
      if (userAvatarEl) userAvatarEl.textContent = initials;
      if (dropdownUserNameEl) dropdownUserNameEl.textContent = name;
      if (dropdownUserEmailEl) {
        dropdownUserEmailEl.textContent = email;
        dropdownUserEmailEl.style.display = email ? 'block' : 'none';
      }

      if (userPillEl) userPillEl.style.display = 'inline-flex';
      if (authNavEl) authNavEl.style.display = 'flex';
      if (publicNavEl) publicNavEl.style.display = 'none';
      if (brandLinkEl) brandLinkEl.setAttribute('href', '#discovery');
    } else {
      if (userNameEl) userNameEl.textContent = 'Guest';
      if (userAvatarEl) userAvatarEl.textContent = 'GU';

      if (userPillEl) {
        userPillEl.style.display = 'none';
        userPillEl.setAttribute('aria-expanded', 'false');
      }
      if (userDropdownEl) userDropdownEl.style.display = 'none';
      if (authNavEl) authNavEl.style.display = 'none';
      if (publicNavEl) publicNavEl.style.display = 'flex';
      if (brandLinkEl) brandLinkEl.setAttribute('href', '#landing');
    }

    if (typeof window.updateDiscoveryBannerVisibility === 'function') {
      window.updateDiscoveryBannerVisibility();
    }
  }

  // ---------------------------------------------------------------------------
  // Quota
  // ---------------------------------------------------------------------------
  async function fetchAndUpdateQuota() {
    const quota = await window.BizzApi.getSearchQuota();
    if (quota) {
      updateQuotaUI(quota);
    }
  }

  function updateQuotaUI(quota) {
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

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Register
  // ---------------------------------------------------------------------------
  async function handleDedicatedRegister() {
    const errorBox = document.getElementById('register-error-box');
    const nameEl = document.getElementById('register-name');
    const emailEl = document.getElementById('register-email');
    const passwordEl = document.getElementById('register-password');
    const confirmEl = document.getElementById('register-confirm-password');
    const submitBtn = document.getElementById('register-submit-btn');

    if (errorBox) {
      errorBox.style.display = 'none';
      errorBox.textContent = '';
      errorBox.style.background = '';
      errorBox.style.borderColor = '';
      errorBox.style.color = '';
    }

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

    // Frontend validation hint (backend is authoritative)
    if (password.length < 8) {
      if (errorBox) { errorBox.textContent = 'Password must be at least 8 characters.'; errorBox.style.display = 'block'; }
      return;
    }

    if (submitBtn) submitBtn.disabled = true;

    try {
      const res = await window.BizzApi.register({ name, email, password });
      if (res.success && res.user) {
        if (nameEl) nameEl.value = '';
        if (emailEl) emailEl.value = '';
        if (passwordEl) passwordEl.value = '';
        if (confirmEl) confirmEl.value = '';

        if (res.token) {
          // Token returned — no email verification enforced, log in directly
          setCurrentUser(res.user);
          window.showToast(`Account created! Welcome, ${res.user.name}!`, 'success');
          await fetchAndUpdateQuota();
          await window.loadUserProspects();
          if (typeof window.loadProfiles === 'function') await window.loadProfiles();
          if (typeof window.initProfileSelector === 'function') await window.initProfileSelector();
          window.switchTab('find-businesses');
          if (typeof window.checkAndRunOnboarding === 'function') await window.checkAndRunOnboarding();
        } else {
          // Email verification required
          window.showToast('Account created! Check your email to verify your account.', 'success');
          if (errorBox) {
            errorBox.style.background = 'rgba(34,197,94,0.08)';
            errorBox.style.borderColor = 'rgba(34,197,94,0.35)';
            errorBox.style.color = 'var(--text-main)';
            errorBox.innerHTML = `<strong>✓ Account created!</strong> A verification email has been sent to <strong>${email}</strong>. Please check your inbox and click the link to activate your account.`;
            errorBox.style.display = 'block';
          }
        }
      } else {
        if (errorBox) { errorBox.textContent = res.message || 'Registration failed.'; errorBox.style.display = 'block'; }
      }
    } catch (err) {
      if (errorBox) { errorBox.textContent = err.message || 'Registration failed.'; errorBox.style.display = 'block'; }
    } finally {
      if (submitBtn) submitBtn.disabled = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Forgot Password
  // ---------------------------------------------------------------------------
  async function handleForgotPassword() {
    const emailEl = document.getElementById('forgot-password-email');
    const submitBtn = document.getElementById('forgot-password-submit-btn');
    const errorBox = document.getElementById('forgot-password-error-box');
    const formWrap = document.getElementById('forgot-password-form-wrap');
    const successEl = document.getElementById('forgot-password-success');

    if (errorBox) { errorBox.style.display = 'none'; errorBox.textContent = ''; }

    const email = emailEl ? emailEl.value.trim() : '';
    if (!email) {
      if (errorBox) { errorBox.textContent = 'Please enter your email address.'; errorBox.style.display = 'block'; }
      return;
    }

    if (submitBtn) { submitBtn.disabled = true; submitBtn.textContent = 'Sending…'; }

    try {
      // Always returns success to prevent account enumeration
      await window.BizzApi.forgotPassword(email);
      if (formWrap) formWrap.style.display = 'none';
      if (successEl) successEl.style.display = 'block';
    } catch (err) {
      // Show success anyway to prevent enumeration
      if (formWrap) formWrap.style.display = 'none';
      if (successEl) successEl.style.display = 'block';
    } finally {
      if (submitBtn) { submitBtn.disabled = false; submitBtn.textContent = 'Send Reset Link'; }
    }
  }

  // ---------------------------------------------------------------------------
  // Reset Password (form submit)
  // ---------------------------------------------------------------------------
  async function handleResetPasswordSubmit() {
    const tokenInput = document.getElementById('reset-password-token');
    const newPwdEl = document.getElementById('reset-new-password');
    const confirmPwdEl = document.getElementById('reset-confirm-password');
    const submitBtn = document.getElementById('reset-password-submit-btn');
    const errorBox = document.getElementById('reset-password-error-box');
    const successEl = document.getElementById('reset-password-success');
    const formEl = document.getElementById('reset-password-form');

    if (errorBox) { errorBox.style.display = 'none'; errorBox.textContent = ''; }

    const token = tokenInput ? tokenInput.value.trim() : '';
    const password = newPwdEl ? newPwdEl.value : '';
    const confirmPassword = confirmPwdEl ? confirmPwdEl.value : '';

    if (!token) {
      if (errorBox) { errorBox.textContent = 'Invalid or expired reset link. Please request a new one.'; errorBox.style.display = 'block'; }
      return;
    }

    if (!password) {
      if (errorBox) { errorBox.textContent = 'Please enter a new password.'; errorBox.style.display = 'block'; }
      return;
    }

    if (password.length < 8) {
      if (errorBox) { errorBox.textContent = 'Password must be at least 8 characters.'; errorBox.style.display = 'block'; }
      return;
    }

    if (password !== confirmPassword) {
      if (errorBox) { errorBox.textContent = 'Passwords do not match.'; errorBox.style.display = 'block'; }
      return;
    }

    if (submitBtn) { submitBtn.disabled = true; submitBtn.textContent = 'Resetting…'; }

    try {
      const res = await window.BizzApi.resetPassword(token, password);
      if (res.success) {
        if (formEl) formEl.style.display = 'none';
        if (successEl) successEl.style.display = 'block';
        window.showToast('Password reset successfully! Redirecting to sign in…', 'success');
        setTimeout(() => { window.switchTab('login'); }, 2500);
      } else {
        if (errorBox) { errorBox.textContent = res.message || 'Reset failed. The link may have expired.'; errorBox.style.display = 'block'; }
      }
    } catch (err) {
      if (errorBox) { errorBox.textContent = err.message || 'Reset failed. Please try again.'; errorBox.style.display = 'block'; }
    } finally {
      if (submitBtn) { submitBtn.disabled = false; submitBtn.textContent = 'Reset Password'; }
    }
  }

  // ---------------------------------------------------------------------------
  // Change Password (Settings > Security)
  // ---------------------------------------------------------------------------
  async function handleChangePassword() {
    const currentPwdEl = document.getElementById('change-current-password');
    const newPwdEl = document.getElementById('change-new-password');
    const confirmPwdEl = document.getElementById('change-confirm-password');
    const submitBtn = document.getElementById('change-password-btn');
    const errorEl = document.getElementById('change-password-error');

    if (errorEl) { errorEl.style.display = 'none'; errorEl.textContent = ''; }

    const currentPassword = currentPwdEl ? currentPwdEl.value : '';
    const newPassword = newPwdEl ? newPwdEl.value : '';
    const confirmPassword = confirmPwdEl ? confirmPwdEl.value : '';

    if (!currentPassword || !newPassword || !confirmPassword) {
      if (errorEl) { errorEl.textContent = 'Please fill out all fields.'; errorEl.style.display = 'block'; }
      return;
    }

    if (newPassword.length < 8) {
      if (errorEl) { errorEl.textContent = 'New password must be at least 8 characters.'; errorEl.style.display = 'block'; }
      return;
    }

    if (newPassword !== confirmPassword) {
      if (errorEl) { errorEl.textContent = 'New passwords do not match.'; errorEl.style.display = 'block'; }
      return;
    }

    if (submitBtn) { submitBtn.disabled = true; submitBtn.textContent = 'Updating…'; }

    try {
      const res = await window.BizzApi.changePassword(currentPassword, newPassword);
      if (res.success) {
        window.showToast('Password updated successfully!', 'success');
        if (currentPwdEl) currentPwdEl.value = '';
        if (newPwdEl) newPwdEl.value = '';
        if (confirmPwdEl) confirmPwdEl.value = '';
      } else {
        if (errorEl) { errorEl.textContent = res.message || 'Failed to update password.'; errorEl.style.display = 'block'; }
      }
    } catch (err) {
      if (errorEl) { errorEl.textContent = err.message || 'Failed to update password.'; errorEl.style.display = 'block'; }
    } finally {
      if (submitBtn) { submitBtn.disabled = false; submitBtn.textContent = 'Update Password'; }
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------
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

  // Global exports
  window.initAuth = initAuth;
  window.checkAuthSession = checkAuthSession;
  window.handleGoogleOAuthCallback = handleGoogleOAuthCallback;
  window.handleEmailVerificationToken = handleEmailVerificationToken;
  window.handleResetPasswordToken = handleResetPasswordToken;
  window.setCurrentUser = setCurrentUser;
  window.fetchAndUpdateQuota = fetchAndUpdateQuota;
  window.updateQuotaUI = updateQuotaUI;
  window.handleDedicatedLogin = handleDedicatedLogin;
  window.handleDedicatedRegister = handleDedicatedRegister;
  window.handleChangePassword = handleChangePassword;
  window.logoutUser = logoutUser;

})(window);
