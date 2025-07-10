import ApiResponse "../../types/APIResponse";

module {
    // Update platform fee (DAO governance function)
    public func update_platform_fee(new_fee_percent : Float) : async ApiResponse.ApiResult<()> {
        if (new_fee_percent < 0.0 or new_fee_percent > 10.0) {
            return #err("Platform fee must be between 0% and 10%");
        };

        return #ok(());
    };
};
