import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";

import T "../types/type";

actor BadgeManager {
        
    // Badge state
    private stable var badge_counter: Nat = 0;
    private var badges = HashMap.HashMap<T.BadgeId, T.Badge>(0, Nat.equal, Hash.hash);
    private var user_badges = HashMap.HashMap<T.DID, [T.BadgeId]>(0, Text.equal, Text.hash);
    
    // Badge thresholds
    private let CERTIFIED_TUTOR_SESSIONS = 50;
    private let TOP_RATED_MIN_RATING = 4.5;
    private let MILESTONE_SESSIONS = [10, 25, 50, 100, 250, 500];
    
    // Inter-canister calls
    private let user_manager : actor {
        get_user_profile: (T.DID) -> async T.ApiResult<T.UserProfile>;
    } = actor "ufxgi-4p777-77774-qaadq-cai"; // Replace with actual UserManager canister ID
    
    private let rating_manager : actor {
        get_user_average_rating: (T.DID) -> async Float;
    } = actor "ulvla-h7777-77774-qaacq-cai"; // Replace with actual RatingManager canister ID
    
    // Check and mint badges for user based on achievements
    public func check_and_mint_badges(user_did: T.DID) : async T.ApiResult<[T.Badge]> {
        
        // Get user profile
        let user_result = await user_manager.get_user_profile(user_did);
        let user_profile = switch (user_result) {
            case (#ok(profile)) { profile };
            case (#err(msg)) { return #err("Failed to get user profile: " # msg) };
        };
        
        // Get user's average rating
        let avg_rating = await rating_manager.get_user_average_rating(user_did);
        
        let new_badges = Buffer.Buffer<T.Badge>(0);
        let existing_badge_ids = Option.get(user_badges.get(user_did), []);
        
        // Check for Certified Tutor badge
        if (user_profile.total_sessions >= CERTIFIED_TUTOR_SESSIONS) {
            let has_certified_badge = Array.find<T.BadgeId>(existing_badge_ids, func(id) {
                switch (badges.get(id)) {
                    case (?badge) {
                        switch (badge.badge_type) {
                            case (#CertifiedTutor(_)) { true };
                            case (_) { false };
                        };
                    };
                    case null { false };
                };
            });
            
            if (has_certified_badge == null) {
                // Mint Certified Tutor badge for primary skill
                let primary_skill = if (user_profile.skills.size() > 0) {
                    user_profile.skills[0]
                } else {
                    "General"
                };
                
                let badge = await mint_badge(
                    user_did,
                    #CertifiedTutor({ skill = primary_skill; level = 1 }),
                    "ipfs://certified-tutor-metadata"
                );
                
                switch (badge) {
                    case (#ok(b)) { new_badges.add(b) };
                    case (#err(_)) { /* continue */ };
                };
            };
        };
        
        // Check for Top Rated badge
        if (avg_rating >= TOP_RATED_MIN_RATING and user_profile.total_sessions >= 10) {
            let has_top_rated_badge = Array.find<T.BadgeId>(existing_badge_ids, func(id) {
                switch (badges.get(id)) {
                    case (?badge) {
                        switch (badge.badge_type) {
                            case (#TopRated(_)) { true };
                            case (_) { false };
                        };
                    };
                    case null { false };
                };
            });
            
            if (has_top_rated_badge == null) {
                let badge = await mint_badge(
                    user_did,
                    #TopRated({ category = "Excellence" }),
                    "ipfs://top-rated-metadata"
                );
                
                switch (badge) {
                    case (#ok(b)) { new_badges.add(b) };
                    case (#err(_)) { /* continue */ };
                };
            };
        };
        
        // Check for Milestone badges
        for (milestone in MILESTONE_SESSIONS.vals()) {
            if (user_profile.total_sessions >= milestone) {
                let has_milestone_badge = Array.find<T.BadgeId>(existing_badge_ids, func(id) {
                    switch (badges.get(id)) {
                        case (?badge) {
                            switch (badge.badge_type) {
                                case (#Milestone(m)) { m.sessions == milestone };
                                case (_) { false };
                            };
                        };
                        case null { false };
                    };
                });
                
                if (has_milestone_badge == null) {
                    let badge = await mint_badge(
                        user_did,
                        #Milestone({ sessions = milestone }),
                        "ipfs://milestone-" # Nat.toText(milestone) # "-metadata"
                    );
                    
                    switch (badge) {
                        case (#ok(b)) { new_badges.add(b) };
                        case (#err(_)) { /* continue */ };
                    };
                };
            };
        };
        
        return #ok(Buffer.toArray(new_badges));
    };
    
    // Mint a new badge NFT
    private func mint_badge(
        owner_did: T.DID,
        badge_type: T.BadgeType,
        metadata_ipfs: Text
    ) : async T.ApiResult<T.Badge> {
        
        let badge_id = badge_counter;
        badge_counter += 1;
        
        let badge: T.Badge = {
            id = badge_id;
            owner_did = owner_did;
            badge_type = badge_type;
            metadata_ipfs = metadata_ipfs;
            issued_at = Time.now();
        };
        
        badges.put(badge_id, badge);
        
        // Update user's badge collection
        let current_badges = Option.get(user_badges.get(owner_did), []);
        user_badges.put(owner_did, Array.append(current_badges, [badge_id]));
        
        return #ok(badge);
    };
    
    // Get user's badges
    public query func get_user_badges(did: T.DID) : async [T.Badge] {
        let badge_ids = Option.get(user_badges.get(did), []);
        let badge_buffer = Buffer.Buffer<T.Badge>(badge_ids.size());
        
        for (badge_id in badge_ids.vals()) {
            switch (badges.get(badge_id)) {
                case (?badge) { badge_buffer.add(badge) };
                case null { /* skip invalid badge */ };
            };
        };
        
        Buffer.toArray(badge_buffer);
    };
    
    // Get specific badge details
    public query func get_badge(badge_id: T.BadgeId) : async T.ApiResult<T.Badge> {
        switch (badges.get(badge_id)) {
            case (?badge) { #ok(badge) };
            case null { #err("Badge not found") };
        };
    };
}