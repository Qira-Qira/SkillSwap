import Principal "mo:base/Principal";
import UserType "UserType";

module {
    public type ProposalId = Nat;
    public type ProposalType = {
        #FeeChange : { new_fee_percent : Float };
        #NewCategory : { category : Text };
        #ArbitratorChange : { new_arbitrator : Principal };
        #General : { title : Text; description : Text };
    };

    public type ProposalStatus = {
        #Active;
        #Passed;
        #Rejected;
        #Executed;
    };

    public type Proposal = {
        id : ProposalId;
        proposer_did : UserType.DID;
        proposal_type : ProposalType;
        description : Text;
        voting_power_required : Nat;
        votes_for : Nat;
        votes_against : Nat;
        voters : [UserType.DID];
        created_at : Int;
        voting_ends_at : Int;
        status : ProposalStatus;
    };
};
