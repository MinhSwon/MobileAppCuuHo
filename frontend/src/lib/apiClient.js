import axios from 'axios';

const CONFIGURED_API_ORIGIN = (import.meta.env.VITE_API_BASE_URL || '').replace(/\/$/, '');
const nativeProtocols = new Set(['capacitor:', 'ionic:']);

function getApiBaseURL() {
  if (CONFIGURED_API_ORIGIN) {
    return CONFIGURED_API_ORIGIN;
  }

  if (import.meta.env.DEV) {
    return '';
  }

  if (nativeProtocols.has(window.location.protocol)) {
    console.error('Missing VITE_API_BASE_URL for native mobile build.');
  }

  return '';
}

axios.defaults.baseURL = getApiBaseURL();
axios.defaults.timeout = 15000;

const savedToken = localStorage.getItem('authToken');
if (savedToken) {
  axios.defaults.headers.common.Authorization = `Bearer ${savedToken}`;
}

axios.interceptors.response.use(
  response => response,
  async error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('authToken');
      localStorage.removeItem('currentUser');
      localStorage.removeItem('currentProfile');
      delete axios.defaults.headers.common.Authorization;
    }

    return Promise.reject(error);
  }
);

export const API_ORIGIN = CONFIGURED_API_ORIGIN;
