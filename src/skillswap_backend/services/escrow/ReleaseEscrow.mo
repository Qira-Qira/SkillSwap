import BookingSession "../../types/BookingSession";
import ApiResponse "../../types/APIResponse";
import EscrowType "../../types/EscrowType";
import StateEscrow "../../storages/StateEscrow";
module {
    // Release escrowed tokens to tutor after successful session
    public func release_escrow(escrow_entries : StateEscrow.EscrowEntries, result_release_swt_escrow : ApiResponse.ApiResult<()>, booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<EscrowType.EscrowEntry> {
        switch (escrow_entries.escrow_entries.get(booking_id)) {
            case null { return #err("Escrow not found") };
            case (?escrow) {
                if (escrow.status != #Locked) {
                    return #err("Escrow is not in locked state");
                };

                // Release tokens via TokenManager
                switch (result_release_swt_escrow) {
                    case (#err(msg)) {
                        return #err("Failed to release tokens: " # msg);
                    };
                    case (#ok()) {
                        let updated_escrow : EscrowType.EscrowEntry = {
                            escrow with status = #Released;
                        };

                        escrow_entries.escrow_entries.put(booking_id, updated_escrow);
                        return #ok(updated_escrow);
                    };
                };
            };
        };
    };
};
