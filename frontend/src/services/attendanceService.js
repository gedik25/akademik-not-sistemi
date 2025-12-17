/**
 * services/attendanceService.js
 * Attendance API calls
 */

import api from './api';

export const attendanceService = {
    definePolicy: async (offeringId, maxAbsencePercent, warningThresholdPercent, autoFailPercent) => {
        const response = await api.post('/attendance/policy', {
            offeringId, maxAbsencePercent, warningThresholdPercent, autoFailPercent
        });
        return response.data;
    },

    recordAttendance: async (sessionId, studentId, status, recordedBy) => {
        const response = await api.post('/attendance/record', {
            sessionId, studentId, status, recordedBy
        });
        return response.data;
    },

    getSummary: async (offeringId) => {
        const response = await api.get(`/attendance/summary/${offeringId}`);
        return response.data;
    },

    getStudentDetail: async (studentId, offeringId) => {
        const response = await api.get(`/attendance/detail/${studentId}/${offeringId}`);
        return response.data;
    },

    getSessions: async (offeringId) => {
        const response = await api.get(`/attendance/sessions/${offeringId}`);
        return response.data;
    },

    getSessionAttendance: async (sessionId) => {
        const response = await api.get(`/attendance/session/${sessionId}`);
        return response.data;
    },

    bulkRecord: async (sessionId, attendanceData, recordedBy) => {
        const response = await api.post('/attendance/bulk-record', {
            sessionId, attendanceData, recordedBy
        });
        return response.data;
    }
};

export default attendanceService;

