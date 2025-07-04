import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";

import T "../types/type";

actor DAOGovernance {
        
    // DAO state
    private stable var proposal_counter: Nat = 0;
    private var proposals = HashMap.HashMap<T.ProposalId, T.Proposal>(0, Nat.equal, Hash.hash);
    private var user_votes = HashMap.HashMap<(T.ProposalId, T.DID), Bool>(0, func(a, b) { a.0 == b.0 and a.1 == b.1 }, func(x) { Hash.hash(x.0) });
    
    // DAO parameters
    private stable var min_voting_power: Nat = 100; // Minimum REP tokens to create proposal
    private stable var voting_period_duration: Int = 7 * 24 * 60 * 60 * 1_000_000_000; // 7 days in nanoseconds
    private stable var quorum_threshold: Nat = 1000; // Minimum total votes needed
    
    // Inter-canister calls
    private let token_manager : actor {
        get_rep_balance: (T.DID) -> async T.TokenBalance;
        update_platform_fee: (Float) -> async T.ApiResult<()>;
    } = actor "ucwa4-rx777-77774-qaada-cai"; // Replace with actual TokenManager canister ID
    
    // Create new governance proposal
    public func create_proposal(
        proposer_did: T.DID,
        proposal_type: T.ProposalType,
        description: Text
    ) : async T.ApiResult<T.Proposal> {
        
        // Check if user has enough REP tokens to propose
        let proposer_rep = await token_manager.get_rep_balance(proposer_did);
        if (proposer_rep < min_voting_power) {
            return #err("Insufficient REP tokens to create proposal. Required: " # Nat.toText(min_voting_power));
        };
        
        let proposal_id = proposal_counter;
        proposal_counter += 1;
        
        let voting_ends_at = Time.now() + voting_period_duration;
        
        let proposal: T.Proposal = {
            id = proposal_id;
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
        
        proposals.put(proposal_id, proposal);
        return #ok(proposal);
    };
    
    // Vote on a proposal
    public func vote_on_proposal(
        proposal_id: T.ProposalId,
        voter_did: T.DID,
        vote_for: Bool
    ) : async T.ApiResult<T.Proposal> {
        
        // Get voter's REP balance (voting power)
        let voting_power = await token_manager.get_rep_balance(voter_did);
        if (voting_power == 0) {
            return #err("No voting power (REP tokens required)");
        };
        
        // Get proposal
        switch (proposals.get(proposal_id)) {
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
                switch (user_votes.get((proposal_id, voter_did))) {
                    case (?_) { return #err("User has already voted on this proposal") };
                    case null {
                        // Record the vote
                        user_votes.put((proposal_id, voter_did), vote_for);
                        
                        // Update vote counts
                        let updated_proposal: T.Proposal = if (vote_for) {
                            {
                                proposal with 
                                votes_for = proposal.votes_for + voting_power;
                                voters = Array.append(proposal.voters, [voter_did]);
                            }
                        } else {
                            {
                                proposal with 
                                votes_against = proposal.votes_against + voting_power;
                                voters = Array.append(proposal.voters, [voter_did]);
                            }
                        };
                        
                        proposals.put(proposal_id, updated_proposal);
                        return #ok(updated_proposal);
                    };
                };
            };
        };
    };
    
    // Execute proposal if it passed
    public func execute_proposal(proposal_id: T.ProposalId) : async T.ApiResult<T.Proposal> {
        switch (proposals.get(proposal_id)) {
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
                    let rejected_proposal: T.Proposal = {
                        proposal with status = #Rejected;
                    };
                    proposals.put(proposal_id, rejected_proposal);
                    return #ok(rejected_proposal);
                };
                
                // Check if proposal passed (simple majority)
                let proposal_passed = proposal.votes_for > proposal.votes_against;
                
                if (proposal_passed) {
                    // Execute the proposal
                    let execution_result = await execute_proposal_action(proposal.proposal_type);
                    
                    let executed_proposal: T.Proposal = switch (execution_result) {
                        case (#ok()) {
                            { proposal with status = #Executed }
                        };
                        case (#err(_)) {
                            { proposal with status = #Passed } // Passed but execution failed
                        };
                    };
                    
                    proposals.put(proposal_id, executed_proposal);
                    return #ok(executed_proposal);
                } else {
                    let rejected_proposal: T.Proposal = {
                        proposal with status = #Rejected;
                    };
                    proposals.put(proposal_id, rejected_proposal);
                    return #ok(rejected_proposal);
                };
            };
        };
    };
    
    // Execute specific proposal actions
    private func execute_proposal_action(proposal_type: T.ProposalType) : async T.ApiResult<()> {
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
    public query func get_active_proposals() : async [T.Proposal] {
        let proposal_buffer = Buffer.Buffer<T.Proposal>(0);
        
        for ((id, proposal) in proposals.entries()) {
            if (proposal.status == #Active and Time.now() <= proposal.voting_ends_at) {
                proposal_buffer.add(proposal);
            };
        };
        
        Buffer.toArray(proposal_buffer);
    };
    
    // Get proposal by ID
    public query func get_proposal(proposal_id: T.ProposalId) : async T.ApiResult<T.Proposal> {
        switch (proposals.get(proposal_id)) {
            case (?proposal) { #ok(proposal) };
            case null { #err("Proposal not found") };
        };
    };
    
    // Get user's voting history
    public query func get_user_votes(user_did: T.DID) : async [(T.ProposalId, Bool)] {
        let vote_buffer = Buffer.Buffer<(T.ProposalId, Bool)>(0);
        
        for (((proposal_id, voter_did), vote) in user_votes.entries()) {
            if (voter_did == user_did) {
                vote_buffer.add((proposal_id, vote));
            };
        };
        
        Buffer.toArray(vote_buffer);
    };
    
    // Update DAO parameters (internal governance)
    public func update_dao_parameters(
        new_min_voting_power: ?Nat,
        new_voting_period: ?Int,
        new_quorum_threshold: ?Nat
    ) : async T.ApiResult<()> {
        
        // In production, this would be protected by admin rights or governance
        switch (new_min_voting_power) {
            case (?power) { min_voting_power := power };
            case null { };
        };
        
        switch (new_voting_period) {
            case (?period) { voting_period_duration := period };
            case null { };
        };
        
        switch (new_quorum_threshold) {
            case (?threshold) { quorum_threshold := threshold };
            case null { };
        };
        
        return #ok(());
    };
}