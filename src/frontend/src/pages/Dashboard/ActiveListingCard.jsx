// src/pages/Dashboard/ActiveListingCard.jsx

import { ArrowRight } from 'lucide-react'; // Ganti ikon Target dengan ArrowRight

function ActiveListingCard({ imageUrl, title }) {
  return (
    // Kontainer utama kartu
    <div
      className="relative aspect-square rounded-2xl bg-cover bg-center overflow-hidden group border-2 border-transparent hover:border-purple-500 transition-all duration-300"
      style={{ backgroundImage: `url(${imageUrl})` }}
    >
      {/* Overlay gelap untuk kontras */}
      <div className="absolute inset-0 bg-black/30"></div>
      
      {/* Kontainer untuk bar di bagian bawah */}
      <div className="absolute bottom-4 left-4 right-4">
        {/* Bar bawah dengan bentuk pill */}
        <div className="flex items-center justify-between gap-2 bg-black/60 backdrop-blur-md p-2 rounded-full border border-gray-700">
          
          {/* Judul List */}
          <span className="text-white font-semibold pl-4 pr-2 truncate">{title}</span>

          {/* Tombol Panah */}
          <button className="bg-gray-700 w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 hover:bg-gray-600 transition-colors">
            <ArrowRight size={18} className="text-white" />
          </button>
        </div>
      </div>
    </div>
  );
}

export default ActiveListingCard;