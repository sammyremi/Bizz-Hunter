/* public/js/api.js - Bizz-Hunter Backend API Service Client */

(function (window) {
  'use strict';

  const BASE_API_URL = '/api/v1';

  class ApiClient {
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
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          }
        });

        const json = await response.json();

        if (!response.ok || !json.success) {
          throw new Error(json.message || `API error: ${response.statusText}`);
        }

        return json.data || [];
      } catch (error) {
        console.error('Bizz-Hunter API Search Error:', error);
        throw error;
      }
    }

    static async getAutocompleteLocations(input) {
      if (!input || input.trim().length < 2) return [];
      try {
        const response = await fetch(`${BASE_API_URL}/locations/autocomplete?input=${encodeURIComponent(input.trim())}`);
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
        const response = await fetch(`${BASE_API_URL}/locations/details?place_id=${encodeURIComponent(placeId)}`);
        const json = await response.json();
        if (json.success && json.data) {
          return json.data;
        }
      } catch (e) {
        console.warn('Error fetching location details', e);
      }
      return null;
    }
  }

  window.BizzApi = ApiClient;

})(window);
