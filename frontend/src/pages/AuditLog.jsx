/**
 * pages/AuditLog.jsx
 * Audit log page for admins
 */

import { useEffect, useState } from 'react';
import reportingService from '../services/reportingService';

const AuditLog = () => {
    const [logs, setLogs] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filters, setFilters] = useState({
        actionType: '',
        tableName: ''
    });

    useEffect(() => {
        fetchLogs();
    }, []);

    const fetchLogs = async () => {
        setLoading(true);
        try {
            const result = await reportingService.searchAuditLog(filters);
            if (result.success) {
                setLogs(result.logs);
            }
        } catch (err) {
            console.error('Audit log error:', err);
        } finally {
            setLoading(false);
        }
    };

    const handleSearch = (e) => {
        e.preventDefault();
        fetchLogs();
    };

    return (
        <div>
            <h1 className="text-2xl font-bold text-gray-800 mb-6">İşlem Kayıtları</h1>

            <form onSubmit={handleSearch} className="bg-white rounded-xl shadow-md p-6 mb-6">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">İşlem Tipi</label>
                        <input
                            type="text"
                            value={filters.actionType}
                            onChange={(e) => setFilters({ ...filters, actionType: e.target.value })}
                            placeholder="Örn: StatusChange"
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                        />
                    </div>
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">Tablo Adı</label>
                        <input
                            type="text"
                            value={filters.tableName}
                            onChange={(e) => setFilters({ ...filters, tableName: e.target.value })}
                            placeholder="Örn: Enrollments"
                            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                        />
                    </div>
                    <div className="flex items-end">
                        <button
                            type="submit"
                            className="w-full px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
                        >
                            Filtrele
                        </button>
                    </div>
                </div>
            </form>

            {loading ? (
                <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
                </div>
            ) : logs.length === 0 ? (
                <div className="text-center py-12 text-gray-500 bg-white rounded-xl shadow-md">
                    İşlem kaydı bulunamadı.
                </div>
            ) : (
                <div className="bg-white rounded-xl shadow-md overflow-hidden">
                    <table className="w-full">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Tarih</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Tablo</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">İşlem</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Kayıt ID</th>
                                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-600">Detay</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-200">
                            {logs.map((log, idx) => (
                                <tr key={idx} className="hover:bg-gray-50">
                                    <td className="px-6 py-4 text-sm text-gray-700">
                                        {new Date(log.ChangeTimestamp).toLocaleString('tr-TR')}
                                    </td>
                                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{log.TableName}</td>
                                    <td className="px-6 py-4">
                                        <span className="px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full">
                                            {log.ActionType}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-700">{log.RecordID}</td>
                                    <td className="px-6 py-4 text-sm text-gray-600 max-w-xs truncate">
                                        {log.ChangeDetails}
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

export default AuditLog;

