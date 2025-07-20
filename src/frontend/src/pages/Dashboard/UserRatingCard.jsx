// src/pages/Dashboard/UserRatingCard.jsx
import { Star } from 'lucide-react';

function UserRatingCard() {
  return (
    <div className="bg-[#161B22] p-3 rounded-xl flex items-center gap-3">
      <h3 className="font-semibold">Rating:</h3>
      <div className="flex items-center">
        <Star size={20} className="text-yellow-400" fill="currentColor" />
        <Star size={20} className="text-yellow-400" fill="currentColor" />
        <Star size={20} className="text-yellow-400" fill="currentColor" />
        <Star size={20} className="text-gray-600" />
        <Star size={20} className="text-gray-600" />
      </div>
    </div>
  );
}

export default UserRatingCard;