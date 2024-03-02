import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import CRC32 "mo:hash/CRC32";
import Sha256 "mo:sha2/Sha256";

module {
	// 32-byte array.
	public type AccountIdentifier = Blob;
	// 32-byte array.
	public type Subaccount = Blob;

	func beBytes(n : Nat32) : [Nat8] {
		func byte(n : Nat32) : Nat8 {
			Nat8.fromNat(Nat32.toNat(n & 0xff));
		};
		[byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)];
	};

	public func principalToSubaccount(id : Principal) : [Nat8] {
		let p = Blob.toArray(Principal.toBlob(id));
		Array.tabulate(
			32,
			func(i : Nat) : Nat8 {
				if (i >= p.size() + 1) 0 else if (i == 0) (Nat8.fromNat(p.size())) else (p[i - 1]);
			},
		);
	};

	public func defaultSubaccount() : Subaccount {
		Blob.fromArrayMut(Array.init(32, 0 : Nat8));
	};

	public func accountIdentifier(principal : Principal, subaccount : Subaccount) : AccountIdentifier {
		let hash = Sha256.Digest(#sha224);
		hash.writeArray([0x0A]);
		hash.writeArray(Blob.toArray(Text.encodeUtf8("account-id")));
		hash.writeArray(Blob.toArray(Principal.toBlob(principal)));
		hash.writeArray(Blob.toArray(subaccount));
		let hashSum = hash.sum();
		let crc32Bytes = beBytes(CRC32.checksum(Blob.toArray(hashSum)));
		Blob.fromArray(Array.append(crc32Bytes, Blob.toArray(hashSum)));
	};

	public func validateAccountIdentifier(accountIdentifier : AccountIdentifier) : Bool {
		if (accountIdentifier.size() != 32) {
			return false;
		};
		let a = Blob.toArray(accountIdentifier);
		let accIdPart = Array.tabulate(28, func(i : Nat) : Nat8 { a[i + 4] });
		let checksumPart = Array.tabulate(4, func(i : Nat) : Nat8 { a[i] });
		let crc32 = CRC32.checksum(accIdPart);
		Array.equal(beBytes(crc32), checksumPart, Nat8.equal);
	};
};
