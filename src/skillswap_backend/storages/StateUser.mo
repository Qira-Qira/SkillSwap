import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Principal "mo:base/Principal";

import UserType "../types/UserType";

module {
    public type UserCounter = {
        user_counter : Nat;
    };
    
    public type UserModel = {
       users : HashMap.HashMap<UserType.DID, UserType.UserProfile>;
       principal_to_did : HashMap.HashMap<UserType.UserId, UserType.DID>;
    }; 

    public func get_user_counter(state_user : UserCounter) : Nat {
        state_user.user_counter;
    };

    public func increment_user_counter(state_user : UserCounter) : UserCounter {
        {
            user_counter = state_user.user_counter + 1;
        };
    };
};
