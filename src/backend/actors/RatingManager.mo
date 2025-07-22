import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Time "mo:base/Time";

import BookingSession "../types/BookingSession";
import RatingReputation "../types/RatingReputation";
import UserType "../types/UserType";
import ApiResponse "../types/APIResponse";
import StateRating "../storages/StateRating";
import SubmitRating "../services/rating/SubmitRating";
import UpdateRating "../services/rating/UpdateRating";
import ValidateScore "../helper/rating/ValidateScore";
import CanUpdateRating "../helper/rating/CanUpdateRating";
import DeleteRating "../services/rating/DeleteRating";
import GetUserRatingStats "../services/rating/GetUserRatingStats";
import CanUserUpdateRating "../services/rating/CanUserUpdateRating";
import GetUserGivenRatings "../services/rating/GetUserGivenRatings";
import GetUserAverageRating "../services/rating/GetUserAverageRating";
import GetBookingRating "../services/rating/GetBookingRating";

actor RatingManager {

    // Stable storage for upgrades
    private stable var ratings_stable : [(BookingSession.BookingId, RatingReputation.Rating)] = [];
    private stable var user_ratings_stable : [(UserType.DID, [RatingReputation.Rating])] = [];

    // Runtime HashMap for efficient operations
    private var rating : StateRating.Rating = {
        ratings = HashMap.HashMap<BookingSession.BookingId, RatingReputation.Rating>(0, Nat.equal, Hash.hash);
        user_ratings = HashMap.HashMap<UserType.DID, [RatingReputation.Rating]>(0, Text.equal, Text.hash);
    };

    // System functions for upgrade safety
    system func preupgrade() {
        // Convert HashMaps to Arrays for stable storage
        ratings_stable := Iter.toArray(rating.ratings.entries());
        user_ratings_stable := Iter.toArray(rating.user_ratings.entries());
    };

    system func postupgrade() {
        // Recreate ratings HashMap
        let new_ratings_map = HashMap.HashMap<BookingSession.BookingId, RatingReputation.Rating>(
            ratings_stable.size(),
            Nat.equal,
            Hash.hash,
        );

        for ((booking_id, rating_entry) in ratings_stable.vals()) {
            new_ratings_map.put(booking_id, rating_entry);
        };

        // Recreate user_ratings HashMap
        let new_user_ratings_map = HashMap.HashMap<UserType.DID, [RatingReputation.Rating]>(
            user_ratings_stable.size(),
            Text.equal,
            Text.hash,
        );

        for ((user_did, user_rating_list) in user_ratings_stable.vals()) {
            new_user_ratings_map.put(user_did, user_rating_list);
        };

        // Update the rating state
        rating := {
            ratings = new_ratings_map;
            user_ratings = new_user_ratings_map;
        };

        // Clear stable storage to save memory
        ratings_stable := [];
        user_ratings_stable := [];
    };

    // Inter-canister calls
    private let user_manager : actor {
        update_user_rating : (UserType.DID, Float, Nat) -> async ApiResponse.ApiResult<()>;
        recalculate_user_rating : (UserType.DID) -> async ApiResponse.ApiResult<()>;
    } = actor "vizcg-th777-77774-qaaea-cai"; // Replace with actual UserManager canister ID

    private let token_manager : actor {
        mint_rep_tokens : (UserType.DID, Nat, Float) -> async ApiResponse.ApiResult<Nat>;
        burn_rep_tokens : (UserType.DID, Nat) -> async ApiResponse.ApiResult<Nat>;
    } = actor "ufxgi-4p777-77774-qaadq-cai"; // Replace with actual TokenManager canister ID

    // Submit rating after completed session
    public func submit_rating(booking_id : BookingSession.BookingId, from_did : UserType.DID, to_did : UserType.DID, score : Nat, comment : Text) : async ApiResponse.ApiResult<RatingReputation.Rating> {
        await SubmitRating.submit_rating(user_manager, token_manager, rating, booking_id, from_did, to_did, score, comment);
    };

    // NEW FUNCTION: Update existing rating
    public func update_rating(booking_id : BookingSession.BookingId, from_did : UserType.DID, new_score : Nat, new_comment : Text) : async ApiResponse.ApiResult<RatingReputation.Rating> {
        await UpdateRating.update_rating(user_manager, token_manager, rating, booking_id, from_did, new_score, new_comment);
    };

    // NEW FUNCTION: Delete rating (optional, with restrictions)
    public func delete_rating(booking_id : BookingSession.BookingId, from_did : UserType.DID) : async ApiResponse.ApiResult<()> {
        await DeleteRating.delete_rating(user_manager, token_manager, rating, booking_id, from_did);
    };

    // Get user's received ratings
    public query func get_user_ratings(did : UserType.DID) : async [RatingReputation.Rating] {
        Option.get(rating.user_ratings.get(did), []);
    };

    // Get specific booking rating
    public query func get_booking_rating(booking_id : BookingSession.BookingId) : async ApiResponse.ApiResult<RatingReputation.Rating> {
        return GetBookingRating.get_booking_rating(rating, booking_id);
    };

    // Calculate user's average rating
    public query func get_user_average_rating(did : UserType.DID) : async Float {
       return GetUserAverageRating.get_user_average_rating(rating, did);
    };

    // Additional helper functions for monitoring and analytics
    public query func get_total_ratings_count() : async Nat {
        rating.ratings.size();
    };

    public query func get_user_rating_count(did : UserType.DID) : async Nat {
        let user_rating_list = Option.get(rating.user_ratings.get(did), []);
        user_rating_list.size();
    };

    // Get rating statistics for a user
    public query func get_user_rating_stats(did : UserType.DID) : async {total_ratings : Nat; average_rating : Float; five_star : Nat; four_star : Nat; three_star : Nat; two_star : Nat; one_star : Nat;} {
       return GetUserRatingStats.get_user_rating_stats(rating, did);
    };

    // Get all ratings for admin purposes
    public query func get_all_ratings() : async [(BookingSession.BookingId, RatingReputation.Rating)] {
        Iter.toArray(rating.ratings.entries());
    };

    // NEW FUNCTION: Check if user can update a specific rating
    public query func can_user_update_rating(booking_id : BookingSession.BookingId, from_did : UserType.DID) : async ApiResponse.ApiResult<Bool> {
       return CanUserUpdateRating.can_user_update_rating(rating, booking_id, from_did);
    };

    // NEW FUNCTION: Get user's given ratings (ratings they submitted)
    public query func get_user_given_ratings(from_did : UserType.DID) : async [RatingReputation.Rating] {
       return GetUserGivenRatings.get_user_given_ratings(rating, from_did);
    };
};
