// src/pages/Dashboard/DashboardContent.jsx

import { ChevronDown } from 'lucide-react';
import BalanceCard from './BalanceCard';
import RatingChart from './RatingChart';
import UserRatingCard from './UserRatingCard';
import ActiveListingCard from './ActiveListingCard';

function DashboardContent() {
  return (
    // Wrapper utama untuk konten dengan padding
    <main className="flex-1 p-6 md:p-8">
      {/* DIV DI BAWAH INI SEBELUMNYA MEMBATASI LEBAR KONTEN.
        KITA HAPUS KELAS max-w-7xl dan mx-auto DARI SINI.
        SEKARANG KONTEN AKAN MELEBAR PENUH.
      */}
      <div>
        <h2 className="text-3xl font-bold mb-8">Dashboard</h2>

        {/* Wrapper untuk semua konten di bawah judul */}
        <div className="flex flex-col gap-8">

          {/* ============================================= */}
          {/* == BAGIAN ATAS: Layout 2 Kolom (Presisi)   == */}
          {/* ============================================= */}
          <div className="flex flex-col lg:flex-row gap-8">

            {/* Kolom Kiri (Streaming Card) */}
            <div className="w-full lg:w-1/2">
              <div 
                className="bg-[#161B22] rounded-xl p-6 flex items-center justify-center relative h-full min-h-[300px] bg-cover bg-center"
                style={{ backgroundImage: "url('')" }}
              >
                <div className="absolute inset-0 bg-black/50 rounded-xl"></div>
                <div className="relative z-10 text-center flex items-center gap-4">
                  <h3 className="text-2xl font-bold">Streaming right now</h3>
                  <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
                    <svg className="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M8 5v14l11-7z" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>

            {/* Kolom Kanan (Berisi semua kartu lainnya) */}
            <div className="w-full lg:w-1/2 flex flex-col gap-6">
              {/* Baris Atas: Settlement & Rating Chart */}
              <div className="flex flex-col md:flex-row gap-6">
                <div className="w-full md:w-[45%] flex flex-col gap-6">
                   <button className="bg-[#161B22] p-4 rounded-xl text-left h-full hover:bg-gray-800 transition-colors">
                    <h3 className="font-semibold">Settlement / Disputes</h3>
                  </button>
                  <BalanceCard />
                </div>
                <div className="w-full md:w-[55%]">
                  <RatingChart />
                </div>
              </div>
              
              {/* Baris Bawah: Create Listing & User Rating */}
              <div className="flex items-center justify-between gap-4">
                <button className="bg-white text-black font-bold py-3 px-6 rounded-lg text-sm hover:bg-gray-200 transition-colors">
                  Create Listing
                </button>
                <UserRatingCard />
              </div>
            </div>
          </div>

          {/* ============================================= */}
          {/* == BAGIAN BAWAH: Active Listing            == */}
          {/* ============================================= */}
          <div>
            <div className="flex flex-col md:flex-row justify-between md:items-center mt-4 mb-4 gap-4">
              <h3 className="text-2xl font-bold">Active Listing</h3>
              <button className="flex items-center justify-center gap-2 bg-[#161B22] py-2 px-4 rounded-lg hover:bg-gray-800 w-full md:w-auto">
                <span>Listing</span>
                <ChevronDown size={16} />
              </button>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              <ActiveListingCard
                imageUrl=""
                title="List Title"
              />
              <div className="bg-[#161B22] rounded-xl aspect-square"></div>
              <div className="bg-[#161B22] rounded-xl aspect-square"></div>
              <div className="bg-[#161B22] rounded-xl aspect-square"></div>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

export default DashboardContent;