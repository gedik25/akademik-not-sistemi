/**
 * layouts/DashboardLayout.jsx
 * Shared dashboard layout with sidebar navigation
 */

import { Link, useLocation, useNavigate, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const DashboardLayout = () => {
    const { user, logout, isAdmin, isAcademic, isStudent } = useAuth();
    const location = useLocation();
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        navigate('/login');
    };

    const navItems = [];

    // Common items
    navItems.push({ path: '/dashboard', label: 'Ana Sayfa', icon: '🏠' });

    // Admin items
    if (isAdmin) {
        navItems.push({ path: '/users', label: 'Kullanıcılar', icon: '👥' });
        navItems.push({ path: '/departments', label: 'Bölümler', icon: '🏛️' });
        navItems.push({ path: '/audit', label: 'İşlem Kayıtları', icon: '📋' });
    }

    // Academic items
    if (isAcademic || isAdmin) {
        navItems.push({ path: '/my-courses', label: 'Derslerim', icon: '📚' });
        navItems.push({ path: '/students', label: 'Öğrenci Listesi', icon: '👥' });
        navItems.push({ path: '/gradebook', label: 'Not Girişi', icon: '✏️' });
        navItems.push({ path: '/attendance', label: 'Yoklama', icon: '📝' });
    }

    // Student items
    if (isStudent) {
        navItems.push({ path: '/catalog', label: 'Ders Kataloğu', icon: '📖' });
        navItems.push({ path: '/my-schedule', label: 'Ders Programım', icon: '📅' });
        navItems.push({ path: '/transcript', label: 'Transkript', icon: '📄' });
        navItems.push({ path: '/my-attendance', label: 'Devam Durumum', icon: '✅' });
    }

    // Common items
    navItems.push({ path: '/notifications', label: 'Bildirimler', icon: '🔔' });

    return (
        <div className="min-h-screen bg-gray-100 flex">
            {/* Sidebar */}
            <aside className="w-64 bg-slate-800 text-white flex flex-col">
                <div className="p-6 border-b border-slate-700">
                    <h1 className="text-xl font-bold">Akademik Sistem</h1>
                    <p className="text-sm text-gray-400 mt-1">Not & Devam Takip</p>
                </div>

                <nav className="flex-1 p-4">
                    <ul className="space-y-2">
                        {navItems.map((item) => (
                            <li key={item.path}>
                                <Link
                                    to={item.path}
                                    className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                                        location.pathname === item.path
                                            ? 'bg-purple-600 text-white'
                                            : 'text-gray-300 hover:bg-slate-700'
                                    }`}
                                >
                                    <span>{item.icon}</span>
                                    <span>{item.label}</span>
                                </Link>
                            </li>
                        ))}
                    </ul>
                </nav>

                <div className="p-4 border-t border-slate-700">
                    <div className="flex items-center gap-3 mb-4">
                        <div className="w-10 h-10 bg-purple-600 rounded-full flex items-center justify-center">
                            {user?.Username?.charAt(0).toUpperCase()}
                        </div>
                        <div>
                            <p className="font-medium">{user?.Username}</p>
                            <p className="text-sm text-gray-400">{user?.RoleName}</p>
                        </div>
                    </div>
                    <button
                        onClick={handleLogout}
                        className="w-full px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
                    >
                        Çıkış Yap
                    </button>
                </div>
            </aside>

            {/* Main content */}
            <main className="flex-1 p-8 overflow-auto">
                <Outlet />
            </main>
        </div>
    );
};

export default DashboardLayout;

