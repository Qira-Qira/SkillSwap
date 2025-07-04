import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Float "mo:base/Float";

import T "../types/type";

actor TokenManager {
        
    // Token state
    private var swt_balances = HashMap.HashMap<T.DID, T.TokenBalance>(0, Text.equal, Text.hash);
    private var rep_balances = HashMap.HashMap<T.DID, T.TokenBalance>(0, Text.equal, Text.hash);
    
    private stable var swt_total_supply: Nat = 1_000_000_000; // 1 billion SWT initial supply  
    private stable var rep_total_supply: Nat = 0; // REP is minted based on reputation
    
    // Platform settings
    private stable var platform_fee_percent: Float = 2.0; // 2% platform fee
    private stable var platform_treasury: T.TokenBalance = 0;
    
    // Initialize user balance (for testing/onboarding)
    public func initialize_user_balance(did: T.DID, swt_amount: Nat) : async T.ApiResult<()> {
        swt_balances.put(did, swt_amount);
        return #ok(());
    };
    
    // Get SWT balance
    public query func get_swt_balance(did: T.DID) : async T.TokenBalance {
        Option.get(swt_balances.get(did), 0);
    };
    
    // Get REP balance  
    public query func get_rep_balance(did: T.DID) : async T.TokenBalance {
        Option.get(rep_balances.get(did), 0);
    };
    
    // Transfer SWT between users
    public func transfer_swt(
        from_did: T.DID,
        to_did: T.DID,
        amount: Nat
    ) : async T.ApiResult<()> {
        
        let from_balance = Option.get(swt_balances.get(from_did), 0);
        
        if (from_balance < amount) {
            return #err("Insufficient SWT balance");
        };
        
        let to_balance = Option.get(swt_balances.get(to_did), 0);
        
        swt_balances.put(from_did, from_balance - amount);
        swt_balances.put(to_did, to_balance + amount);
        
        return #ok(());
    };
    
    // Lock SWT in escrow (called by Escrow canister)
    public func lock_swt_escrow(
        user_did: T.DID,
        amount: Nat,
        booking_id: T.BookingId
    ) : async T.ApiResult<()> {
        
        let user_balance = Option.get(swt_balances.get(user_did), 0);
        
        if (user_balance < amount) {
            return #err("Insufficient SWT balance for escrow");
        };
        
        // Deduct from user balance (effectively locked)
        swt_balances.put(user_did, user_balance - amount);
        
        return #ok(());
    };
    
    // Release SWT from escrow to tutor (with platform fee)
    public func release_swt_escrow(
        tutor_did: T.DID,
        amount: Nat,
        booking_id: T.BookingId
    ) : async T.ApiResult<()> {
        
        // Calculate platform fee
        let fee_amount = Int.abs(Float.toInt(Float.fromInt(amount) * platform_fee_percent / 100.0));
        let tutor_amount = amount - fee_amount;
        
        // Transfer to tutor
        let tutor_balance = Option.get(swt_balances.get(tutor_did), 0);
        swt_balances.put(tutor_did, tutor_balance + tutor_amount);
        
        // Add fee to platform treasury
        platform_treasury += fee_amount;
        
        return #ok(());
    };
    
    // Refund SWT from escrow back to learner
    public func refund_swt_escrow(
        learner_did: T.DID,
        amount: Nat,
        booking_id: T.BookingId
    ) : async T.ApiResult<()> {
        
        let learner_balance = Option.get(swt_balances.get(learner_did), 0);
        swt_balances.put(learner_did, learner_balance + amount);
        
        return #ok(());
    };
    
    // Mint REP tokens based on session completion and rating
    public func mint_rep_tokens(
        tutor_did: T.DID,
        base_amount: Nat,
        rating_multiplier: Float
    ) : async T.ApiResult<Nat> {
        
        // Calculate REP amount based on rating (0.5 REP per session * rating multiplier)
        let rep_amount = Int.abs(Float.toInt(Float.fromInt(base_amount) * rating_multiplier));
        
        let current_rep = Option.get(rep_balances.get(tutor_did), 0);
        rep_balances.put(tutor_did, current_rep + rep_amount);
        
        rep_total_supply += rep_amount;
        
        return #ok(rep_amount);
    };
    
    // Get platform treasury balance
    public query func get_platform_treasury() : async T.TokenBalance {
        platform_treasury;
    };
    
    // Update platform fee (DAO governance function)
    public func update_platform_fee(new_fee_percent: Float) : async T.ApiResult<()> {
        if (new_fee_percent < 0.0 or new_fee_percent > 10.0) {
            return #err("Platform fee must be between 0% and 10%");
        };
        
        platform_fee_percent := new_fee_percent;
        return #ok(());
    };
}