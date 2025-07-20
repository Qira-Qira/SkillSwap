// src/pages/Dashboard/BalanceCard.jsx
import { Cloud } from 'lucide-react'; // Mengganti Wallet2 dengan Cloud

function BalanceCard() {
  return (
    <div className="bg-[#161B22] p-4 rounded-xl">
      <div className="flex justify-between items-center mb-2">
        <p className="text-sm text-gray-400">Balance</p>
        <Cloud size={20} className="text-gray-400" />
      </div>
      <p className="text-xl font-bold">$0703.612.2010</p> {/* Ukuran font disesuaikan */}
    </div>
  );
}

export default BalanceCard;