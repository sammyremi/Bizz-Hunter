/* public/js/api.js - Bizz-Hunter Backend API Service Client */

(function (window) {
  'use strict';

  const BASE_API_URL = '/api/v1';
  const TOKEN_STORAGE_KEY = 'bizz_hunter_jwt_token';

  class ApiClient {
    static getToken() {
      return localStorage.getItem(TOKEN_STORAGE_KEY);
    }

    static setToken(token) {
      if (token) {
        localStorage.setItem(TOKEN_STORAGE_KEY, token);
      } else {
        localStorage.removeItem(TOKEN_STORAGE_KEY);
      }
    }

    static removeToken() {
      localStorage.removeItem(TOKEN_STORAGE_KEY);
    }

    static getHeaders(extraHeaders = {}) {
      const headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...extraHeaders
      };

      const token = this.getToken();
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      return headers;
    }

    // --- Auth API ---
    static async register(data) {
      const response = await fetch(`${BASE_API_URL}/auth/register`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(data)
      });
      const json = await response.json();
      if (response.ok && json.success && json.token) {
        this.setToken(json.token);
      }
      return json;
    }

    static async login(credentials) {
      const response = await fetch(`${BASE_API_URL}/auth/login`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(credentials)
      });
      const json = await response.json();
      if (response.ok && json.success && json.token) {
        this.setToken(json.token);
      }
      return json;
    }

    static async getMe() {
      if (!this.getToken()) return null;
      try {
        const response = await fetch(`${BASE_API_URL}/auth/me`, {
          method: 'GET',
          headers: this.getHeaders()
        });
        const json = await response.json();
        if (response.ok && json.success) {
          return json.user;
        }
      } catch (e) {
        console.warn('Auth check error', e);
      }
      return null;
    }

    static async logout() {
      try {
        await fetch(`${BASE_API_URL}/auth/logout`, {
          method: 'POST',
          headers: this.getHeaders()
        });
      } catch (e) {
        console.warn('Logout API error', e);
      } finally {
        this.removeToken();
      }
    }

    // --- Business Discovery API ---
    static async getSearchQuota() {
      try {
        const response = await fetch(`${BASE_API_URL}/business-discovery/quota`, {
          method: 'GET',
          headers: this.getHeaders()
        });
        const json = await response.json();
        if (response.ok && json.success) {
          return json.quota;
        }
      } catch (e) {
        console.warn('Error fetching search quota', e);
      }
      return null;
    }

    static async searchBusinesses(params) {
      const queryParams = new URLSearchParams();

      if (params.business_type) queryParams.append('business_type', params.business_type);
      if (params.place_id) queryParams.append('place_id', params.place_id);
      if (params.location_name) queryParams.append('location_name', params.location_name);
      if (params.country) queryParams.append('country', params.country);
      if (params.state) queryParams.append('state', params.state);
      if (params.city) queryParams.append('city', params.city);
      if (params.area) queryParams.append('area', params.area);
      if (params.min_rating) queryParams.append('min_rating', params.min_rating);
      if (params.has_phone !== undefined && params.has_phone !== '') {
        queryParams.append('has_phone', params.has_phone);
      }
      if (params.has_website !== undefined && params.has_website !== '') {
        queryParams.append('has_website', params.has_website);
      }

      const url = `${BASE_API_URL}/business-discovery/search?${queryParams.toString()}`;

      try {
        const response = await fetch(url, {
          method: 'GET',
          headers: this.getHeaders()
        });

        const json = await response.json();

        if (!response.ok || !json.success) {
          const err = new Error(json.message || `API error: ${response.statusText}`);
          err.status = response.status;
          err.quota = json.quota;
          throw err;
        }

        return {
          data: json.data || [],
          quota: json.quota
        };
      } catch (error) {
        console.error('Bizz-Hunter API Search Error:', error);
        throw error;
      }
    }

    // --- Location Autocomplete API ---
    static async getAutocompleteLocations(input) {
      if (!input || input.trim().length < 2) return [];
      try {
        const response = await fetch(`${BASE_API_URL}/locations/autocomplete?input=${encodeURIComponent(input.trim())}`, {
          headers: this.getHeaders()
        });
        const json = await response.json();
        if (json.success && Array.isArray(json.data)) {
          return json.data;
        }
      } catch (e) {
        console.warn('Error fetching location autocomplete predictions', e);
      }
      return [];
    }

    static async getLocationDetails(placeId) {
      if (!placeId) return null;
      try {
        const response = await fetch(`${BASE_API_URL}/locations/details?place_id=${encodeURIComponent(placeId)}`, {
          headers: this.getHeaders()
        });
        const json = await response.json();
        if (json.success && json.data) {
          return json.data;
        }
      } catch (e) {
        console.warn('Error fetching location details', e);
      }
      return null;
    }

    // --- Prospects Database Persistence API ---
    static async getProspects(statusFilter = '') {
      const url = statusFilter ? `${BASE_API_URL}/prospects?status=${encodeURIComponent(statusFilter)}` : `${BASE_API_URL}/prospects`;
      const response = await fetch(url, {
        method: 'GET',
        headers: this.getHeaders()
      });
      const json = await response.json();
      if (!response.ok || !json.success) {
        throw new Error(json.message || 'Failed to fetch prospects');
      }
      return json.data || [];
    }

    static async saveProspect(b) {
      const payload = {
        google_place_id: b.id || b.google_place_id,
        business_name: b.name || b.business_name,
        category: b.types ? (Array.isArray(b.types) ? b.types[0] : b.types) : b.category,
        address: b.address,
        latitude: b.latitude,
        longitude: b.longitude,
        rating: b.rating,
        review_count: b.review_count,
        phone_number: b.phone || b.phone_number,
        international_phone_number: b.national_phone || b.international_phone_number,
        website: b.website,
        google_maps_url: b.google_maps_url,
        status: b.status || 'NEW',
        notes: b.notes || '',
        follow_up_at: b.follow_up_at || null
      };

      const response = await fetch(`${BASE_API_URL}/prospects`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(payload)
      });

      const json = await response.json();
      if (!response.ok || !json.success) {
        throw new Error(json.message || 'Failed to save prospect');
      }
      return json.data;
    }

    static async updateProspect(id, updateData) {
      const response = await fetch(`${BASE_API_URL}/prospects/${id}`, {
        method: 'PATCH',
        headers: this.getHeaders(),
        body: JSON.stringify(updateData)
      });
      const json = await response.json();
      if (!response.ok || !json.success) {
        throw new Error(json.message || 'Failed to update prospect');
      }
      return json.data;
    }

    static async deleteProspect(id) {
      const response = await fetch(`${BASE_API_URL}/prospects/${id}`, {
        method: 'DELETE',
        headers: this.getHeaders()
      });
      const json = await response.json();
      if (!response.ok || !json.success) {
        throw new Error(json.message || 'Failed to delete prospect');
      }
      return json;
    }
  }

  window.BizzApi = ApiClient;

})(window);
