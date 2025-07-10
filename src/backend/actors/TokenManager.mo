import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Float "mo:base/Float";

import UserType "../types/UserType";
import TokenType "../types/TokenType";
import ApiResponse "../types/APIResponse";
import BookingSession "../types/BookingSession";
import StateToken "../storages/StateToken";
import TransferSwt "../services/token/TransferSWT";
import LockSwtEscrow "../services/token/LockSwtEscrow";
import ReleaseSwtEscrow "../services/token/ReleaseSwtEscrow";
import UpdatePlatformFee "../services/token/UpdatePlatformFee";
import MintRepTokens "../services/token/MintRepTokens";

actor TokenManager {

    private var balances : StateToken.Balances = {
        swt_balances = HashMap.HashMap<UserType.DID, TokenType.TokenBalance>(0, Text.equal, Text.hash);
        rep_balances = HashMap.HashMap<UserType.DID, TokenType.TokenBalance>(0, Text.equal, Text.hash);
    };

    private stable var swt : StateToken.SwtTotalSupply = {
        swt_total_supply = 0;
    };

    private stable var rep : StateToken.RepTotalSupply = {
        rep_total_supply = 0;
    };

    // Platform settings
    private stable var platform_fee_percent : Float = 2.0; // 2% platform fee

    private stable var platform_treasury : StateToken.PlatformTreasury = {
        platform_teasury = 0;
    };

    // Initialize user balance (for testing/onboarding)
    public func initialize_user_balance(did : UserType.DID, swt_amount : Nat) : async ApiResponse.ApiResult<()> {
        balances.swt_balances.put(did, swt_amount);
        return #ok(());
    };

    // Get SWT balance
    public query func get_swt_balance(did : UserType.DID) : async TokenType.TokenBalance {
        Option.get(balances.swt_balances.get(did), 0);
    };

    // Get REP balance
    public query func get_rep_balance(did : UserType.DID) : async TokenType.TokenBalance {
        Option.get(balances.rep_balances.get(did), 0);
    };

    // Transfer SWT between users
    public func transfer_swt(from_did : UserType.DID, to_did : UserType.DID, amount : Nat) : async ApiResponse.ApiResult<()> {
        await TransferSwt.transfer_swt(balances, from_did, to_did, amount);
    };

    // Lock SWT in escrow (called by Escrow canister)
    public func lock_swt_escrow(user_did : UserType.DID, amount : Nat, booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<()> {
        await LockSwtEscrow.lock_swt_escrow(balances, user_did, amount, booking_id);
    };

    // Release SWT from escrow to tutor (with platform fee)
    public func release_swt_escrow(tutor_did : UserType.DID, amount : Nat, booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<()> {
        let result : Nat = await ReleaseSwtEscrow.release_swt_escrow(platform_fee_percent, balances, tutor_did, amount, booking_id);
        platform_treasury := StateToken.set_platform_treasury(platform_treasury, result);
        #ok(());
    };

    // Refund SWT from escrow back to learner
    public func refund_swt_escrow(learner_did : UserType.DID, amount : Nat, booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<()> {
        let learner_balance = Option.get(balances.swt_balances.get(learner_did), 0); 
        balances.swt_balances.put(learner_did, learner_balance + amount);
        return #ok(());
    };

    // Mint REP tokens based on session completion and rating
    public func mint_rep_tokens(tutor_did : UserType.DID, base_amount : Nat, rating_multiplier : Float) : async ApiResponse.ApiResult<Nat> {
        let result = await MintRepTokens.mint_rep_tokens(balances, tutor_did, base_amount, rating_multiplier);
        switch (result) {
            case (#ok(value)) {
                ignore StateToken.set_rep_total_supply(rep, value);
            };
            case (_) {};
        };

        result;
    };

    // Get platform treasury balance
    public query func get_platform_treasury() : async TokenType.TokenBalance {
        platform_treasury.platform_teasury;
    };

    // Update platform fee (DAO governance function)
    public func update_platform_fee(new_fee_percent : Float) : async ApiResponse.ApiResult<()> {
        let result = await UpdatePlatformFee.update_platform_fee(new_fee_percent);
        switch (result) {
            case (#ok(())) {
                platform_fee_percent := new_fee_percent;
            };
            case (_) {};
        };

        result;
    };
};
