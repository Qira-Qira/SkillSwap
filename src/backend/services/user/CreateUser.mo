import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import StateUser "../../storages/StateUser";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
module {
    // Create new user profile and DID
    public func create_user_profile(
        did_user : Nat,
        models : StateUser.UserModel,
        caller : UserType.UserId,
        name : Text,
        bio : Text,
        skills : [Text],
        role : UserType.UserRole,
    ) : async ApiResponse.ApiResult<UserType.UserProfile> {

        // Check if user already exists
        switch (models.principal_to_did.get(caller)) {
            case (?existing_did) {
                return #err("User already has a profile with DID: " # existing_did);
            };
            case null {
                // Generate new DID - in production, this would be more sophisticated
                let did = "did:skillswap:" # Nat.toText(did_user);

                let profile : UserType.UserProfile = {
                    did = did;
                    principal = caller;
                    name = name;
                    bio = bio;
                    skills = skills;
                    avatar_ipfs = null;
                    rating = 0.0;
                    total_sessions = 0;
                    created_at = Time.now();
                    role = role;
                };

                // Store the profile and mapping
                models.users.put(did, profile);
                models.principal_to_did.put(caller, did);

                return #ok(profile);
            };
        };
    };

};
