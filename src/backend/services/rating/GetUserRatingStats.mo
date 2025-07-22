import Option "mo:base/Option";
import Float "mo:base/Float";
import UserType "../../types/UserType";
import StateRating "../../storages/StateRating";
module {
// Get rating statistics for a user
    public func get_user_rating_stats(rating : StateRating.Rating, did : UserType.DID) : {
        total_ratings : Nat;
        average_rating : Float;
        five_star : Nat;
        four_star : Nat;
        three_star : Nat;
        two_star : Nat;
        one_star : Nat;
    } {
        let user_rating_list = Option.get(rating.user_ratings.get(did), []);

        if (user_rating_list.size() == 0) {
            return {
                total_ratings = 0;
                average_rating = 0.0;
                five_star = 0;
                four_star = 0;
                three_star = 0;
                two_star = 0;
                one_star = 0;
            };
        };

        var total_score = 0;
        var five_count = 0;
        var four_count = 0;
        var three_count = 0;
        var two_count = 0;
        var one_count = 0;

        for (rating_entry in user_rating_list.vals()) {
            total_score += rating_entry.score;
            switch (rating_entry.score) {
                case (5) { five_count += 1 };
                case (4) { four_count += 1 };
                case (3) { three_count += 1 };
                case (2) { two_count += 1 };
                case (1) { one_count += 1 };
                case (_) { /* Invalid rating */ };
            };
        };

        {
            total_ratings = user_rating_list.size();
            average_rating = Float.fromInt(total_score) / Float.fromInt(user_rating_list.size());
            five_star = five_count;
            four_star = four_count;
            three_star = three_count;
            two_star = two_count;
            one_star = one_count;
        };
    };
};