import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Char "mo:base/Char";
import Hash "mo:base/Hash";
import Buffer "mo:base/Buffer";

import ICPLedger "../types/ICPLedger";
import Token "../types/Token";

actor PaymentGateway {
    private type OrderId = Nat;
    private type OrderStatus = { #pending; #completed; #failed; #refunded };

    // State variables
    private stable var nextOrderId : OrderId = 0;
    private var token : ?Token.Token = null; // Make optional initially
    private let conversionRate : Nat = 100; // 1 ICP = 100 SWT
    private let fee : Nat = 10_000; // Biaya transaksi ICP (0.0001 ICP)
    private let orderExpiry : Int = 300_000_000_000; // 5 menit dalam nanoseconds
    private let MIN_PAYMENT : Nat = 1_000_000; // Minimum 0.01 ICP

    // Principal pemilik (ganti dengan principal Anda)
    private stable var ownerPrincipal : Principal = Principal.fromText("2vxsx-fae");

    // Mock untuk testing lokal
    private var mockLedger = HashMap.HashMap<Blob, Nat>(
        0,
        Blob.equal,
        Blob.hash,
    );

    // Order storage
    private stable var orders : [(OrderId, Order)] = [];
    private var ordersMap = HashMap.HashMap<OrderId, Order>(
        0,
        Nat.equal,
        Hash.hash,
    );

    public type Order = {
        buyer : Principal;
        depositAddress : Blob;
        amountExpected : Nat; // Dalam e8s (1 ICP = 100,000,000 e8s)
        status : OrderStatus;
        createdAt : Time.Time;
    };

    // ===== SYSTEM FUNCTIONS =====
    system func preupgrade() {
        // Simpan state sebelum upgrade
        orders := Iter.toArray(ordersMap.entries());
    };

    system func postupgrade() {
        // Restore state setelah upgrade
        ordersMap := HashMap.fromIter<OrderId, Order>(
            orders.vals(),
            orders.size(),
            Nat.equal,
            Hash.hash,
        );
        orders := [];
    };

    // ===== OWNER MANAGEMENT =====

    // Set owner (can only be called once or by current owner)
    public shared (msg) func setOwner(newOwner : Principal) : async Result.Result<(), Text> {
        // Allow setting owner if current owner is anonymous (first time setup)
        // or if caller is current owner
        if (ownerPrincipal == Principal.fromText("2vxsx-fae") or msg.caller == ownerPrincipal) {
            ownerPrincipal := newOwner;
            Debug.print("Owner set to: " # Principal.toText(newOwner));
            #ok();
        } else {
            #err("Access denied");
        };
    };

    // Get current owner
    public query func getOwner() : async Principal {
        ownerPrincipal;
    };

    // Debug function to check caller
    public shared (msg) func debug_caller() : async {
        caller: Principal;
        owner: Principal;
        isMatch: Bool;
        callerText: Text;
        ownerText: Text;
    } {
        {
            caller = msg.caller;
            owner = ownerPrincipal;
            isMatch = msg.caller == ownerPrincipal;
            callerText = Principal.toText(msg.caller);
            ownerText = Principal.toText(ownerPrincipal);
        }
    };

    // ===== PUBLIC INTERFACE =====

    // Set token canister ID (panggil setelah deploy token canister)
    public func setTokenCanisterId(id : Text) : async () {
        token := ?actor (id);
    };

    // Start a purchase
    public shared (msg) func startPurchase(icpAmountE8s : Nat) : async Result.Result<{
        depositAddress : Text;
        orderId : OrderId;
        expiresAt : Int;
    }, Text> {
        // Validate amount
        if (icpAmountE8s < MIN_PAYMENT) {
            return #err("Amount too small. Minimum: " # Nat.toText(MIN_PAYMENT) # " e8s");
        };

        // Check if token canister is set
        switch (token) {
            case (null) {
                return #err("Token canister not set");
            };
            case (?_) {};
        };

        let orderId = nextOrderId;
        nextOrderId += 1;

        let depositAddressBlob = generateDepositAddress(msg.caller, orderId);
        let depositAddressHex = toHex(depositAddressBlob);
        let expiresAt = Time.now() + orderExpiry;

        // Save order
        ordersMap.put(
            orderId,
            {
                buyer = msg.caller;
                depositAddress = depositAddressBlob;
                amountExpected = icpAmountE8s;
                status = #pending;
                createdAt = Time.now();
            },
        );

        Debug.print(
            "Order created: OrderID: " # Nat.toText(orderId)
            # " | Address: " # depositAddressHex
            # " | Amount: " # Nat.toText(icpAmountE8s) # " e8s"
            # " | Expires: " # Int.toText(expiresAt)
        );

        #ok({
            depositAddress = depositAddressHex;
            orderId = orderId;
            expiresAt = expiresAt;
        });
    };

    // Complete purchase (works for both testnet and mainnet)
    public shared (msg) func completePurchase(orderId : OrderId) : async Result.Result<(), Text> {
        switch (ordersMap.get(orderId)) {
            case (null) {
                return #err("Order tidak ditemukan");
            };
            case (?order) {
                // Verifikasi pemanggil
                if (msg.caller != order.buyer) {
                    return #err("Hanya pembeli yang bisa menyelesaikan order");
                };

                // Verifikasi waktu
                if (Time.now() > order.createdAt + orderExpiry) {
                    return #err("Order sudah kadaluarsa");
                };

                // Verifikasi token canister sudah di-set
                switch (token) {
                    case (null) {
                        return #err("Token canister belum di-set");
                    };
                    case (?tokenActor) {
                        // Dapatkan jumlah pembayaran
                        let amountPaid = await getAccountBalance(order.depositAddress);

                        if (amountPaid >= order.amountExpected) {
                            // Hitung token yang akan dikirim
                            let tokensToSend = (amountPaid * conversionRate) / 100_000_000;

                            // Kirim token ke pembeli
                            try {
                                switch (await tokenActor.mint(order.buyer, tokensToSend)) {
                                    case (#err(e)) {
                                        return #err("Gagal mengirim token: " # e);
                                    };
                                    case (#ok()) {};
                                };
                            } catch (e) {
                                return #err("Error saat mint token: " # Error.message(e));
                            };

                            // Update status order
                            ordersMap.put(
                                orderId,
                                {
                                    order with status = #completed
                                },
                            );
                            return #ok();
                        } else {
                            return #err(
                                "Pembayaran belum lengkap. Dibutuhkan: "
                                # Nat.toText(order.amountExpected)
                                # " e8s | Diterima: "
                                # Nat.toText(amountPaid) # " e8s"
                            );
                        };
                    };
                };
            };
        };
    };

    // Withdraw funds to owner's wallet
    public shared (msg) func withdrawFunds(to : Principal, amountE8s : Nat) : async Result.Result<(), Text> {
        // Verifikasi pemanggil adalah pemilik
        if (msg.caller != ownerPrincipal) {
            return #err("Hanya pemilik yang bisa menarik dana");
        };

        // Dapatkan saldo canister
        let totalBalance = await getCanisterBalance();
        if (amountE8s > totalBalance) {
            return #err("Saldo tidak mencukupi");
        };

        // Proses penarikan
        let transferArgs : ICPLedger.TransferArgs = {
            memo = 0;
            amount = { e8s = Nat64.fromNat(amountE8s) };
            fee = { e8s = Nat64.fromNat(fee) };
            from_subaccount = null;
            to = Principal.toBlob(to);
            created_at_time = ?{
                timestamp_nanos = Nat64.fromIntWrap(Time.now());
            };
        };

        try {
            // Gunakan ICP Ledger asli di mainnet
            let ledger : actor {
                transfer : ICPLedger.TransferArgs -> async ICPLedger.TransferResult;
            } = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");

            let result = await ledger.transfer(transferArgs);
            switch (result) {
                case (#Ok(_blockIndex)) { #ok() };
                case (#Err(err)) {
                    #err("Transfer gagal: " # debug_show (err));
                };
            };
        } catch (e) {
            #err("Error saat transfer: " # Error.message(e));
        };
    };

    // Withdraw all funds to owner's wallet
    public shared (msg) func withdrawAllFunds(to : Principal) : async Result.Result<(), Text> {
        if (msg.caller != ownerPrincipal) {
            return #err("Akses ditolak");
        };

        // Dapatkan saldo total
        let totalBalance = await getCanisterBalance();
        if (totalBalance <= fee) {
            return #err("Saldo tidak mencukupi untuk penarikan");
        };

        // Hitung jumlah yang bisa ditarik (kurangi biaya transaksi)
        let amountToSend = totalBalance - fee;

        // Proses penarikan
        await withdrawFunds(to, amountToSend);
    };

    // ===== QUERY FUNCTIONS =====

     // Get all orders for a user
    public query (msg) func getMyOrders() : async [{
        orderId : OrderId;
        status : OrderStatus;
        amountExpected : Nat;
        depositAddress : Text;
        createdAt : Int;
        expiresAt : Int;
    }] {
        let userOrders = Buffer.Buffer<{
            orderId : OrderId;
            status : OrderStatus;
            amountExpected : Nat;
            depositAddress : Text;
            createdAt : Int;
            expiresAt : Int;
        }>(0);

        for ((orderId, order) in ordersMap.entries()) {
            if (order.buyer == msg.caller) {
                userOrders.add({
                    orderId = orderId;
                    status = order.status;
                    amountExpected = order.amountExpected;
                    depositAddress = toHex(order.depositAddress);
                    createdAt = order.createdAt;
                    expiresAt = order.createdAt + orderExpiry;
                });
            };
        };

        Buffer.toArray(userOrders);
    };

    // Get minimum payment
    public query func getMinimumPayment() : async Nat {
        MIN_PAYMENT;
    };

    // Get conversion rate
    public query func getConversionRate() : async Nat {
        conversionRate;
    };

    // Get order status with more details
    public query func getOrderStatus(orderId : OrderId) : async ?{
        buyer : Principal;
        status : OrderStatus;
        amountExpected : Nat;
        depositAddress : Text;
        createdAt : Int;
        expiresAt : Int;
        isExpired : Bool;
    } {
        switch (ordersMap.get(orderId)) {
            case (null) { null };
            case (?order) {
                let expiresAt = order.createdAt + orderExpiry;
                let isExpired = Time.now() > expiresAt;
                
                ?{
                    buyer = order.buyer;
                    status = order.status;
                    amountExpected = order.amountExpected;
                    depositAddress = toHex(order.depositAddress);
                    createdAt = order.createdAt;
                    expiresAt = expiresAt;
                    isExpired = isExpired;
                };
            };
        };
    };

    // Get canister balance in e8s
    public func getCanisterBalance() : async Nat {
        let canisterId = Principal.fromActor(PaymentGateway);
        let account = Principal.toBlob(canisterId);
        await getAccountBalance(account);
    };

    // ===== TESTING HELPERS =====

   // Simulate payment (local testing only)
    public func simulatePayment(depositAddress : Text, amountE8s : Nat) : async Result.Result<(), Text> {
        let addressBlob = switch (hexToBlob(depositAddress)) {
            case (null) { return #err("Invalid address format"); };
            case (?blob) { blob };
        };

        mockLedger.put(addressBlob, amountE8s);
        Debug.print(
            "Payment simulated: " # Nat.toText(amountE8s) # " e8s to " # depositAddress
        );
        #ok();
    };

    public query func getCanisterAccountHex() : async Text {
        let blob = Principal.toBlob(Principal.fromActor(PaymentGateway));
        toHex(blob);
    };

    // ===== PRIVATE UTILITIES =====

    private func generateDepositAddress(user : Principal, orderId : OrderId) : Blob {
        let userBlob = Principal.toBlob(user);
        let orderBlob = Blob.fromArray(beBytes(orderId));
        let canisterId = Principal.fromActor(PaymentGateway);
        let canisterBlob = Principal.toBlob(canisterId);

        // Create more unique address by including timestamp
        let timeBlob = Blob.fromArray(beBytes(Int.abs(Time.now())));

        Blob.fromArray(
            Array.append(
                Array.append(
                    Array.append(Blob.toArray(userBlob), Blob.toArray(orderBlob)),
                    Blob.toArray(canisterBlob)
                ),
                Blob.toArray(timeBlob)
            )
        );
    };

    private func toHex(blob : Blob) : Text {
        let base : [Text] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f"];
        let bytes = Blob.toArray(blob);
        Array.foldLeft<Nat8, Text>(
            bytes,
            "",
            func(acc, byte) {
                acc # base[Nat8.toNat(byte / 16)]
                # base[Nat8.toNat(byte % 16)];
            },
        );
    };

    private func hexToBlob(hex : Text) : ?Blob {
        let chars = Iter.toArray(Text.toIter(hex));
        if (chars.size() % 2 != 0) return null;

        let bytes = Array.init<Nat8>(chars.size() / 2, 0);
        var i = 0;

        while (i < chars.size()) {
            let highChar = chars[i];
            let lowChar = chars[i + 1];

            let charToNat8 = func(c : Char) : ?Nat8 {
                switch (c) {
                    case ('0') { ?0 };
                    case ('1') { ?1 };
                    case ('2') { ?2 };
                    case ('3') { ?3 };
                    case ('4') { ?4 };
                    case ('5') { ?5 };
                    case ('6') { ?6 };
                    case ('7') { ?7 };
                    case ('8') { ?8 };
                    case ('9') { ?9 };
                    case ('a') { ?10 };
                    case ('b') { ?11 };
                    case ('c') { ?12 };
                    case ('d') { ?13 };
                    case ('e') { ?14 };
                    case ('f') { ?15 };
                    case ('A') { ?10 };
                    case ('B') { ?11 };
                    case ('C') { ?12 };
                    case ('D') { ?13 };
                    case ('E') { ?14 };
                    case ('F') { ?15 };
                    case (_) { null };
                };
            };

            switch (charToNat8(highChar), charToNat8(lowChar)) {
                case (?high, ?low) {
                    bytes[i / 2] := (high * 16) + low;
                };
                case (_, _) {
                    return null;
                };
            };

            i += 2;
        };

        ?Blob.fromArray(Array.freeze(bytes));
    };

    private func beBytes(n : Nat) : [Nat8] {
        let size = 8; // 64-bit
        Array.tabulate<Nat8>(
            size,
            func (i) {
                let shift = (size - i - 1) * 8;
                Nat8.fromIntWrap(n / (2 ** shift));
            },
        );
    };

     private func getAccountBalance(account: Blob) : async Nat {
        // Di mainnet, gunakan ICP Ledger asli
        let canisterId = Principal.fromActor(PaymentGateway);
        let canisterIdText = Principal.toText(canisterId);
        if (canisterIdText != "ulvla-h7777-77774-qaacq-cai") { // Bukan di local replica
            try {
                let ledger : actor { 
                    account_balance : ICPLedger.AccountBalanceArgs -> async ICPLedger.AccountBalanceResult 
                } = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");
                
                let balance = await ledger.account_balance({ account = account });
                Nat64.toNat(balance.e8s);
            } catch(e) {
                Debug.print("Error checking balance: " # Error.message(e));
                0;
            }
        } else {
            // Di local replica, gunakan mock ledger
            Option.get(mockLedger.get(account), 0);
        }
    };
};