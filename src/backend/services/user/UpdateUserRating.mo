import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import Float "mo:base/Float";
import StateUser "../../storages/StateUser";

module {
// Update user rating after completed session
    public func update_user_rating(models : StateUser.UserModel, did : UserType.DID, new_rating : Float, sessions_increment : Nat) : async ApiResponse.ApiResult<()> {
        switch (models.users.get(did)) {
            case null { return #err("User not found") };
            case (?current_profile) {
                let total_sessions = current_profile.total_sessions + sessions_increment;

                // Calculate weighted average rating
                let current_total_score = current_profile.rating * Float.fromInt(current_profile.total_sessions);
                let new_total_score = current_total_score + new_rating;
                let updated_rating = new_total_score / Float.fromInt(total_sessions);

                let updated_profile : UserType.UserProfile = {
                    current_profile with
                    rating = updated_rating;
                    total_sessions = total_sessions;
                };

                models.users.put(did, updated_profile);
                return #ok(());
            };
        };
    };

};