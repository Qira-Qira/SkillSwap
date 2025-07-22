import DaoGovernance "../../types/DAOGovernance";
import ApiResponse "../../types/APIResponse";
import HashMap "mo:base/HashMap";

module {
 public func get_proposal(dao_hashmap_proposals : HashMap.HashMap<DaoGovernance.ProposalId, DaoGovernance.Proposal>, proposal_id : DaoGovernance.ProposalId) : ApiResponse.ApiResult<DaoGovernance.Proposal> {
        switch (dao_hashmap_proposals.get(proposal_id)) {
            case (?proposal) { #ok(proposal) };
            case null { #err("Proposal not found") };
        };
    };
};