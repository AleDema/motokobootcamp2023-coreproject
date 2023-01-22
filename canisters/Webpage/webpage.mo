import Http "./Http";
import T "mo:base/Text";
import O "mo:base/Option";
import A "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import CertifiedData "mo:base/CertifiedData";
import SHA256 "./SHA256";
// import DAO "canister:DAO";

actor Webpage {

    public type HttpRequest = Http.HttpRequest;
    public type HttpResponse = Http.HttpResponse;
    stable var body = "Hello World";

    let IS_LOCAL_ENV = true;
    let main_DAO_principal = "db3eq-6iaaa-aaaah-abz6a-cai";
    let local_DAO_principal = "l7jw7-difaq-aaaaa-aaaaa-c";
    var DAO_principal = main_DAO_principal;
    if (IS_LOCAL_ENV) {
        DAO_principal := local_DAO_principal
    };

    //must be called on init to work
    public shared ({ caller }) func update_body(msg : Text) : async () {
        //TODO UPDATE FOR MAINNET
        if (not Principal.equal(caller, Principal.fromText(DAO_principal))) return;
        body := msg;
        update_asset_hash()
    };

    public query func http_request(req : HttpRequest) : async HttpResponse {
        return {
            status_code = 200;
            headers = [("content-type", "text/plain"), certification_header()];
            body = main_page();
            streaming_strategy = null
        }
    };

    // CERTIFICATION STUFF

    type Hash = Blob;
    type Key = Blob;
    type Value = Blob;
    type HashTree = {
        #empty;
        #pruned : Hash;
        #fork : (HashTree, HashTree);
        #labeled : (Key, HashTree);
        #leaf : Value
    };

    func my_id() : Principal = Principal.fromActor(Webpage);

    func main_page() : Blob {
        return T.encodeUtf8(
            "https://" # debug_show my_id() # ".ic0.app/\n" # body,
        )
    };

    func asset_tree() : HashTree {
        #labeled(
            "http_assets",
            #labeled(
                "/",
                #leaf(h(main_page())),
            ),
        )
    };

    func update_asset_hash() {
        CertifiedData.set(hash_tree(asset_tree()))
    };

    system func postupgrade() {
        update_asset_hash()
    };

    type HeaderField = (Text, Text);
    func certification_header() : HeaderField {
        let cert = switch (CertifiedData.getCertificate()) {
            case (?c) c;
            case null {
                "getCertificate failed. Call this as a query call!" : Blob
            }
        };
        return (
            "ic-certificate",
            "certificate=:" # base64(cert) # ":, " # "tree=:" # base64(cbor_tree(asset_tree())) # ":",
        )
    };

    // CRYPTO STUFF

    func h(b1 : Blob) : Blob {
        let d = SHA256.Digest();
        d.write(Blob.toArray(b1));
        Blob.fromArray(d.sum())
    };
    func h2(b1 : Blob, b2 : Blob) : Blob {
        let d = SHA256.Digest();
        d.write(Blob.toArray(b1));
        d.write(Blob.toArray(b2));
        Blob.fromArray(d.sum())
    };
    func h3(b1 : Blob, b2 : Blob, b3 : Blob) : Blob {
        let d = SHA256.Digest();
        d.write(Blob.toArray(b1));
        d.write(Blob.toArray(b2));
        d.write(Blob.toArray(b3));
        Blob.fromArray(d.sum())
    };

    /*
Base64 encoding.
*/

    func base64(b : Blob) : Text {
        let base64_chars : [Text] = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "/"];
        let bytes = Blob.toArray(b);
        let pad_len = if (bytes.size() % 3 == 0) { 0 } else {
            3 - bytes.size() % 3 : Nat
        };
        let padded_bytes = A.append(bytes, A.tabulate<Nat8>(pad_len, func(_) { 0 }));
        var out = "";
        for (j in Iter.range(1, padded_bytes.size() / 3)) {
            let i = j - 1 : Nat; // annoying inclusive upper bound in Iter.range
            let b1 = padded_bytes[3 * i];
            let b2 = padded_bytes[3 * i +1];
            let b3 = padded_bytes[3 * i +2];
            let c1 = (b1 >> 2) & 63;
            let c2 = (b1 << 4 | b2 >> 4) & 63;
            let c3 = (b2 << 2 | b3 >> 6) & 63;
            let c4 = (b3) & 63;
            out #= base64_chars[Nat8.toNat(c1)] # base64_chars[Nat8.toNat(c2)] # (if (3 * i +1 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c3)] }) # (if (3 * i +2 >= bytes.size()) { "=" } else { base64_chars[Nat8.toNat(c4)] })
        };
        return out
    };

    func hash_tree(t : HashTree) : Hash {
        switch (t) {
            case (#empty) {
                h("\11ic-hashtree-empty")
            };
            case (#fork(t1, t2)) {
                h3("\10ic-hashtree-fork", hash_tree(t1), hash_tree(t2))
            };
            case (#labeled(l, t)) {
                h3("\13ic-hashtree-labeled", l, hash_tree(t))
            };
            case (#leaf(v)) {
                h2("\10ic-hashtree-leaf", v)
            };
            case (#pruned(h)) {
                h
            }
        }
    };

    func cbor_tree(tree : HashTree) : Blob {
        let buf = Buffer.Buffer<Nat8>(100);

        // CBOR self-describing tag
        buf.add(0xD9);
        buf.add(0xD9);
        buf.add(0xF7);

        func add_blob(b : Blob) {
            // Only works for blobs with less than 256 bytes
            buf.add(0x58);
            buf.add(Nat8.fromNat(b.size()));
            for (c in Blob.toArray(b).vals()) {
                buf.add(c)
            }
        };

        func go(t : HashTree) {
            switch (t) {
                case (#empty) { buf.add(0x81); buf.add(0x00) };
                case (#fork(t1, t2)) {
                    buf.add(0x83);
                    buf.add(0x01);
                    go(t1);
                    go(t2)
                };
                case (#labeled(l, t)) {
                    buf.add(0x83);
                    buf.add(0x02);
                    add_blob(l);
                    go(t)
                };
                case (#leaf(v)) { buf.add(0x82); buf.add(0x03); add_blob(v) };
                case (#pruned(h)) { buf.add(0x82); buf.add(0x04); add_blob(h) }
            }
        };

        go(tree);

        return Blob.fromArray(buf.toArray())
    }
}
