// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module sui::bls12381_tests {
    use sui::bls12381;
    use sui::group_ops;
    use std::hash::sha2_256;
    use std::vector;
    use sui::test_utils::assert_eq;

    const ORDER_BYTES: vector<u8> = x"73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001";
    const ORDER_MINUS_ONE_BYTES: vector<u8> = x"73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000000";
    const LONG_SCALAR_BYTES: vector<u8> = x"73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff0000000000";
    const SHORT_SCALAR_BYTES: vector<u8> = x"73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff0000";
    const LONG_G1_BYTES: vector<u8> = x"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bbbbbb";
    const SHORT_G1_BYTES: vector<u8> = x"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb";

    #[test]
    fun test_bls12381_min_sig_valid_sig() {
        let msg = x"0101010101";
        let pk = x"8df101606f91f3cad7f54b8aff0f0f64c41c482d9b9f9fe81d2b607bc5f611bdfa8017cf04b47b44b222c356ef555fbd11058c52c077f5a7ec6a15ccfd639fdc9bd47d005a111dd6cdb8c02fe49608df55a3c9822986ad0b86bdea3abfdfe464";
        let sig = x"908e345f2e2803cd941ae88c218c96194233c9053fa1bca52124787d3cca141c36429d7652435a820c72992d5eee6317";

        let verify = bls12381::bls12381_min_sig_verify(&sig, &pk, &msg);
        assert!(verify == true, 0)
    }

    #[test]
    fun test_bls12381_min_sig_invalid_sig() {
        let msg = x"0201010101";
        let pk = x"8df101606f91f3cad7f54b8aff0f0f64c41c482d9b9f9fe81d2b607bc5f611bdfa8017cf04b47b44b222c356ef555fbd11058c52c077f5a7ec6a15ccfd639fdc9bd47d005a111dd6cdb8c02fe49608df55a3c9822986ad0b86bdea3abfdfe464";
        let sig = x"908e345f2e2803cd941ae88c218c96194233c9053fa1bca52124787d3cca141c36429d7652435a820c72992d5eee6317";

        let verify = bls12381::bls12381_min_sig_verify(&sig, &pk, &msg);
        assert!(verify == false, 0)
    }

    #[test]
    fun test_bls12381_min_sig_invalid_signature_key_length() {
        let msg = x"0201010101";
        let pk = x"606f91f3cad7f54b8aff0f0f64c41c482d9b9f9fe81d2b607bc5f611bdfa8017cf04b47b44b222c356ef555fbd11058c52c077f5a7ec6a15ccfd639fdc9bd47d005a111dd6cdb8c02fe49608df55a3c9822986ad0b86bdea3abfdfe464";
        let sig = x"908e34002e2803cd941ae88c218c96194233c9053fa1bca52124787d3cca141c36429d7652435a820c72992d5eee6317";

        let verify = bls12381::bls12381_min_sig_verify(&sig, &pk, &msg);
        assert!(verify == false, 0)
    }

    #[test]
    fun test_bls12381_min_sig_invalid_public_key_length() {
        let msg = x"0201010101";
        let pk = x"606f91f3cad7f54b8aff0f0f64c41c482d9b9f9fe81d2b607bc5f611bdfa8017cf04b47b44b222c356ef555fbd11058c52c077f5a7ec6a15ccfd639fdc9bd47d005a111dd6cdb8c02fe49608df55a3c9822986ad0b86bdea3abfdfe464";
        let sig = x"908e345f2e2803cd941ae88c218c96194233c9053fa1bca52124787d3cca141c36429d7652435a820c72992d5eee6317";

        let verify = bls12381::bls12381_min_sig_verify(&sig, &pk, &msg);
        assert!(verify == false, 0)
    }

    #[test]
    fun test_bls12381_min_pk_valid_and_invalid_sig() {
        // Test an actual Drand response.
        let pk = x"868f005eb8e6e4ca0a47c8a77ceaa5309a47978a7c71bc5cce96366b5d7a569937c529eeda66c7293784a9402801af31";
        let sig = x"a2cd8577944b84484ef557a7f92f0d5092779497cc470b1b97680b8f7c807d97250d310b801c7c2185c7c8a21032d45403b97530ca87bd8f05d0cf4ffceb4bcb9bf7184fb604967db7e9e6ea555bc51b25a9e41fbd51181f712aa73aaec749fe";
        let prev_sig = x"a96aace596906562dc525dba4dff734642d71b334d51324f9c9bcb5a3d6caf14b05cde91d6507bf4615cb4285e5b4efd1358ebc46b80b51e338f9dc46cca17cf2e046765ba857c04101a560887fa81aef101a5bb3b2350884558bd3adc72be37";
        let round: u64 = 2373935;
        assert!(verify_drand_round(pk, sig, prev_sig, round) == true, 0);
        // Check invalid signatures.
        let invalid_sig = x"11118577944b84484ef557a7f92f0d5092779497cc470b1b97680b8f7c807d97250d310b801c7c2185c7c8a21032d45403b97530ca87bd8f05d0cf4ffceb4bcb9bf7184fb604967db7e9e6ea555bc51b25a9e41fbd51181f712aa73aaec749fe";
        assert!(verify_drand_round(pk, invalid_sig, prev_sig, round) == false, 0);
        assert!(verify_drand_round(pk, sig, prev_sig, round + 1) == false, 0);
    }

    #[test]
    fun test_bls12381_min_pk_invalid_signature_key_length() {
        let pk = x"868f005eb8e6e4ca0a47c8a77ceaa5309a47978a7c71bc5cce96366b5d7a569937c529eeda66c7293784a9402801af31";
        let sig = x"cd8577944b84484ef557a7f92f0d5092779497cc470b1b97680b8f7c807d97250d310b801c7c2185c7c8a21032d45403b97530ca87bd8f05d0cf4ffceb4bcb9bf7184fb604967db7e9e6ea555bc51b25a9e41fbd51181f712aa73aaec749fe";
        let prev_sig = x"a96aace596906562dc525dba4dff734642d71b334d51324f9c9bcb5a3d6caf14b05cde91d6507bf4615cb4285e5b4efd1358ebc46b80b51e338f9dc46cca17cf2e046765ba857c04101a560887fa81aef101a5bb3b2350884558bd3adc72be37";
        let round: u64 = 2373935;
        assert!(verify_drand_round(pk, sig, prev_sig, round) == false, 0);
    }

    #[test]
    fun test_bls12381_min_pk_invalid_public_key_length() {
        let pk = x"8f005eb8e6e4ca0a47c8a77ceaa5309a47978a7c71bc5cce96366b5d7a569937c529eeda66c7293784a9402801af31";
        let sig = x"a2cd8577944b84484ef557a7f92f0d5092779497cc470b1b97680b8f7c807d97250d310b801c7c2185c7c8a21032d45403b97530ca87bd8f05d0cf4ffceb4bcb9bf7184fb604967db7e9e6ea555bc51b25a9e41fbd51181f712aa73aaec749fe";
        let prev_sig = x"a96aace596906562dc525dba4dff734642d71b334d51324f9c9bcb5a3d6caf14b05cde91d6507bf4615cb4285e5b4efd1358ebc46b80b51e338f9dc46cca17cf2e046765ba857c04101a560887fa81aef101a5bb3b2350884558bd3adc72be37";
        let round: u64 = 2373935;
        assert!(verify_drand_round(pk, sig, prev_sig, round) == false, 0);
    }

    fun verify_drand_round(pk: vector<u8>, sig: vector<u8>, prev_sig: vector<u8>, round: u64): bool {
        // The signed message can be computed in Rust using:
        //  let mut sha = Sha256::new();
        //  sha.update(&prev_sig);
        //  sha.update(round.to_be_bytes());
        //  let digest = sha.finalize().digest;
        let round_bytes: vector<u8> = vector[0, 0, 0, 0, 0, 0, 0, 0];
        let i = 7;
        while (i > 0) {
            let curr_byte = round % 0x100;
            let curr_element = vector::borrow_mut(&mut round_bytes, i);
            *curr_element = (curr_byte as u8);
            round = round >> 8;
            i = i - 1;
        };
        vector::append(&mut prev_sig, round_bytes);
        let digest = sha2_256(prev_sig);
        bls12381::bls12381_min_pk_verify(&sig, &pk, &digest)
    }


    //// Group operations ////

    #[test]
    fun test_scalar_ops() {
        let zero = bls12381::scalar_from_u64(0);
        let one = bls12381::scalar_from_u64(1);

        assert!(group_ops::equal(&zero, &bls12381::scalar_zero()), 0);
        assert!(group_ops::equal(&one, &bls12381::scalar_one()), 0);
        assert!(group_ops::equal(&zero, &bls12381::scalar_one()) == false, 0);

        let two = bls12381::scalar_add(&one, &one);
        let four = bls12381::scalar_add(&two, &two);
        assert!(group_ops::equal(&four, &bls12381::scalar_from_u64(4)), 0);

        let eight = bls12381::scalar_mul(&four, &two);
        assert!(group_ops::equal(&eight, &bls12381::scalar_from_u64(8)), 0);

        let eight_from_bytes = bls12381::scalar_from_bytes(group_ops::bytes(&eight));
        assert!(group_ops::equal(&eight, &eight_from_bytes), 0);

        let six = bls12381::scalar_sub(&eight, &two);
        assert!(group_ops::equal(&six, &bls12381::scalar_from_u64(6)), 0);

        let three = bls12381::scalar_div(&two, &six);
        assert!(group_ops::equal(&three, &bls12381::scalar_from_u64(3)), 0);

        let minus_three = bls12381::scalar_neg(&three);
        assert!(group_ops::equal(&bls12381::scalar_add(&minus_three, &six), &bls12381::scalar_from_u64(3)), 0);

        let inv_three = bls12381::scalar_inv(&three);
        assert!(group_ops::equal(&bls12381::scalar_mul(&six, &inv_three), &bls12381::scalar_from_u64(2)), 0);

        let order_minus_one = bls12381::scalar_from_bytes(&ORDER_MINUS_ONE_BYTES);
        let _ = bls12381::scalar_add(&order_minus_one, &order_minus_one);
        let _ = bls12381::scalar_mul(&order_minus_one, &order_minus_one);
    }

    #[test]
    #[expected_failure(abort_code = group_ops::EInvalidInput)]
    fun test_invalid_scalar_order() {
        let _ = bls12381::scalar_from_bytes(&ORDER_BYTES);
    }

    #[test]
    #[expected_failure(abort_code = group_ops::EInvalidInput)]
    fun test_invalid_scalar_too_short() {
        let _ = bls12381::scalar_from_bytes(&SHORT_SCALAR_BYTES);
    }

    #[test]
    #[expected_failure(abort_code = group_ops::EInvalidInput)]
    fun test_invalid_scalar_too_long() {
        let _ = bls12381::scalar_from_bytes(&LONG_SCALAR_BYTES);
    }

    #[test]
    #[expected_failure(abort_code = group_ops::EInvalidInput)]
    fun test_invalid_scalar_div() {
        let a = bls12381::scalar_from_u64(0);
        let b = bls12381::scalar_from_u64(10);
        let _ = bls12381::scalar_div(&a, &b);
    }

    #[test]
    #[expected_failure(abort_code = group_ops::EInvalidInput)]
    fun test_invalid_scalar_inv() {
        let a = bls12381::scalar_from_u64(0);
        let _ = bls12381::scalar_inv(&a);
    }

    #[test]
    fun test_g1_ops() {
        let id = bls12381::g1_identity();
        let g = bls12381::g1_generator();

        let two_g = bls12381::g1_add(&g, &g);
        let four_g = bls12381::g1_add(&two_g, &two_g);

        let another_four_g = bls12381::g1_add(&id, &four_g);
        assert!(group_ops::equal(&four_g, &another_four_g), 0);

        let another_four_g = bls12381::g1_mul(&bls12381::scalar_from_u64(4), &g);
        assert!(group_ops::equal(&four_g, &another_four_g), 0);

        let another_two_g = bls12381::g1_div(&bls12381::scalar_from_u64(2), &four_g);
        assert!(group_ops::equal(&two_g, &another_two_g), 0);

        let another_two_g = bls12381::g1_sub(&four_g, &two_g);
        assert!(group_ops::equal(&two_g, &another_two_g), 0);

        let minus_two_g = bls12381::g1_neg(&two_g);
        let another_two_g = bls12381::g1_add(&minus_two_g, &four_g);
        assert!(group_ops::equal(&two_g, &another_two_g), 0);

        let order_minus_one = bls12381::scalar_from_bytes(&ORDER_MINUS_ONE_BYTES);
        let _ = bls12381::g1_mul(&order_minus_one, &g);

        let msg1 = b"123";
        let msg2 = b"321";
        let hash1 = bls12381::hash_to_g1(&msg1);
        let hash2 = bls12381::hash_to_g1(&msg2);
        assert!(group_ops::equal(&hash1, &hash2) == false, 0);

        // TODO: msm
    }

    #[test]
    #[expected_failure(abort_code = group_ops::EInvalidInput)]
    fun test_invalid_g1_too_short() {
        let _ = bls12381::g1_from_bytes(&SHORT_G1_BYTES);
    }

    #[test]
    #[expected_failure(abort_code = group_ops::EInvalidInput)]
    fun test_invalid_g1_too_long() {
        let _ = bls12381::g1_from_bytes(&LONG_G1_BYTES);
    }

    #[test]
    #[expected_failure(abort_code = group_ops::EInvalidInput)]
    fun test_invalid_g1_div() {
        let a = bls12381::scalar_from_u64(0);
        let b = bls12381::g1_generator();
        let _ = bls12381::g1_div(&a, &b);
    }

    // TODO: same tests for G2

    #[test]
    fun test_gt_ops() {
        let id = bls12381::gt_identity();
        let g = bls12381::gt_generator();

        let two_g = bls12381::gt_add(&g, &g);
        let four_g = bls12381::gt_add(&two_g, &two_g);

        let another_four_g = bls12381::gt_add(&id, &four_g);
        assert!(group_ops::equal(&four_g, &another_four_g), 0);

        let another_four_g = bls12381::gt_mul(&bls12381::scalar_from_u64(4), &g);
        assert!(group_ops::equal(&four_g, &another_four_g), 0);

        let another_two_g = bls12381::gt_div(&bls12381::scalar_from_u64(2), &four_g);
        assert!(group_ops::equal(&two_g, &another_two_g), 0);

        let another_two_g = bls12381::gt_sub(&four_g, &two_g);
        assert!(group_ops::equal(&two_g, &another_two_g), 0);

        let minus_two_g = bls12381::gt_neg(&two_g);
        let another_two_g = bls12381::gt_add(&minus_two_g, &four_g);
        assert!(group_ops::equal(&two_g, &another_two_g), 0);

        let order_minus_one = bls12381::scalar_from_bytes(&ORDER_MINUS_ONE_BYTES);
        let _ = bls12381::gt_mul(&order_minus_one, &g);
    }

    // TODO: test failuers for GT

    #[test]
    fun test_msm_g1() {
        let i = 1;
        let expected_result = bls12381::g1_identity();
        let g = bls12381::g1_generator();
        let scalars: vector<group_ops::Element<bls12381::Scalar>> = vector::empty();
        let elements: vector<group_ops::Element<bls12381::G1>> = vector::empty();
        while (i < 20) {
            let scalar = bls12381::scalar_from_u64(i);
            vector::push_back(&mut elements, g);
            let g = bls12381::g1_mul(&scalar, &g);
            vector::push_back(&mut scalars, scalar);
            expected_result = bls12381::g1_add(&expected_result, &g);
            i = i + 1;
        };
        let result = bls12381::g1_multi_scalar_multiplication(&scalars, &elements);
        assert!(group_ops::equal(&result, &expected_result), 0);
    }

    #[test]
    fun test_msm_g2() {
        let i = 1;
        let expected_result = bls12381::g2_identity();
        let g = bls12381::g2_generator();
        let scalars: vector<group_ops::Element<bls12381::Scalar>> = vector::empty();
        let elements: vector<group_ops::Element<bls12381::G2>> = vector::empty();
        while (i < 20) {
            let scalar = bls12381::scalar_from_u64(i);
            vector::push_back(&mut elements, g);
            let g = bls12381::g2_mul(&scalar, &g);
            vector::push_back(&mut scalars, scalar);
            expected_result = bls12381::g2_add(&expected_result, &g);
            i = i + 1;
        };
        let result = bls12381::g2_multi_scalar_multiplication(&scalars, &elements);
        assert!(group_ops::equal(&result, &expected_result), 0);
    }

    #[test]
    fun test_pairing() {
        let g1 = bls12381::g1_generator();
        let g2 = bls12381::g2_generator();
        let gt = bls12381::gt_generator();
        assert_eq(bls12381::pairing(&g1, &g2), gt);

        let g1_3 = bls12381::g1_mul(&bls12381::scalar_from_u64(3), &g1);
        let g2_5 = bls12381::g2_mul(&bls12381::scalar_from_u64(5), &g2);
        let gt_5 = bls12381::gt_mul(&bls12381::scalar_from_u64(15), &gt);
        assert_eq(bls12381::pairing(&g1_3, &g2_5), gt_5);
    }

    // #[test]
    // fun test_regression() {
    //     // Based on the RFC
    //     let rfc_four_g = x"da80862773358b466ffadfe0b3293ab3d9fd53c5ea6c955358f568322daf6a57";
    //     let four_g = ristretto255::g_mul(&ristretto255::scalar_from_u64(4), &ristretto255::g_generator());
    //     assert!(rfc_four_g == *group_ops::bytes(&four_g), 0);
    //
    //     // TODO: add more checks
    // }


}