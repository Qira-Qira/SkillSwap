import UserType "../../types/UserType";
import DaoGovernance "../../types/DAOGovernance";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";

module {
    public func get_user_votes(dao_hashmap_user_votes : HashMap.HashMap<(DaoGovernance.ProposalId, UserType.DID), Bool>, user_did : UserType.DID) : [(DaoGovernance.ProposalId, Bool)] {
        let vote_buffer = Buffer.Buffer<(DaoGovernance.ProposalId, Bool)>(0);

        for (((proposal_id, voter_did), vote) in dao_hashmap_user_votes.entries()) {
            if (voter_did == user_did) {
                vote_buffer.add((proposal_id, vote));
            };
        };

        Buffer.toArray(vote_buffer);
    };
}