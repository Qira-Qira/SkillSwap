import StateDao "../../storages/StateDao";
import ApiResponse "../../types/APIResponse";
import DaoGovernance "../../types/DAOGovernance";
import Time "mo:base/Time";

module {
    // Execute proposal if it passed
    public func execute_proposal(dao_hashmap : StateDao.DaoHashmap, execution_result : ApiResponse.ApiResult<()>, proposal_id : DaoGovernance.ProposalId) : async ApiResponse.ApiResult<DaoGovernance.Proposal> {
        switch (dao_hashmap.proposals.get(proposal_id)) {
            case null { return #err("Proposal not found") };
            case (?proposal) {
                // Check if voting period ended
                if (Time.now() <= proposal.voting_ends_at) {
                    return #err("Voting period is still active");
                };

                if (proposal.status != #Active) {
                    return #err("Proposal is not active");
                };

                let total_votes = proposal.votes_for + proposal.votes_against;

                // Check quorum
                if (total_votes < proposal.voting_power_required) {
                    let rejected_proposal : DaoGovernance.Proposal = {
                        proposal with status = #Rejected;
                    };
                    dao_hashmap.proposals.put(proposal_id, rejected_proposal);
                    return #ok(rejected_proposal);
                };

                // Check if proposal passed (simple majority)
                let proposal_passed = proposal.votes_for > proposal.votes_against;

                if (proposal_passed) {
                    // Execute the proposal
                    let executed_proposal : DaoGovernance.Proposal = switch (execution_result) {
                        case (#ok()) { { proposal with status = #Executed } };
                        case (#err(_)) {
                            { proposal with status = #Passed } // Passed but execution failed
                        };
                    };

                    dao_hashmap.proposals.put(proposal_id, executed_proposal);
                    return #ok(executed_proposal);
                } else {
                    let rejected_proposal : DaoGovernance.Proposal = {
                        proposal with status = #Rejected;
                    };
                    dao_hashmap.proposals.put(proposal_id, rejected_proposal);
                    return #ok(rejected_proposal);
                };
            };
        };
    };
};
