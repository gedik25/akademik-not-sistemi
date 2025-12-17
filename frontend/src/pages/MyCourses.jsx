/**
 * pages/MyCourses.jsx
 * Academic's courses page - shows only courses taught by the logged-in academic
 */

import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import courseService from '../services/courseService';

const MyCourses = () => {
    const { user } = useAuth();
    const [courses, setCourses] = useState([]);
    const [loading, setLoading] = useState(true);
    const [term, setTerm] = useState('2025-FALL');

    useEffect(() => {
        if (user?.UserID) {
            fetchCourses();
        }
    }, [term, user]);

    const fetchCourses = async () => {
        setLoading(true);
        try {
            // Akademisyenin kendi derslerini getir
            const result = await courseService.getAcademicCourses(user.UserID, term);
            if (result.success) {
                setCourses(result.courses);
            }
        } catch (err) {
            console.error('Courses error:', err);
            // Fallback: tüm katalog (eski davranış)
            try {
                const fallbackResult = await courseService.getCatalog(null, term);
                if (fallbackResult.success) {
                    setCourses(fallbackResult.courses);
                }
            } catch (fallbackErr) {
                console.error('Fallback error:', fallbackErr);
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-gray-800">Derslerim</h1>
                <select
                    value={term}
                    onChange={(e) => setTerm(e.target.value)}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                >
                    <option value="2025-FALL">2025 Güz</option>
                    <option value="2025-SPRING">2025 Bahar</option>
                </select>
            </div>

            {loading ? (
                <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
                </div>
            ) : courses.length === 0 ? (
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    Bu dönem için ders bulunamadı.
                </div>
            ) : (
                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {courses.map((course) => (
                        <div key={course.OfferingID} className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow">
                            <div className="flex justify-between items-start mb-4">
                                <span className="px-3 py-1 bg-purple-100 text-purple-800 text-sm rounded-full">
                                    {course.CourseCode}
                                </span>
                                <span className="text-gray-500 text-sm">Şube {course.Section}</span>
                            </div>
                            <h3 className="text-lg font-semibold text-gray-800 mb-2">{course.CourseName}</h3>
                            <div className="text-sm text-gray-600 space-y-1">
                                <p>Kredi: {course.Credit} | ECTS: {course.ECTS}</p>
                                <div className="flex items-center gap-4">
                                    <span className="flex items-center gap-1">
                                        <svg className="w-4 h-4 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                                        </svg>
                                        <span>{course.EnrolledCount || 0}/{course.Capacity}</span>
                                    </span>
                                    <span className="flex items-center gap-1">
                                        <svg className="w-4 h-4 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                                        </svg>
                                        <span>{course.SessionCount || 0} hafta</span>
                                    </span>
                                </div>
                            </div>
                            <div className="mt-4 pt-4 border-t border-gray-100 grid grid-cols-2 gap-2">
                                <Link
                                    to={`/students?offering=${course.OfferingID}`}
                                    className="text-center px-3 py-2 bg-indigo-100 text-indigo-700 text-sm rounded-lg hover:bg-indigo-200 transition-colors"
                                >
                                    Öğrenciler
                                </Link>
                                <Link
                                    to={`/gradebook?offering=${course.OfferingID}`}
                                    className="text-center px-3 py-2 bg-blue-100 text-blue-700 text-sm rounded-lg hover:bg-blue-200 transition-colors"
                                >
                                    Notlar
                                </Link>
                                <Link
                                    to={`/attendance?offering=${course.OfferingID}`}
                                    className="text-center px-3 py-2 bg-green-100 text-green-700 text-sm rounded-lg hover:bg-green-200 transition-colors"
                                >
                                    Yoklama
                                </Link>
                                <Link
                                    to={`/attendance?offering=${course.OfferingID}&mode=summary`}
                                    className="text-center px-3 py-2 bg-orange-100 text-orange-700 text-sm rounded-lg hover:bg-orange-200 transition-colors"
                                >
                                    Özet
                                </Link>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default MyCourses;
