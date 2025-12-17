/**
 * services/api.js
 * Axios instance with base URL and interceptors
 */

import axios from 'axios';

const api = axios.create({
    baseURL: '/api',
    headers: {
        'Content-Type': 'application/json'
    }
});

// Response interceptor for error handling
api.interceptors.response.use(
    response => response,
    error => {
        const message = error.response?.data?.message || 'Bir hata oluştu';
        console.error('API Error:', message);
        return Promise.reject(error);
    }
);

export default api;

