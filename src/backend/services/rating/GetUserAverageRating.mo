import UserType "../../types/UserType";
import Option "mo:base/Option";
import Float "mo:base/Float";
import StateRating "../../storages/StateRating";

module {
     public func get_user_average_rating(rating : StateRating.Rating, did : UserType.DID) : Float {
        let user_rating_list = Option.get(rating.user_ratings.get(did), []);

        if (user_rating_list.size() == 0) {
            return 0.0;
        };

        var total_score = 0;
        for (rating_entry in user_rating_list.vals()) {
            total_score += rating_entry.score;
        };

        Float.fromInt(total_score) / Float.fromInt(user_rating_list.size());
    };
};