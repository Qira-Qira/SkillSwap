import UserType "../../types/UserType";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";

module {
     public func get_all_tutors(models_users : HashMap.HashMap<UserType.DID, UserType.UserProfile>) : [UserType.UserProfile] {
        let tutor_buffer = Buffer.Buffer<UserType.UserProfile>(0);

        for ((did, profile) in models_users.entries()) {
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