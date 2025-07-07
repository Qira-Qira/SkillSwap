import UserType "../../types/UserType";
import MarketplaceListing "../../types/MarketplaceListing";
import ApiResponse "../../types/APIResponse";
import StateMarketplace "../../storages/StateMarketplace";

import Time "mo:base/Time";
import Option "mo:base/Option";
import Array "mo:base/Array";

module {
    // Create new skill listing
    public func create_listing(
        listing_id : Nat,
        marketplace_hashmap : StateMarketplace.MarketplaceHashmap,
        tutor_did : UserType.DID,
        title : Text,
        description : Text,
        skills : [Text],
        duration_minutes : Nat,
        price_swt : Nat,
        available_slots : Nat,
        method : MarketplaceListing.LearningMethod,
        ipfs_cid : Text,
    ) : async ApiResponse.ApiResult<MarketplaceListing.Listing> {

        let listing : MarketplaceListing.Listing = {
            id = listing_id;
            tutor_did = tutor_did;
            title = title;
            description = description;
            skills = skills;
            duration_minutes = duration_minutes;
            price_swt = price_swt;
            available_slots = available_slots;
            method = method;
            ipfs_cid = ipfs_cid;
            created_at = Time.now();
            status = #Active;
        };

        marketplace_hashmap.listings.put(listing_id, listing);

        // Update tutor's listings index
        let current_listings = Option.get(marketplace_hashmap.tutor_listings.get(tutor_did), []);
        marketplace_hashmap.tutor_listings.put(tutor_did, Array.append(current_listings, [listing_id]));

        return #ok(listing);
    };
};
