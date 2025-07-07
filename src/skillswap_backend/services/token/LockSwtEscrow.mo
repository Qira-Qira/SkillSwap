import UserType "../../types/UserType";
import BookingSession "../../types/BookingSession";
import ApiResponse "../../types/APIResponse";
import Option "mo:base/Option";
import StateToken "../../storages/StateToken";

module {
    // Lock SWT in escrow (called by Escrow canister)
    public func lock_swt_escrow(balances : StateToken.Balances, user_did : UserType.DID, amount : Nat, booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<()> {

        let user_balance = Option.get(balances.swt_balances.get(user_did), 0);

        if (user_balance < amount) {
            return #err("Insufficient SWT balance for escrow");
        };

        // Deduct from user balance (effectively locked)
        balances.swt_balances.put(user_did, user_balance - amount);

        return #ok(());
    };

};
