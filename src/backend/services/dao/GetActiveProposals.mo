import DaoGovernance "../../types/DAOGovernance";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Time "mo:base/Time";

module {
    public func get_active_proposals(dao_hashmap_proposals : HashMap.HashMap<DaoGovernance.ProposalId, DaoGovernance.Proposal>) : [DaoGovernance.Proposal] {
        let proposal_buffer = Buffer.Buffer<DaoGovernance.Proposal>(0);

        for ((id, proposal) in dao_hashmap_proposals.entries()) {
            if (proposal.status == #Active and Time.now() <= proposal.voting_ends_at) {
                proposal_buffer.add(proposal);
            };
        };

        Buffer.toArray(proposal_buffer);
    };

};