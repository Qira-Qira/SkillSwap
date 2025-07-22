import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";

import MarketplaceListing "../types/MarketplaceListing";
import BookingSession "../types/BookingSession";
import UserType "../types/UserType";
import ApiResponse "../types/APIResponse";
import StateMarketplace "../storages/StateMarketplace";
import CreateListing "../services/marketplace/CreateListing";
import CreateBooking "../services/marketplace/CreateBooking";
import MarkSessionComplete "../services/marketplace/MarkSessionComplete";
import ScheduleSession "../services/marketplace/ScheduleSession";
import BrowseListings "../services/marketplace/BrowseListings";
import GetListing "../services/marketplace/GetListing";
import GetLearnerBookings "../services/marketplace/GetLearnerBookings";
import GetTutorListings "../services/marketplace/GetTutorListings";

actor Marketplace {

    // State variables

    private stable var listing_counter : StateMarketplace.ListingCounter = {
        listing_counter = 0;
    };

    private stable var booking_counter : StateMarketplace.BookingCounter = {
        booking_counter = 0;
    };

    private var marketplace_hashmap : StateMarketplace.MarketplaceHashmap = {
        listings = HashMap.HashMap<MarketplaceListing.ListingId, MarketplaceListing.Listing>(0, Nat.equal, Hash.hash);
        bookings = HashMap.HashMap<BookingSession.BookingId, BookingSession.Booking>(0, Nat.equal, Hash.hash);
        tutor_listings = HashMap.HashMap<UserType.DID, [MarketplaceListing.ListingId]>(0, Text.equal, Text.hash);
        learner_bookings = HashMap.HashMap<UserType.DID, [BookingSession.BookingId]>(0, Text.equal, Text.hash);
    };

    // Create new skill listing
    public func create_listing(
        tutor_did : UserType.DID,
        title : Text,
        description : Text,
        skills : [Text],
        duration_minutes : Nat,
        price_swt : Nat,
        available_slots : Nat,
        method : MarketplaceListing.LearningMethod,
        ipfs_cid : Text,
    ) : async ApiResponse.ApiResult<MarketplaceListing.Listing> {

        let listing_id = listing_counter.listing_counter;
        listing_counter := StateMarketplace.set_listing_counter(listing_counter);
        await CreateListing.create_listing(listing_id, marketplace_hashmap, tutor_did, title, description, skills, duration_minutes, price_swt, available_slots, method, ipfs_cid);
    };

    // Browse all active listings
    public query func browse_listings(skill_filter : ?Text) : async [MarketplaceListing.Listing] {
        return BrowseListings.browse_listings(marketplace_hashmap.listings, skill_filter);
    };

    // Get specific listing details
    public query func get_listing(listing_id : MarketplaceListing.ListingId) : async ApiResponse.ApiResult<MarketplaceListing.Listing> {
        return GetListing.get_listing(marketplace_hashmap.listings, listing_id);
    };

    // Create booking for a listing
    public func create_booking(
        listing_id : MarketplaceListing.ListingId,
        learner_did : UserType.DID,
    ) : async ApiResponse.ApiResult<BookingSession.Booking> {
        let result = await CreateBooking.create_booking(booking_counter.booking_counter, marketplace_hashmap, listing_id, learner_did);
        switch (result) {
            case (#ok(value)) {
                let booking_id = booking_counter.booking_counter;
                booking_counter := StateMarketplace.set_booking_counter(booking_counter);
            };
            case (_) {};
        };
        result;
    };

    // Schedule a session for existing booking
    public func schedule_session(
        booking_id : BookingSession.BookingId,
        caller_did : UserType.DID,
        scheduled_time : Int,
    ) : async ApiResponse.ApiResult<BookingSession.Booking> {
        await ScheduleSession.schedule_session(marketplace_hashmap, booking_id, caller_did, scheduled_time);
    };

    // Mark session as complete
    public func mark_session_complete(
        booking_id : BookingSession.BookingId,
        caller_did : UserType.DID,
    ) : async ApiResponse.ApiResult<BookingSession.Booking> {
        await MarkSessionComplete.mark_session_complete(marketplace_hashmap, booking_id, caller_did);
    };

    // Get user's bookings (as learner)
    public query func get_learner_bookings(learner_did : UserType.DID) : async [BookingSession.Booking] {
       return GetLearnerBookings.get_learner_bookings(marketplace_hashmap.learner_bookings, marketplace_hashmap.bookings, learner_did);
    };

    // Get tutor's listings
    public query func get_tutor_listings(tutor_did : UserType.DID) : async [MarketplaceListing.Listing] {
       return GetTutorListings.get_tutor_listings(marketplace_hashmap.tutor_listings, marketplace_hashmap.listings, tutor_did);
    };
};
