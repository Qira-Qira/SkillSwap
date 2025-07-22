import UserType "../../types/UserType";
import BookingSession "../../types/BookingSession";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";

module {
    public func get_learner_bookings(marketplace_hashmap_learner_bookings : HashMap.HashMap<UserType.DID, [BookingSession.BookingId]>, marketplace_hashmap_bookings : HashMap.HashMap<BookingSession.BookingId, BookingSession.Booking>, learner_did : UserType.DID) : [BookingSession.Booking] {
        let booking_ids = Option.get(marketplace_hashmap_learner_bookings.get(learner_did), []);
        let booking_buffer = Buffer.Buffer<BookingSession.Booking>(booking_ids.size());

        for (booking_id in booking_ids.vals()) {
            switch (marketplace_hashmap_bookings.get(booking_id)) {
                case (?booking) { booking_buffer.add(booking) };
                case null { /* skip invalid booking */ };
            };
        };

        Buffer.toArray(booking_buffer);
    };
};
