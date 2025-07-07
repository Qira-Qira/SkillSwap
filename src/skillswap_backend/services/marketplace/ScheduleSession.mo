import BookingSession "../../types/BookingSession";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import StateMarketplace "../../storages/StateMarketplace";

module {
    // Schedule a session for existing booking
    public func schedule_session(
        marketplace_hashmap : StateMarketplace.MarketplaceHashmap,
        booking_id : BookingSession.BookingId,
        caller_did : UserType.DID,
        scheduled_time : Int,
    ) : async ApiResponse.ApiResult<BookingSession.Booking> {

        switch (marketplace_hashmap.bookings.get(booking_id)) {
            case null { return #err("Booking not found") };
            case (?booking) {
                // Only tutor or learner can schedule
                if (booking.tutor_did != caller_did and booking.learner_did != caller_did) {
                    return #err("Unauthorized: only tutor or learner can schedule");
                };

                let updated_booking : BookingSession.Booking = {
                    booking with
                    scheduled_time = ?scheduled_time;
                    status = #Confirmed;
                };

                marketplace_hashmap.bookings.put(booking_id, updated_booking);
                return #ok(updated_booking);
            };
        };
    };
};
