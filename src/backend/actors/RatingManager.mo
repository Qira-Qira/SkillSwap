import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Time "mo:base/Time";

import BookingSession "../types/BookingSession";
import RatingReputation "../types/RatingReputation";
import UserType "../types/UserType";
import ApiResponse "../types/APIResponse";
import StateRating "../storages/StateRating";
import SubmitRating "../services/rating/SubmitRating";

actor RatingManager {

    // Stable storage for upgrades
    private stable var ratings_stable : [(BookingSession.BookingId, RatingReputation.Rating)] = [];
    private stable var user_ratings_stable : [(UserType.DID, [RatingReputation.Rating])] = [];

    // Runtime HashMap for efficient operations
    private var rating : StateRating.Rating = {
        ratings = HashMap.HashMap<BookingSession.BookingId, RatingReputation.Rating>(0, Nat.equal, Hash.hash);
        user_ratings = HashMap.HashMap<UserType.DID, [RatingReputation.Rating]>(0, Text.equal, Text.hash);
    };

    // System functions for upgrade safety
    system func preupgrade() {
        // Convert HashMaps to Arrays for stable storage
        ratings_stable := Iter.toArray(rating.ratings.entries());
        user_ratings_stable := Iter.toArray(rating.user_ratings.entries());
    };

    system func postupgrade() {
        // Recreate ratings HashMap
        let new_ratings_map = HashMap.HashMap<BookingSession.BookingId, RatingReputation.Rating>(
            ratings_stable.size(), 
            Nat.equal, 
            Hash.hash
        );
        
        for ((booking_id, rating_entry) in ratings_stable.vals()) {
            new_ratings_map.put(booking_id, rating_entry);
        };

        // Recreate user_ratings HashMap
        let new_user_ratings_map = HashMap.HashMap<UserType.DID, [RatingReputation.Rating]>(
            user_ratings_stable.size(), 
            Text.equal, 
            Text.hash
        );
        
        for ((user_did, user_rating_list) in user_ratings_stable.vals()) {
            new_user_ratings_map.put(user_did, user_rating_list);
        };

        // Update the rating state
        rating := {
            ratings = new_ratings_map;
            user_ratings = new_user_ratings_map;
        };
        
        // Clear stable storage to save memory
        ratings_stable := [];
        user_ratings_stable := [];
    };

    // Inter-canister calls
    private let user_manager : actor {
        update_user_rating : (UserType.DID, Float, Nat) -> async ApiResponse.ApiResult<()>;
        recalculate_user_rating : (UserType.DID) -> async ApiResponse.ApiResult<()>;
    } = actor "vizcg-th777-77774-qaaea-cai"; // Replace with actual UserManager canister ID

    private let token_manager : actor {
        mint_rep_tokens : (UserType.DID, Nat, Float) -> async ApiResponse.ApiResult<Nat>;
        burn_rep_tokens : (UserType.DID, Nat) -> async ApiResponse.ApiResult<Nat>;
    } = actor "ufxgi-4p777-77774-qaadq-cai"; // Replace with actual TokenManager canister ID

    // Helper function to validate rating score
    private func validate_score(score : Nat) : Bool {
        score >= 1 and score <= 5
    };

    // Helper function to check if user can update rating (e.g., within time limit)
    private func can_update_rating(original_rating : RatingReputation.Rating) : Bool {
        // Allow updates within 24 hours (24 * 60 * 60 * 1_000_000_000 nanoseconds)
        let time_limit : Int = 24 * 60 * 60 * 1_000_000_000;
        let current_time = Time.now();
        
        // Assuming RatingReputation.Rating has a created_at field
        // You might need to adjust this based on your actual Rating type structure
        (current_time - original_rating.created_at) < time_limit
    };

    // Helper function to update user_ratings HashMap when a rating is updated
    private func update_user_ratings_map(to_did : UserType.DID, old_rating : RatingReputation.Rating, new_rating : RatingReputation.Rating) {
        switch (rating.user_ratings.get(to_did)) {
            case (?user_rating_list) {
                // Find and replace the old rating with new rating
                let updated_list = Array.map<RatingReputation.Rating, RatingReputation.Rating>(
                    user_rating_list,
                    func(r : RatingReputation.Rating) : RatingReputation.Rating {
                        if (r.booking_id == old_rating.booking_id) {
                            new_rating
                        } else {
                            r
                        }
                    }
                );
                rating.user_ratings.put(to_did, updated_list);
            };
            case null {
                // This shouldn't happen if data is consistent
                rating.user_ratings.put(to_did, [new_rating]);
            };
        };
    };

    // Submit rating after completed session
    public func submit_rating(booking_id : BookingSession.BookingId, from_did : UserType.DID, to_did : UserType.DID, score : Nat, comment : Text) : async ApiResponse.ApiResult<RatingReputation.Rating> {
        // Check if rating already exists
        switch (rating.ratings.get(booking_id)) {
            case (?existing_rating) {
                return #err("Rating already exists for this booking. Use update_rating function to modify it.");
            };
            case null {
                // Proceed with new rating
            };
        };

        if (not validate_score(score)) {
            return #err("Invalid score. Score must be between 1 and 5.");
        };

        let result = await SubmitRating.submit_rating(rating, booking_id, from_did, to_did, score, comment);
        switch (result) {
            case (#ok(_value)) {
                // Update user's overall rating in UserManager
                let _ = await user_manager.update_user_rating(to_did, Float.fromInt(score), 1);

                // Mint REP tokens for tutor based on rating
                if (score >= 4) {
                    // Only mint REP for good ratings (4-5 stars)
                    let rating_multiplier = Float.fromInt(score) / 5.0; // 0.8 for 4 stars, 1.0 for 5 stars
                    let _ = await token_manager.mint_rep_tokens(to_did, 50, rating_multiplier); // Base 50 REP tokens
                };
            };
            case (_) {};
        };
        result;
    };

    // NEW FUNCTION: Update existing rating
    public func update_rating(booking_id : BookingSession.BookingId, from_did : UserType.DID, new_score : Nat, new_comment : Text) : async ApiResponse.ApiResult<RatingReputation.Rating> {
        // Validate new score
        if (not validate_score(new_score)) {
            return #err("Invalid score. Score must be between 1 and 5.");
        };

        // Check if rating exists
        switch (rating.ratings.get(booking_id)) {
            case (?existing_rating) {
                // Verify that the user trying to update is the original rater
                if (existing_rating.from_did != from_did) {
                    return #err("Unauthorized: Only the original rater can update this rating.");
                };

                // Check if update is allowed (within time limit)
                if (not can_update_rating(existing_rating)) {
                    return #err("Rating update time limit exceeded. You can only update ratings within 24 hours.");
                };

                // Create updated rating
                let updated_rating : RatingReputation.Rating = {
                    existing_rating with
                    score = new_score;
                    comment = new_comment;
                    timestamp = Time.now(); // Update timestamp
                    is_updated = true; // Mark as updated (you might need to add this field to your Rating type)
                };

                // Update ratings HashMap
                rating.ratings.put(booking_id, updated_rating);

                // Update user_ratings HashMap
                update_user_ratings_map(existing_rating.to_did, existing_rating, updated_rating);

                // Handle REP token adjustments
                let old_score = existing_rating.score;
                let score_difference = new_score - old_score;
                
                if (score_difference != 0) {
                    // Recalculate user's overall rating
                    let _ = await user_manager.recalculate_user_rating(existing_rating.to_did);

                    // Adjust REP tokens based on score change
                    if (old_score >= 4 and new_score < 4) {
                        // User lost good rating, burn some REP tokens
                        let _ = await token_manager.burn_rep_tokens(existing_rating.to_did, 25);
                    } else if (old_score < 4 and new_score >= 4) {
                        // User gained good rating, mint REP tokens
                        let rating_multiplier = Float.fromInt(new_score) / 5.0;
                        let _ = await token_manager.mint_rep_tokens(existing_rating.to_did, 25, rating_multiplier);
                    } else if (old_score >= 4 and new_score >= 4 and score_difference > 0) {
                        // Both are good ratings but score improved
                        let rating_multiplier = Float.fromInt(score_difference) / 5.0;
                        let _ = await token_manager.mint_rep_tokens(existing_rating.to_did, 10, rating_multiplier);
                    } else if (old_score >= 4 and new_score >= 4 and score_difference < 0) {
                        // Both are good ratings but score decreased
                        let _ = await token_manager.burn_rep_tokens(existing_rating.to_did, 10);
                    };
                };

                #ok(updated_rating);
            };
            case null {
                #err("Rating not found for the specified booking.");
            };
        };
    };

    // NEW FUNCTION: Delete rating (optional, with restrictions)
    public func delete_rating(booking_id : BookingSession.BookingId, from_did : UserType.DID) : async ApiResponse.ApiResult<()> {
        switch (rating.ratings.get(booking_id)) {
            case (?existing_rating) {
                // Verify that the user trying to delete is the original rater
                if (existing_rating.from_did != from_did) {
                    return #err("Unauthorized: Only the original rater can delete this rating.");
                };

                // Check if deletion is allowed (within shorter time limit, e.g., 1 hour)
                let deletion_time_limit : Int = 1 * 60 * 60 * 1_000_000_000; // 1 hour
                let current_time = Time.now();
                if ((current_time - existing_rating.created_at) > deletion_time_limit) {
                    return #err("Rating deletion time limit exceeded. You can only delete ratings within 1 hour.");
                };

                // Remove from ratings HashMap
                rating.ratings.delete(booking_id);

                // Remove from user_ratings HashMap
                switch (rating.user_ratings.get(existing_rating.to_did)) {
                    case (?user_rating_list) {
                        let filtered_list = Array.filter<RatingReputation.Rating>(
                            user_rating_list,
                            func(r : RatingReputation.Rating) : Bool {
                                r.booking_id != booking_id
                            }
                        );
                        rating.user_ratings.put(existing_rating.to_did, filtered_list);
                    };
                    case null {
                        // This shouldn't happen if data is consistent
                    };
                };

                // Recalculate user's overall rating
                let _ = await user_manager.recalculate_user_rating(existing_rating.to_did);

                // Burn REP tokens if it was a good rating
                if (existing_rating.score >= 4) {
                    let _ = await token_manager.burn_rep_tokens(existing_rating.to_did, 50);
                };

                #ok(());
            };
            case null {
                #err("Rating not found for the specified booking.");
            };
        };
    };

    // Get user's received ratings
    public query func get_user_ratings(did : UserType.DID) : async [RatingReputation.Rating] {
        Option.get(rating.user_ratings.get(did), []);
    };

    // Get specific booking rating
    public query func get_booking_rating(booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<RatingReputation.Rating> {
        switch (rating.ratings.get(booking_id)) {
            case (?rating_entry) { #ok(rating_entry) };
            case null { #err("Rating not found") };
        };
    };

    // Calculate user's average rating
    public query func get_user_average_rating(did : UserType.DID) : async Float {
        let user_rating_list = Option.get(rating.user_ratings.get(did), []);

        if (user_rating_list.size() == 0) {
            return 0.0;
        };

        var total_score = 0;
        for (rating_entry in user_rating_list.vals()) {
            total_score += rating_entry.score;
        };

        Float.fromInt(total_score) / Float.fromInt(user_rating_list.size());
    };

    // Additional helper functions for monitoring and analytics
    public query func get_total_ratings_count() : async Nat {
        rating.ratings.size();
    };

    public query func get_user_rating_count(did : UserType.DID) : async Nat {
        let user_rating_list = Option.get(rating.user_ratings.get(did), []);
        user_rating_list.size();
    };

    // Get rating statistics for a user
    public query func get_user_rating_stats(did : UserType.DID) : async {
        total_ratings: Nat;
        average_rating: Float;
        five_star: Nat;
        four_star: Nat;
        three_star: Nat;
        two_star: Nat;
        one_star: Nat;
    } {
        let user_rating_list = Option.get(rating.user_ratings.get(did), []);
        
        if (user_rating_list.size() == 0) {
            return {
                total_ratings = 0;
                average_rating = 0.0;
                five_star = 0;
                four_star = 0;
                three_star = 0;
                two_star = 0;
                one_star = 0;
            };
        };

        var total_score = 0;
        var five_count = 0;
        var four_count = 0;
        var three_count = 0;
        var two_count = 0;
        var one_count = 0;

        for (rating_entry in user_rating_list.vals()) {
            total_score += rating_entry.score;
            switch (rating_entry.score) {
                case (5) { five_count += 1; };
                case (4) { four_count += 1; };
                case (3) { three_count += 1; };
                case (2) { two_count += 1; };
                case (1) { one_count += 1; };
                case (_) { /* Invalid rating */ };
            };
        };

        {
            total_ratings = user_rating_list.size();
            average_rating = Float.fromInt(total_score) / Float.fromInt(user_rating_list.size());
            five_star = five_count;
            four_star = four_count;
            three_star = three_count;
            two_star = two_count;
            one_star = one_count;
        };
    };

    // Get all ratings for admin purposes
    public query func get_all_ratings() : async [(BookingSession.BookingId, RatingReputation.Rating)] {
        Iter.toArray(rating.ratings.entries());
    };

    // NEW FUNCTION: Check if user can update a specific rating
    public query func can_user_update_rating(booking_id : BookingSession.BookingId, from_did : UserType.DID) : async ApiResponse.ApiResult<Bool> {
        switch (rating.ratings.get(booking_id)) {
            case (?existing_rating) {
                if (existing_rating.from_did != from_did) {
                    #ok(false);
                } else {
                    #ok(can_update_rating(existing_rating));
                };
            };
            case null {
                #err("Rating not found for the specified booking.");
            };
        };
    };

    // NEW FUNCTION: Get user's given ratings (ratings they submitted)
    public query func get_user_given_ratings(from_did : UserType.DID) : async [RatingReputation.Rating] {
        let all_ratings = Iter.toArray(rating.ratings.entries());
        let user_given_ratings = Array.mapFilter<(BookingSession.BookingId, RatingReputation.Rating), RatingReputation.Rating>(
            all_ratings,
            func((booking_id, rating_entry)) : ?RatingReputation.Rating {
                if (rating_entry.from_did == from_did) {
                    ?rating_entry
                } else {
                    null
                }
            }
        );
        user_given_ratings;
    };
};