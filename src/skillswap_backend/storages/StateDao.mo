import HashMap "mo:base/HashMap";
import DaoGovernance "../types/DAOGovernance";
import UserType "../types/UserType";
module {
    // DAO state
    public type ProposalCounter = {
        proposal_counter : Nat;
    };

    public func set_proposal_counter(proposal_counter : ProposalCounter) : ProposalCounter {
        {
            proposal_counter = proposal_counter.proposal_counter + 1;
        };
    };

    public type DaoHashmap = {
        proposals : HashMap.HashMap<DaoGovernance.ProposalId, DaoGovernance.Proposal>;
        user_votes : HashMap.HashMap<(DaoGovernance.ProposalId, UserType.DID), Bool>;
    };
};
