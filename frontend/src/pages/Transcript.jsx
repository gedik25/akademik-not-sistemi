/**
 * pages/Transcript.jsx
 * Student transcript page
 */

import { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import gradingService from '../services/gradingService';

const Transcript = () => {
    const { user } = useAuth();
    const [transcript, setTranscript] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchTranscript();
    }, [user]);

    const fetchTranscript = async () => {
        if (!user?.UserID) return;
        setLoading(true);
        try {
            const result = await gradingService.getTranscript(user.UserID);
            if (result.success) {
                setTranscript(result.transcript);
            }
        } catch (err) {
            console.error('Transcript error:', err);
        } finally {
            setLoading(false);
        }
    };

    const getGradeColor = (grade) => {
        if (!grade) return 'text-gray-500';
        if (['AA', 'BA'].includes(grade)) return 'text-green-600';
        if (['BB', 'CB', 'CC'].includes(grade)) return 'text-blue-600';
        if (['DC', 'DD'].includes(grade)) return 'text-yellow-600';
        return 'text-red-600';
    };

    return (
        <div>
            <h1 className="text-2xl font-bold text-gray-800 mb-6">Transkript</h1>

            {loading ? (
                <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
                </div>
            ) : transcript.length === 0 ? (
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    Transkript verisi bulunamadı.
                </div>
            ) : (
                <div className="bg-white rounded-xl shadow-md overflow-hidden">
                    <table className="w-full">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Ders Kodu</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Ders Adı</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Dönem</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Kredi</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Ortalama</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Harf Notu</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Durum</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200">
                            {transcript.map((item, idx) => (
                                <tr key={idx} className="hover:bg-gray-50">
                                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{item.CourseCode}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{item.CourseName}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{item.Term}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{item.Credit}</td>
                                    <td className="px-6 py-4 text-sm text-gray-700">
                                        {item.CurrentAverage?.toFixed(2) || '-'}
                                    </td>
                                    <td className={`px-6 py-4 text-sm font-bold ${getGradeColor(item.LetterGrade)}`}>
                                        {item.LetterGrade || '-'}
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-2 py-1 text-xs rounded-full ${
                                            item.EnrollStatus === 'Active' 
                                                ? 'bg-green-100 text-green-800'
                                                : item.EnrollStatus === 'Completed'
                                                ? 'bg-blue-100 text-blue-800'
                                                : 'bg-gray-100 text-gray-800'
                                        }`}>
                                            {item.EnrollStatus}
                                        </span>
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

export default Transcript;

