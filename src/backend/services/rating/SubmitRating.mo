import BookingSession "../../types/BookingSession";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";

import Option "mo:base/Option";
import Array "mo:base/Array";
import Float "mo:base/Float";
import Time "mo:base/Time";
import StateRating "../../storages/StateRating";
import RatingReputation "../../types/RatingReputation";

module {
    // Submit rating after completed session
    public func submit_rating(
        rating : StateRating.Rating,
        booking_id : BookingSession.BookingId,
        from_did : UserType.DID,
        to_did : UserType.DID,
        score : Nat,
        comment : Text,
    ) : async ApiResponse.ApiResult<RatingReputation.Rating> {

        // Validate score range
        if (score < 1 or score > 5) {
            return #err("Rating score must be between 1 and 5");
        };

        // Check if rating already exists
        switch (rating.ratings.get(booking_id)) {
            case (?existing) {
                return #err("Rating already submitted for this booking");
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

                return #ok(new_rating);
            };
        };
    };
};
