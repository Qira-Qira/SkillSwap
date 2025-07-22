import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import HashMap "mo:base/HashMap";

module {
    public func get_user_did(models_principal : HashMap.HashMap<UserType.UserId, UserType.DID>, principal : UserType.UserId) : ApiResponse.ApiResult<UserType.DID> {
        switch (models_principal.get(principal)) {
            case (?did) { #ok(did) };
            case null { #err("No DID found for this principal") };
        };
    };
};
