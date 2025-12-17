/**
 * pages/MySchedule.jsx
 * Student's course schedule page
 */

import { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import courseService from '../services/courseService';

const MySchedule = () => {
    const { user } = useAuth();
    const [schedule, setSchedule] = useState([]);
    const [loading, setLoading] = useState(true);
    const [term, setTerm] = useState('2025-FALL');

    useEffect(() => {
        fetchSchedule();
    }, [term, user]);

    const fetchSchedule = async () => {
        if (!user?.UserID) return;
        setLoading(true);
        try {
            const result = await courseService.getStudentSchedule(user.UserID, term);
            if (result.success) {
                setSchedule(result.schedule);
            }
        } catch (err) {
            console.error('Schedule error:', err);
        } finally {
            setLoading(false);
        }
    };

    const parseScheduleJSON = (jsonStr) => {
        try {
            return JSON.parse(jsonStr);
        } catch {
            return [];
        }
    };

    return (
        <div>
            <div className="flex justify-between items-center mb-6">
                <h1 className="text-2xl font-bold text-gray-800">Ders Programım</h1>
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
            ) : schedule.length === 0 ? (
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    Bu dönem için kayıtlı ders bulunamadı.
                </div>
            ) : (
                <div className="grid gap-4">
                    {schedule.map((course) => {
                        const scheduleData = parseScheduleJSON(course.ScheduleJSON);
                        return (
                            <div key={course.OfferingID} className="bg-white rounded-xl shadow-md p-6">
                                <div className="flex justify-between items-start">
                                    <div>
                                        <h3 className="text-lg font-semibold text-gray-800">
                                            {course.CourseCode} - {course.CourseName}
                                        </h3>
                                        <p className="text-gray-600 mt-1">
                                            Şube: {course.Section} | Dönem: {course.Term}
                                        </p>
                                    </div>
                                    <span className="px-3 py-1 bg-green-100 text-green-800 text-sm rounded-full">
                                        Aktif
                                    </span>
                                </div>
                                {scheduleData.length > 0 && (
                                    <div className="mt-4 pt-4 border-t border-gray-100">
                                        <p className="text-sm text-gray-500 mb-2">Program:</p>
                                        <div className="flex flex-wrap gap-2">
                                            {scheduleData.map((slot, idx) => (
                                                <span key={idx} className="px-3 py-1 bg-purple-100 text-purple-800 text-sm rounded-lg">
                                                    {slot.day} {slot.start}-{slot.end} ({slot.room})
                                                </span>
                                            ))}
                                        </div>
                                    </div>
                                )}
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default MySchedule;

