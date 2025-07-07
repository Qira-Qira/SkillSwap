import UserType "UserType";
import BookingSession "BookingSession";
module {
     public type Rating = {
        booking_id: BookingSession.BookingId;
        from_did: UserType.DID;
        to_did: UserType.DID;
        score: Nat; // 1-5 stars
        comment: Text;
        created_at: Int;
    };
}