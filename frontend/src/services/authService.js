/**
 * services/authService.js
 * Authentication API calls
 */

import api from './api';

export const authService = {
    login: async (username, password) => {
        const response = await api.post('/auth/login', { username, password });
        return response.data;
    },

    register: async (userData) => {
        const response = await api.post('/auth/register', userData);
        return response.data;
    },

    updateContact: async (userId, email, phone) => {
        const response = await api.put('/auth/contact', { userId, email, phone });
        return response.data;
    },

    deactivate: async (userId, reason) => {
        const response = await api.post('/auth/deactivate', { userId, reason });
        return response.data;
    }
};

export default authService;

