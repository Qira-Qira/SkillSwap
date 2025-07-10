import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import Option "mo:base/Option";
import StateToken "../../storages/StateToken";

module {
    // Transfer SWT between users
    public func transfer_swt(balances : StateToken.Balances, from_did : UserType.DID, to_did : UserType.DID, amount : Nat) : async ApiResponse.ApiResult<()> {

        let from_balance = Option.get(balances.swt_balances.get(from_did), 0);

        if (from_balance < amount) {
            return #err("Insufficient SWT balance");
        };

        let to_balance = Option.get(balances.swt_balances.get(to_did), 0);

        balances.swt_balances.put(from_did, from_balance - amount);
        balances.swt_balances.put(to_did, to_balance + amount);

        return #ok(());
    };

};
