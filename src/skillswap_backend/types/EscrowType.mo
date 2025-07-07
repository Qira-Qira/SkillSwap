import BookingSession "BookingSession";
import UserType "UserType";

module {
     // Escrow state
    public type EscrowStatus = {
        #Locked;
        #Released;
        #Refunded;
        #Disputed;
    };
    
    public type EscrowEntry = {
        booking_id: BookingSession.BookingId;
        learner_did: UserType.DID;
        tutor_did: UserType.DID;
        amount: Nat;
        status: EscrowStatus;
        created_at: Int;
        auto_release_at: Int;
    };
}