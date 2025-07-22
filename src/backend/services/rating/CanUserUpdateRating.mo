import StateRating "../../storages/StateRating";
import CanUpdateRating "../../helper/rating/CanUpdateRating";
import BookingSession "../../types/BookingSession";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";

module {
    public func can_user_update_rating(rating : StateRating.Rating, booking_id : BookingSession.BookingId, from_did : UserType.DID) : ApiResponse.ApiResult<Bool> {
        switch (rating.ratings.get(booking_id)) {
            case (?existing_rating) {
                if (existing_rating.from_did != from_did) {
                    #ok(false);
                } else {
                    #ok(CanUpdateRating.can_update_rating(existing_rating));
                };
            };
            case null {
                #err("Rating not found for the specified booking.");
            };
        };
    };
};
