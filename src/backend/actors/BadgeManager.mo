import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";

import BadgeNft "../types/BadgeNFT";
import UserType "../types/UserType";
import ApiResponse "../types/APIResponse";
import StateBadge "../storages/StateBadge";
import MintBadges "../services/badge/MintBadges";
import CheckAndMintBadges "../services/badge/CheckAndMintBadges";
import GetUserBadges "../services/badge/GetUserBadges";
import GetBadge "../services/badge/GetBadge";

actor BadgeManager {

    // Badge state
    private stable var badge_counter : StateBadge.BadgeCounter = {
        badge_counter = 0;
    };

    private var badge_hashmap : StateBadge.BadgeHashmap = {
        badges = HashMap.HashMap<BadgeNft.BadgeId, BadgeNft.Badge>(0, Nat.equal, Hash.hash);
        user_badges = HashMap.HashMap<UserType.DID, [BadgeNft.BadgeId]>(0, Text.equal, Text.hash);
    };

    // Badge thresholds
    private let CERTIFIED_TUTOR_SESSIONS = 50;
    private let TOP_RATED_MIN_RATING = 4.5;
    private let MILESTONE_SESSIONS = [10, 25, 50, 100, 250, 500];

    // Inter-canister calls
    private let user_manager : actor {
        get_user_profile : (UserType.DID) -> async ApiResponse.ApiResult<UserType.UserProfile>;
    } = actor "vizcg-th777-77774-qaaea-cai"; // Replace with actual UserManager canister ID

    private let rating_manager : actor {
        get_user_average_rating : (UserType.DID) -> async Float;
    } = actor "ucwa4-rx777-77774-qaada-cai"; // Replace with actual RatingManager canister ID

    // Check and mint badges for user based on achievements
    public func check_and_mint_badges(user_did : UserType.DID) : async ApiResponse.ApiResult<[BadgeNft.Badge]> {
        // Get user profile
        let certified_tutor_sessions = CERTIFIED_TUTOR_SESSIONS;
        let top_rated_min_rating = TOP_RATED_MIN_RATING;
        let milestone_sessions = MILESTONE_SESSIONS;
        await CheckAndMintBadges.check_and_mint_badges(badge_counter, certified_tutor_sessions, top_rated_min_rating, milestone_sessions, badge_hashmap, rating_manager, user_manager, user_did);
    };

    // Mint a new badge NFT
    private func mint_badge(owner_did : UserType.DID, badge_type : BadgeNft.BadgeType, metadata_ipfs : Text) : async ApiResponse.ApiResult<BadgeNft.Badge> {
        let result_mint_badge = await MintBadges.mint_badge(badge_counter, badge_hashmap, owner_did, badge_type, metadata_ipfs);
        switch (result_mint_badge) {
            case (#ok(value)) {
                badge_counter := StateBadge.set_badge_counter(badge_counter);
                return #ok(value);
            };
            case (_) {};
        };
        result_mint_badge;
    };

    // Get user's badges
    public query func get_user_badges(did : UserType.DID) : async [BadgeNft.Badge] {
        return GetUserBadges.get_user_badges(badge_hashmap.user_badges, badge_hashmap.badges, did);
    };

    // Get specific badge details
    public query func get_badge(badge_id : BadgeNft.BadgeId) : async ApiResponse.ApiResult<BadgeNft.Badge> {
        return GetBadge.get_badge(badge_hashmap.badges, badge_id);
    };
};
