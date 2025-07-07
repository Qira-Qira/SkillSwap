import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

// import types
import UserType "../types/UserType";
import ApiResponse "../types/APIResponse";
import StateUser "../storages/StateUser";
import CreateUser "../services/user/CreateUser";
import UpdateProfile "../services/user/UpdateProfile";
import UpdateUserRating "../services/user/UpdateUserRating";

actor UserManager {

    // State variables - persistent storage
    private stable var state : StateUser.UserCounter = {
        user_counter = 0;
    };

    // Stable arrays to persist data during upgrades
    private stable var stable_users : [(UserType.DID, UserType.UserProfile)] = [];
    private stable var stable_principal_to_did : [(UserType.UserId, UserType.DID)] = [];

    private var models : StateUser.UserModel = {
        users = HashMap.HashMap<UserType.DID, UserType.UserProfile>(0, Text.equal, Text.hash);
        principal_to_did = HashMap.HashMap<UserType.UserId, UserType.DID>(0, Principal.equal, Principal.hash);
    };

    // System upgrade hooks untuk preserve state
    system func preupgrade() {
        // Convert HashMaps to stable arrays before upgrade
        stable_users := Iter.toArray(models.users.entries());
        stable_principal_to_did := Iter.toArray(models.principal_to_did.entries());
    };

    system func postupgrade() {
        let old_principal_to_did = models.principal_to_did;
        // Restore HashMaps from stable arrays after upgrade
        models := {
            users = HashMap.fromIter<UserType.DID, UserType.UserProfile>(
                stable_users.vals(),
                stable_users.size(),
                Text.equal,
                Text.hash,
            );
            principal_to_did = old_principal_to_did;
        };

        let old_users = models.users;

        models := {
            users = old_users;
            principal_to_did = HashMap.fromIter<UserType.UserId, UserType.DID>(
                stable_principal_to_did.vals(),
                stable_principal_to_did.size(),
                Principal.equal,
                Principal.hash,
            );
        };

        // Clear stable arrays to save memory
        stable_users := [];
        stable_principal_to_did := [];
    };

    // Initialize HashMaps on first deployment
    private func init_hashmaps() {
        if (models.users.size() == 0 and stable_users.size() > 0) {
            let old_principal_to_did = models.principal_to_did;
            models := {
                users = HashMap.fromIter<UserType.DID, UserType.UserProfile>(
                    stable_users.vals(),
                    stable_users.size(),
                    Text.equal,
                    Text.hash,
                );
                principal_to_did = old_principal_to_did;
            };
        };

        if (models.principal_to_did.size() == 0 and stable_principal_to_did.size() > 0) {
            let old_users = models.users;
            models := {
                users = old_users;
                principal_to_did = HashMap.fromIter<UserType.UserId, UserType.DID>(
                    stable_principal_to_did.vals(),
                    stable_principal_to_did.size(),
                    Principal.equal,
                    Principal.hash,
                );
            };
        };
    };

    // Call init on actor creation
    init_hashmaps();

    // Create new user profile and DID
    public func create_user_profile(caller : UserType.UserId, name : Text, bio : Text, skills : [Text], role : UserType.UserRole) : async ApiResponse.ApiResult<UserType.UserProfile> {
        let did_user = StateUser.get_user_counter(state);
        let result = await CreateUser.create_user_profile(did_user, models, caller, name, bio, skills, role);
        switch (result) {
            case (#ok(_profile)) {
                state := StateUser.increment_user_counter(state);
            };
            case (_) {};
        };
        result;
    };

    // Get user profile by DID
    public query func get_user_profile(did : UserType.DID) : async ApiResponse.ApiResult<UserType.UserProfile> {
        switch (models.users.get(did)) {
            case (?profile) { #ok(profile) };
            case null { #err("User profile not found") };
        };
    };

    // Get user's DID from their principal
    public query func get_user_did(principal : UserType.UserId) : async ApiResponse.ApiResult<UserType.DID> {
        switch (models.principal_to_did.get(principal)) {
            case (?did) { #ok(did) };
            case null { #err("No DID found for this principal") };
        };
    };

    // Update user profile
    public func update_user_profile(caller : UserType.UserId, name : ?Text, bio : ?Text, skills : ?[Text], avatar_ipfs : ?Text) : async ApiResponse.ApiResult<UserType.UserProfile> {
        await UpdateProfile.update_user_profile(models, caller, name, bio, skills, avatar_ipfs);
    };

    // Update user rating after completed session
    public func update_user_rating(did : UserType.DID, new_rating : Float, sessions_increment : Nat) : async ApiResponse.ApiResult<()> {
        await UpdateUserRating.update_user_rating(models, did, new_rating, sessions_increment);
    };

    // Get all tutors (for marketplace browsing)
    public query func get_all_tutors() : async [UserType.UserProfile] {
        let tutor_buffer = Buffer.Buffer<UserType.UserProfile>(0);

        for ((did, profile) in models.users.entries()) {
            switch (profile.role) {
                case (#Tutor or #Both) {
                    tutor_buffer.add(profile);
                };
                case (#Learner) {
                    // Skip learner-only profiles
                };
            };
        };

        Buffer.toArray(tutor_buffer);
    };
};
