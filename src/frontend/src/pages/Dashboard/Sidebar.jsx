// src/pages/Dashboard/Sidebar.jsx

import { useState } from 'react';
import {
  LayoutDashboard, List, ShoppingBag, CircleDollarSign, Landmark, MoreHorizontal, Home, Menu
} from 'lucide-react';

const navItems = [
  { id: 'dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { id: 'listings', icon: List, label: 'My Listings' },
  { id: 'bookings', icon: ShoppingBag, label: 'My Bookings' },
  { id: 'token', icon: CircleDollarSign, label: 'Top Up Token' },
  { id: 'governance', icon: Landmark, label: 'Governance' },
];

function Sidebar({ activePage, onNavigate }) {
  const [open, setOpen] = useState(false);
  const buttonText = activePage === 'governance' ? 'Create Proposal' : 'Create Listing';

  // Sidebar content, reusable for desktop & mobile
  const sidebarContent = (
    <div className="flex flex-col h-full">
      <div className="flex-1 flex flex-col p-6 overflow-y-auto">
        <div className="flex items-center gap-3 mb-10">
          <div className="bg-gray-700 p-2 rounded-lg">
            <Home size={24} />
          </div>
          <h1 className="text-xl font-bold">SS</h1>
        </div>
        <nav>
          <ul>
            {navItems.map((item) => (
              <li key={item.id} className="mb-4">
                <button
                  type="button"
                  onClick={() => {
                    onNavigate(item.id);
                    setOpen(false); // Tutup drawer jika mobile
                  }}
                  className={`w-full text-left flex items-center gap-3 p-3 rounded-lg transition-colors ${
                    activePage === item.id
                      ? 'bg-gray-700 text-white'
                      : 'text-gray-400 hover:bg-gray-700/50 hover:text-white'
                  }`}
                >
                  <item.icon size={20} />
                  <span className="font-medium">{item.label}</span>
                </button>
              </li>
            ))}
          </ul>
        </nav>
      </div>
      <div className="p-6 border-t border-gray-700">
        <button className="w-full bg-white text-black font-bold py-3 px-4 rounded-lg hover:bg-gray-200 transition-colors mb-6">
          {buttonText}
        </button>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img
              src="https://i.pravatar.cc/40?u=fathin"
              alt="User Avatar"
              className="w-10 h-10 rounded-full"
            />
            <div>
              <p className="font-semibold">M. Fathin Halim</p>
              <p className="text-xs text-gray-400">$0703.612.2010</p>
            </div>
          </div>
          <button className="text-gray-400 hover:text-white">
            <MoreHorizontal size={20} />
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <>
      {/* Hamburger untuk mobile */}
      <button
        className="lg:hidden fixed top-4 left-4 z-30 bg-[#161B22] p-2 rounded-lg shadow-md"
        onClick={() => setOpen(true)}
        aria-label="Open sidebar"
      >
        <Menu size={28} />
      </button>

      {/* Sidebar desktop */}
      <aside className="hidden lg:flex w-64 bg-[#161B22] flex-col flex-shrink-0 h-full">
        {sidebarContent}
      </aside>

      {/* Sidebar mobile drawer */}
      {open && (
        <div className="fixed inset-0 z-40 flex">
          {/* Overlay */}
          <div
            className="fixed inset-0 bg-black/40"
            onClick={() => setOpen(false)}
            aria-label="Close sidebar"
          />
          {/* Drawer */}
          <aside className="relative w-64 bg-[#161B22] h-full flex flex-col animate-slide-in-left">
            <button
              className="absolute top-4 right-4 text-gray-400 hover:text-white"
              onClick={() => setOpen(false)}
              aria-label="Close sidebar"
            >
              <Menu size={28} />
            </button>
            {sidebarContent}
          </aside>
        </div>
      )}
    </>
  );
}

export default Sidebar;