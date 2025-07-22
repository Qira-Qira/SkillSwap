import BookingSession "../../types/BookingSession";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import RatingReputation "../../types/RatingReputation";
import StateRating "../../storages/StateRating";
import ValidateScore "../../helper/rating/ValidateScore";
import UpdateUserRatingsMap "../../helper/rating/UpdateUserRatingsMap";
import CanUpdateRating "../../helper/rating/CanUpdateRating";
import Float "mo:base/Float";
import Time "mo:base/Time";

module {
    public func update_rating(
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
        new_score : Nat,
        new_comment : Text,
    ) : async ApiResponse.ApiResult<RatingReputation.Rating> {
        // Validate new score
        if (not ValidateScore.validate_score(new_score)) {
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
                if (not CanUpdateRating.can_update_rating(existing_rating)) {
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
                UpdateUserRatingsMap.update_user_ratings_map(rating, existing_rating.to_did, existing_rating, updated_rating);

                // Handle REP token adjustments
                let old_score = existing_rating.score;
                let score_difference = new_score - old_score;

                if (score_difference != 0) {
                    // Recalculate user's overall rating
                    let _ = ignore await user_manager.recalculate_user_rating(existing_rating.to_did);

                    // Adjust REP tokens based on score change
                    if (old_score >= 4 and new_score < 4) {
                        // User lost good rating, burn some REP tokens
                        let _ = ignore await token_manager.burn_rep_tokens(existing_rating.to_did, 25);
                    } else if (old_score < 4 and new_score >= 4) {
                        // User gained good rating, mint REP tokens
                        let rating_multiplier = Float.fromInt(new_score) / 5.0;
                        let _ = ignore await token_manager.mint_rep_tokens(existing_rating.to_did, 25, rating_multiplier);
                    } else if (old_score >= 4 and new_score >= 4 and score_difference > 0) {
                        // Both are good ratings but score improved
                        let rating_multiplier = Float.fromInt(score_difference) / 5.0;
                        let _ = ignore await token_manager.mint_rep_tokens(existing_rating.to_did, 10, rating_multiplier);
                    } else if (old_score >= 4 and new_score >= 4 and score_difference < 0) {
                        // Both are good ratings but score decreased
                        let _ = ignore await token_manager.burn_rep_tokens(existing_rating.to_did, 10);
                    };
                };

                #ok(updated_rating);
            };
            case null {
                #err("Rating not found for the specified booking.");
            };
        };
    };

};
