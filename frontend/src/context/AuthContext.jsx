/**
 * context/AuthContext.jsx
 * Authentication context for user state management
 */

import { createContext, useContext, useState, useEffect } from 'react';
import authService from '../services/authService';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Check for stored user on mount
        const storedUser = localStorage.getItem('user');
        if (storedUser) {
            setUser(JSON.parse(storedUser));
        }
        setLoading(false);
    }, []);

    const login = async (username, password) => {
        const result = await authService.login(username, password);
        if (result.success && result.user) {
            setUser(result.user);
            localStorage.setItem('user', JSON.stringify(result.user));
            return { success: true };
        }
        return { success: false, message: result.message || 'Giriş başarısız' };
    };

    const logout = () => {
        setUser(null);
        localStorage.removeItem('user');
    };

    const value = {
        user,
        loading,
        login,
        logout,
        isAuthenticated: !!user,
        isAdmin: user?.RoleName === 'Admin',
        isAcademic: user?.RoleName === 'Academic',
        isStudent: user?.RoleName === 'Student'
    };

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

export default AuthContext;

