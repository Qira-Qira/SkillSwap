import StateDao "../../storages/StateDao";
import UserType "../../types/UserType";
import DaoGovernance "../../types/DAOGovernance";
import ApiResponse "../../types/APIResponse";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import TokenType "../../types/TokenType";

module {
    // Create new governance proposal
    public func create_proposal(
        min_voting_power : Nat,
        quorum_threshold : Nat,
        token_manager : actor {
            get_rep_balance : (UserType.DID) -> async TokenType.TokenBalance;
            update_platform_fee : (Float) -> async ApiResponse.ApiResult<()>;
        },
        proposal_counter : StateDao.ProposalCounter,
        voting_period_duration : Int,
        dao_hashmap : StateDao.DaoHashmap,
        proposer_did : UserType.DID,
        proposal_type : DaoGovernance.ProposalType,
        description : Text,
    ) : async ApiResponse.ApiResult<DaoGovernance.Proposal> {
        // Check if user has enough REP tokens to propose
        let proposer_rep = await token_manager.get_rep_balance(proposer_did);
        // Check if user has enough REP tokens to propose
        if (proposer_rep < min_voting_power) {
            return #err("Insufficient REP tokens to create proposal. Required: " # Nat.toText(min_voting_power));
        };

        let voting_ends_at = Time.now() + voting_period_duration;

        let proposal : DaoGovernance.Proposal = {
            id = proposal_counter.proposal_counter;
            proposer_did = proposer_did;
            proposal_type = proposal_type;
            description = description;
            voting_power_required = quorum_threshold;
            votes_for = 0;
            votes_against = 0;
            voters = [];
            created_at = Time.now();
            voting_ends_at = voting_ends_at;
            status = #Active;
        };

        dao_hashmap.proposals.put(proposal_counter.proposal_counter, proposal);
        return #ok(proposal);
    };
};
