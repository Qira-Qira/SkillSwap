import BookingSession "../../types/BookingSession";
import ApiResponse "../../types/APIResponse";
import EscrowType "../../types/EscrowType";
import StateEscrow "../../storages/StateEscrow";
import HashMap "mo:base/HashMap";
import UserType "../../types/UserType";

module {
    // Release escrowed tokens to tutor after successful session
    public func release_escrow(
        token_manager : actor {
            lock_swt_escrow : (UserType.DID, Nat, BookingSession.BookingId) -> async ApiResponse.ApiResult<()>;
            release_swt_escrow : (UserType.DID, Nat, BookingSession.BookingId) -> async ApiResponse.ApiResult<()>;
            refund_swt_escrow : (UserType.DID, Nat, BookingSession.BookingId) -> async ApiResponse.ApiResult<()>;
        },
        escrow_entries_escrow_entries : HashMap.HashMap<BookingSession.BookingId, EscrowType.EscrowEntry>,
        booking_id : BookingSession.BookingId,
    ) : async ApiResponse.ApiResult<EscrowType.EscrowEntry> {
        switch (escrow_entries_escrow_entries.get(booking_id)) {
            case null { return #err("Escrow not found") };
            case (?escrow) {
                if (escrow.status != #Locked) {
                    return #err("Escrow is not in locked state");
                };

                let result_release_swt_escrow = await token_manager.release_swt_escrow(escrow.tutor_did, escrow.amount, booking_id);

                // Release tokens via TokenManager
                switch (result_release_swt_escrow) {
                    case (#err(msg)) {
                        return #err("Failed to release tokens: " # msg);
                    };
                    case (#ok()) {
                        let updated_escrow : EscrowType.EscrowEntry = {
                            escrow with status = #Released;
                        };

                        escrow_entries_escrow_entries.put(booking_id, updated_escrow);
                        return #ok(updated_escrow);
                    };
                };
            };
        };
    };
};
