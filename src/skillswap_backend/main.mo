import UserManager "canister:UserManager";
import Marketplace "canister:Marketplace";
import TokenManager "canister:TokenManager";
import EscrowManager "canister:EscrowManager";
import RatingManager "canister:RatingManager";
import BadgeManager "canister:BadgeManager";
import DAOGovernance "canister:DAOGovernance";

import Time "mo:base/Time";

import T "types/type";

actor SkillSwapOrchestrator {
    // Unified API endpoints that coordinate multiple canisters
    
    // Complete onboarding flow
    public func complete_onboarding(
        caller: T.UserId,
        name: Text,
        bio: Text,
        skills: [Text],
        role: T.UserRole,
        initial_swt: Nat
    ) : async T.ApiResult<T.UserProfile> {
        
        // Create user profile
        let profile_result = await UserManager.create_user_profile(caller, name, bio, skills, role);
        
        switch (profile_result) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(profile)) {
                // Initialize token balance
                let _ = await TokenManager.initialize_user_balance(profile.did, initial_swt);
                
                return #ok(profile);
            };
        };
    };
    
    // Complete booking flow with escrow
    public func complete_booking_flow(
        listing_id: T.ListingId,
        learner_did: T.DID
    ) : async T.ApiResult<(T.Booking, EscrowManager.EscrowEntry)> {
        
        // Create booking
        let booking_result = await Marketplace.create_booking(listing_id, learner_did);
        
        switch (booking_result) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(booking)) {
                // Create escrow
                let escrow_result = await EscrowManager.create_escrow(
                    booking.id,
                    booking.learner_did,
                    booking.tutor_did,
                    booking.amount_swt
                );
                
                switch (escrow_result) {
                    case (#err(msg)) { 
                        // TODO: Cancel booking if escrow fails
                        return #err("Booking created but escrow failed: " # msg);
                    };
                    case (#ok(escrow)) {
                        return #ok((booking, escrow));
                    };
                };
            };
        };
    };
    
    // Complete session completion flow
    public func complete_session_flow(
        booking_id: T.BookingId,
        caller_did: T.DID,
        rating_score: Nat,
        rating_comment: Text
    ) : async T.ApiResult<Text> {
        
        // Mark session complete
        let booking_result = await Marketplace.mark_session_complete(booking_id, caller_did);
        
        switch (booking_result) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(booking)) {
                if (booking.status == #Completed) {
                    // Release escrow
                    let _ = await EscrowManager.release_escrow(booking_id);
                    
                    // Submit rating (determine who rates whom)
                    let (from_did, to_did) = if (caller_did == booking.learner_did) {
                        (booking.learner_did, booking.tutor_did)
                    } else {
                        (booking.tutor_did, booking.learner_did)
                    };
                    
                    let _ = await RatingManager.submit_rating(
                        booking_id,
                        from_did,
                        to_did,
                        rating_score,
                        rating_comment
                    );
                    
                    // Check and mint badges for tutor
                    let _ = await BadgeManager.check_and_mint_badges(booking.tutor_did);
                    
                    return #ok("Session completed successfully with rating and potential badges awarded");
                } else {
                    return #ok("Session completion recorded, waiting for other party confirmation");
                };
            };
        };
    };
    
    // Get comprehensive user dashboard data
    public func get_user_dashboard(user_did: T.DID) : async T.ApiResult<{
        profile: T.UserProfile;
        swt_balance: T.TokenBalance;
        rep_balance: T.TokenBalance;
        listings: [T.Listing];
        bookings: [T.Booking];
        ratings: [T.Rating];
        badges: [T.Badge];
    }> {
        
        // Get user profile
        let profile_result = await UserManager.get_user_profile(user_did);
        let profile = switch (profile_result) {
            case (#ok(p)) { p };
            case (#err(msg)) { return #err("Failed to get profile: " # msg) };
        };
        
        // Get balances
        let swt_balance = await TokenManager.get_swt_balance(user_did);
        let rep_balance = await TokenManager.get_rep_balance(user_did);
        
        // Get listings (if tutor)
        let listings = await Marketplace.get_tutor_listings(user_did);
        
        // Get bookings (if learner)
        let bookings = await Marketplace.get_learner_bookings(user_did);
        
        // Get ratings
        let ratings = await RatingManager.get_user_ratings(user_did);
        
        // Get badges
        let badges = await BadgeManager.get_user_badges(user_did);
        
        let dashboard_data = {
            profile = profile;
            swt_balance = swt_balance;
            rep_balance = rep_balance;
            listings = listings;
            bookings = bookings;
            ratings = ratings;
            badges = badges;
        };
        
        return #ok(dashboard_data);
    };
    
    // System health check
    public query func system_health() : async {
        status: Text;
        timestamp: Int;
        canister_count: Nat;
    } {
        {
            status = "All systems operational";
            timestamp = Time.now();
            canister_count = 7; // Number of canisters in the system
        }
    };
}