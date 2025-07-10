import Result "mo:base/Result";

module {
    public type ApiResult<T> = Result.Result<T, Text>;
};
