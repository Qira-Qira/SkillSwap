import Int "mo:base/Int";
import Float "mo:base/Float";
import Option "mo:base/Option";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import StateToken "../../storages/StateToken";
module {
    // Mint REP tokens based on session completion and rating
    public func mint_rep_tokens(balances : StateToken.Balances, tutor_did : UserType.DID, base_amount : Nat, rating_multiplier : Float) : async ApiResponse.ApiResult<Nat> {

        // Calculate REP amount based on rating (0.5 REP per session * rating multiplier)
        let rep_amount = Int.abs(Float.toInt(Float.fromInt(base_amount) * rating_multiplier));

        let current_rep = Option.get(balances.rep_balances.get(tutor_did), 0);
        balances.rep_balances.put(tutor_did, current_rep + rep_amount);

        return #ok(rep_amount);
    };
};
 