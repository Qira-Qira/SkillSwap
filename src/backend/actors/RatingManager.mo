import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Float "mo:base/Float";


import BookingSession "../types/BookingSession";
import RatingReputation "../types/RatingReputation";
import UserType "../types/UserType";
import ApiResponse "../types/APIResponse";
import StateRating "../storages/StateRating";
import SubmitRating "../services/rating/SubmitRating";

actor RatingManager {

    private var rating : StateRating.Rating = {
        ratings = HashMap.HashMap<BookingSession.BookingId, RatingReputation.Rating>(0, Nat.equal, Hash.hash);
        user_ratings = HashMap.HashMap<UserType.DID, [RatingReputation.Rating]>(0, Text.equal, Text.hash);
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
            case (?rating) { #ok(rating) };
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
        for (rating in user_rating_list.vals()) {
            total_score += rating.score;
        };

        Float.fromInt(total_score) / Float.fromInt(user_rating_list.size());
    };
};
