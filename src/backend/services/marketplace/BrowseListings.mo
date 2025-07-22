import MarketplaceListing "../../types/MarketplaceListing";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
import HashMap "mo:base/HashMap";

module {
    public func browse_listings(marketplace_hashmap_listings : HashMap.HashMap<MarketplaceListing.ListingId, MarketplaceListing.Listing>, skill_filter : ?Text) : [MarketplaceListing.Listing] {
        let listing_buffer = Buffer.Buffer<MarketplaceListing.Listing>(0);

        for ((id, listing) in marketplace_hashmap_listings.entries()) {
            if (listing.status == #Active) {
                switch (skill_filter) {
                    case null {
                        listing_buffer.add(listing);
                    };
                    case (?skill) {
                        // Check if the listing contains the requested skill
                        let has_skill = Array.find<Text>(listing.skills, func(s) { s == skill });
                        switch (has_skill) {
                            case (?_) { listing_buffer.add(listing) };
                            case null { /* skip */ };
                        };
                    };
                };
            };
        };

        Buffer.toArray(listing_buffer);
    };
};
