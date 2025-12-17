/**
 * pages/Notifications.jsx
 * User notifications page
 */

import { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import reportingService from '../services/reportingService';

const Notifications = () => {
    const { user } = useAuth();
    const [notifications, setNotifications] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchNotifications();
    }, [user]);

    const fetchNotifications = async () => {
        if (!user?.UserID) return;
        setLoading(true);
        try {
            const result = await reportingService.getNotifications(user.UserID);
            if (result.success) {
                setNotifications(result.notifications);
            }
        } catch (err) {
            console.error('Notifications error:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleMarkRead = async (notificationId) => {
        try {
            await reportingService.markNotificationRead(notificationId);
            setNotifications(notifications.map(n => 
                n.NotificationID === notificationId ? { ...n, IsRead: true } : n
            ));
        } catch (err) {
            console.error('Mark read error:', err);
        }
    };

    const getTypeIcon = (type) => {
        switch (type) {
            case 'Grade': return '📊';
            case 'Attendance': return '✅';
            case 'Account': return '👤';
            default: return '🔔';
        }
    };

    return (
        <div>
            <h1 className="text-2xl font-bold text-gray-800 mb-6">Bildirimler</h1>

            {loading ? (
                <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
                </div>
            ) : notifications.length === 0 ? (
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    Bildirim bulunamadı.
                </div>
            ) : (
                <div className="space-y-4">
                    {notifications.map((notification) => (
                        <div 
                            key={notification.NotificationID}
                            className={`bg-white rounded-xl shadow-md p-6 ${
                                !notification.IsRead ? 'border-l-4 border-purple-600' : ''
                            }`}
                        >
                            <div className="flex justify-between items-start">
                                <div className="flex gap-4">
                                    <span className="text-2xl">{getTypeIcon(notification.Type)}</span>
                                    <div>
                                        <h3 className="font-semibold text-gray-800">{notification.Title}</h3>
                                        <p className="text-gray-600 mt-1">{notification.Message}</p>
                                        <p className="text-sm text-gray-400 mt-2">
                                            {new Date(notification.CreatedAt).toLocaleString('tr-TR')}
                                        </p>
                                    </div>
                                </div>
                                {!notification.IsRead && (
                                    <button
                                        onClick={() => handleMarkRead(notification.NotificationID)}
                                        className="px-3 py-1 text-sm bg-purple-100 text-purple-700 rounded-lg hover:bg-purple-200 transition-colors"
                                    >
                                        Okundu
                                    </button>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default Notifications;

