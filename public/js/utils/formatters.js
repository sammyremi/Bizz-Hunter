/* public/js/utils/formatters.js - Utility string and URL formatters */

(function (window) {
  'use strict';

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  function capitalize(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  // WhatsApp Phone Number Sanitizer & Link Formatter
  function buildWhatsAppUrl(b) {
    const rawIntl = b.phone || b.phone_number || '';
    const rawNat = b.national_phone || b.international_phone_number || '';
    const phoneStr = rawIntl || rawNat || '';
    if (!phoneStr) return null;

    // Strip everything except 0-9 digits
    let digits = phoneStr.replace(/\D/g, '');
    if (!digits) return null;

    // Handle Nigerian local format (e.g. 08032079169 -> 2348032079169)
    if (digits.startsWith('0') && digits.length === 11) {
      digits = '234' + digits.substring(1);
    } else if (digits.length === 10 && !digits.startsWith('234')) {
      digits = '234' + digits;
    }

    if (digits.length < 7) return null;

    // Format: https://wa.me/<FULL_INTERNATIONAL_PHONE_NUMBER>
    return `https://wa.me/${digits}`;
  }

  window.escapeHtml = escapeHtml;
  window.escapeRegExp = escapeRegExp;
  window.capitalize = capitalize;
  window.buildWhatsAppUrl = buildWhatsAppUrl;

})(window);
