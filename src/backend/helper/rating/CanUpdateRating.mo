import RatingReputation "../../types/RatingReputation";
import Time "mo:base/Time";

module {
    // Helper function to check if user can update rating (e.g., within time limit)
    public func can_update_rating(original_rating : RatingReputation.Rating) : Bool {
        // Allow updates within 24 hours (24 * 60 * 60 * 1_000_000_000 nanoseconds)
        let time_limit : Int = 24 * 60 * 60 * 1_000_000_000;
        let current_time = Time.now();
        
        // Assuming RatingReputation.Rating has a created_at field
        // You might need to adjust this based on your actual Rating type structure
        (current_time - original_rating.created_at) < time_limit
    };
}