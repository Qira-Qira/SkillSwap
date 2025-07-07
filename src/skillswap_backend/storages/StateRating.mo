import HashMap "mo:base/HashMap";
import BookingSession "../types/BookingSession";
import RatingReputation "../types/RatingReputation";
import UserType "../types/UserType";

module {
    public type Rating = {
        ratings : HashMap.HashMap<BookingSession.BookingId, RatingReputation.Rating>;
        user_ratings : HashMap.HashMap<UserType.DID, [RatingReputation.Rating]>;
    };
};
