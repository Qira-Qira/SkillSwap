// src/pages/Governance/GovernancePage.jsx

import ProposalCard from './ProposalCard';

const dummyProposals = [
  {
    id: 1,
    title: 'Steve itu Karbit',
    description: 'STEVE ITU KARBIT KARENA MAHIRU ISTRI FATHIN!!!!',
    time: '2 hours 3 minutes',
    status: 'Open',
    needs: 'need 10 vote power',
  },
  {
    id: 2,
    title: 'Steve itu Karbit',
    description: 'STEVE ITU KARBIT KARENA MAHIRU ISTRI FATHIN!!!!',
    time: '2 hours 3 minutes',
    status: 'Open',
    needs: 'need 10 vote power',
  },
  {
    id: 3,
    title: 'Steve itu Karbit',
    description: 'STEVE ITU KARBIT KARENA MAHIRU ISTRI FATHIN!!!!',
    time: '2 hours 3 minutes',
    status: 'Open',
    needs: 'need 10 vote power',
  },
  {
    id: 4,
    title: 'Steve itu Karbit',
    description: 'STEVE ITU KARBIT KARENA MAHIRU ISTRI FATHIN!!!!',
    time: '2 hours 3 minutes',
    status: 'Open',
    needs: 'need 10 vote power',
  },
];

function GovernancePage() {
  return (
    // Kontainer ini akan otomatis mengisi parentnya (area <main>)
    <div className="p-6 md:p-8">
      
      {/* Tidak ada lagi struktur flex/kolom yang membatasi lebar */}
      <div className="flex flex-col gap-4">
        {dummyProposals.map((proposal) => (
          <ProposalCard
            key={proposal.id}
            title={proposal.title}
            description={proposal.description}
            time={proposal.time}
            status={proposal.status}
            needs={proposal.needs}
          />
        ))}
      </div>
    </div>
  );
}

// Pastikan file ProposalCard.jsx Anda juga ada dan benar
export default GovernancePage;