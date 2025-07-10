import UserType "UserType";
module {
    public type ListingId = Nat;

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
        id : ListingId;
        tutor_did : UserType.DID;
        title : Text;
        description : Text;
        skills : [Text];
        duration_minutes : Nat;
        price_swt : Nat; // Price in SkillSwap Tokens
        available_slots : Nat;
        method : LearningMethod;
        ipfs_cid : Text; // Metadata stored on IPFS
        created_at : Int;
        status : ListingStatus;
    };
};
