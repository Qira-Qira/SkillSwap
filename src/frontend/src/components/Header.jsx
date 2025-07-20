// src/components/Header.jsx

function Header() {
  return (
    <header className="bg-[#161B22] text-white p-4 border-b border-gray-800">
      <div className="container mx-auto flex justify-between items-center">
        {/* Navigasi Kiri */}
        <nav className="flex items-center gap-6">
          <span className="text-xl font-bold">SkillsSwap DAO</span>
          <a href="#" className="text-gray-400 hover:text-white">About</a>
          <a href="#" className="text-gray-400 hover:text-white">Features</a>
        </nav>
        {/* Tombol Kanan */}
        <button className="bg-gray-700 hover:bg-gray-600 text-white font-semibold py-2 px-4 rounded-lg transition-colors">
          Dashboard
        </button>
      </div>
    </header>
  );
}

export default Header;