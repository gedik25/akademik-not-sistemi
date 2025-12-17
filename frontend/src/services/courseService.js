/**
 * services/courseService.js
 * Course, offering, and enrollment API calls
 */

import api from './api';

export const courseService = {
    getCatalog: async (programId = null, term = null, studentId = null) => {
        const params = new URLSearchParams();
        if (programId) params.append('programId', programId);
        if (term) params.append('term', term);
        if (studentId) params.append('studentId', studentId);
        const response = await api.get(`/course/catalog?${params}`);
        return response.data;
    },

    createCourse: async (courseData) => {
        const response = await api.post('/course', courseData);
        return response.data;
    },

    updateCourse: async (courseId, courseData) => {
        const response = await api.put(`/course/${courseId}`, courseData);
        return response.data;
    },

    deleteCourse: async (courseId) => {
        const response = await api.delete(`/course/${courseId}`);
        return response.data;
    },

    openOffering: async (offeringData) => {
        const response = await api.post('/course/offering', offeringData);
        return response.data;
    },

    enrollStudent: async (offeringId, studentId) => {
        const response = await api.post('/course/enroll', { offeringId, studentId });
        return response.data;
    },

    dropEnrollment: async (enrollmentId, reason = null) => {
        const response = await api.post('/course/drop', { enrollmentId, reason });
        return response.data;
    },

    getStudentSchedule: async (studentId, term) => {
        const response = await api.get(`/course/schedule/${studentId}?term=${term}`);
        return response.data;
    },

    getAcademicCourses: async (academicId, term = null) => {
        const params = term ? `?term=${term}` : '';
        const response = await api.get(`/course/academic-courses/${academicId}${params}`);
        return response.data;
    },

    getEnrolledStudents: async (offeringId) => {
        const response = await api.get(`/course/enrolled-students/${offeringId}`);
        return response.data;
    },

    generateSessions: async (sessionData) => {
        const response = await api.post('/course/generate-sessions', sessionData);
        return response.data;
    }
};

export default courseService;

