import HashMap "mo:base/HashMap";
import UserType "../types/UserType";
import TokenType "../types/TokenType";

module {
    // Token state

    public type Balances = {
        swt_balances : HashMap.HashMap<UserType.DID, TokenType.TokenBalance>;
        rep_balances : HashMap.HashMap<UserType.DID, TokenType.TokenBalance>;
    };

    public type SwtTotalSupply = {
        swt_total_supply : Nat;
    };

    public func get_swt_total_supply(swt : SwtTotalSupply) : Nat {
        swt.swt_total_supply;
    };

    public func set_swt_total_supply(swt : SwtTotalSupply) : SwtTotalSupply {
        {
            swt_total_supply = swt.swt_total_supply + 1;
        };
    };

    public type RepTotalSupply = {
        rep_total_supply : Nat;
    };

    public func get_rep_total_supply(rep : RepTotalSupply) : Nat {
        rep.rep_total_supply;
    };

    public func set_rep_total_supply(rep : RepTotalSupply, rep_amount : Nat) : RepTotalSupply {
        {
            rep_total_supply = rep.rep_total_supply + rep_amount;
        };
    };

    public type PlatformTreasury = {
        platform_teasury : TokenType.TokenBalance;
    };

    public func get_platform_treasury(platform_teasury : PlatformTreasury) : TokenType.TokenBalance {
        platform_teasury.platform_teasury;
    };

    public func set_platform_treasury(platform_teasury : PlatformTreasury, amount : Nat) : PlatformTreasury {
        {
            platform_teasury = platform_teasury.platform_teasury + amount;
        };
    };
};
