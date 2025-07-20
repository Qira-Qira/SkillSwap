// src/pages/MyBookings/BookingCard.jsx

import { Calendar, CheckCircle } from 'lucide-react';

function BookingCard({ title, bookingDate, status }) {
  // Atur warna status
  const statusColor = status === 'Confirmed' ? 'text-green-400' : 'text-yellow-400';

  return (
    <div className="bg-[#161B22] border border-gray-800 p-5 rounded-lg flex flex-col h-full">
      <div className="flex-grow">
        <p className="text-gray-400 text-sm">You booked:</p>
        <h3 className="text-lg font-bold text-white mt-1">{title}</h3>
      </div>
      
      <div className="mt-4 pt-4 border-t border-gray-700/50 flex flex-col gap-2 text-sm">
        <div className="flex items-center gap-2 text-gray-400">
          <Calendar size={14} />
          <span>{bookingDate}</span>
        </div>
        <div className={`flex items-center gap-2 font-medium ${statusColor}`}>
          <CheckCircle size={14} />
          <span>{status}</span>
        </div>
      </div>
    </div>
  );
}

export default BookingCard;