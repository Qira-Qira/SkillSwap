import UserType "../../types/UserType";
import BookingSession "../../types/BookingSession";
import ApiResponse "../../types/APIResponse";

import Int "mo:base/Int";
import Float "mo:base/Float";
import Option "mo:base/Option";
import StateToken "../../storages/StateToken";

module {
    // Release SWT from escrow to tutor (with platform fee)
    public func release_swt_escrow(platform_fee_percent : Float, balances : StateToken.Balances, tutor_did : UserType.DID, amount : Nat, booking_id : BookingSession.BookingId) : async Nat {

        // Calculate platform fee
        let fee_amount = Int.abs(Float.toInt(Float.fromInt(amount) * platform_fee_percent / 100.0));
        let tutor_amount = amount - fee_amount;

        // Transfer to tutor
        let tutor_balance = Option.get(balances.swt_balances.get(tutor_did), 0);
        balances.swt_balances.put(tutor_did, tutor_balance + tutor_amount);
        
        return fee_amount;
    };
};
