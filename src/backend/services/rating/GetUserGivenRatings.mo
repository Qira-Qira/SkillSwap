import StateRating "../../storages/StateRating";
import UserType "../../types/UserType";
import RatingReputation "../../types/RatingReputation";
import BookingSession "../../types/BookingSession";

import Iter "mo:base/Iter";
import Array "mo:base/Array";

module {
    public func get_user_given_ratings(rating : StateRating.Rating, from_did : UserType.DID) : [RatingReputation.Rating] {
        let all_ratings = Iter.toArray(rating.ratings.entries());
        let user_given_ratings = Array.mapFilter<(BookingSession.BookingId, RatingReputation.Rating), RatingReputation.Rating>(
            all_ratings,
            func((booking_id, rating_entry)) : ?RatingReputation.Rating {
                if (rating_entry.from_did == from_did) {
                    ?rating_entry;
                } else {
                    null;
                };
            },
        );
        user_given_ratings;
    };
};
