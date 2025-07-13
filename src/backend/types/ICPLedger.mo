module ICPLedger {
    public type AccountIdentifier = Blob;
    public type SubAccount = Blob;
    public type Tokens = { e8s : Nat64 };
    public type Memo = Nat64;
    public type Timestamp = { timestamp_nanos : Nat64 };
    public type TransferArgs = {
        memo : Memo;
        amount : Tokens;
        fee : Tokens;
        from_subaccount : ?SubAccount;
        to : AccountIdentifier;
        created_at_time : ?Timestamp;
    };
    public type TransferError = {
        #BadFee : { expected_fee : Tokens };
        #InsufficientFunds : { balance : Tokens };
        #TxTooOld : { allowed_window_nanos : Nat64 };
        #TxCreatedInFuture;
        #TxDuplicate : { duplicate_of : Nat64 };
        #Other : { error_message : Text; error_code : Nat64 };
    };
    public type TransferResult = {
        #Ok : Nat64;
        #Err : TransferError;
    };
    public type AccountBalanceArgs = { account : AccountIdentifier };
    public type AccountBalanceResult = { e8s : Nat64 };
};