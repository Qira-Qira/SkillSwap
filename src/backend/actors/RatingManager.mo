import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

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
    } = actor "vizcg-th777-77774-qaaea-cai"; // Replace with actual UserManager canister ID

    private let token_manager : actor {
        mint_rep_tokens : (UserType.DID, Nat, Float) -> async ApiResponse.ApiResult<Nat>;
    } = actor "ufxgi-4p777-77774-qaadq-cai"; // Replace with actual TokenManager canister ID

    // Submit rating after completed session
    public func submit_rating(booking_id : BookingSession.BookingId, from_did : UserType.DID, to_did : UserType.DID, score : Nat, comment : Text) : async ApiResponse.ApiResult<RatingReputation.Rating> {
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
};