import MarketplaceListing "../../types/MarketplaceListing";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import BookingSession "../../types/BookingSession";
import StateMarketplace "../../storages/StateMarketplace";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Time "mo:base/Time";
module {
    // Create booking for a listing
    public func create_booking(
        booking_id : Nat,
        marketplace_hashmap : StateMarketplace.MarketplaceHashmap,
        listing_id : MarketplaceListing.ListingId,
        learner_did : UserType.DID,
    ) : async ApiResponse.ApiResult<BookingSession.Booking> {

        switch (marketplace_hashmap.listings.get(listing_id)) {
            case null { return #err("Listing not found") };
            case (?listing) {
                if (listing.status != #Active) {
                    return #err("Listing is not active");
                };

                if (listing.available_slots == 0) {
                    return #err("No available slots");
                };

                let booking : BookingSession.Booking = {
                    id = booking_id;
                    listing_id = listing_id;
                    learner_did = learner_did;
                    tutor_did = listing.tutor_did;
                    amount_swt = listing.price_swt;
                    scheduled_time = null;
                    status = #Pending;
                    created_at = Time.now();
                    completed_at = null;
                    learner_confirmed = false;
                    tutor_confirmed = false;
                };

                marketplace_hashmap.bookings.put(booking_id, booking);

                // Update learner's bookings index
                let current_bookings = Option.get(marketplace_hashmap.learner_bookings.get(learner_did), []);
                marketplace_hashmap.learner_bookings.put(learner_did, Array.append(current_bookings, [booking_id]));

                // Decrease available slots
                let updated_listing : MarketplaceListing.Listing = {
                    listing with available_slots = listing.available_slots - 1;
                };
                marketplace_hashmap.listings.put(listing_id, updated_listing);

                return #ok(booking);
            };
        };
    };

};
