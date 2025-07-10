import HashMap "mo:base/HashMap";
import BadgeNft "../types/BadgeNFT";
import UserType "../types/UserType";

module {
    // Badge state
    public type BadgeCounter = {
        badge_counter : Nat;
    };

    public func set_badge_counter(badge_counter : BadgeCounter) : BadgeCounter {
        {
            badge_counter = badge_counter.badge_counter + 1;
        };
    };

    public type BadgeHashmap = {
        badges : HashMap.HashMap<BadgeNft.BadgeId, BadgeNft.Badge>;
        user_badges : HashMap.HashMap<UserType.DID, [BadgeNft.BadgeId]>;
    };
};
