/**
 * App.jsx
 * Main application with routing
 */

import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import DashboardLayout from './layouts/DashboardLayout';

// Pages
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import CourseCatalog from './pages/CourseCatalog';
import MySchedule from './pages/MySchedule';
import Transcript from './pages/Transcript';
import Notifications from './pages/Notifications';
import MyCourses from './pages/MyCourses';
import StudentList from './pages/StudentList';
import Gradebook from './pages/Gradebook';
import Attendance from './pages/Attendance';
import AuditLog from './pages/AuditLog';

function App() {
    return (
        <AuthProvider>
            <BrowserRouter>
                <Routes>
                    {/* Public routes */}
                    <Route path="/login" element={<Login />} />
                    
                    {/* Protected routes */}
                    <Route path="/" element={
                        <ProtectedRoute>
                            <DashboardLayout />
                        </ProtectedRoute>
                    }>
                        <Route index element={<Navigate to="/dashboard" replace />} />
                        <Route path="dashboard" element={<Dashboard />} />
                        <Route path="notifications" element={<Notifications />} />
                        
                        {/* Student routes */}
                        <Route path="catalog" element={<CourseCatalog />} />
                        <Route path="my-schedule" element={<MySchedule />} />
                        <Route path="transcript" element={<Transcript />} />
                        <Route path="my-attendance" element={<Attendance />} />
                        
                        {/* Academic routes */}
                        <Route path="my-courses" element={<MyCourses />} />
                        <Route path="students" element={<StudentList />} />
                        <Route path="gradebook" element={<Gradebook />} />
                        <Route path="attendance" element={<Attendance />} />
                        
                        {/* Admin routes */}
                        <Route path="audit" element={
                            <ProtectedRoute allowedRoles={['Admin']}>
                                <AuditLog />
                            </ProtectedRoute>
                        } />
                    </Route>

                    {/* Catch all */}
                    <Route path="*" element={<Navigate to="/dashboard" replace />} />
                </Routes>
            </BrowserRouter>
        </AuthProvider>
    );
}

export default App;
