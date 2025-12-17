/**
 * pages/Attendance.jsx
 * Attendance recording page for academics - with weekly session selection
 */

import { useEffect, useState } from 'react';
import { useSearchParams, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import attendanceService from '../services/attendanceService';

const ATTENDANCE_STATUSES = [
    { value: 'Present', label: 'Geldi', color: 'bg-green-500', icon: '✓' },
    { value: 'Absent', label: 'Gelmedi', color: 'bg-red-500', icon: '✗' },
    { value: 'Late', label: 'Geç', color: 'bg-yellow-500', icon: '⏰' },
    { value: 'Excused', label: 'Mazeret', color: 'bg-blue-500', icon: '📋' }
];

const Attendance = () => {
    const { user } = useAuth();
    const [searchParams] = useSearchParams();
    const offeringId = searchParams.get('offering');
    const mode = searchParams.get('mode'); // 'summary' veya null

    const [sessions, setSessions] = useState([]);
    const [selectedSession, setSelectedSession] = useState(null);
    const [students, setStudents] = useState([]);
    const [summary, setSummary] = useState([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState(null);

    useEffect(() => {
        if (offeringId) {
            if (mode === 'summary') {
                fetchSummary();
            } else {
                fetchSessions();
            }
        } else {
            setLoading(false);
        }
    }, [offeringId, mode]);

    const fetchSessions = async () => {
        setLoading(true);
        try {
            const result = await attendanceService.getSessions(offeringId);
            if (result.success) {
                setSessions(result.sessions);
                // İlk yoklama alınmamış oturumu seç
                const firstUnrecorded = result.sessions.find(s => !s.AttendanceRecorded);
                if (firstUnrecorded) {
                    setSelectedSession(firstUnrecorded);
                    fetchSessionAttendance(firstUnrecorded.SessionID);
                } else if (result.sessions.length > 0) {
                    setSelectedSession(result.sessions[0]);
                    fetchSessionAttendance(result.sessions[0].SessionID);
                }
            }
        } catch (err) {
            console.error('Sessions error:', err);
        } finally {
            setLoading(false);
        }
    };

    const fetchSessionAttendance = async (sessionId) => {
        try {
            const result = await attendanceService.getSessionAttendance(sessionId);
            if (result.success) {
                // Varsayılan olarak tüm öğrencileri "Present" yap (kayıt yoksa)
                setStudents(result.students.map(s => ({
                    ...s,
                    Status: s.Status || 'Present'
                })));
            }
        } catch (err) {
            console.error('Session attendance error:', err);
        }
    };

    const fetchSummary = async () => {
        setLoading(true);
        try {
            const result = await attendanceService.getSummary(offeringId);
            if (result.success) {
                setSummary(result.summary);
            }
        } catch (err) {
            console.error('Summary error:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleSessionChange = (session) => {
        setSelectedSession(session);
        fetchSessionAttendance(session.SessionID);
    };

    const handleStatusChange = (studentId, status) => {
        setStudents(prev => prev.map(s => 
            s.StudentID === studentId ? { ...s, Status: status } : s
        ));
    };

    const handleSave = async () => {
        if (!selectedSession || !user) return;
        
        setSaving(true);
        setMessage(null);
        try {
            const attendanceData = students.map(s => ({
                studentId: s.StudentID,
                status: s.Status,
                remarks: null
            }));

            const result = await attendanceService.bulkRecord(
                selectedSession.SessionID,
                attendanceData,
                user.UserID
            );

            if (result.success) {
                setMessage({ type: 'success', text: `${result.recordedCount} öğrenci için yoklama kaydedildi.` });
                // Oturumları yenile
                fetchSessions();
            }
        } catch (err) {
            setMessage({ type: 'error', text: 'Kayıt sırasında hata oluştu: ' + err.message });
        } finally {
            setSaving(false);
        }
    };

    const setAllStatus = (status) => {
        setStudents(prev => prev.map(s => ({ ...s, Status: status })));
    };

    if (!offeringId) {
        return (
            <div>
                <h1 className="text-2xl font-bold text-gray-800 mb-6">Yoklama</h1>
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    Lütfen "Derslerim" sayfasından bir ders seçin.
                </div>
            </div>
        );
    }

    // Summary Mode
    if (mode === 'summary') {
        return (
            <div>
                <div className="flex justify-between items-center mb-6">
                    <h1 className="text-2xl font-bold text-gray-800">Yoklama Özeti</h1>
                    <Link
                        to={`/attendance?offering=${offeringId}`}
                        className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                    >
                        Yoklama Al
                    </Link>
                </div>

                {loading ? (
                    <div className="text-center py-12">
                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
                    </div>
                ) : summary.length === 0 ? (
                    <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                        Bu ders için yoklama kaydı bulunamadı.
                    </div>
                ) : (
                    <div className="bg-white rounded-xl shadow-md overflow-hidden">
                        <table className="w-full">
                            <thead className="bg-gray-50">
                                <tr>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Öğrenci No</th>
                                    <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Ad Soyad</th>
                                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Toplam</th>
                                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Geldi</th>
                                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Gelmedi</th>
                                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Geç</th>
                                    <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Devam %</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-200">
                                {summary.map((student, idx) => {
                                    const total = student.TotalSessions || 0;
                                    const present = student.Presents || 0;
                                    const absent = student.Absents || 0;
                                    const late = student.Lates || 0;
                                    const rate = total > 0 ? ((present + late * 0.5) / total * 100) : 0;
                                    
                                    return (
                                        <tr key={idx} className="hover:bg-gray-50">
                                            <td className="px-6 py-4 text-sm font-medium text-gray-900">{student.StudentNumber}</td>
                                            <td className="px-6 py-4 text-sm text-gray-700">{student.FirstName} {student.LastName}</td>
                                            <td className="px-6 py-4 text-center text-sm text-gray-600">{total}</td>
                                            <td className="px-6 py-4 text-center text-sm text-green-600 font-medium">{present}</td>
                                            <td className="px-6 py-4 text-center text-sm text-red-600 font-medium">{absent}</td>
                                            <td className="px-6 py-4 text-center text-sm text-yellow-600 font-medium">{late}</td>
                                            <td className="px-6 py-4 text-center">
                                                <div className="flex items-center justify-center gap-2">
                                                    <div className="w-16 bg-gray-200 rounded-full h-2">
                                                        <div 
                                                            className={`h-2 rounded-full ${
                                                                rate >= 70 ? 'bg-green-500' : 
                                                                rate >= 50 ? 'bg-yellow-500' : 'bg-red-500'
                                                            }`}
                                                            style={{ width: `${Math.min(rate, 100)}%` }}
                                                        ></div>
                                                    </div>
                                                    <span className="text-sm font-medium text-gray-700">
                                                        %{rate.toFixed(0)}
                                                    </span>
                                                </div>
                                            </td>
                                        </tr>
                                    );
                                })}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        );
    }

    // Entry Mode
    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-gray-800">Yoklama Al</h1>
                <div className="flex gap-2">
                    <Link
                        to={`/attendance?offering=${offeringId}&mode=summary`}
                        className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                    >
                        Özete Git
                    </Link>
                    <Link
                        to="/my-courses"
                        className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                    >
                        ← Derslerime Dön
                    </Link>
                </div>
            </div>

            {loading ? (
                <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
                </div>
            ) : sessions.length === 0 ? (
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    <p className="mb-4">Bu ders için oturum bulunamadı.</p>
                    <p className="text-sm">Lütfen önce ders oturumlarını oluşturun.</p>
                </div>
            ) : (
                <div className="grid grid-cols-4 gap-6">
                    {/* Session List */}
                    <div className="col-span-1 bg-white rounded-xl shadow-md p-4 h-fit">
                        <h2 className="text-lg font-semibold text-gray-800 mb-4">Haftalar</h2>
                        <div className="space-y-2 max-h-96 overflow-y-auto">
                            {sessions.map((session) => (
                                <button
                                    key={session.SessionID}
                                    onClick={() => handleSessionChange(session)}
                                    className={`w-full text-left px-3 py-2 rounded-lg transition-colors ${
                                        selectedSession?.SessionID === session.SessionID
                                            ? 'bg-purple-100 text-purple-800 border-2 border-purple-500'
                                            : 'bg-gray-50 text-gray-700 hover:bg-gray-100'
                                    }`}
                                >
                                    <div className="flex justify-between items-center">
                                        <span className="font-medium">Hafta {session.WeekNumber}</span>
                                        {session.AttendanceRecorded ? (
                                            <span className="text-xs bg-green-100 text-green-800 px-2 py-1 rounded-full">✓</span>
                                        ) : (
                                            <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-full">—</span>
                                        )}
                                    </div>
                                    <div className="text-xs text-gray-500 mt-1">
                                        {new Date(session.SessionDate).toLocaleDateString('tr-TR')}
                                    </div>
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Attendance Entry */}
                    <div className="col-span-3">
                        {selectedSession && (
                            <>
                                {/* Session Info */}
                                <div className="bg-white rounded-xl shadow-md p-4 mb-4">
                                    <div className="flex justify-between items-center">
                                        <div>
                                            <h3 className="font-semibold text-gray-800">
                                                Hafta {selectedSession.WeekNumber} - {new Date(selectedSession.SessionDate).toLocaleDateString('tr-TR', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
                                            </h3>
                                            <p className="text-sm text-gray-500">
                                                {selectedSession.StartTime?.substring(0, 5)} - {selectedSession.EndTime?.substring(0, 5)} | {selectedSession.Location || 'Derslik belirtilmedi'}
                                            </p>
                                        </div>
                                        <div className="flex gap-2">
                                            {ATTENDANCE_STATUSES.map((status) => (
                                                <button
                                                    key={status.value}
                                                    onClick={() => setAllStatus(status.value)}
                                                    className={`px-3 py-1 text-xs text-white rounded ${status.color} hover:opacity-80 transition-opacity`}
                                                    title={`Tümünü ${status.label} yap`}
                                                >
                                                    Tümü {status.label}
                                                </button>
                                            ))}
                                        </div>
                                    </div>
                                </div>

                                {/* Message */}
                                {message && (
                                    <div className={`p-4 rounded-lg mb-4 ${
                                        message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                                    }`}>
                                        {message.text}
                                    </div>
                                )}

                                {/* Student List */}
                                <div className="bg-white rounded-xl shadow-md overflow-hidden">
                                    <table className="w-full">
                                        <thead className="bg-gray-50">
                                            <tr>
                                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Öğrenci No</th>
                                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Ad Soyad</th>
                                                <th className="px-6 py-4 text-center text-sm font-semibold text-gray-600">Durum</th>
                                            </tr>
                                        </thead>
                                        <tbody className="divide-y divide-gray-200">
                                            {students.map((student) => (
                                                <tr key={student.StudentID} className="hover:bg-gray-50">
                                                    <td className="px-6 py-4 text-sm font-medium text-gray-900">
                                                        {student.StudentNumber}
                                                    </td>
                                                    <td className="px-6 py-4 text-sm text-gray-700">
                                                        {student.FullName || `${student.FirstName} ${student.LastName}`}
                                                    </td>
                                                    <td className="px-6 py-4">
                                                        <div className="flex justify-center gap-2">
                                                            {ATTENDANCE_STATUSES.map((status) => (
                                                                <button
                                                                    key={status.value}
                                                                    onClick={() => handleStatusChange(student.StudentID, status.value)}
                                                                    className={`w-10 h-10 rounded-lg text-white transition-all ${
                                                                        student.Status === status.value
                                                                            ? `${status.color} ring-2 ring-offset-2 ring-${status.color.replace('bg-', '')}`
                                                                            : 'bg-gray-200 text-gray-400 hover:bg-gray-300'
                                                                    }`}
                                                                    title={status.label}
                                                                >
                                                                    {status.icon}
                                                                </button>
                                                            ))}
                                                        </div>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>

                                {/* Save Button */}
                                <div className="mt-4 flex justify-end">
                                    <button
                                        onClick={handleSave}
                                        disabled={saving || students.length === 0}
                                        className={`px-6 py-3 rounded-lg text-white font-medium transition-colors ${
                                            saving || students.length === 0
                                                ? 'bg-gray-400 cursor-not-allowed'
                                                : 'bg-purple-600 hover:bg-purple-700'
                                        }`}
                                    >
                                        {saving ? 'Kaydediliyor...' : 'Yoklamayı Kaydet'}
                                    </button>
                                </div>
                            </>
                        )}
                    </div>
                </div>
            )}
        </div>
    );
};

export default Attendance;
