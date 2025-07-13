import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";

import UserType "../types/UserType";
import TokenType "../types/TokenType";
import ApiResponse "../types/APIResponse";
import DaoGovernance "../types/DAOGovernance";
import StateDao "../storages/StateDao";
import CreateProposal "../services/dao/CreateProposal";
import VoteOnProposal "../services/dao/VoteOnProposal";
import ExecuteProposal "../services/dao/ExecuteProposal";

actor DAOGovernance {

    // DAO state
    private stable var proposal_counter : StateDao.ProposalCounter = {
        proposal_counter : Nat = 0;
    };
    private var dao_hashmap : StateDao.DaoHashmap = {
        proposals = HashMap.HashMap<DaoGovernance.ProposalId, DaoGovernance.Proposal>(0, Nat.equal, Hash.hash);
        user_votes = HashMap.HashMap<(DaoGovernance.ProposalId, UserType.DID), Bool>(0, func(a, b) { a.0 == b.0 and a.1 == b.1 }, func(x) { Hash.hash(x.0) });
    };

    // DAO parameters
    private stable var min_voting_power : Nat = 100; // Minimum REP tokens to create proposal
    private stable var voting_period_duration : Int = 7 * 24 * 60 * 60 * 1_000_000_000; // 7 days in nanoseconds
    private stable var quorum_threshold : Nat = 1000; // Minimum total votes needed

    // Inter-canister calls
    private let token_manager : actor {
        get_rep_balance : (UserType.DID) -> async TokenType.TokenBalance;
        update_platform_fee : (Float) -> async ApiResponse.ApiResult<()>;
    } = actor "ufxgi-4p777-77774-qaadq-cai"; // Replace with actual TokenManager canister ID

    // Create new governance proposal
    public func create_proposal(proposer_did : UserType.DID, proposal_type : DaoGovernance.ProposalType, description : Text) : async ApiResponse.ApiResult<DaoGovernance.Proposal> {
        // Check if user has enough REP tokens to propose
        let proposer_rep = await token_manager.get_rep_balance(proposer_did);
        let result_create_proposal = await CreateProposal.create_proposal(min_voting_power, quorum_threshold, proposer_rep, proposal_counter, voting_period_duration, dao_hashmap, proposer_did, proposal_type, description);
        switch (result_create_proposal) {
            case (#ok(value)) {
                proposal_counter := StateDao.set_proposal_counter(proposal_counter);
            };
            case (_) {};
        };
        result_create_proposal;
    };

    // Vote on a proposal
    public func vote_on_proposal(
        proposal_id : DaoGovernance.ProposalId,
        voter_did : UserType.DID,
        vote_for : Bool,
    ) : async ApiResponse.ApiResult<DaoGovernance.Proposal> {

        // Get voter's REP balance (voting power)
        let voting_power = await token_manager.get_rep_balance(voter_did);
        await VoteOnProposal.vote_on_proposal(voting_power, dao_hashmap, proposal_id, voter_did, vote_for);
    };

    // Execute proposal if it passed
    public func execute_proposal(proposal_id : DaoGovernance.ProposalId) : async ApiResponse.ApiResult<DaoGovernance.Proposal> {
        switch (dao_hashmap.proposals.get(proposal_id)) {
            case (?proposal) {
                let execution_result = await execute_proposal_action(proposal.proposal_type);
                await ExecuteProposal.execute_proposal(dao_hashmap, execution_result, proposal_id);
            };
            case null {
                return #err("Proposal not found")
            };
        };
    };

    // Execute specific proposal actions
    private func execute_proposal_action(proposal_type : DaoGovernance.ProposalType) : async ApiResponse.ApiResult<()> {
        switch (proposal_type) {
            case (#FeeChange(params)) {
                await token_manager.update_platform_fee(params.new_fee_percent);
            };
            case (#NewCategory(params)) {
                // In a real implementation, this would update marketplace categories
                #ok(());
            };
            case (#ArbitratorChange(params)) {
                // In a real implementation, this would update arbitrator settings
                #ok(());
            };
            case (#General(params)) {
                // General proposals don't have automatic execution
                #ok(());
            };
        };
    };

    // Get all active proposals
    public query func get_active_proposals() : async [DaoGovernance.Proposal] {
        let proposal_buffer = Buffer.Buffer<DaoGovernance.Proposal>(0);

        for ((id, proposal) in dao_hashmap.proposals.entries()) {
            if (proposal.status == #Active and Time.now() <= proposal.voting_ends_at) {
                proposal_buffer.add(proposal);
            };
        };

        Buffer.toArray(proposal_buffer);
    };

    // Get proposal by ID
    public query func get_proposal(proposal_id : DaoGovernance.ProposalId) : async ApiResponse.ApiResult<DaoGovernance.Proposal> {
        switch (dao_hashmap.proposals.get(proposal_id)) {
            case (?proposal) { #ok(proposal) };
            case null { #err("Proposal not found") };
        };
    };

    // Get user's voting history
    public query func get_user_votes(user_did : UserType.DID) : async [(DaoGovernance.ProposalId, Bool)] {
        let vote_buffer = Buffer.Buffer<(DaoGovernance.ProposalId, Bool)>(0);

        for (((proposal_id, voter_did), vote) in dao_hashmap.user_votes.entries()) {
            if (voter_did == user_did) {
                vote_buffer.add((proposal_id, vote));
            };
        };

        Buffer.toArray(vote_buffer);
    };

    // Update DAO parameters (internal governance)
    public func update_dao_parameters(
        new_min_voting_power : ?Nat,
        new_voting_period : ?Int,
        new_quorum_threshold : ?Nat,
    ) : async ApiResponse.ApiResult<()> {

        // In production, this would be protected by admin rights or governance
        switch (new_min_voting_power) {
            case (?power) { min_voting_power := power };
            case null {};
        };

        switch (new_voting_period) {
            case (?period) { voting_period_duration := period };
            case null {};
        };

        switch (new_quorum_threshold) {
            case (?threshold) { quorum_threshold := threshold };
            case null {};
        };

        return #ok(());
    };
};
