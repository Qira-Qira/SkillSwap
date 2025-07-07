import HashMap "mo:base/HashMap";
import MarketplaceListing "../types/MarketplaceListing";
import BookingSession "../types/BookingSession";
import UserType "../types/UserType";
module {
    // State variables
    public type ListingCounter = {
        listing_counter : Nat;
    };

    public type BookingCounter = {
        booking_counter : Nat;
    };

    public func set_listing_counter(listing_counter : ListingCounter) : ListingCounter {
        {
            listing_counter = listing_counter.listing_counter + 1;
        };
    };

    public func set_booking_counter(booking_counter : BookingCounter) : BookingCounter {
        {
            booking_counter = booking_counter.booking_counter + 1;
        };
    };

    public type MarketplaceHashmap = {
        listings : HashMap.HashMap<MarketplaceListing.ListingId, MarketplaceListing.Listing>;
        bookings : HashMap.HashMap<BookingSession.BookingId, BookingSession.Booking>;
        tutor_listings : HashMap.HashMap<UserType.DID, [MarketplaceListing.ListingId]>;
        learner_bookings : HashMap.HashMap<UserType.DID, [BookingSession.BookingId]>;
    };

};
