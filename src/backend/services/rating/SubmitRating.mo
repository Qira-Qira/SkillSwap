import BookingSession "../../types/BookingSession";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";

import Option "mo:base/Option";
import Array "mo:base/Array";
import Float "mo:base/Float";
import Time "mo:base/Time";
import StateRating "../../storages/StateRating";
import RatingReputation "../../types/RatingReputation";
import ValidateScore "../../helper/rating/ValidateScore";

module {
    // Submit rating after completed session
    public func submit_rating(
        user_manager : actor {
            update_user_rating : (UserType.DID, Float, Nat) -> async ApiResponse.ApiResult<()>;
            recalculate_user_rating : (UserType.DID) -> async ApiResponse.ApiResult<()>;
        },
        token_manager : actor {
            mint_rep_tokens : (UserType.DID, Nat, Float) -> async ApiResponse.ApiResult<Nat>;
            burn_rep_tokens : (UserType.DID, Nat) -> async ApiResponse.ApiResult<Nat>;
        },
        rating : StateRating.Rating,
        booking_id : BookingSession.BookingId,
        from_did : UserType.DID,
        to_did : UserType.DID,
        score : Nat,
        comment : Text,
    ) : async ApiResponse.ApiResult<RatingReputation.Rating> {

        if (not ValidateScore.validate_score(score)) {
            return #err("Invalid score. Score must be between 1 and 5.");
        };

        // Check if rating already exists
        switch (rating.ratings.get(booking_id)) {
            case (?existing) {
                return #err("Rating already exists for this booking. Use update_rating function to modify it.");
            };
            case null {
                let new_rating : RatingReputation.Rating = {
                    booking_id = booking_id;
                    from_did = from_did;
                    to_did = to_did;
                    score = score;
                    comment = comment;
                    created_at = Time.now();
                };

                rating.ratings.put(booking_id, new_rating);

                // Update user's rating history
                let current_ratings = Option.get(rating.user_ratings.get(to_did), []);
                rating.user_ratings.put(to_did, Array.append(current_ratings, [new_rating]));

                // Update user's overall rating in UserManager
                let _ = ignore await user_manager.update_user_rating(to_did, Float.fromInt(score), 1);

                // Mint REP tokens for tutor based on rating
                if (score >= 4) {
                    // Only mint REP for good ratings (4-5 stars)
                    let rating_multiplier = Float.fromInt(score) / 5.0; // 0.8 for 4 stars, 1.0 for 5 stars
                    let _ = ignore await token_manager.mint_rep_tokens(to_did, 50, rating_multiplier); // Base 50 REP tokens
                };

                return #ok(new_rating);
            };
        };
    };
};
