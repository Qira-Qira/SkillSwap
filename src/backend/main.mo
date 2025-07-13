import UserManager "canister:UserManager";
import Marketplace "canister:Marketplace";
import TokenManager "canister:TokenManager";
import EscrowManager "canister:EscrowManager";
import RatingManager "canister:RatingManager";
import BadgeManager "canister:BadgeManager";
import PaymentGateway "canister:PaymentGateway"; 
import _DAOGovernance "canister:DAOGovernance";

import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import UserType "types/UserType";
import ApiResponse "types/APIResponse";
import MarketplaceListing "types/MarketplaceListing";
import BookingSession "types/BookingSession";
import EscrowType "types/EscrowType";
import TokenType "types/TokenType";
import RatingReputation "types/RatingReputation";
import BadgeNft "types/BadgeNFT";

actor SkillSwapOrchestrator {
    // Unified API endpoints that coordinate multiple canisters
    
    // Complete onboarding flow
    public func complete_onboarding(
        caller: UserType.UserId,
        name: Text,
        bio: Text,
        skills: [Text],
        role: UserType.UserRole,
        initial_swt: Nat
    ) : async ApiResponse.ApiResult<UserType.UserProfile> {
        
        // Create user profile
        let profile_result = await UserManager.create_user_profile(caller, name, bio, skills, role);
        
        switch (profile_result) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(profile)) {
                // Initialize token balance
                let _ = await TokenManager.initialize_user_balance(profile.did, initial_swt);
                
                return #ok(profile);
            };
        };
    };
    
    // ===== PAYMENT GATEWAY INTEGRATION =====
    
    // Start ICP to SWT purchase flow
    public func start_icp_to_swt_purchase(
        user_did: UserType.DID,
        icp_amount_e8s: Nat
    ) : async ApiResponse.ApiResult<{
        orderId: Nat;
        depositAddress: Text;
        expectedAmount: Nat;
        expiryTime: Int;
    }> {
        
        // Verify user exists
        let profile_result = await UserManager.get_user_profile(user_did);
        switch (profile_result) {
            case (#err(msg)) { return #err("User not found: " # msg) };
            case (#ok(_)) {};
        };
        
        // Start purchase in payment gateway
        let purchase_result = await PaymentGateway.startPurchase(icp_amount_e8s);
        
        return #ok({
            orderId = purchase_result.orderId;
            depositAddress = purchase_result.depositAddress;
            expectedAmount = icp_amount_e8s;
            expiryTime = Time.now() + 300_000_000_000; // 5 minutes
        });
    };
    
    // Complete ICP to SWT purchase and mint tokens
    public func complete_icp_to_swt_purchase(
        user_did: UserType.DID,
        order_id: Nat
    ) : async ApiResponse.ApiResult<{
        swt_minted: Nat;
        new_balance: Nat;
    }> {
        
        // Complete purchase in payment gateway
        let purchase_result = await PaymentGateway.completePurchase(order_id);
        
        switch (purchase_result) {
            case (#err(msg)) { return #err("Purchase failed: " # msg) };
            case (#ok()) {
                // Get order details to calculate SWT amount
                let order_status = await PaymentGateway.getOrderStatus(order_id);
                
                switch (order_status) {
                    case (null) { return #err("Order not found") };
                    case (?order) {
                        // Calculate SWT to mint (1 ICP = 100 SWT, 1 ICP = 100,000,000 e8s)
                        let swt_amount = (order.amountExpected * 100) / 100_000_000;
                        
                        // Mint SWT tokens to user
                        let mint_result = await TokenManager.mint(Principal.fromText(user_did), swt_amount);
                        
                        switch (mint_result) {
                            case (#err(msg)) { 
                                return #err("Payment completed but token minting failed: " # msg);
                            };
                            case (#ok()) {
                                // Get new balance
                                let new_balance = await TokenManager.get_swt_balance(user_did);
                                
                                return #ok({
                                    swt_minted = swt_amount;
                                    new_balance = new_balance;
                                });
                            };
                        };
                    };
                };
            };
        };
    };
    
// Get payment order status
public func get_payment_order_status(order_id: Nat) : async ?{
    buyer: Principal;
    status: Text;
    amountExpected: Nat;
    depositAddress: Text;
    createdAt: Int;
} {
    let orderOpt = await PaymentGateway.getOrderStatus(order_id);
    switch (orderOpt) {
        case null { null };
        case (?order) {
            ?{
                buyer = order.buyer;
                status = debug_show(order.status); // or use a custom toText function if available
                amountExpected = order.amountExpected;
                depositAddress = order.depositAddress;
                createdAt = order.createdAt;
            }
        }
    }
};
    
    // ===== ENHANCED BOOKING FLOW WITH PAYMENT OPTIONS =====
    
    // Complete booking flow with multiple payment options
    public func complete_booking_flow_with_payment(
        listing_id: MarketplaceListing.ListingId,
        learner_did: UserType.DID,
        payment_method: { #swt_balance; #icp_purchase : Nat } // ICP amount in e8s
    ) : async ApiResponse.ApiResult<{
        booking: BookingSession.Booking;
        escrow: EscrowType.EscrowEntry;
        payment_info: ?{ orderId: Nat; depositAddress: Text };
    }> {
        
        // Get listing details first
        let listing_result = await Marketplace.get_listing(listing_id);
        let listing = switch (listing_result) {
            case (#err(msg)) { return #err("Listing not found: " # msg) };
            case (#ok(l)) { l };
        };
        
        // Handle payment method
        let payment_info = switch (payment_method) {
            case (#swt_balance) {
                // Check if user has enough SWT balance
                let balance = await TokenManager.get_swt_balance(learner_did);
                if (balance < listing.price_swt) {
                    return #err("Insufficient SWT balance. Required: " # Nat.toText(listing.price_swt) # ", Available: " # Nat.toText(balance));
                };
                null // No additional payment info needed
            };
            case (#icp_purchase(icp_amount)) {
                // Start ICP purchase
                let purchase_result = await start_icp_to_swt_purchase(learner_did, icp_amount);
                switch (purchase_result) {
                    case (#err(msg)) { return #err("Failed to start ICP purchase: " # msg) };
                    case (#ok(purchase_info)) {
                        ?{ 
                            orderId = purchase_info.orderId; 
                            depositAddress = purchase_info.depositAddress;
                        }
                    };
                };
            };
        };
        
        // Create booking
        let booking_result = await Marketplace.create_booking(listing_id, learner_did);
        
        switch (booking_result) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(booking)) {
                // Create escrow
                let escrow_result = await EscrowManager.create_escrow(
                    booking.id,
                    booking.learner_did,
                    booking.tutor_did,
                    booking.amount_swt
                );
                
                switch (escrow_result) {
                    case (#err(msg)) { 
                        return #err("Booking created but escrow failed: " # msg);
                    };
                    case (#ok(escrow)) {
                        return #ok({
                            booking = booking;
                            escrow = escrow;
                            payment_info = payment_info;
                        });
                    };
                };
            };
        };
    };
    
    // Complete session completion flow
    public func complete_session_flow(
        booking_id: BookingSession.BookingId,
        caller_did: UserType.DID,
        rating_score: Nat,
        rating_comment: Text
    ) : async ApiResponse.ApiResult<Text> {
        
        // Mark session complete
        let booking_result = await Marketplace.mark_session_complete(booking_id, caller_did);
        
        switch (booking_result) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(booking)) {
                if (booking.status == #Completed) {
                    // Release escrow
                    let _ = await EscrowManager.release_escrow(booking_id);
                    
                    // Submit rating (determine who rates whom)
                    let (from_did, to_did) = if (caller_did == booking.learner_did) {
                        (booking.learner_did, booking.tutor_did)
                    } else {
                        (booking.tutor_did, booking.learner_did)
                    };
                    
                    let _ = await RatingManager.submit_rating(
                        booking_id,
                        from_did,
                        to_did,
                        rating_score,
                        rating_comment
                    );
                    
                    // Check and mint badges for tutor
                    let _ = await BadgeManager.check_and_mint_badges(booking.tutor_did);
                    
                    return #ok("Session completed successfully with rating and potential badges awarded");
                } else {
                    return #ok("Session completion recorded, waiting for other party confirmation");
                };
            };
        };
    };
    
    // Get comprehensive user dashboard data with payment history
    public func get_user_dashboard(user_did: UserType.DID) : async ApiResponse.ApiResult<{
        profile: UserType.UserProfile;
        swt_balance: TokenType.TokenBalance;
        rep_balance: TokenType.TokenBalance;
        listings: [MarketplaceListing.Listing];
        bookings: [BookingSession.Booking];
        ratings: [RatingReputation.Rating];
        badges: [BadgeNft.Badge];
        payment_gateway_balance: Nat;
    }> {
        
        // Get user profile
        let profile_result = await UserManager.get_user_profile(user_did);
        let profile = switch (profile_result) {
            case (#ok(p)) { p };
            case (#err(msg)) { return #err("Failed to get profile: " # msg) };
        };
        
        // Get balances
        let swt_balance = await TokenManager.get_swt_balance(user_did);
        let rep_balance = await TokenManager.get_rep_balance(user_did);
        
        // Get listings (if tutor)
        let listings = await Marketplace.get_tutor_listings(user_did);
        
        // Get bookings (if learner)
        let bookings = await Marketplace.get_learner_bookings(user_did);
        
        // Get ratings
        let ratings = await RatingManager.get_user_ratings(user_did);
        
        // Get badges
        let badges = await BadgeManager.get_user_badges(user_did);
        
        // Get payment gateway balance
        let pg_balance = await PaymentGateway.getCanisterBalance();
        
        let dashboard_data = {
            profile = profile;
            swt_balance = swt_balance;
            rep_balance = rep_balance;
            listings = listings;
            bookings = bookings;
            ratings = ratings;
            badges = badges;
            payment_gateway_balance = pg_balance;
        };
        
        return #ok(dashboard_data);
    };
    
    // Admin functions for payment gateway management
    public func admin_withdraw_funds(to: Principal, amount_e8s: Nat) : async Result.Result<(), Text> {
        await PaymentGateway.withdrawFunds(to, amount_e8s);
    };
    
    public func admin_withdraw_all_funds(to: Principal) : async Result.Result<(), Text> {
        await PaymentGateway.withdrawAllFunds(to);
    };
    
    // System health check
    public query func system_health() : async {
        status: Text;
        timestamp: Int;
        canister_count: Nat;
    } {
        {
            status = "All systems operational";
            timestamp = Time.now();
            canister_count = 8; // Updated to include PaymentGateway
        }
    };
}