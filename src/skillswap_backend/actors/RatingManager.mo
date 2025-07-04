import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Array "mo:base/Array";

import T "../types/type";

actor RatingManager {
    
    private var ratings = HashMap.HashMap<T.BookingId, T.Rating>(0, Nat.equal, Hash.hash);
    private var user_ratings = HashMap.HashMap<T.DID, [T.Rating]>(0, Text.equal, Text.hash);
    
    // Inter-canister calls
    private let user_manager : actor {
        update_user_rating: (T.DID, Float, Nat) -> async T.ApiResult<()>;
    } = actor "ufxgi-4p777-77774-qaadq-cai"; // Replace with actual UserManager canister ID
    
    private let token_manager : actor {
        mint_rep_tokens: (T.DID, Nat, Float) -> async T.ApiResult<Nat>;
    } = actor "ucwa4-rx777-77774-qaada-cai"; // Replace with actual TokenManager canister ID
    
    // Submit rating after completed session
    public func submit_rating(
        booking_id: T.BookingId,
        from_did: T.DID,
        to_did: T.DID,
        score: Nat,
        comment: Text
    ) : async T.ApiResult<T.Rating> {
        
        // Validate score range
        if (score < 1 or score > 5) {
            return #err("Rating score must be between 1 and 5");
        };
        
        // Check if rating already exists
        switch (ratings.get(booking_id)) {
            case (?existing) { return #err("Rating already submitted for this booking") };
            case null {
                let rating: T.Rating = {
                    booking_id = booking_id;
                    from_did = from_did;
                    to_did = to_did;
                    score = score;
                    comment = comment;
                    created_at = Time.now();
                };
                
                ratings.put(booking_id, rating);
                
                // Update user's rating history
                let current_ratings = Option.get(user_ratings.get(to_did), []);
                user_ratings.put(to_did, Array.append(current_ratings, [rating]));
                
                // Update user's overall rating in UserManager
                let _ = await user_manager.update_user_rating(to_did, Float.fromInt(score), 1);
                
                // Mint REP tokens for tutor based on rating
                if (score >= 4) { // Only mint REP for good ratings (4-5 stars)
                    let rating_multiplier = Float.fromInt(score) / 5.0; // 0.8 for 4 stars, 1.0 for 5 stars
                    let _ = await token_manager.mint_rep_tokens(to_did, 50, rating_multiplier); // Base 50 REP tokens
                };
                
                return #ok(rating);
            };
        };
    };
    
    // Get user's received ratings
    public query func get_user_ratings(did: T.DID) : async [T.Rating] {
        Option.get(user_ratings.get(did), []);
    };
    
    // Get specific booking rating
    public query func get_booking_rating(booking_id: T.BookingId) : async T.ApiResult<T.Rating> {
        switch (ratings.get(booking_id)) {
            case (?rating) { #ok(rating) };
            case null { #err("Rating not found") };
        };
    };
    
    // Calculate user's average rating
    public query func get_user_average_rating(did: T.DID) : async Float {
        let user_rating_list = Option.get(user_ratings.get(did), []);
        
        if (user_rating_list.size() == 0) {
            return 0.0;
        };
        
        var total_score = 0;
        for (rating in user_rating_list.vals()) {
            total_score += rating.score;
        };
        
        Float.fromInt(total_score) / Float.fromInt(user_rating_list.size());
    };
}