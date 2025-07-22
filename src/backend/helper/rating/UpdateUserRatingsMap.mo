import UserType "../../types/UserType";
import RatingReputation "../../types/RatingReputation";
import Array "mo:base/Array";
import StateRating "../../storages/StateRating";

module {
    // Helper function to update user_ratings HashMap when a rating is updated
    public func update_user_ratings_map(rating : StateRating.Rating, to_did : UserType.DID, old_rating : RatingReputation.Rating, new_rating : RatingReputation.Rating) {
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
}