// src/pages/Dashboard/RatingChart.jsx
function RatingChart() {
  // Tinggi bar dalam persen, disesuaikan agar mirip dengan desain
  const ratings = [
    { height: 60, color: 'bg-green-400' },
    { height: 45, color: 'bg-red-400' },
    { height: 85, color: 'bg-green-400' },
    { height: 55, color: 'bg-red-400' },
    { height: 65, color: 'bg-green-400' },
    { height: 90, color: 'bg-green-400' },
  ];

  return (
    <div className="bg-[#161B22] p-4 rounded-xl flex flex-col h-full">
      <h3 className="font-semibold mb-4">This Year Rating</h3>
      <div className="flex-grow flex items-end justify-between gap-3 h-[100px]">
        {ratings.map((bar, index) => (
          <div key={index} className="w-full flex items-end justify-center">
            <div
              className={`w-[80%] rounded-md ${bar.color}`}
              style={{ height: `${bar.height}%` }}
            ></div>
          </div>
        ))}
      </div>
    </div>
  );
}
export default RatingChart;