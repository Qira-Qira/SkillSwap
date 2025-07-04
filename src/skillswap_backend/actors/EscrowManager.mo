import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";

import T "../types/type";

actor EscrowManager {
        
    // Escrow state
    public type EscrowStatus = {
        #Locked;
        #Released;
        #Refunded;
        #Disputed;
    };
    
    public type EscrowEntry = {
        booking_id: T.BookingId;
        learner_did: T.DID;
        tutor_did: T.DID;
        amount: Nat;
        status: EscrowStatus;
        created_at: Int;
        auto_release_at: Int;
    };
    
    private var escrow_entries = HashMap.HashMap<T.BookingId, EscrowEntry>(0, Nat.equal, Hash.hash);
    
    // Inter-canister calls to Token Manager
    private let token_manager : actor {
        lock_swt_escrow: (T.DID, Nat, T.BookingId) -> async T.ApiResult<()>;
        release_swt_escrow: (T.DID, Nat, T.BookingId) -> async T.ApiResult<()>;
        refund_swt_escrow: (T.DID, Nat, T.BookingId) -> async T.ApiResult<()>;
    } = actor "ucwa4-rx777-77774-qaada-cai"; // Replace with actual TokenManager canister ID
    
    // Lock tokens in escrow for a booking
    public func create_escrow(
        booking_id: T.BookingId,
        learner_did: T.DID,
        tutor_did: T.DID,
        amount: Nat
    ) : async T.ApiResult<EscrowEntry> {
        
        // Check if escrow already exists
        switch (escrow_entries.get(booking_id)) {
            case (?existing) { return #err("Escrow already exists for this booking") };
            case null {
                // Lock tokens via TokenManager
                switch (await token_manager.lock_swt_escrow(learner_did, amount, booking_id)) {
                    case (#err(msg)) { return #err("Failed to lock tokens: " # msg) };
                    case (#ok()) {
                        let auto_release_time = Time.now() + (48 * 60 * 60 * 1_000_000_000); // 48 hours in nanoseconds
                        
                        let escrow_entry: EscrowEntry = {
                            booking_id = booking_id;
                            learner_did = learner_did;
                            tutor_did = tutor_did;
                            amount = amount;
                            status = #Locked;
                            created_at = Time.now();
                            auto_release_at = auto_release_time;
                        };
                        
                        escrow_entries.put(booking_id, escrow_entry);
                        return #ok(escrow_entry);
                    };
                };
            };
        };
    };
    
    // Release escrowed tokens to tutor after successful session
    public func release_escrow(booking_id: T.BookingId) : async T.ApiResult<EscrowEntry> {
        switch (escrow_entries.get(booking_id)) {
            case null { return #err("Escrow not found") };
            case (?escrow) {
                if (escrow.status != #Locked) {
                    return #err("Escrow is not in locked state");
                };
                
                // Release tokens via TokenManager
                switch (await token_manager.release_swt_escrow(escrow.tutor_did, escrow.amount, booking_id)) {
                    case (#err(msg)) { return #err("Failed to release tokens: " # msg) };
                    case (#ok()) {
                        let updated_escrow: EscrowEntry = {
                            escrow with status = #Released;
                        };
                        
                        escrow_entries.put(booking_id, updated_escrow);
                        return #ok(updated_escrow);
                    };
                };
            };
        };
    };
    
    // Refund escrowed tokens back to learner
    public func refund_escrow(booking_id: T.BookingId) : async T.ApiResult<EscrowEntry> {
        switch (escrow_entries.get(booking_id)) {
            case null { return #err("Escrow not found") };
            case (?escrow) {
                if (escrow.status != #Locked) {
                    return #err("Escrow is not in locked state");
                };
                
                // Refund tokens via TokenManager
                switch (await token_manager.refund_swt_escrow(escrow.learner_did, escrow.amount, booking_id)) {
                    case (#err(msg)) { return #err("Failed to refund tokens: " # msg) };
                    case (#ok()) {
                        let updated_escrow: EscrowEntry = {
                            escrow with status = #Refunded;
                        };
                        
                        escrow_entries.put(booking_id, updated_escrow);
                        return #ok(updated_escrow);
                    };
                };
            };
        };
    };
    
    // Auto-release escrow after timeout (called by timer or manually)
    public func check_auto_release() : async [T.BookingId] {
        let current_time = Time.now();
        let released_bookings = Buffer.Buffer<T.BookingId>(0);
        
        for ((booking_id, escrow) in escrow_entries.entries()) {
            if (escrow.status == #Locked and current_time >= escrow.auto_release_at) {
                // Auto-release to tutor after timeout
                switch (await release_escrow(booking_id)) {
                    case (#ok(_)) { released_bookings.add(booking_id) };
                    case (#err(_)) { /* Log error but continue */ };
                };
            };
        };
        
        Buffer.toArray(released_bookings);
    };
    
    // Get escrow status
    public query func get_escrow_status(booking_id: T.BookingId) : async T.ApiResult<EscrowEntry> {
        switch (escrow_entries.get(booking_id)) {
            case (?escrow) { #ok(escrow) };
            case null { #err("Escrow not found") };
        };
    };
}