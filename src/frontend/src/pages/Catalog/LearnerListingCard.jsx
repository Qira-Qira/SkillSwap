// src/pages/Catalog/LearnerListingCard.jsx

function LearnerListingCard({ tutor }) {
  return (
    <div className="bg-[#161B22] p-1 rounded-xl border border-gray-800 mb-4">
      {/* Gambar Latar */}
      <div 
        className="relative p-6 rounded-lg overflow-hidden bg-cover bg-center h-72 flex flex-col justify-end"
        style={{ backgroundImage: `url(${tutor.imageUrl})`}}
      >
        {/* Gradient gelap di bagian bawah untuk keterbacaan teks */}
        <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/50 to-transparent"></div>
        
        {/* Konten Bawah yang Disederhanakan */}
        <div className="relative flex justify-between items-center">
          <button className="bg-black/60 backdrop-blur-md py-2 px-5 rounded-full border border-gray-600">
            Title Here
          </button>
          
          <span className="bg-[#1d232c] text-white font-bold py-2 px-5 rounded-full text-sm border border-gray-600">
            ${tutor.price} SWT
          </span>

          <button className="bg-white text-black font-bold py-2 px-6 rounded-lg">
            Book Now
          </button>
        </div>
      </div>
      
      {/* Baris Profil Tutor di Bawah Kartu */}
      <div className="flex items-center gap-3 p-3">
        <img src={tutor.avatarUrl} className="w-8 h-8 rounded-full" />
        <span className="font-semibold">{tutor.name}</span>
      </div>
    </div>
  );
}

export default LearnerListingCard;