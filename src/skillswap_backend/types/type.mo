import Result "mo:base/Result";

// Core data types yang digunakan across all canisters
module Types {
    
    // User identity and profile types
    public type UserId = Principal;
    public type DID = Text; // Decentralized Identifier
    
    public type UserRole = {
        #Learner;
        #Tutor;
        #Both;
    };
    
    public type UserProfile = {
        did: DID;
        principal: UserId;
        name: Text;
        bio: Text;
        skills: [Text]; // Array of skill tags
        avatar_ipfs: ?Text; // IPFS CID for avatar
        rating: Float;
        total_sessions: Nat;
        created_at: Int;
        role: UserRole;
    };
    
    // Marketplace listing types
    public type ListingId = Nat;
    public type BookingId = Nat;
    
    public type LearningMethod = {
        #VideoCall;
        #VoiceCall;
        #Chat;
        #InPerson;
    };
    
    public type ListingStatus = {
        #Active;
        #Paused;
        #Completed;
        #Cancelled;
    };
    
    public type Listing = {
        id: ListingId;
        tutor_did: DID;
        title: Text;
        description: Text;
        skills: [Text];
        duration_minutes: Nat;
        price_swt: Nat; // Price in SkillSwap Tokens
        available_slots: Nat;
        method: LearningMethod;
        ipfs_cid: Text; // Metadata stored on IPFS
        created_at: Int;
        status: ListingStatus;
    };
    
    // Booking and session types
    public type BookingStatus = {
        #Pending;
        #Confirmed;
        #InProgress;
        #Completed;
        #Disputed;
        #Cancelled;
        #Refunded;
    };
    
    public type Booking = {
        id: BookingId;
        listing_id: ListingId;
        learner_did: DID;
        tutor_did: DID;
        amount_swt: Nat;
        scheduled_time: ?Int;
        status: BookingStatus;
        created_at: Int;
        completed_at: ?Int;
        learner_confirmed: Bool;
        tutor_confirmed: Bool;
    };
    
    // Token types
    public type TokenBalance = Nat;
    public type TokenSymbol = Text;
    
    // Rating and reputation types
    public type Rating = {
        booking_id: BookingId;
        from_did: DID;
        to_did: DID;
        score: Nat; // 1-5 stars
        comment: Text;
        created_at: Int;
    };
    
    // Badge NFT types
    public type BadgeId = Nat;
    public type BadgeType = {
        #CertifiedTutor: { skill: Text; level: Nat };
        #TopRated: { category: Text };
        #Milestone: { sessions: Nat };
        #Community: { contribution: Text };
    };
    
    public type Badge = {
        id: BadgeId;
        owner_did: DID;
        badge_type: BadgeType;
        metadata_ipfs: Text;
        issued_at: Int;
    };
    
    // DAO Governance types
    public type ProposalId = Nat;
    public type ProposalType = {
        #FeeChange: { new_fee_percent: Float };
        #NewCategory: { category: Text };
        #ArbitratorChange: { new_arbitrator: Principal };
        #General: { title: Text; description: Text };
    };
    
    public type ProposalStatus = {
        #Active;
        #Passed;
        #Rejected;
        #Executed;
    };
    
    public type Proposal = {
        id: ProposalId;
        proposer_did: DID;
        proposal_type: ProposalType;
        description: Text;
        voting_power_required: Nat;
        votes_for: Nat;
        votes_against: Nat;
        voters: [DID];
        created_at: Int;
        voting_ends_at: Int;
        status: ProposalStatus;
    };
    
    // API Response types
    public type ApiResult<T> = Result.Result<T, Text>;
}