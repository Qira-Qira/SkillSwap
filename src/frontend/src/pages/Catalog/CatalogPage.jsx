// src/pages/Catalog/CatalogPage.jsx

import FilterSidebar from './FilterSidebar';
import LearnerListingCard from './LearnerListingCard';

const dummyTutors = [
  {
    id: 1,
    name: 'M. Fathin Halim',
    avatarUrl: 'https://i.pravatar.cc/40?u=fathin',
    imageUrl: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?q=80&w=2071',
    quote: 'Every line of code is a new possibility.',
    skills: ['Next.js', 'HTML, CSS', 'TailwindCSS', 'Bootstrap'],
    price: 10,
  },
   {
    id: 2,
    name: 'Jane Doe',
    avatarUrl: 'https://i.pravatar.cc/40?u=jane',
    imageUrl: 'https://images.unsplash.com/photo-1588681664899-f142ff2dc9b1?q=80&w=1974',
    quote: 'Design is thinking made visual.',
    skills: ['Figma', 'UI/UX', 'Webflow', 'Canva'],
    price: 15,
  },
];

function CatalogPage() {
  return (
    <div className="container mx-auto p-8">
      <div className="flex flex-col lg:flex-row gap-8">
        {/* Kolom Filter */}
        <FilterSidebar />
        
        {/* Kolom Listing */}
        <div className="flex-1">
          {dummyTutors.map(tutor => (
            <LearnerListingCard key={tutor.id} tutor={tutor} />
          ))}
        </div>
      </div>
    </div>
  );
}

export default CatalogPage;