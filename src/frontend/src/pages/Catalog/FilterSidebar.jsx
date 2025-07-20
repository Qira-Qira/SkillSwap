// src/pages/Catalog/FilterSidebar.jsx

function FilterCheckbox({ label }) {
  return (
    <label className="flex items-center gap-2 text-white cursor-pointer">
      <input type="checkbox" defaultChecked className="w-4 h-4 accent-purple-500 bg-gray-700 border-gray-600 rounded" />
      {label}
    </label>
  );
}

function MethodCheckbox({ label }) {
    return (
      <label className="flex items-center gap-2 text-white cursor-pointer">
        <input type="checkbox" defaultChecked className="w-4 h-4 accent-purple-500 bg-gray-700 border-gray-600 rounded" />
        {label}
      </label>
    );
  }

function FilterSidebar() {
  return (
    <aside className="w-72 flex-shrink-0 bg-[#161B22] p-6 rounded-lg self-start">
      <h2 className="text-2xl font-bold mb-6">Filters</h2>
      
      {/* Filter Tags */}
      <div className="mb-6">
        <h3 className="font-semibold mb-3">Tags</h3>
        <div className="grid grid-cols-2 gap-2">
          <FilterCheckbox label="NextJS" />
          <FilterCheckbox label="NextJS" />
          <FilterCheckbox label="NextJS" />
          <FilterCheckbox label="NextJS" />
        </div>
        <button className="text-purple-400 hover:text-purple-300 mt-3 text-sm">+ Add Tag</button>
      </div>
      
      {/* Filter Price */}
      <div className="mb-6">
        <h3 className="font-semibold mb-3">Price</h3>
        <input type="range" min="0" max="100" defaultValue="50" className="w-full h-2 bg-gray-700 rounded-lg appearance-none cursor-pointer" />
        <p className="text-sm text-gray-400 mt-1">1G SWT</p>
      </div>
      
      {/* Filter Method */}
      <div>
        <h3 className="font-semibold mb-3">Method</h3>
        <div className="flex flex-col gap-2">
            <MethodCheckbox label="Video Call" />
            <MethodCheckbox label="Chat" />
        </div>
      </div>
    </aside>
  );
}

export default FilterSidebar;