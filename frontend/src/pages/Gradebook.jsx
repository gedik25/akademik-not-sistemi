/**
 * pages/Gradebook.jsx
 * Grade entry page for academics - with component-based grade input
 */

import { useEffect, useState } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import gradingService from '../services/gradingService';

const Gradebook = () => {
    const { user } = useAuth();
    const [searchParams] = useSearchParams();
    const offeringId = searchParams.get('offering');

    const [components, setComponents] = useState([]);
    const [students, setStudents] = useState([]);
    const [grades, setGrades] = useState({});
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState(null);

    // New component form
    const [showNewComponent, setShowNewComponent] = useState(false);
    const [newComponentName, setNewComponentName] = useState('');
    const [newComponentWeight, setNewComponentWeight] = useState('');

    useEffect(() => {
        if (offeringId) {
            fetchData();
        } else {
            setLoading(false);
        }
    }, [offeringId]);

    const fetchData = async () => {
        setLoading(true);
        try {
            // Paralel olarak bileşenleri ve notları getir
            const [componentsResult, gradesResult] = await Promise.all([
                gradingService.getComponents(offeringId),
                gradingService.getStudentGrades(offeringId)
            ]);

            if (componentsResult.success) {
                setComponents(componentsResult.components);
            }

            if (gradesResult.success) {
                // Öğrencileri ve notları düzenle
                const studentMap = {};
                const gradeMap = {};

                gradesResult.grades.forEach(row => {
                    if (!studentMap[row.StudentID]) {
                        studentMap[row.StudentID] = {
                            EnrollmentID: row.EnrollmentID,
                            StudentID: row.StudentID,
                            StudentNumber: row.StudentNumber,
                            FullName: row.FullName,
                            CurrentAverage: row.CurrentAverage,
                            LetterGrade: row.LetterGrade
                        };
                    }
                    
                    const key = `${row.EnrollmentID}-${row.ComponentID}`;
                    gradeMap[key] = row.Score !== null ? row.Score.toString() : '';
                });

                setStudents(Object.values(studentMap));
                setGrades(gradeMap);
            }
        } catch (err) {
            console.error('Gradebook error:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleGradeChange = (enrollmentId, componentId, value) => {
        const key = `${enrollmentId}-${componentId}`;
        // Sadece sayısal değerler (0-100)
        if (value === '' || (/^\d*\.?\d*$/.test(value) && parseFloat(value) <= 100)) {
            setGrades(prev => ({ ...prev, [key]: value }));
        }
    };

    const handleSaveGrade = async (enrollmentId, componentId) => {
        const key = `${enrollmentId}-${componentId}`;
        const score = parseFloat(grades[key]);

        if (isNaN(score) || score < 0 || score > 100) {
            setMessage({ type: 'error', text: 'Not 0-100 arasında olmalıdır.' });
            return;
        }

        setSaving(true);
        try {
            const result = await gradingService.recordGrade(enrollmentId, componentId, score, user.UserID);
            if (result.success) {
                setMessage({ type: 'success', text: 'Not kaydedildi.' });
                // Verileri yenile (ortalama güncellenmiş olabilir)
                fetchData();
            }
        } catch (err) {
            setMessage({ type: 'error', text: 'Kayıt sırasında hata: ' + err.message });
        } finally {
            setSaving(false);
            setTimeout(() => setMessage(null), 3000);
        }
    };

    const handleAddComponent = async () => {
        if (!newComponentName || !newComponentWeight) return;

        setSaving(true);
        try {
            const result = await gradingService.defineComponent(
                parseInt(offeringId),
                newComponentName,
                parseFloat(newComponentWeight)
            );
            if (result.success) {
                setMessage({ type: 'success', text: 'Bileşen eklendi.' });
                setShowNewComponent(false);
                setNewComponentName('');
                setNewComponentWeight('');
                fetchData();
            }
        } catch (err) {
            setMessage({ type: 'error', text: 'Bileşen eklenemedi: ' + err.message });
        } finally {
            setSaving(false);
        }
    };

    const getTotalWeight = () => {
        return components.reduce((sum, c) => sum + (c.WeightPercent || 0), 0);
    };

    if (!offeringId) {
        return (
            <div>
                <h1 className="text-2xl font-bold text-gray-800 mb-6">Not Girişi</h1>
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    Lütfen "Derslerim" sayfasından bir ders seçin.
                </div>
            </div>
        );
    }

    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-gray-800">Not Girişi</h1>
                <Link
                    to="/my-courses"
                    className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                >
                    ← Derslerime Dön
                </Link>
            </div>

            {/* Message */}
            {message && (
                <div className={`p-4 rounded-lg mb-4 ${
                    message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                }`}>
                    {message.text}
                </div>
            )}

            {loading ? (
                <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
                </div>
            ) : (
                <>
                    {/* Component Summary */}
                    <div className="bg-white rounded-xl shadow-md p-4 mb-6">
                        <div className="flex justify-between items-center mb-4">
                            <h2 className="text-lg font-semibold text-gray-800">Not Bileşenleri</h2>
                            <button
                                onClick={() => setShowNewComponent(!showNewComponent)}
                                className="px-4 py-2 bg-purple-600 text-white text-sm rounded-lg hover:bg-purple-700 transition-colors"
                            >
                                + Bileşen Ekle
                            </button>
                        </div>

                        {/* New Component Form */}
                        {showNewComponent && (
                            <div className="bg-gray-50 p-4 rounded-lg mb-4">
                                <div className="flex gap-4 items-end">
                                    <div className="flex-1">
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Bileşen Adı</label>
                                        <input
                                            type="text"
                                            value={newComponentName}
                                            onChange={(e) => setNewComponentName(e.target.value)}
                                            placeholder="Örn: Vize, Final, Ödev"
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                                        />
                                    </div>
                                    <div className="w-32">
                                        <label className="block text-sm font-medium text-gray-700 mb-1">Ağırlık (%)</label>
                                        <input
                                            type="number"
                                            value={newComponentWeight}
                                            onChange={(e) => setNewComponentWeight(e.target.value)}
                                            placeholder="30"
                                            min="0"
                                            max={100 - getTotalWeight()}
                                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                                        />
                                    </div>
                                    <button
                                        onClick={handleAddComponent}
                                        disabled={saving || !newComponentName || !newComponentWeight}
                                        className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:bg-gray-400"
                                    >
                                        Ekle
                                    </button>
                                    <button
                                        onClick={() => setShowNewComponent(false)}
                                        className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400 transition-colors"
                                    >
                                        İptal
                                    </button>
                                </div>
                            </div>
                        )}

                        {/* Component List */}
                        <div className="flex flex-wrap gap-3">
                            {components.map((comp) => (
                                <div
                                    key={comp.ComponentID}
                                    className="px-4 py-2 bg-gray-100 rounded-lg"
                                >
                                    <span className="font-medium text-gray-800">{comp.ComponentName}</span>
                                    <span className="text-gray-500 ml-2">%{comp.WeightPercent}</span>
                                    <span className="text-gray-400 ml-2 text-sm">({comp.GradesEntered} not)</span>
                                </div>
                            ))}
                            <div className={`px-4 py-2 rounded-lg ${getTotalWeight() === 100 ? 'bg-green-100' : 'bg-yellow-100'}`}>
                                <span className="font-medium">Toplam: %{getTotalWeight()}</span>
                                {getTotalWeight() !== 100 && (
                                    <span className="text-yellow-700 ml-2 text-sm">(100 olmalı)</span>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Grade Entry Table */}
                    {components.length === 0 ? (
                        <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                            Henüz not bileşeni tanımlanmamış. Yukarıdan bileşen ekleyin.
                        </div>
                    ) : students.length === 0 ? (
                        <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                            Bu derse kayıtlı öğrenci bulunamadı.
                        </div>
                    ) : (
                        <div className="bg-white rounded-xl shadow-md overflow-x-auto">
                            <table className="w-full">
                                <thead className="bg-gray-50">
                                    <tr>
                                        <th className="px-4 py-4 text-left text-sm font-semibold text-gray-600 sticky left-0 bg-gray-50">Öğrenci No</th>
                                        <th className="px-4 py-4 text-left text-sm font-semibold text-gray-600">Ad Soyad</th>
                                        {components.map((comp) => (
                                            <th key={comp.ComponentID} className="px-4 py-4 text-center text-sm font-semibold text-gray-600">
                                                {comp.ComponentName}
                                                <div className="text-xs font-normal text-gray-400">%{comp.WeightPercent}</div>
                                            </th>
                                        ))}
                                        <th className="px-4 py-4 text-center text-sm font-semibold text-gray-600">Ortalama</th>
                                        <th className="px-4 py-4 text-center text-sm font-semibold text-gray-600">Harf</th>
                                    </tr>
                                </thead>
                                <tbody className="divide-y divide-gray-200">
                                    {students.map((student) => (
                                        <tr key={student.EnrollmentID} className="hover:bg-gray-50">
                                            <td className="px-4 py-3 text-sm font-medium text-gray-900 sticky left-0 bg-white">
                                                {student.StudentNumber}
                                            </td>
                                            <td className="px-4 py-3 text-sm text-gray-700">
                                                {student.FullName}
                                            </td>
                                            {components.map((comp) => {
                                                const key = `${student.EnrollmentID}-${comp.ComponentID}`;
                                                return (
                                                    <td key={comp.ComponentID} className="px-4 py-3 text-center">
                                                        <div className="flex items-center justify-center gap-1">
                                                            <input
                                                                type="text"
                                                                value={grades[key] || ''}
                                                                onChange={(e) => handleGradeChange(student.EnrollmentID, comp.ComponentID, e.target.value)}
                                                                onBlur={() => {
                                                                    if (grades[key] && grades[key] !== '') {
                                                                        handleSaveGrade(student.EnrollmentID, comp.ComponentID);
                                                                    }
                                                                }}
                                                                className="w-16 px-2 py-1 text-center border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-purple-500"
                                                                placeholder="-"
                                                            />
                                                        </div>
                                                    </td>
                                                );
                                            })}
                                            <td className="px-4 py-3 text-center">
                                                <span className={`font-medium ${
                                                    student.CurrentAverage === null ? 'text-gray-400' :
                                                    student.CurrentAverage >= 70 ? 'text-green-600' :
                                                    student.CurrentAverage >= 50 ? 'text-yellow-600' : 'text-red-600'
                                                }`}>
                                                    {student.CurrentAverage !== null ? student.CurrentAverage.toFixed(2) : '-'}
                                                </span>
                                            </td>
                                            <td className="px-4 py-3 text-center">
                                                <span className="font-bold text-gray-800">
                                                    {student.LetterGrade || '-'}
                                                </span>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </>
            )}
        </div>
    );
};

export default Gradebook;
