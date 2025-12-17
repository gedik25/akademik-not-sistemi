/**
 * services/reportingService.js
 * Dashboard, notifications, and audit log API calls
 */

import api from './api';

export const reportingService = {
    getDashboardStats: async (userId) => {
        const response = await api.get(`/reporting/dashboard/${userId}`);
        return response.data;
    },

    getNotifications: async (userId) => {
        const response = await api.get(`/reporting/notifications/${userId}`);
        return response.data;
    },

    markNotificationRead: async (notificationId) => {
        const response = await api.put(`/reporting/notifications/${notificationId}/read`);
        return response.data;
    },

    searchAuditLog: async (filters = {}) => {
        const params = new URLSearchParams();
        if (filters.dateFrom) params.append('dateFrom', filters.dateFrom);
        if (filters.dateTo) params.append('dateTo', filters.dateTo);
        if (filters.actionType) params.append('actionType', filters.actionType);
        if (filters.tableName) params.append('tableName', filters.tableName);
        const response = await api.get(`/reporting/audit?${params}`);
        return response.data;
    }
};

export default reportingService;

