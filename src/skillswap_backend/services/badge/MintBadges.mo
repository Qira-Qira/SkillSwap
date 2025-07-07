import UserType "../../types/UserType";
import BadgeNft "../../types/BadgeNFT";
import ApiResponse "../../types/APIResponse";
import Time "mo:base/Time";
import Option "mo:base/Option";
import Array "mo:base/Array";
import StateBadge "../../storages/StateBadge";

module {
    // Mint a new badge NFT
    public func mint_badge(badge_counter : StateBadge.BadgeCounter, badge_hashmap : StateBadge.BadgeHashmap, owner_did : UserType.DID, badge_type : BadgeNft.BadgeType, metadata_ipfs : Text) : async ApiResponse.ApiResult<BadgeNft.Badge> {

        let badge : BadgeNft.Badge = {
            id = badge_counter.badge_counter;
            owner_did = owner_did;
            badge_type = badge_type;
            metadata_ipfs = metadata_ipfs;
            issued_at = Time.now();
        };

        badge_hashmap.badges.put(badge_counter.badge_counter, badge);

        // Update user's badge collection
        let current_badges = Option.get(badge_hashmap.user_badges.get(owner_did), []);
        badge_hashmap.user_badges.put(owner_did, Array.append(current_badges, [badge_counter.badge_counter]));

        return #ok(badge);
    };

};
