import MarketplaceListing "MarketplaceListing";
import UserType "UserType";

module {
    public type BookingId = Nat;

    public type BookingStatus = {
        #Pending;
        #Confirmed;
        #InProgress;
        #Completed;
        #Disputed;
        #Cancelled;
        #Refunded;
    };

    public type Booking = {
        id : BookingId;
        listing_id : MarketplaceListing.ListingId;
        learner_did : UserType.DID;
        tutor_did : UserType.DID;
        amount_swt : Nat;
        scheduled_time : ?Int;
        status : BookingStatus;
        created_at : Int;
        completed_at : ?Int;
        learner_confirmed : Bool;
        tutor_confirmed : Bool;
    };

};
