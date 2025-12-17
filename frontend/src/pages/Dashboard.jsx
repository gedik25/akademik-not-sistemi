/**
 * pages/Dashboard.jsx
 * Main dashboard page - shows role-appropriate content
 */

import { useEffect, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import reportingService from '../services/reportingService';

const Dashboard = () => {
    const { user, isAdmin, isAcademic, isStudent } = useAuth();
    const [stats, setStats] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchStats = async () => {
            try {
                const result = await reportingService.getDashboardStats(user.UserID);
                if (result.success) {
                    setStats(result.stats);
                }
            } catch (err) {
                console.error('Dashboard stats error:', err);
            } finally {
                setLoading(false);
            }
        };

        if (user?.UserID) {
            fetchStats();
        }
    }, [user]);

    return (
        <div>
            <div className="mb-8">
                <h1 className="text-3xl font-bold text-gray-800">
                    Hoş Geldiniz, {user?.Username}!
                </h1>
                <p className="text-gray-600 mt-2">
                    {isAdmin && 'Sistem yönetim paneline hoş geldiniz.'}
                    {isAcademic && 'Akademik paneline hoş geldiniz.'}
                    {isStudent && 'Öğrenci paneline hoş geldiniz.'}
                </p>
            </div>

            {/* Quick Stats */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
                {isAdmin && (
                    <>
                        <StatCard title="Toplam Kullanıcı" value="--" icon="👥" color="bg-blue-500" />
                        <StatCard title="Aktif Dersler" value="--" icon="📚" color="bg-green-500" />
                        <StatCard title="Kayıtlı Öğrenci" value="--" icon="🎓" color="bg-purple-500" />
                        <StatCard title="Akademisyen" value="--" icon="👨‍🏫" color="bg-orange-500" />
                    </>
                )}
                {isAcademic && (
                    <>
                        <StatCard title="Verdiğim Dersler" value="--" icon="📚" color="bg-blue-500" />
                        <StatCard title="Toplam Öğrenci" value="--" icon="👥" color="bg-green-500" />
                        <StatCard title="Bekleyen Notlar" value="--" icon="✏️" color="bg-yellow-500" />
                        <StatCard title="Bugünkü Dersler" value="--" icon="📅" color="bg-purple-500" />
                    </>
                )}
                {isStudent && (
                    <>
                        <StatCard title="Kayıtlı Derslerim" value="--" icon="📚" color="bg-blue-500" />
                        <StatCard title="Genel Ortalama" value="--" icon="📊" color="bg-green-500" />
                        <StatCard title="Devam Oranı" value="--" icon="✅" color="bg-purple-500" />
                        <StatCard title="Bildirimler" value="--" icon="🔔" color="bg-orange-500" />
                    </>
                )}
            </div>

            {/* Recent Activity */}
            <div className="bg-white rounded-xl shadow-md p-6">
                <h2 className="text-xl font-semibold text-gray-800 mb-4">Son Aktiviteler</h2>
                <div className="text-gray-500 text-center py-8">
                    Henüz aktivite bulunmuyor.
                </div>
            </div>
        </div>
    );
};

const StatCard = ({ title, value, icon, color }) => (
    <div className="bg-white rounded-xl shadow-md p-6 flex items-center gap-4">
        <div className={`w-14 h-14 ${color} rounded-xl flex items-center justify-center text-2xl`}>
            {icon}
        </div>
        <div>
            <p className="text-gray-500 text-sm">{title}</p>
            <p className="text-2xl font-bold text-gray-800">{value}</p>
        </div>
    </div>
);

export default Dashboard;

