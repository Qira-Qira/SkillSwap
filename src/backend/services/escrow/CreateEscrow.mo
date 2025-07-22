import BookingSession "../../types/BookingSession";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import EscrowType "../../types/EscrowType";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
import StateEscrow "../../storages/StateEscrow";

module {
    // Lock tokens in escrow for a booking
    public func create_escrow(
        token_manager : actor {
            lock_swt_escrow : (UserType.DID, Nat, BookingSession.BookingId) -> async ApiResponse.ApiResult<()>;
            release_swt_escrow : (UserType.DID, Nat, BookingSession.BookingId) -> async ApiResponse.ApiResult<()>;
            refund_swt_escrow : (UserType.DID, Nat, BookingSession.BookingId) -> async ApiResponse.ApiResult<()>;
        },
        escrow_entries_escrow_entries : HashMap.HashMap<BookingSession.BookingId, EscrowType.EscrowEntry>,
        booking_id : BookingSession.BookingId,
        learner_did : UserType.DID,
        tutor_did : UserType.DID,
        amount : Nat,
    ) : async ApiResponse.ApiResult<EscrowType.EscrowEntry> {
        // Check if escrow already exists
        switch (escrow_entries_escrow_entries.get(booking_id)) {
            case (?existing) {
                return #err("Escrow already exists for this booking");
            };
            case null {
                let result_lock_swt_escrow = await token_manager.lock_swt_escrow(learner_did, amount, booking_id);

                // Lock tokens via TokenManager
                switch (result_lock_swt_escrow) {
                    case (#err(msg)) {
                        return #err("Failed to lock tokens: " # msg);
                    };
                    case (#ok()) {
                        let auto_release_time = Time.now() + (48 * 60 * 60 * 1_000_000_000); // 48 hours in nanoseconds

                        let escrow_entry : EscrowType.EscrowEntry = {
                            booking_id = booking_id;
                            learner_did = learner_did;
                            tutor_did = tutor_did;
                            amount = amount;
                            status = #Locked;
                            created_at = Time.now();
                            auto_release_at = auto_release_time;
                        };

                        escrow_entries_escrow_entries.put(booking_id, escrow_entry);
                        return #ok(escrow_entry);
                    };
                };
            };
        };
    };
};
