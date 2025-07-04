import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";

import T "../types/type";

actor Marketplace {
    
    // State variables
    private stable var listing_counter: Nat = 0;
    private stable var booking_counter: Nat = 0;
    
    private var listings = HashMap.HashMap<T.ListingId, T.Listing>(0, Nat.equal, Hash.hash);
    private var bookings = HashMap.HashMap<T.BookingId, T.Booking>(0, Nat.equal, Hash.hash);
    private var tutor_listings = HashMap.HashMap<T.DID, [T.ListingId]>(0, Text.equal, Text.hash);
    private var learner_bookings = HashMap.HashMap<T.DID, [T.BookingId]>(0, Text.equal, Text.hash);
    
    // Create new skill listing
    public func create_listing(
        tutor_did: T.DID,
        title: Text,
        description: Text,
        skills: [Text],
        duration_minutes: Nat,
        price_swt: Nat,
        available_slots: Nat,
        method: T.LearningMethod,
        ipfs_cid: Text
    ) : async T.ApiResult<T.Listing> {
        
        let listing_id = listing_counter;
        listing_counter += 1;
        
        let listing: T.Listing = {
            id = listing_id;
            tutor_did = tutor_did;
            title = title;
            description = description;
            skills = skills;
            duration_minutes = duration_minutes;
            price_swt = price_swt;
            available_slots = available_slots;
            method = method;
            ipfs_cid = ipfs_cid;
            created_at = Time.now();
            status = #Active;
        };
        
        listings.put(listing_id, listing);
        
        // Update tutor's listings index
        let current_listings = Option.get(tutor_listings.get(tutor_did), []);
        tutor_listings.put(tutor_did, Array.append(current_listings, [listing_id]));
        
        return #ok(listing);
    };
    
    // Browse all active listings
    public query func browse_listings(skill_filter: ?Text) : async [T.Listing] {
        let listing_buffer = Buffer.Buffer<T.Listing>(0);
        
        for ((id, listing) in listings.entries()) {
            if (listing.status == #Active) {
                switch (skill_filter) {
                    case null {
                        listing_buffer.add(listing);
                    };
                    case (?skill) {
                        // Check if the listing contains the requested skill
                        let has_skill = Array.find<Text>(listing.skills, func(s) { s == skill });
                        switch (has_skill) {
                            case (?_) { listing_buffer.add(listing) };
                            case null { /* skip */ };
                        };
                    };
                };
            };
        };
        
        Buffer.toArray(listing_buffer);
    };
    
    // Get specific listing details
    public query func get_listing(listing_id: T.ListingId) : async T.ApiResult<T.Listing> {
        switch (listings.get(listing_id)) {
            case (?listing) { #ok(listing) };
            case null { #err("Listing not found") };
        };
    };
    
    // Create booking for a listing
    public func create_booking(
        listing_id: T.ListingId,
        learner_did: T.DID
    ) : async T.ApiResult<T.Booking> {
        
        switch (listings.get(listing_id)) {
            case null { return #err("Listing not found") };
            case (?listing) {
                if (listing.status != #Active) {
                    return #err("Listing is not active");
                };
                
                if (listing.available_slots == 0) {
                    return #err("No available slots");
                };
                
                let booking_id = booking_counter;
                booking_counter += 1;
                
                let booking: T.Booking = {
                    id = booking_id;
                    listing_id = listing_id;
                    learner_did = learner_did;
                    tutor_did = listing.tutor_did;
                    amount_swt = listing.price_swt;
                    scheduled_time = null;
                    status = #Pending;
                    created_at = Time.now();
                    completed_at = null;
                    learner_confirmed = false;
                    tutor_confirmed = false;
                };
                
                bookings.put(booking_id, booking);
                
                // Update learner's bookings index
                let current_bookings = Option.get(learner_bookings.get(learner_did), []);
                learner_bookings.put(learner_did, Array.append(current_bookings, [booking_id]));
                
                // Decrease available slots
                let updated_listing: T.Listing = {
                    listing with available_slots = listing.available_slots - 1;
                };
                listings.put(listing_id, updated_listing);
                
                return #ok(booking);
            };
        };
    };
    
    // Schedule a session for existing booking
    public func schedule_session(
        booking_id: T.BookingId,
        caller_did: T.DID,
        scheduled_time: Int
    ) : async T.ApiResult<T.Booking> {
        
        switch (bookings.get(booking_id)) {
            case null { return #err("Booking not found") };
            case (?booking) {
                // Only tutor or learner can schedule
                if (booking.tutor_did != caller_did and booking.learner_did != caller_did) {
                    return #err("Unauthorized: only tutor or learner can schedule");
                };
                
                let updated_booking: T.Booking = {
                    booking with 
                    scheduled_time = ?scheduled_time;
                    status = #Confirmed;
                };
                
                bookings.put(booking_id, updated_booking);
                return #ok(updated_booking);
            };
        };
    };
    
    // Mark session as complete
    public func mark_session_complete(
        booking_id: T.BookingId,
        caller_did: T.DID
    ) : async T.ApiResult<T.Booking> {
        
        switch (bookings.get(booking_id)) {
            case null { return #err("Booking not found") };
            case (?booking) {
                if (booking.tutor_did != caller_did and booking.learner_did != caller_did) {
                    return #err("Unauthorized");
                };
                
                let (learner_confirmed, tutor_confirmed) = if (caller_did == booking.learner_did) {
                    (true, booking.tutor_confirmed)
                } else {
                    (booking.learner_confirmed, true)
                };
                
                let new_status = if (learner_confirmed and tutor_confirmed) {
                    #Completed
                } else {
                    booking.status
                };
                
                let completed_at = if (new_status == #Completed) {
                    ?Time.now()
                } else {
                    booking.completed_at
                };
                
                let updated_booking: T.Booking = {
                    booking with 
                    learner_confirmed = learner_confirmed;
                    tutor_confirmed = tutor_confirmed;
                    status = new_status;
                    completed_at = completed_at;
                };
                
                bookings.put(booking_id, updated_booking);
                return #ok(updated_booking);
            };
        };
    };
    
    // Get user's bookings (as learner)
    public query func get_learner_bookings(learner_did: T.DID) : async [T.Booking] {
        let booking_ids = Option.get(learner_bookings.get(learner_did), []);
        let booking_buffer = Buffer.Buffer<T.Booking>(booking_ids.size());
        
        for (booking_id in booking_ids.vals()) {
            switch (bookings.get(booking_id)) {
                case (?booking) { booking_buffer.add(booking) };
                case null { /* skip invalid booking */ };
            };
        };
        
        Buffer.toArray(booking_buffer);
    };
    
    // Get tutor's listings
    public query func get_tutor_listings(tutor_did: T.DID) : async [T.Listing] {
        let listing_ids = Option.get(tutor_listings.get(tutor_did), []);
        let listing_buffer = Buffer.Buffer<T.Listing>(listing_ids.size());
        
        for (listing_id in listing_ids.vals()) {
            switch (listings.get(listing_id)) {
                case (?listing) { listing_buffer.add(listing) };
                case null { /* skip invalid listing */ };
            };
        };
        
        Buffer.toArray(listing_buffer);
    };
}