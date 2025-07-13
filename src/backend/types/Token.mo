import Result "mo:base/Result";

// Token interface
module Token {
    public type Token = actor {
        mint : (Principal, Nat) -> async Result.Result<(), Text>;
    };
};