import UserType "../../types/UserType";
import BadgeNft "../../types/BadgeNFT";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";

module {
    public func get_user_badges(badge_hashmap_user_badges : HashMap.HashMap<UserType.DID, [BadgeNft.BadgeId]>, badge_hashmap_badges : HashMap.HashMap<BadgeNft.BadgeId, BadgeNft.Badge>, did : UserType.DID) : [BadgeNft.Badge] {
        let badge_ids = Option.get(badge_hashmap_user_badges.get(did), []);
        let badge_buffer = Buffer.Buffer<BadgeNft.Badge>(badge_ids.size());

        for (badge_id in badge_ids.vals()) {
            switch (badge_hashmap_badges.get(badge_id)) {
                case (?badge) { badge_buffer.add(badge) };
                case null { /* skip invalid badge */ };
            };
        };

        Buffer.toArray(badge_buffer);
    };
};
