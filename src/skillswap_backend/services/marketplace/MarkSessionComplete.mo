import StateMarketplace "../../storages/StateMarketplace";
import BookingSession "../../types/BookingSession";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import Time "mo:base/Time";
module {
    // Mark session as complete
    public func mark_session_complete(
        marketplace_hashmap : StateMarketplace.MarketplaceHashmap,
        booking_id : BookingSession.BookingId,
        caller_did : UserType.DID,
    ) : async ApiResponse.ApiResult<BookingSession.Booking> {

        switch (marketplace_hashmap.bookings.get(booking_id)) {
            case null { return #err("Booking not found") };
            case (?booking) {
                if (booking.tutor_did != caller_did and booking.learner_did != caller_did) {
                    return #err("Unauthorized");
                };

                let (learner_confirmed, tutor_confirmed) = if (caller_did == booking.learner_did) {
                    (true, booking.tutor_confirmed);
                } else { (booking.learner_confirmed, true) };

                let new_status = if (learner_confirmed and tutor_confirmed) {
                    #Completed;
                } else {
                    booking.status;
                };

                let completed_at = if (new_status == #Completed) {
                    ?Time.now();
                } else {
                    booking.completed_at;
                };

                let updated_booking : BookingSession.Booking = {
                    booking with
                    learner_confirmed = learner_confirmed;
                    tutor_confirmed = tutor_confirmed;
                    status = new_status;
                    completed_at = completed_at;
                };

                marketplace_hashmap.bookings.put(booking_id, updated_booking);
                return #ok(updated_booking);
            };
        };
    };
};
