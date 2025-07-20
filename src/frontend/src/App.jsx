// src/App.jsx

import { useState } from 'react';
import Sidebar from './pages/Dashboard/Sidebar';
import GovernancePage from './pages/Governance/GovernancePage';
import DashboardContent from './pages/Dashboard/DashboardContent';
import MyListingsPage from './pages/MyListing/MyListingPage'; // Import My Listings page
import MyBookingPage from './pages/MyBooking/MyBookingPage'; // Import My Booking page


function App() {
  // State untuk halaman aktif
  const [currentPage, setCurrentPage] = useState('dashboard');

  return (
    // STRUKTUR UTAMA: Wajib seperti ini untuk layout yang benar
    <div className="h-screen flex bg-[#0D1117] text-white overflow-hidden">
      
      {/* Sidebar menerima activePage dan onNavigate */}
      <Sidebar activePage={currentPage} onNavigate={setCurrentPage} />
      
      {/* Area konten akan mengisi sisa ruang dan punya scroll sendiri */}
      <main className="flex-1 overflow-y-auto">
        
        {/* Logika untuk menampilkan halaman yang benar */}
        {currentPage === 'governance' && <GovernancePage />}
        
        {/* Jika ingin menampilkan Dashboard, gunakan ini */}
        {currentPage === 'dashboard' && <DashboardContent />}

        {/* Tambahkan logika untuk menampilkan My Listings */}
        {currentPage === 'listings' && <MyListingsPage />}

        {/* Tambahkan logika untuk menampilkan My Bookings */}
        {currentPage === 'bookings' && <MyBookingPage />}

      </main>

    </div>
  );
}

export default App;