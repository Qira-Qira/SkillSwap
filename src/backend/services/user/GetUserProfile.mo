import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import HashMap "mo:base/HashMap";

module {
    public func get_user_profile(models_users : HashMap.HashMap<UserType.DID, UserType.UserProfile>, did : UserType.DID) : ApiResponse.ApiResult<UserType.UserProfile> {
        switch (models_users.get(did)) {
            case (?profile) { #ok(profile) };
            case null { #err("User profile not found") };
        };
    };
};
