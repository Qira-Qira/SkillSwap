import BookingSession "../../types/BookingSession";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import RatingReputation "../../types/RatingReputation";

import Time "mo:base/Time";
import Array "mo:base/Array";
import StateRating "../../storages/StateRating";

module {
    public func delete_rating(
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
    ) : async ApiResponse.ApiResult<()> {
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
                                r.booking_id != booking_id;
                            },
                        );
                        rating.user_ratings.put(existing_rating.to_did, filtered_list);
                    };
                    case null {
                        // This shouldn't happen if data is consistent
                    };
                };

                // Recalculate user's overall rating
                let _ = ignore await user_manager.recalculate_user_rating(existing_rating.to_did);

                // Burn REP tokens if it was a good rating
                if (existing_rating.score >= 4) {
                    let _ = ignore await token_manager.burn_rep_tokens(existing_rating.to_did, 50);
                };

                #ok(());
            };
            case null {
                #err("Rating not found for the specified booking.");
            };
        };
    };
};
