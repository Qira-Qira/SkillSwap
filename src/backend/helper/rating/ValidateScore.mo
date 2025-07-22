module {
     // Helper function to validate rating score
    public func validate_score(score : Nat) : Bool {
        score >= 1 and score <= 5
    };
}