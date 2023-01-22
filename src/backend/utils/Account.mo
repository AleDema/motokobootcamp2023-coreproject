import Bool "mo:base/Bool";
import Text "mo:base/Text";
import CRC32 "./CRC32";
import SHA224 "./SHA224";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

module Identity {

    public func isAnonymous(caller : Principal) : Bool {
        Principal.equal(caller, Principal.fromText("2vxsx-fae"))
    };

    public func isCanisterPrincipal(p : Principal) : Bool {
        let principal_text = Principal.toText(p);
        let correct_length = Text.size(principal_text) == 27;
        let correct_last_characters = Text.endsWith(principal_text, #text "-cai");

        if (Bool.logand(correct_length, correct_last_characters)) {
            return true
        };
        return false
    };

    // 32-byte array.
    public type AccountIdentifier = Blob;
    // 32-byte array.
    public type Subaccount = Blob;

    public func beBytes(n : Nat32) : [Nat8] {
        func byte(n : Nat32) : Nat8 {
            Nat8.fromNat(Nat32.toNat(n & 0xff))
        };
        [byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)]
    };

    public func defaultSubaccount() : Subaccount {
        Blob.fromArrayMut(Array.init(32, 0 : Nat8))
    };

    public func accountIdentifier(principal : Principal, subaccount : Subaccount) : AccountIdentifier {
        let hash = SHA224.Digest();
        hash.write([0x0A]);
        hash.write(Blob.toArray(Text.encodeUtf8("account-id")));
        hash.write(Blob.toArray(Principal.toBlob(principal)));
        hash.write(Blob.toArray(subaccount));
        let hashSum = hash.sum();
        let crc32Bytes = beBytes(CRC32.ofArray(hashSum));
        let buf = Buffer.Buffer<Nat8>(32);
        Blob.fromArray(Array.append(crc32Bytes, hashSum))
    };

    public func validateAccountIdentifier(accountIdentifier : AccountIdentifier) : Bool {
        if (accountIdentifier.size() != 32) {
            return false
        };
        let a = Blob.toArray(accountIdentifier);
        let accIdPart = Array.tabulate(28, func(i : Nat) : Nat8 { a[i + 4] });
        let checksumPart = Array.tabulate(4, func(i : Nat) : Nat8 { a[i] });
        let crc32 = CRC32.ofArray(accIdPart);
        Array.equal(beBytes(crc32), checksumPart, Nat8.equal)
    };

    public type Account = {
        owner : Principal;
        subaccount : ?Subaccount
    };

    public func validate(account : Account) : Bool {
        let is_anonymous = Principal.isAnonymous(account.owner);
        let invalid_size = Principal.toBlob(account.owner).size() > 29;

        if (is_anonymous or invalid_size) {
            false
        } else {
            validate_subaccount(account.subaccount)
        }
    };
    public func validate_subaccount(subaccount : ?Subaccount) : Bool {
        switch (subaccount) {
            case (?bytes) {
                bytes.size() == 32
            };
            case (_) true
        }
    };

    public func principalToSubaccount(principal : Principal) : Blob {
        let idHash = SHA224.Digest();
        idHash.write(Blob.toArray(Principal.toBlob(principal)));
        let hashSum = idHash.sum();
        let crc32Bytes = beBytes(CRC32.ofArray(hashSum));
        let buf = Buffer.Buffer<Nat8>(32);
        Blob.fromArray(Array.append(crc32Bytes, hashSum))
    };

    // public func accountIdentifierToText(accountIdentifier : AccountIdentifier, canisterId : ?Principal) : Result.Result<Text, AccountIdentifierToErr> {
    //     switch (accountIdentifier) {
    //         case (#text(identifier)) {
    //             return #ok(identifier)
    //         };
    //         case (#principal(identifier)) {
    //             let blobResult = accountIdentifierToBlob(accountIdentifier, canisterId);
    //             switch (blobResult) {
    //                 case (#ok(blob)) {
    //                     return #ok(Hex.encode(Blob.toArray(blob)))
    //                 };
    //                 case (#err(err)) {
    //                     return #err(err)
    //                 }
    //             }
    //         };
    //         case (#blob(identifier)) {
    //             let blobResult = accountIdentifierToBlob(accountIdentifier, canisterId);
    //             switch (blobResult) {
    //                 case (#ok(blob)) {
    //                     return #ok(Hex.encode(Blob.toArray(blob)))
    //                 };
    //                 case (#err(err)) {
    //                     return #err(err)
    //                 }
    //             }
    //         }
    //     }
    // };

}
