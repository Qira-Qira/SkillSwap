import UserType "UserType";
module {
    public type BadgeId = Nat;
    public type BadgeType = {
        #CertifiedTutor: { skill: Text; level: Nat };
        #TopRated: { category: Text };
        #Milestone: { sessions: Nat };
        #Community: { contribution: Text };
    };
    
    public type Badge = {
        id: BadgeId;
        owner_did: UserType.DID;
        badge_type: BadgeType;
        metadata_ipfs: Text;
        issued_at: Int;
    };
}