import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import Option "mo:base/Option";
import StateUser "../../storages/StateUser";
module {
    // Update user profile
    public func update_user_profile(
        models : StateUser.UserModel,
        caller : UserType.UserId,
        name : ?Text,
        bio : ?Text,
        skills : ?[Text],
        avatar_ipfs : ?Text,
    ) : async ApiResponse.ApiResult<UserType.UserProfile> {

        switch (models.principal_to_did.get(caller)) {
            case null { return #err("User not found") };
            case (?did) {
                switch (models.users.get(did)) {
                    case null { return #err("Profile not found") };
                    case (?current_profile) {
                        let updated_profile : UserType.UserProfile = {
                            did = current_profile.did;
                            principal = current_profile.principal;
                            name = Option.get(name, current_profile.name);
                            bio = Option.get(bio, current_profile.bio);
                            skills = Option.get(skills, current_profile.skills);
                            avatar_ipfs = switch (avatar_ipfs) {
                                case (?cid) { ?cid };
                                case null { current_profile.avatar_ipfs };
                            };
                            rating = current_profile.rating;
                            total_sessions = current_profile.total_sessions;
                            created_at = current_profile.created_at;
                            role = current_profile.role;
                        };

                        models.users.put(did, updated_profile);
                        return #ok(updated_profile);
                    };
                };
            };
        };
    };
};
