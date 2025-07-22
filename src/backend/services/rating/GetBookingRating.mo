import BookingSession "../../types/BookingSession";
import ApiResponse "../../types/APIResponse";
import RatingReputation "../../types/RatingReputation";
import StateRating "../../storages/StateRating";

module {
 public func get_booking_rating(rating : StateRating.Rating, booking_id : BookingSession.BookingId) : ApiResponse.ApiResult<RatingReputation.Rating> {
        switch (rating.ratings.get(booking_id)) {
            case (?rating_entry) { #ok(rating_entry) };
            case null { #err("Rating not found") };
        };
    };
};