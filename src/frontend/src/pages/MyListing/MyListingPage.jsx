// src/pages/MyListings/MyListingsPage.jsx

import { useState } from 'react'; // <-- 1. Impor useState
import { ChevronDown } from 'lucide-react';
import ActiveListingCard from '../Dashboard/ActiveListingCard';

// Data dummy untuk semua listing yang ada
const allListings = Array.from({ length: 12 }, (_, i) => ({
  id: i + 1,
  title: `My Listing #${i + 1}`,
  // Kita tambahkan status untuk simulasi filter
  status: i % 3 === 0 ? 'Active' : 'Inactive', 
}));

// Opsi untuk filter
const filterOptions = ['All', 'Active', 'Inactive'];

function MyListingsPage() {
  // --- 2. State untuk menyimpan filter aktif dan status dropdown ---
  const [activeFilter, setActiveFilter] = useState('All');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  // --- 3. Logika untuk memfilter daftar berdasarkan state ---
  const filteredListings = allListings.filter(listing => {
    if (activeFilter === 'All') {
      return true; // Tampilkan semua jika filter adalah 'All'
    }
    return listing.status === activeFilter; // Tampilkan yang statusnya cocok
  });

  const handleFilterClick = (option) => {
    setActiveFilter(option);
    setIsDropdownOpen(false); // Tutup dropdown setelah opsi dipilih
  };

  return (
    <div className="p-6 md:p-8">
      {/* Header Halaman */}
      <div className="flex flex-col md:flex-row justify-between md:items-center mb-6 gap-4">
        <h2 className="text-3xl font-bold">My Listings</h2>

        {/* --- 4. Tombol Filter dengan Dropdown --- */}
        <div className="relative">
          <button
            onClick={() => setIsDropdownOpen(!isDropdownOpen)} // Buka/tutup dropdown
            className="flex items-center justify-center gap-2 bg-[#161B22] py-2 px-4 rounded-lg hover:bg-gray-800 w-full md:w-40"
          >
            <span>{activeFilter}</span>
            <ChevronDown size={16} />
          </button>
          
          {/* Menu Dropdown */}
          {isDropdownOpen && (
            <div className="absolute top-full right-0 mt-2 w-40 bg-[#161B22] border border-gray-700 rounded-lg shadow-lg z-10">
              {filterOptions.map((option) => (
                <button
                  key={option}
                  onClick={() => handleFilterClick(option)}
                  className="block w-full text-left px-4 py-2 text-sm text-white hover:bg-gray-700 first:rounded-t-lg last:rounded-b-lg"
                >
                  {option}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Grid untuk menampilkan semua kartu listing */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {/* --- 5. Gunakan `filteredListings` untuk di-render --- */}
        {filteredListings.map((listing) => (
          <ActiveListingCard
            key={listing.id}
            imageUrl={`https://picsum.photos/seed/${listing.id}/400`}
            title={listing.title}
          />
        ))}
      </div>
    </div>
  );
}

export default MyListingsPage;