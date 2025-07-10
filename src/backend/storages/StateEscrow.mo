import HashMap "mo:base/HashMap";
import BookingSession "../types/BookingSession";
import EscrowType "../types/EscrowType";

module {
    public type EscrowEntries = {
        escrow_entries : HashMap.HashMap<BookingSession.BookingId, EscrowType.EscrowEntry>;
    };
};
