/**
 * services/gradingService.js
 * Grading API calls
 */

import api from './api';

export const gradingService = {
    defineComponent: async (offeringId, componentName, weightPercent, isMandatory = true) => {
        const response = await api.post('/grading/component', {
            offeringId, componentName, weightPercent, isMandatory
        });
        return response.data;
    },

    recordGrade: async (enrollmentId, componentId, score, gradedBy) => {
        const response = await api.post('/grading/record', {
            enrollmentId, componentId, score, gradedBy
        });
        return response.data;
    },

    getGradebook: async (offeringId) => {
        const response = await api.get(`/grading/gradebook/${offeringId}`);
        return response.data;
    },

    getTranscript: async (studentId) => {
        const response = await api.get(`/grading/transcript/${studentId}`);
        return response.data;
    },

    approveFinalGrades: async (offeringId, academicId) => {
        const response = await api.post('/grading/approve', { offeringId, academicId });
        return response.data;
    },

    getComponents: async (offeringId) => {
        const response = await api.get(`/grading/components/${offeringId}`);
        return response.data;
    },

    getStudentGrades: async (offeringId) => {
        const response = await api.get(`/grading/student-grades/${offeringId}`);
        return response.data;
    }
};

export default gradingService;

