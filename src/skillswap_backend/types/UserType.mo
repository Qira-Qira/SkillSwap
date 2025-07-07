import Principal "mo:base/Principal";
module {
    // User identity and profile types
    public type UserId = Principal;
    public type DID = Text; // Decentralized Identifier

    public type UserRole = {
        #Learner;
        #Tutor;
        #Both;
    };

    public type UserProfile = {
        did : DID;
        principal : UserId;
        name : Text;
        bio : Text;
        skills : [Text]; // Array of skill tags
        avatar_ipfs : ?Text; // IPFS CID for avatar
        rating : Float;
        total_sessions : Nat;
        created_at : Int;
        role : UserRole;
    };
};
