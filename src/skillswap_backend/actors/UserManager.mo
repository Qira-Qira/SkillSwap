import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";

// import types
import T "../types/type";

actor UserManager {
    
    // State variables - persistent storage
    private stable var user_counter: Nat = 0;
    private var users = HashMap.HashMap<T.DID, T.UserProfile>(0, Text.equal, Text.hash);
    private var principal_to_did = HashMap.HashMap<T.UserId, T.DID>(0, Principal.equal, Principal.hash);
    
    // System upgrade hooks untuk preserve state
    system func preupgrade() {
        // Convert HashMaps to stable arrays before upgrade
    };
    
    system func postupgrade() {
        // Restore HashMaps from stable arrays after upgrade
    };
    
    // Create new user profile and DID
    public func create_user_profile(
        caller: T.UserId,
        name: Text, 
        bio: Text, 
        skills: [Text],
        role: T.UserRole
    ) : async T.ApiResult<T.UserProfile> {
        
        // Check if user already exists
        switch (principal_to_did.get(caller)) {
            case (?existing_did) {
                return #err("User already has a profile with DID: " # existing_did);
            };
            case null {
                // Generate new DID - in production, this would be more sophisticated
                let did = "did:skillswap:" # Nat.toText(user_counter);
                user_counter += 1;
                
                let profile: T.UserProfile = {
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
                users.put(did, profile);
                principal_to_did.put(caller, did);
                
                return #ok(profile);
            };
        };
    };
    
    // Get user profile by DID
    public query func get_user_profile(did: T.DID) : async T.ApiResult<T.UserProfile> {
        switch (users.get(did)) {
            case (?profile) { #ok(profile) };
            case null { #err("User profile not found") };
        };
    };
    
    // Get user's DID from their principal
    public query func get_user_did(principal: T.UserId) : async T.ApiResult<T.DID> {
        switch (principal_to_did.get(principal)) {
            case (?did) { #ok(did) };
            case null { #err("No DID found for this principal") };
        };
    };
    
    // Update user profile
    public func update_user_profile(
        caller: T.UserId,
        name: ?Text,
        bio: ?Text,
        skills: ?[Text],
        avatar_ipfs: ?Text
    ) : async T.ApiResult<T.UserProfile> {
        
        switch (principal_to_did.get(caller)) {
            case null { return #err("User not found") };
            case (?did) {
                switch (users.get(did)) {
                    case null { return #err("Profile not found") };
                    case (?current_profile) {
                        let updated_profile: T.UserProfile = {
                            did = current_profile.did;
                            principal = current_profile.principal;
                            name = Option.get(name, current_profile.name);
                            bio = Option.get(bio, current_profile.bio);
                            skills = Option.get(skills, current_profile.skills);
                            avatar_ipfs = switch(avatar_ipfs) {
                                case (?cid) { ?cid };
                                case null { current_profile.avatar_ipfs };
                            };
                            rating = current_profile.rating;
                            total_sessions = current_profile.total_sessions;
                            created_at = current_profile.created_at;
                            role = current_profile.role;
                        };
                        
                        users.put(did, updated_profile);
                        return #ok(updated_profile);
                    };
                };
            };
        };
    };
    
    // Update user rating after completed session
    public func update_user_rating(did: T.DID, new_rating: Float, sessions_increment: Nat) : async T.ApiResult<()> {
        switch (users.get(did)) {
            case null { return #err("User not found") };
            case (?current_profile) {
                let total_sessions = current_profile.total_sessions + sessions_increment;
                
                // Calculate weighted average rating
                let current_total_score = current_profile.rating * Float.fromInt(current_profile.total_sessions);
                let new_total_score = current_total_score + new_rating;
                let updated_rating = new_total_score / Float.fromInt(total_sessions);
                
                let updated_profile: T.UserProfile = {
                    current_profile with 
                    rating = updated_rating;
                    total_sessions = total_sessions;
                };
                
                users.put(did, updated_profile);
                return #ok(());
            };
        };
    };
    
    // Get all tutors (for marketplace browsing)
    public query func get_all_tutors() : async [T.UserProfile] {
        let tutor_buffer = Buffer.Buffer<T.UserProfile>(0);
        
        for ((did, profile) in users.entries()) {
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
}