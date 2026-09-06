/* public/js/features/analysis.js - Dedicated Intelligence Analysis Workspace Component */

(function (window) {
  'use strict';

  function calculateOpportunityScore(b) {
    let score = 0;
    const factors = [];

    const hasWebsite = Boolean(b.website);
    const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';
    const hasPhone = Boolean(rawPhone);
    const waUrl = window.buildWhatsAppUrl(b);
    const hasWhatsapp = Boolean(waUrl);

    const rating = parseFloat(b.rating || 0);
    const reviewCount = parseInt(b.review_count || b.user_rating_count || 0, 10);

    if (!hasWebsite) {
      score += 30;
      factors.push('No website');
    }

    if (hasPhone) {
      score += 20;
      factors.push('Phone available');
    }

    if (hasWhatsapp) {
      score += 15;
      factors.push('WhatsApp available');
    }

    if (rating >= 4.5) {
      score += 15;
      factors.push(`${rating.toFixed(1)} rating`);
    } else if (rating >= 4.0) {
      score += 12;
      factors.push(`${rating.toFixed(1)} rating`);
    } else if (rating >= 3.5) {
      score += 8;
      factors.push(`${rating.toFixed(1)} rating`);
    } else if (rating >= 3.0) {
      score += 4;
      factors.push(`${rating.toFixed(1)} rating`);
    }

    if (reviewCount > 500) {
      score += 10;
      factors.push(`${reviewCount} reviews`);
    } else if (reviewCount >= 101) {
      score += 7;
      factors.push(`${reviewCount} reviews`);
    } else if (reviewCount >= 51) {
      score += 4;
      factors.push(`${reviewCount} reviews`);
    } else if (reviewCount >= 11) {
      score += 2;
      factors.push(`${reviewCount} reviews`);
    }

    score = Math.min(score, 100);

    let tier = 'low';
    if (score >= 80) tier = 'high';
    else if (score >= 50) tier = 'medium';

    return {
      score,
      tier,
      level: tier.toUpperCase(),
      factors
    };
  }

  function calculateAnalytics(businessesList = []) {
    const list = Array.isArray(businessesList) ? businessesList : [];
    const totalFound = list.length;

    let noWebsiteCount = 0;
    let hasWebsiteCount = 0;

    let phoneCount = 0;
    let whatsappCount = 0;
    let noPhoneCount = 0;

    let highOppCount = 0;
    let medOppCount = 0;
    let lowOppCount = 0;

    const typesMap = {};
    const locationsMap = {};
    const ratingsMap = {
      '5.0': 0,
      '4.5-4.9': 0,
      '4.0-4.4': 0,
      '3.5-3.9': 0,
      'Below 3.5': 0
    };

    const processedList = list.map(b => {
      const opp = calculateOpportunityScore(b);
      const enriched = {
        ...b,
        opportunity_score: b.opportunity_score || opp.score,
        opportunity_tier: b.opportunity_tier || opp.tier,
        opportunity_level: b.opportunity_level || opp.level,
        opportunity_factors: b.opportunity_factors || opp.factors
      };

      if (enriched.opportunity_tier === 'high') highOppCount++;
      else if (enriched.opportunity_tier === 'medium') medOppCount++;
      else lowOppCount++;

      if (b.website) hasWebsiteCount++;
      else noWebsiteCount++;

      const rawPhone = b.phone || b.phone_number || b.national_phone || b.international_phone_number || '';
      if (rawPhone) {
        phoneCount++;
        if (window.buildWhatsAppUrl(b)) whatsappCount++;
      } else {
        noPhoneCount++;
      }

      // Types
      let rawTypes = b.types;
      if (!rawTypes && b.category) rawTypes = [b.category];
      if (typeof rawTypes === 'string') rawTypes = [rawTypes];
      if (Array.isArray(rawTypes)) {
        rawTypes
          .filter(t => !['point_of_interest', 'establishment', 'business'].includes(String(t).toLowerCase()))
          .forEach(t => {
            const formatted = window.capitalize(String(t).replace(/_/g, ' '));
            typesMap[formatted] = (typesMap[formatted] || 0) + 1;
          });
      }

      // Locations
      if (b.address) {
        const parts = b.address.split(',').map(s => s.trim());
        const loc = parts.length >= 3 ? parts[1] : (parts[0] || 'Local Area');
        locationsMap[loc] = (locationsMap[loc] || 0) + 1;
      }

      // Ratings
      const r = parseFloat(b.rating || 0);
      if (r >= 5.0) ratingsMap['5.0']++;
      else if (r >= 4.5) ratingsMap['4.5-4.9']++;
      else if (r >= 4.0) ratingsMap['4.0-4.4']++;
      else if (r >= 3.5) ratingsMap['3.5-3.9']++;
      else if (r > 0) ratingsMap['Below 3.5']++;

      return enriched;
    });

    const sortedTypes = Object.keys(typesMap)
      .map(k => ({ type: k, count: typesMap[k] }))
      .sort((a, b) => b.count - a.count);

    const sortedLocations = Object.keys(locationsMap)
      .map(k => ({ name: k, count: locationsMap[k] }))
      .sort((a, b) => b.count - a.count);

    const topProspects = [...processedList]
      .sort((a, b) => (b.opportunity_score || 0) - (a.opportunity_score || 0))
      .slice(0, 10);

    return {
      totalFound,
      noWebsiteCount,
      hasWebsiteCount,
      phoneCount,
      whatsappCount,
      noPhoneCount,
      highOppCount,
      medOppCount,
      lowOppCount,
      sortedTypes,
      sortedLocations,
      ratingsMap,
      topProspects,
      processedList
    };
  }

  // --- Render Dedicated Analysis Workspace ---
  async function renderAnalysisWorkspace() {
    const dom = window.dom;
    const state = window.BizzState;

    if (!state.currentUser) {
      if (dom.analysisAuthGate) dom.analysisAuthGate.style.display = 'block';
      if (dom.searchHistoryContainer) dom.searchHistoryContainer.style.display = 'none';
      if (dom.analysisEmptyState) dom.analysisEmptyState.style.display = 'none';
      if (dom.topProspectsList) dom.topProspectsList.innerHTML = '';
      if (dom.analysisLoginBtn) {
        dom.analysisLoginBtn.onclick = () => window.openAuthModal('login', 'Sign up or log in to access the Analysis Workspace!');
      }
      return;
    }

    if (dom.analysisAuthGate) dom.analysisAuthGate.style.display = 'none';

    // Render Search History list
    const searches = await window.BizzApi.getSearches();
    if (searches && searches.length > 0) {
      if (!state.activeSearchId) {
        state.activeSearchId = searches[0].id;
      }
      if (dom.searchHistoryContainer) dom.searchHistoryContainer.style.display = 'block';
      if (dom.searchHistoryList) {
        dom.searchHistoryList.innerHTML = searches.map(s => {
          const isSelected = state.activeSearchId === s.id;
          const dateStr = new Date(s.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
          return `
            <div class="chart-filter-btn ${isSelected ? 'active' : ''}" style="display: flex; align-items: center; gap: 0.5rem; white-space: nowrap;" data-search-id="${s.id}">
              <span>🏢 ${window.escapeHtml(s.business_type)} (${window.escapeHtml(s.location_name || 'All')})</span>
              <span style="opacity: 0.75; font-size: 0.75rem;">• ${s.results_count} leads • ${dateStr}</span>
            </div>
          `;
        }).join('');

        dom.searchHistoryList.querySelectorAll('[data-search-id]').forEach(btn => {
          btn.onclick = async () => {
            state.activeSearchId = btn.getAttribute('data-search-id');
            await renderAnalysisWorkspace();
          };
        });
      }
    } else {
      if (dom.searchHistoryContainer) dom.searchHistoryContainer.style.display = 'none';
    }

    // Fetch search-specific analysis or latest search analysis
    let analysisData = await window.BizzApi.getSearchAnalysis(state.activeSearchId);
    const hasAnalysisData = analysisData && analysisData.summary && analysisData.summary.total_businesses > 0;

    if (!hasAnalysisData && state.searchResults && state.searchResults.length > 0) {
      analysisData = calculateAnalytics(state.searchResults);
    }

    if (!analysisData || (!analysisData.top_prospects && (!analysisData.summary || analysisData.summary.total_businesses === 0))) {
      if (dom.analysisEmptyState) dom.analysisEmptyState.style.display = 'block';
      if (dom.analysisKpiFound) dom.analysisKpiFound.textContent = '0';
      if (dom.analysisKpiNoWebsite) dom.analysisKpiNoWebsite.textContent = '0';
      if (dom.analysisKpiPhone) dom.analysisKpiPhone.textContent = '0';
      if (dom.analysisKpiWhatsapp) dom.analysisKpiWhatsapp.textContent = '0';
      if (dom.analysisKpiHighOpp) dom.analysisKpiHighOpp.textContent = '0';
      if (dom.topProspectsList) dom.topProspectsList.innerHTML = '';
      if (dom.analysisEmptySearchBtn) {
        dom.analysisEmptySearchBtn.onclick = () => window.switchTab('find-businesses');
      }
      return;
    }

    if (dom.analysisEmptyState) dom.analysisEmptyState.style.display = 'none';

    const summary = analysisData.summary || {
      total_businesses: analysisData.totalFound || 0,
      no_website_count: analysisData.noWebsiteCount || 0,
      phone_available_count: analysisData.phoneCount || 0,
      whatsapp_available_count: analysisData.whatsappCount || 0,
      high_opportunity_count: analysisData.highOppCount || 0
    };

    const oppCounts = analysisData.opportunity || {
      high: analysisData.highOppCount || 0,
      medium: analysisData.medOppCount || 0,
      low: analysisData.lowOppCount || 0
    };

    const webCounts = analysisData.website || {
      no_website: analysisData.noWebsiteCount || 0,
      has_website: analysisData.hasWebsiteCount || 0
    };

    const contactCounts = analysisData.contactability || {
      phone_available: analysisData.phoneCount || 0,
      whatsapp_available: analysisData.whatsappCount || 0,
      no_phone: analysisData.noPhoneCount || 0
    };

    const topProspects = analysisData.top_prospects || [];
    const searchMeta = analysisData.search;

    if (dom.analysisSearchContextLabel) {
      if (searchMeta) {
        dom.analysisSearchContextLabel.textContent = `Search Analysis: ${searchMeta.business_type} in ${searchMeta.location_name || 'All'} • ${summary.total_businesses} businesses analyzed`;
      } else {
        dom.analysisSearchContextLabel.textContent = `Search Analysis: ${summary.total_businesses} businesses analyzed`;
      }
    }

    // Update 5 KPI Cards
    if (dom.analysisKpiFound) dom.analysisKpiFound.textContent = summary.total_businesses;
    if (dom.analysisKpiNoWebsite) dom.analysisKpiNoWebsite.textContent = summary.no_website_count;
    if (dom.analysisKpiPhone) dom.analysisKpiPhone.textContent = summary.phone_available_count;
    if (dom.analysisKpiWhatsapp) dom.analysisKpiWhatsapp.textContent = summary.whatsapp_available_count;
    if (dom.analysisKpiHighOpp) dom.analysisKpiHighOpp.textContent = summary.high_opportunity_count;

    const colors = window.getChartColors();

    // 1. Opportunity Overview Donut Chart
    window.createChart('analysis-chart-opportunity', {
      type: 'doughnut',
      data: {
        labels: [
          `High (${oppCounts.high})`,
          `Medium (${oppCounts.medium})`,
          `Low (${oppCounts.low})`
        ],
        datasets: [{
          data: [oppCounts.high, oppCounts.medium, oppCounts.low],
          backgroundColor: [colors.highOpp, colors.medOpp, colors.lowOpp],
          borderWidth: 2,
          borderColor: colors.borderColor
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { color: colors.textColor, font: { weight: '600' } } }
        }
      }
    });

    // 2. Website Opportunity Chart
    window.createChart('analysis-chart-website', {
      type: 'doughnut',
      data: {
        labels: [`No Website (${webCounts.no_website})`, `Has Website (${webCounts.has_website})`],
        datasets: [{
          data: [webCounts.no_website, webCounts.has_website],
          backgroundColor: [colors.noWebsite, colors.hasWebsite],
          borderWidth: 2,
          borderColor: colors.borderColor
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'bottom', labels: { color: colors.textColor, font: { weight: '600' } } }
        }
      }
    });

    // 3. Contactability Chart
    window.createChart('analysis-chart-contactability', {
      type: 'bar',
      data: {
        labels: ['Phone Available', 'WhatsApp Available', 'No Phone'],
        datasets: [{
          data: [
            contactCounts.phone_available || 0,
            contactCounts.whatsapp_available || 0,
            contactCounts.no_phone || 0
          ],
          backgroundColor: [colors.phone, colors.whatsapp, colors.noPhone],
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: colors.textColor }, grid: { display: false } },
          y: { ticks: { color: colors.textColor }, grid: { color: colors.borderColor } }
        }
      }
    });

    // 4. Rating Distribution Chart
    const ratingList = analysisData.ratings || [];
    const ratingMap = {};
    if (Array.isArray(ratingList)) {
      ratingList.forEach(r => { ratingMap[r.range] = r.count; });
    } else if (analysisData.ratingsMap) {
      Object.assign(ratingMap, analysisData.ratingsMap);
    }

    window.createChart('analysis-chart-ratings', {
      type: 'bar',
      data: {
        labels: ['5.0', '4.5–4.9', '4.0–4.4', '3.5–3.9', 'Below 3.5'],
        datasets: [{
          data: [
            ratingMap['5.0'] || 0,
            ratingMap['4.5-4.9'] || 0,
            ratingMap['4.0-4.4'] || 0,
            ratingMap['3.5-3.9'] || 0,
            ratingMap['Below 3.5'] || 0
          ],
          backgroundColor: colors.primary,
          borderRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: colors.textColor }, grid: { display: false } },
          y: { ticks: { color: colors.textColor }, grid: { color: colors.borderColor } }
        }
      }
    });

    // 5. Business Type Distribution Chart
    const typesData = (analysisData.business_types || analysisData.sortedTypes || []).slice(0, 8);
    window.createChart('analysis-chart-business-types', {
      type: 'bar',
      data: {
        labels: typesData.map(t => t.type),
        datasets: [{
          data: typesData.map(t => t.count),
          backgroundColor: colors.primary,
          borderRadius: 6
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: colors.textColor }, grid: { color: colors.borderColor } },
          y: { ticks: { color: colors.textColor }, grid: { display: false } }
        }
      }
    });

    // 6. Location Distribution Chart
    const locsData = (analysisData.locations || analysisData.sortedLocations || []).slice(0, 8);
    window.createChart('analysis-chart-locations', {
      type: 'bar',
      data: {
        labels: locsData.length > 0 ? locsData.map(l => l.name) : ['All Areas'],
        datasets: [{
          data: locsData.length > 0 ? locsData.map(l => l.count) : [summary.total_businesses],
          backgroundColor: colors.primary,
          borderRadius: 6
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: colors.textColor }, grid: { color: colors.borderColor } },
          y: { ticks: { color: colors.textColor }, grid: { display: false } }
        }
      }
    });

    // Render Ranked Top Opportunities Workspace
    renderTopProspectsList(topProspects);

    // Attach Analysis Buttons
    if (dom.analysisBtnBackResults) {
      dom.analysisBtnBackResults.onclick = () => window.switchTab('find-businesses');
    }

    const processedList = analysisData.processedList || topProspects;
    if (dom.analysisBtnExportCsv) {
      dom.analysisBtnExportCsv.onclick = () => exportAnalysisToCsv(processedList);
    }

    if (dom.filterBtnHighOpp) {
      dom.filterBtnHighOpp.onclick = () => filterResultsBy('high_opp');
    }
    if (dom.filterBtnMedOpp) {
      dom.filterBtnMedOpp.onclick = () => filterResultsBy('med_opp');
    }
    if (dom.filterBtnLowOpp) {
      dom.filterBtnLowOpp.onclick = () => filterResultsBy('low_opp');
    }
    if (dom.filterBtnNoWebsite) {
      dom.filterBtnNoWebsite.onclick = () => filterResultsBy('no_website');
    }
    if (dom.filterBtnWhatsappOnly) {
      dom.filterBtnWhatsappOnly.onclick = () => filterResultsBy('whatsapp_only');
    }
  }

  // --- Render Top Opportunities Prospects List ---
  function renderTopProspectsList(topList) {
    const dom = window.dom;
    const state = window.BizzState;
    if (!dom.topProspectsList) return;

    if (!topList || topList.length === 0) {
      dom.topProspectsList.innerHTML = `<div style="text-align: center; color: var(--text-muted); padding: 1.5rem;">No opportunities scored yet.</div>`;
      return;
    }

    dom.topProspectsList.innerHTML = topList.map(b => {
      const score = b.opportunity_score || 0;
      const tier = b.opportunity_tier || (score >= 80 ? 'high' : (score >= 50 ? 'medium' : 'low'));
      const factors = Array.isArray(b.opportunity_factors) ? b.opportunity_factors : [];
      const waUrl = window.buildWhatsAppUrl(b);
      const name = b.name || b.business_name;
      const placeId = b.google_place_id || b.id;
      const isSaved = state.savedBusinesses.some(saved => saved.google_place_id === placeId || saved.id === placeId);

      const tierBadgeClass = tier === 'high' ? 'badge-tier-high' : (tier === 'medium' ? 'badge-tier-medium' : 'badge-tier-low');
      const tierLabel = tier.toUpperCase();

      return `
        <div class="top-prospect-card">
          <div class="score-badge-circle">
            <span class="score-badge-val">${score}</span>
            <span class="score-badge-lbl">SCORE</span>
          </div>

          <div class="top-prospect-details">
            <div style="display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap;">
              <span class="top-prospect-name">${window.escapeHtml(name)}</span>
              <span class="${tierBadgeClass}">${tierLabel} OPPORTUNITY</span>
            </div>

            <div class="top-prospect-meta">
              <span>⭐ ${b.rating ? Number(b.rating).toFixed(1) : 'N/A'} (${b.review_count || 0} reviews)</span>
              <span>📍 ${window.escapeHtml(b.address || 'Address unavailable')}</span>
            </div>

            <div style="font-size: 0.78rem; font-weight: 700; color: var(--text-muted); margin-top: 0.25rem;">
              Why contact this business:
            </div>
            <div class="factors-list-box">
              ${factors.map(f => `<span class="factor-tag">✓ ${window.escapeHtml(f)}</span>`).join('')}
            </div>
          </div>

          <div class="top-prospect-actions">
            ${waUrl ? `<a href="${waUrl}" target="_blank" class="btn btn-whatsapp btn-sm btn-block">💬 WhatsApp</a>` : ''}
            <button class="btn btn-secondary btn-sm btn-block save-prospect-btn" data-place-id="${placeId}">
              ${isSaved ? '📌 Saved' : '➕ Save'}
            </button>
          </div>
        </div>
      `;
    }).join('');

    // Attach save listeners
    dom.topProspectsList.querySelectorAll('.save-prospect-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const placeId = btn.getAttribute('data-place-id');
        const b = topList.find(x => (x.google_place_id || x.id) === placeId);
        if (b) window.toggleSaveBusiness(b);
      });
    });
  }

  // --- Interactive Chart Filtering Trigger ---
  function filterResultsBy(criteria) {
    const dom = window.dom;
    const state = window.BizzState;
    let filtered = [...state.searchResults];

    if (criteria === 'high_opp') {
      filtered = filtered.filter(b => (b.opportunity_score || calculateOpportunityScore(b).score) >= 80);
    } else if (criteria === 'med_opp') {
      filtered = filtered.filter(b => {
        const s = b.opportunity_score || calculateOpportunityScore(b).score;
        return s >= 50 && s < 80;
      });
    } else if (criteria === 'low_opp') {
      filtered = filtered.filter(b => (b.opportunity_score || calculateOpportunityScore(b).score) < 50);
    } else if (criteria === 'no_website') {
      filtered = filtered.filter(b => !b.website);
    } else if (criteria === 'whatsapp_only') {
      filtered = filtered.filter(b => Boolean(window.buildWhatsAppUrl(b)));
    }

    if (dom.cardsGrid) {
      dom.cardsGrid.innerHTML = filtered.map(b => window.createBusinessCardHtml(b)).join('');
      window.attachCardEventListeners();
    }

    if (dom.resultsCount) dom.resultsCount.textContent = filtered.length;
    window.switchTab('find-businesses');
    window.showToast(`Filtered ${filtered.length} matching prospects`, 'info');
  }

  // --- Export Analysis CSV ---
  function exportAnalysisToCsv(list) {
    if (!list || list.length === 0) {
      window.showToast('No analysis data to export', 'error');
      return;
    }

    const headers = ['Rank', 'Name', 'Opportunity Score', 'Tier', 'Phone', 'WhatsApp Available', 'Website', 'Rating', 'Review Count', 'Factors', 'Address'];
    const rows = list.map((b, idx) => {
      const opp = calculateOpportunityScore(b);
      const score = b.opportunity_score || opp.score;
      const tier = (b.opportunity_tier || opp.tier).toUpperCase();
      const phone = b.phone || b.national_phone || b.phone_number || '';
      const waAvailable = Boolean(window.buildWhatsAppUrl(b)) ? 'Yes' : 'No';
      const website = b.website || 'No Website';
      const rating = b.rating || 'N/A';
      const reviews = b.review_count || 0;
      const factors = (b.opportunity_factors || opp.factors).join(' | ');
      const address = (b.address || '').replace(/"/g, '""');

      return [
        idx + 1,
        `"${(b.name || b.business_name || '').replace(/"/g, '""')}"`,
        score,
        tier,
        `"${phone}"`,
        waAvailable,
        `"${website}"`,
        rating,
        reviews,
        `"${factors}"`,
        `"${address}"`
      ].join(',');
    });

    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `bizz_hunter_analysis_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    window.showToast('Analysis exported to CSV file', 'success');
  }

  window.calculateOpportunityScore = calculateOpportunityScore;
  window.calculateAnalytics = calculateAnalytics;
  window.renderAnalysisWorkspace = renderAnalysisWorkspace;
  window.renderTopProspectsList = renderTopProspectsList;
  window.filterResultsBy = filterResultsBy;
  window.exportAnalysisToCsv = exportAnalysisToCsv;

})(window);
