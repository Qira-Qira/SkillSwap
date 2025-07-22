import BadgeNft "../../types/BadgeNFT";
import ApiResponse "../../types/APIResponse";
import HashMap "mo:base/HashMap";

module {
    public func get_badge(badge_hashmap_badges : HashMap.HashMap<BadgeNft.BadgeId, BadgeNft.Badge>, badge_id : BadgeNft.BadgeId) : ApiResponse.ApiResult<BadgeNft.Badge> {
        switch (badge_hashmap_badges.get(badge_id)) {
            case (?badge) { #ok(badge) };
            case null { #err("Badge not found") };
        };
    };
};
