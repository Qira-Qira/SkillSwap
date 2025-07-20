// src/pages/Governance/ProposalCard.jsx

/**
 * Komponen untuk menampilkan satu kartu proposal governance.
 * @param {object} props
 * @param {string} props.title - Judul proposal.
 * @param {string} props.description - Deskripsi singkat proposal.
 * @param {string} props.time - Waktu yang tersisa.
 * @param {string} props.status - Status proposal (e.g., Open, Closed).
 * @param {string} props.needs - Kebutuhan untuk proposal (e.g., vote power).
 */
function ProposalCard({ title, description, time, status, needs }) {
  return (
    <div className="bg-[#161B22] border border-gray-700 p-6 rounded-lg transition-all hover:border-gray-500">
      <h3 className="text-xl font-bold text-white mb-1">{title}</h3>
      <p className="text-gray-400 text-sm">{description}</p>
      
      <div className="mt-4 pt-4 border-t border-gray-700/50 flex flex-col md:flex-row justify-between text-sm text-gray-400 gap-2">
        <span>
          Time: <span className="text-white font-medium">{time}</span>
        </span>
        <span>
          Status: <span className="text-green-400 font-medium">{status}</span> | <span>{needs}</span>
        </span>
      </div>
    </div>
  );
}

export default ProposalCard;