import MarketplaceListing "../../types/MarketplaceListing";
import ApiResponse "../../types/APIResponse";
import HashMap "mo:base/HashMap";

module {
    public func get_listing(marketplace_hashmap_listings :  HashMap.HashMap<MarketplaceListing.ListingId, MarketplaceListing.Listing>, listing_id : MarketplaceListing.ListingId) : ApiResponse.ApiResult<MarketplaceListing.Listing> {
        switch (marketplace_hashmap_listings.get(listing_id)) {
            case (?listing) { #ok(listing) };
            case null { #err("Listing not found") };
        };
    };
};
