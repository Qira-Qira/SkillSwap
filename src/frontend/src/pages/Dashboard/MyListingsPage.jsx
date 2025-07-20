import ActiveListingCard from './ActiveListingCard';

function MyListingsPage() {
  return (
    <div className="p-6">
      <h2 className="text-3xl font-bold mb-6">My Listings</h2>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <ActiveListingCard imageUrl="" title="List Title 1" />
        <ActiveListingCard imageUrl="" title="List Title 2" />
        <ActiveListingCard imageUrl="" title="List Title 3" />
        <ActiveListingCard imageUrl="" title="List Title 4" />
      </div>
    </div>
  );
}

export default MyListingsPage;
