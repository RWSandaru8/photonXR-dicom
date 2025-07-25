import React, { useState, useEffect } from 'react';
import { Clock } from 'lucide-react';

interface StatisticsData {
  totalStudies: number;
  todaysScans: number;
  lastScanTime: string | null;
  percentageChange: number;
}

const StatisticsCards: React.FC = () => {
  const [statistics, setStatistics] = useState<StatisticsData>({
    totalStudies: 0,
    todaysScans: 0,
    lastScanTime: null,
    percentageChange: 0
  });
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchStatistics = async () => {
      setIsLoading(true);
      try {
        const response = await fetch('http://localhost:3000/api/statistics');
        
        if (!response.ok) {
          throw new Error(`Failed to fetch statistics: ${response.status}`);
        }
        
        const data = await response.json();
        setStatistics(data);
        setError(null);
      } catch (err) {
        console.error('Error fetching statistics:', err);
        setError('Failed to load statistics');
      } finally {
        setIsLoading(false);
      }
    };

    fetchStatistics();
  }, []);

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-white rounded-xl shadow p-4 animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/3 mb-2"></div>
          <div className="h-8 bg-gray-200 rounded w-1/4"></div>
        </div>
        <div className="bg-white rounded-xl shadow p-4 animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/3 mb-2"></div>
          <div className="h-8 bg-gray-200 rounded w-1/4"></div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-red-500 bg-red-100 p-2 rounded">
        {error}
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {/* Total Studies Card */}
      <div className="bg-white rounded-xl shadow p-6">
        <div className="flex justify-between items-start">
          <div>
            <h3 className="text-sm font-medium text-gray-500">Total Studies</h3>
            <div className="flex items-baseline mt-1">
              <span className="text-3xl font-semibold text-gray-900">{statistics.totalStudies}</span>
              <span className={`ml-2 text-sm ${statistics.percentageChange >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                {statistics.percentageChange >= 0 ? '+' : ''}{statistics.percentageChange}% from last month
              </span>
            </div>
          </div>
          <div className="bg-green-100 p-2 rounded-lg">
            <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
            </svg>
          </div>
        </div>
      </div>

      {/* Today's Scans Card */}
      <div className="bg-white rounded-xl shadow p-6">
        <div className="flex justify-between items-start">
          <div>
            <h3 className="text-sm font-medium text-gray-500">Today's Scans</h3>
            <div className="flex items-baseline mt-1">
              <span className="text-3xl font-semibold text-gray-900">{statistics.todaysScans}</span>
            </div>
            {statistics.lastScanTime && (
              <div className="mt-2 flex items-center text-sm text-gray-500">
                <Clock className="h-4 w-4 mr-1" />
                <span>Last scan: {statistics.lastScanTime}</span>
              </div>
            )}
          </div>
          <div className="bg-blue-100 p-2 rounded-lg">
            <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
            </svg>
          </div>
        </div>
      </div>
    </div>
  );
};

export default StatisticsCards;
