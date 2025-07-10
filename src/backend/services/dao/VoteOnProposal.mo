import StateDao "../../storages/StateDao";
import TokenType "../../types/TokenType";
import DaoGovernance "../../types/DAOGovernance";
import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import Time "mo:base/Time";
import Array "mo:base/Array";

module {
    // Vote on a proposal
    public func vote_on_proposal(
        voting_power : TokenType.TokenBalance,
        dao_hashmap : StateDao.DaoHashmap,
        proposal_id : DaoGovernance.ProposalId,
        voter_did : UserType.DID,
        vote_for : Bool,
    ) : async ApiResponse.ApiResult<DaoGovernance.Proposal> {

        // Get voter's REP balance (voting power)
        if (voting_power == 0) {
            return #err("No voting power (REP tokens required)");
        };

        // Get proposal
        switch (dao_hashmap.proposals.get(proposal_id)) {
            case null { return #err("Proposal not found") };
            case (?proposal) {
                // Check if voting is still active
                if (Time.now() > proposal.voting_ends_at) {
                    return #err("Voting period has ended");
                };

                if (proposal.status != #Active) {
                    return #err("Proposal is not active");
                };

                // Check if user already voted
                switch (dao_hashmap.user_votes.get((proposal_id, voter_did))) {
                    case (?_) {
                        return #err("User has already voted on this proposal");
                    };
                    case null {
                        // Record the vote
                        dao_hashmap.user_votes.put((proposal_id, voter_did), vote_for);

                        // Update vote counts
                        let updated_proposal : DaoGovernance.Proposal = if (vote_for) {
                            {
                                proposal with
                                votes_for = proposal.votes_for + voting_power;
                                voters = Array.append(proposal.voters, [voter_did]);
                            };
                        } else {
                            {
                                proposal with
                                votes_against = proposal.votes_against + voting_power;
                                voters = Array.append(proposal.voters, [voter_did]);
                            };
                        };

                        dao_hashmap.proposals.put(proposal_id, updated_proposal);
                        return #ok(updated_proposal);
                    };
                };
            };
        };
    };
};
