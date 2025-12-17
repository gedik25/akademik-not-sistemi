/**
 * pages/StudentList.jsx
 * Shows enrolled students for a course offering with attendance % and average
 */

import { useEffect, useState } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import courseService from '../services/courseService';

const StudentList = () => {
    const [searchParams] = useSearchParams();
    const offeringId = searchParams.get('offering');
    const [students, setStudents] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (offeringId) {
            fetchStudents();
        } else {
            setLoading(false);
        }
    }, [offeringId]);

    const fetchStudents = async () => {
        setLoading(true);
        try {
            const result = await courseService.getEnrolledStudents(offeringId);
            if (result.success) {
                setStudents(result.students);
            }
        } catch (err) {
            console.error('Students error:', err);
        } finally {
            setLoading(false);
        }
    };

    const getStatusBadge = (status) => {
        const statusStyles = {
            'Active': 'bg-green-100 text-green-800',
            'AtRisk': 'bg-yellow-100 text-yellow-800',
            'Completed': 'bg-blue-100 text-blue-800',
            'Dropped': 'bg-gray-100 text-gray-800',
            'AutoFailDueToAttendance': 'bg-red-100 text-red-800'
        };
        const statusLabels = {
            'Active': 'Aktif',
            'AtRisk': 'Risk',
            'Completed': 'Tamamlandı',
            'Dropped': 'Bıraktı',
            'AutoFailDueToAttendance': 'Devamsızlık'
        };
        return (
            <span className={`px-2 py-1 text-xs rounded-full ${statusStyles[status] || 'bg-gray-100 text-gray-800'}`}>
                {statusLabels[status] || status}
            </span>
        );
    };

    const getAttendanceColor = (percent) => {
        if (percent === null || percent === undefined) return 'text-gray-400';
        if (percent >= 80) return 'text-green-600';
        if (percent >= 60) return 'text-yellow-600';
        return 'text-red-600';
    };

    const getGradeColor = (average) => {
        if (average === null || average === undefined) return 'text-gray-400';
        if (average >= 70) return 'text-green-600';
        if (average >= 50) return 'text-yellow-600';
        return 'text-red-600';
    };

    if (!offeringId) {
        return (
            <div>
                <h1 className="text-2xl font-bold text-gray-800 mb-6">Öğrenci Listesi</h1>
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    Lütfen "Derslerim" sayfasından bir ders seçin.
                </div>
            </div>
        );
    }

    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-gray-800">Öğrenci Listesi</h1>
                <Link
                    to="/my-courses"
                    className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                >
                    ← Derslerime Dön
                </Link>
            </div>

            {loading ? (
                <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
                </div>
            ) : students.length === 0 ? (
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    Bu derse kayıtlı öğrenci bulunamadı.
                </div>
            ) : (
                <>
                    {/* Summary Stats */}
                    <div className="grid grid-cols-4 gap-4 mb-6">
                        <div className="bg-white rounded-xl shadow-md p-4 text-center">
                            <div className="text-3xl font-bold text-purple-600">{students.length}</div>
                            <div className="text-sm text-gray-500">Toplam Öğrenci</div>
                        </div>
                        <div className="bg-white rounded-xl shadow-md p-4 text-center">
                            <div className="text-3xl font-bold text-green-600">
                                {students.filter(s => s.EnrollStatus === 'Active').length}
                            </div>
                            <div className="text-sm text-gray-500">Aktif</div>
                        </div>
                        <div className="bg-white rounded-xl shadow-md p-4 text-center">
                            <div className="text-3xl font-bold text-yellow-600">
                                {students.filter(s => s.EnrollStatus === 'AtRisk').length}
                            </div>
                            <div className="text-sm text-gray-500">Riskli</div>
                        </div>
                        <div className="bg-white rounded-xl shadow-md p-4 text-center">
                            <div className="text-3xl font-bold text-blue-600">
                                {students.filter(s => s.CurrentAverage !== null).length > 0
                                    ? (students.reduce((acc, s) => acc + (s.CurrentAverage || 0), 0) / students.filter(s => s.CurrentAverage !== null).length).toFixed(1)
                                    : '-'}
                            </div>
                            <div className="text-sm text-gray-500">Sınıf Ort.</div>
                        </div>
                    </div>

                    {/* Student Table */}
                    <div className="bg-white rounded-xl shadow-md overflow-hidden">
                        <table className="w-full">
                            <thead className="bg-gray-50">
                                <tr>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Öğrenci No</th>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Ad Soyad</th>
                                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Devam %</th>
                                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Ortalama</th>
                                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Harf Notu</th>
                                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Durum</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200">
                                {students.map((student) => (
                                    <tr key={student.EnrollmentID} className="hover:bg-gray-50">
                                        <td className="px-6 py-4 text-sm font-medium text-gray-900">
                                            {student.StudentNumber}
                                        </td>
                                        <td className="px-6 py-4 text-sm text-gray-700">
                                            {student.FullName || `${student.FirstName} ${student.LastName}`}
                                        </td>
                                        <td className="px-6 py-4 text-center">
                                            <div className="flex items-center justify-center gap-2">
                                                <div className="w-16 bg-gray-200 rounded-full h-2">
                                                    <div 
                                                        className={`h-2 rounded-full ${
                                                            (student.AttendancePercent || 0) >= 80 ? 'bg-green-500' : 
                                                            (student.AttendancePercent || 0) >= 60 ? 'bg-yellow-500' : 'bg-red-500'
                                                        }`}
                                                        style={{ width: `${Math.min(student.AttendancePercent || 0, 100)}%` }}
                                                    ></div>
                                                </div>
                                                <span className={`text-sm font-medium ${getAttendanceColor(student.AttendancePercent)}`}>
                                                    {student.AttendancePercent !== null ? `%${student.AttendancePercent.toFixed(0)}` : '-'}
                                                </span>
                                            </div>
                                        </td>
                                        <td className={`px-6 py-4 text-center text-sm font-medium ${getGradeColor(student.CurrentAverage)}`}>
                                            {student.CurrentAverage !== null ? student.CurrentAverage.toFixed(2) : '-'}
                                        </td>
                                        <td className="px-6 py-4 text-center">
                                            <span className="text-sm font-bold text-gray-800">
                                                {student.LetterGrade || '-'}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-center">
                                            {getStatusBadge(student.EnrollStatus)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                </>
            )}
        </div>
    );
};

export default StudentList;

