import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

import BookingSession "../types/BookingSession";
import UserType "../types/UserType";
import ApiResponse "../types/APIResponse";
import EscrowType "../types/EscrowType";
import StateEscrow "../storages/StateEscrow";
import CreateEscrow "../services/escrow/CreateEscrow";
import ReleaseEscrow "../services/escrow/ReleaseEscrow";
import RefundEscrow "../services/escrow/RefundEscrow";

actor EscrowManager {

    // Stable storage for upgrades
    private stable var escrow_entries_stable : [(BookingSession.BookingId, EscrowType.EscrowEntry)] = [];
    
    // Runtime HashMap for efficient operations
    private var escrow_entries : StateEscrow.EscrowEntries = {
        escrow_entries = HashMap.HashMap<BookingSession.BookingId, EscrowType.EscrowEntry>(0, Nat.equal, Hash.hash);
    };

    // Initialize HashMap from stable storage on startup
    system func preupgrade() {
        escrow_entries_stable := Iter.toArray(escrow_entries.escrow_entries.entries());
    };

    system func postupgrade() {
        let new_map = HashMap.HashMap<BookingSession.BookingId, EscrowType.EscrowEntry>(
            escrow_entries_stable.size(), 
            Nat.equal, 
            Hash.hash
        );
        
        for ((booking_id, escrow_entry) in escrow_entries_stable.vals()) {
            new_map.put(booking_id, escrow_entry);
        };
        
        escrow_entries := {
            escrow_entries = new_map;
        };
        
        escrow_entries_stable := [];
    };

    // Inter-canister calls to Token Manager
    private let token_manager : actor {
        lock_swt_escrow : (UserType.DID, Nat, BookingSession.BookingId) -> async ApiResponse.ApiResult<()>;
        release_swt_escrow : (UserType.DID, Nat, BookingSession.BookingId) -> async ApiResponse.ApiResult<()>;
        refund_swt_escrow : (UserType.DID, Nat, BookingSession.BookingId) -> async ApiResponse.ApiResult<()>;
    } = actor "ufxgi-4p777-77774-qaadq-cai"; // Replace with actual TokenManager canister ID

    // Lock tokens in escrow for a booking
    public func create_escrow(booking_id : BookingSession.BookingId, learner_did : UserType.DID, tutor_did : UserType.DID, amount : Nat) : async ApiResponse.ApiResult<EscrowType.EscrowEntry> {
        let result_lock_swt_escrow = await token_manager.lock_swt_escrow(learner_did, amount, booking_id);
        await CreateEscrow.create_escrow(result_lock_swt_escrow, escrow_entries, booking_id, learner_did, tutor_did, amount);
    };

    // Release escrowed tokens to tutor after successful session
    public func release_escrow(booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<EscrowType.EscrowEntry> {
        switch (escrow_entries.escrow_entries.get(booking_id)) {
            case (?escrow) {
                let result_release_swt_escrow = await token_manager.release_swt_escrow(escrow.tutor_did, escrow.amount, booking_id);
                await ReleaseEscrow.release_escrow(escrow_entries, result_release_swt_escrow, booking_id);
            };
            case null {
                return #err("Escrow not found");
            };
        };
    };

    // Refund escrowed tokens back to learner
    public func refund_escrow(booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<EscrowType.EscrowEntry> {
        switch (escrow_entries.escrow_entries.get(booking_id)) {
            case (?escrow) {
                let result_refund_swt_escrow = await token_manager.refund_swt_escrow(escrow.learner_did, escrow.amount, booking_id);
                await RefundEscrow.refund_escrow(escrow_entries, result_refund_swt_escrow, booking_id);
            };
            case (null) {
                return #err("Escrow not found");
            };
        };
    };

    // Auto-release escrow after timeout (called by timer or manually)
    public func check_auto_release() : async [BookingSession.BookingId] {
        let current_time = Time.now();
        let released_bookings = Buffer.Buffer<BookingSession.BookingId>(0);
        for ((booking_id, escrow) in escrow_entries.escrow_entries.entries()) {
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
    public query func get_escrow_status(booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<EscrowType.EscrowEntry> {
        switch (escrow_entries.escrow_entries.get(booking_id)) {
            case (?escrow) { #ok(escrow) };
            case null { #err("Escrow not found") };
        };
    };

    // Additional helper functions for monitoring
    public query func get_all_escrows() : async [(BookingSession.BookingId, EscrowType.EscrowEntry)] {
        Iter.toArray(escrow_entries.escrow_entries.entries());
    };

    public query func get_escrow_count() : async Nat {
        escrow_entries.escrow_entries.size();
    };
};