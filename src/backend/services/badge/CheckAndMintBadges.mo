import UserType "../../types/UserType";
import ApiResponse "../../types/APIResponse";
import BadgeNft "../../types/BadgeNFT";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import StateBadge "../../storages/StateBadge";
import MintBadges "MintBadges";

module {
    // Check and mint badges for user based on achievements
    public func check_and_mint_badges(badge_counter : StateBadge.BadgeCounter, certified_tutor_sessions : Nat, top_rated_min_rating : Float, milestone_sessions : [Nat], badge_hashmap : StateBadge.BadgeHashmap, avg_rating : Float, user_result : ApiResponse.ApiResult<UserType.UserProfile>, user_did : UserType.DID) : async ApiResponse.ApiResult<[BadgeNft.Badge]> {

        // Get user profile
        let user_profile = switch (user_result) {
            case (#ok(profile)) { profile };
            case (#err(msg)) {
                return #err("Failed to get user profile: " # msg);
            };
        };

        // Get user's average rating

        let new_badges = Buffer.Buffer<BadgeNft.Badge>(0);
        let existing_badge_ids = Option.get(badge_hashmap.user_badges.get(user_did), []);

        // Check for Certified Tutor badge
        if (user_profile.total_sessions >= certified_tutor_sessions) {
            let has_certified_badge = Array.find<BadgeNft.BadgeId>(
                existing_badge_ids,
                func(id) {
                    switch (badge_hashmap.badges.get(id)) {
                        case (?badge) {
                            switch (badge.badge_type) {
                                case (#CertifiedTutor(_)) { true };
                                case (_) { false };
                            };
                        };
                        case null { false };
                    };
                },
            );

            if (has_certified_badge == null) {
                // Mint Certified Tutor badge for primary skill
                let primary_skill = if (user_profile.skills.size() > 0) {
                    user_profile.skills[0];
                } else {
                    "General";
                };

                let badge = await MintBadges.mint_badge(
                    badge_counter,
                    badge_hashmap,
                    user_did,
                    #CertifiedTutor({ skill = primary_skill; level = 1 }),
                    "ipfs://certified-tutor-metadata",
                );

                switch (badge) {
                    case (#ok(b)) { new_badges.add(b) };
                    case (#err(_)) { /* continue */ };
                };
            };
        };

        // Check for Top Rated badge
        if (avg_rating >= top_rated_min_rating and user_profile.total_sessions >= 10) {
            let has_top_rated_badge = Array.find<BadgeNft.BadgeId>(
                existing_badge_ids,
                func(id) {
                    switch (badge_hashmap.badges.get(id)) {
                        case (?badge) {
                            switch (badge.badge_type) {
                                case (#TopRated(_)) { true };
                                case (_) { false };
                            };
                        };
                        case null { false };
                    };
                },
            );

            if (has_top_rated_badge == null) {
                let badge = await MintBadges.mint_badge(
                    badge_counter,
                    badge_hashmap,
                    user_did,
                    #TopRated({ category = "Excellence" }),
                    "ipfs://top-rated-metadata",
                );

                switch (badge) {
                    case (#ok(b)) { new_badges.add(b) };
                    case (#err(_)) { /* continue */ };
                };
            };
        };

        // Check for Milestone badges
        for (milestone in milestone_sessions.vals()) {
            if (user_profile.total_sessions >= milestone) {
                let has_milestone_badge = Array.find<BadgeNft.BadgeId>(
                    existing_badge_ids,
                    func(id) {
                        switch (badge_hashmap.badges.get(id)) {
                            case (?badge) {
                                switch (badge.badge_type) {
                                    case (#Milestone(m)) {
                                        m.sessions == milestone;
                                    };
                                    case (_) { false };
                                };
                            };
                            case null { false };
                        };
                    },
                );

                if (has_milestone_badge == null) {
                    let badge = await MintBadges.mint_badge(
                        badge_counter,
                        badge_hashmap,
                        user_did,
                        #Milestone({ sessions = milestone }),
                        "ipfs://milestone-" # Nat.toText(milestone) # "-metadata",
                    );

                    switch (badge) {
                        case (#ok(b)) { new_badges.add(b) };
                        case (#err(_)) { /* continue */ };
                    };
                };
            };
        };

        return #ok(Buffer.toArray(new_badges));
    };

};
