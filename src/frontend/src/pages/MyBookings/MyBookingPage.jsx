// src/pages/MyBookings/MyBookingsPage.jsx

import { ShoppingBag } from 'lucide-react';
import BookingCard from './BookingCard'; // <-- 1. Impor komponen kartu baru

// 2. Buat data dummy untuk ditampilkan
const dummyBookings = [
  {
    id: 1,
    title: 'Website Design Consultation',
    bookingDate: 'August 10, 2025',
    status: 'Confirmed',
  },
  {
    id: 2,
    title: 'Smart Contract Audit',
    bookingDate: 'August 12, 2025',
    status: 'Confirmed',
  },
  {
    id: 3,
    title: 'Frontend Development Session',
    bookingDate: 'August 15, 2025',
    status: 'Pending',
  },
];

function MyBookingsPage() {
  return (
    <div className="p-6 md:p-8">
      <h2 className="text-3xl font-bold mb-6">My Bookings</h2>

      {dummyBookings.length === 0 ? (
        <div className="flex flex-col items-center justify-center text-center text-gray-500 bg-[#161B22] p-12 rounded-lg border border-gray-800">
          <ShoppingBag size={48} className="mb-4" />
          <h3 className="text-xl font-semibold text-white">No Bookings Yet</h3>
          <p>Your booked listings will appear here.</p>
        </div>
      ) : (
        // 3. Tampilkan data booking menggunakan BookingCard
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {dummyBookings.map((booking) => (
            <BookingCard
              key={booking.id}
              title={booking.title}
              bookingDate={booking.bookingDate}
              status={booking.status}
            />
          ))}
        </div>
      )}
    </div>
  );
}

export default MyBookingsPage;