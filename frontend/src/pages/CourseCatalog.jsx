/**
 * pages/CourseCatalog.jsx
 * Course catalog page for students
 */

import { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import courseService from '../services/courseService';

const CourseCatalog = () => {
    const { user } = useAuth();
    const [courses, setCourses] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [term, setTerm] = useState('2025-FALL');
    const [enrolling, setEnrolling] = useState(null);

    useEffect(() => {
        fetchCourses();
    }, [term]);

    const fetchCourses = async () => {
        setLoading(true);
        try {
            const result = await courseService.getCatalog(null, term);
            if (result.success) {
                setCourses(result.courses);
            }
        } catch (err) {
            setError('Ders kataloğu yüklenirken hata oluştu');
        } finally {
            setLoading(false);
        }
    };

    const handleEnroll = async (offeringId) => {
        setEnrolling(offeringId);
        try {
            const result = await courseService.enrollStudent(offeringId, user.UserID);
            if (result.success) {
                alert('Derse kayıt başarılı!');
                fetchCourses();
            }
        } catch (err) {
            alert(err.response?.data?.message || 'Kayıt sırasında hata oluştu');
        } finally {
            setEnrolling(null);
        }
    };

    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-gray-800">Ders Kataloğu</h1>
                <select
                    value={term}
                    onChange={(e) => setTerm(e.target.value)}
                    className="px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                >
                    <option value="2025-FALL">2025 Güz</option>
                    <option value="2025-SPRING">2025 Bahar</option>
                    <option value="2024-FALL">2024 Güz</option>
                </select>
            </div>

            {error && (
                <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded-lg mb-4">
                    {error}
                </div>
            )}

            {loading ? (
                <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
                </div>
            ) : courses.length === 0 ? (
                <div className="text-center py-12 text-gray-500">
                    Bu dönem için ders bulunamadı.
                </div>
            ) : (
                <div className="bg-white rounded-xl shadow-md overflow-hidden">
                    <table className="w-full">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Ders Kodu</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Ders Adı</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Kredi</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">ECTS</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Şube</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Öğretim Üyesi</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Kapasite</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">İşlem</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200">
                            {courses.map((course) => (
                                <tr key={course.OfferingID} className="hover:bg-gray-50">
                                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{course.CourseCode}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{course.CourseName}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{course.Credit}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{course.ECTS}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{course.Section}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{course.AcademicName}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{course.Capacity}</td>
                                    <td className="px-6 py-4">
                                        <button
                                            onClick={() => handleEnroll(course.OfferingID)}
                                            disabled={enrolling === course.OfferingID}
                                            className="px-4 py-2 bg-purple-600 text-white text-sm rounded-lg hover:bg-purple-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                        >
                                            {enrolling === course.OfferingID ? 'Kayıt...' : 'Kayıt Ol'}
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}
        </div>
    );
};

export default CourseCatalog;

