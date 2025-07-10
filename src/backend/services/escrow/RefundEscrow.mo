import StateEscrow "../../storages/StateEscrow";
import ApiResponse "../../types/APIResponse";
import BookingSession "../../types/BookingSession";
import EscrowType "../../types/EscrowType";

module {
    // Refund escrowed tokens back to learner
    public func refund_escrow(escrow_entries : StateEscrow.EscrowEntries, result_refund_swt_escrow : ApiResponse.ApiResult<()>, booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<EscrowType.EscrowEntry> {
        switch (escrow_entries.escrow_entries.get(booking_id)) {
            case null { return #err("Escrow not found") };
            case (?escrow) {
                if (escrow.status != #Locked) {
                    return #err("Escrow is not in locked state");
                };

                // Refund tokens via TokenManager
                switch (result_refund_swt_escrow) {
                    case (#err(msg)) {
                        return #err("Failed to refund tokens: " # msg);
                    };
                    case (#ok()) {
                        let updated_escrow : EscrowType.EscrowEntry = {
                            escrow with status = #Refunded;
                        };

                        escrow_entries.escrow_entries.put(booking_id, updated_escrow);
                        return #ok(updated_escrow);
                    };
                };
            };
        };
    };

};