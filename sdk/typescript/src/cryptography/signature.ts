// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import { fromB64, toB64 } from '@mysten/bcs';
import { Ed25519PublicKey } from './ed25519-publickey';
import { PublicKey } from './publickey';
import { Secp256k1PublicKey } from './secp256k1-publickey';
import { Secp256r1PublicKey } from './secp256r1-publickey';

/**
 * A keypair used for signing transactions.
 */
export type SignatureScheme = 'ED25519' | 'Secp256k1' | 'Secp256r1';

/**
 * Pair of signature and corresponding public key
 */
export type SignaturePubkeyPair = {
  signatureScheme: SignatureScheme;
  /** Base64-encoded signature */
  signature: Uint8Array;
  /** Base64-encoded public key */
  pubKey: PublicKey;
};

/**
 * (`flag || signature || pubkey` bytes, as base-64 encoded string).
 * Signature is committed to the intent message of the transaction data, as base-64 encoded string.
 */
export type SerializedSignature = string;

export const SIGNATURE_SCHEME_TO_FLAG = {
  ED25519: 0x00,
  Secp256k1: 0x01,
  Secp256r1: 0x02,
};

export const SIGNATURE_FLAG_TO_SCHEME = {
  0x00: 'ED25519',
  0x01: 'Secp256k1',
  0x02: 'Secp256r1',
} as const;

export function toSerializedSignature({
  signature,
  signatureScheme,
  pubKey,
}: SignaturePubkeyPair): SerializedSignature {
  const serializedSignature = new Uint8Array(
    1 + signature.length + pubKey.toBytes().length,
  );
  serializedSignature.set([SIGNATURE_SCHEME_TO_FLAG[signatureScheme]]);
  serializedSignature.set(signature, 1);
  serializedSignature.set(pubKey.toBytes(), 1 + signature.length);
  return toB64(serializedSignature);
}

export function fromSerializedSignature(
  serializedSignature: SerializedSignature,
): SignaturePubkeyPair {
  const bytes = fromB64(serializedSignature);
  const signatureScheme =
    SIGNATURE_FLAG_TO_SCHEME[bytes[0] as keyof typeof SIGNATURE_FLAG_TO_SCHEME];

  const PublicKey = (function () {
    switch (signatureScheme) {
      case 'ED25519':
        return Ed25519PublicKey;
      case 'Secp256k1':
        return Secp256k1PublicKey;
      case 'Secp256r1':
        return Secp256r1PublicKey;
    }
  })();

  const signature = bytes.slice(1, bytes.length - PublicKey.SIZE);
  const pubkeyBytes = bytes.slice(1 + signature.length);
  const pubKey = new PublicKey(pubkeyBytes);

  return {
    signatureScheme,
    signature,
    pubKey,
  };
}
