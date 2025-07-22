import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import MarketplaceListing "../../types/MarketplaceListing";
import UserType "../../types/UserType";

module {
    public func get_tutor_listings(marketplace_hashmap_tutor_listings : HashMap.HashMap<UserType.DID, [MarketplaceListing.ListingId]>, marketplace_hashmap_listings : HashMap.HashMap<MarketplaceListing.ListingId, MarketplaceListing.Listing>, tutor_did : UserType.DID) : [MarketplaceListing.Listing] {
        let listing_ids = Option.get(marketplace_hashmap_tutor_listings.get(tutor_did), []);
        let listing_buffer = Buffer.Buffer<MarketplaceListing.Listing>(listing_ids.size());

        for (listing_id in listing_ids.vals()) {
            switch (marketplace_hashmap_listings.get(listing_id)) {
                case (?listing) { listing_buffer.add(listing) };
                case null { /* skip invalid listing */ };
            };
        };

        Buffer.toArray(listing_buffer);
    };
};
