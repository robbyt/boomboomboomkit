    r1 = arg1;
    r0 = arg0;
    r31 = r31 - 0xf0;
    var_60 = d9;
    decomp_var_58 = d8;
    var_50 = r28;
    decomp_var_48 = r27;
    var_40 = r26;
    decomp_var_38 = r25;
    var_30 = r24;
    decomp_var_28 = r23;
    var_20 = r22;
    decomp_var_18 = r21;
    var_10 = r20;
    decomp_var_8 = r19;
    saved_fp = r29;
    decomp_var_m8 = r30;
    r8 = *(int8_t *)r0;
    d8 = 0x0;
    if (r8 == 0x0) goto .l7;
    goto loc_102306b64;

.l7:
    return r0;

loc_102306b64:
    r20 = r1;
    if (r8 == 0x1) goto loc_102306b90;
    goto loc_102306b70;

loc_102306b90:
    r9 = r0[0x1];
    r9 = *r9;
    r10 = 0xcccccccccccccccd;
    if ((SAR(r9[0x1] - r9, 0x3)) * 0xcccccccccccccccd == 0x0) goto .l7;
    goto loc_102306bb0;

loc_102306b70:
    if (r8 != 0x2) goto .l13;
    goto loc_102306b78;

loc_102306bb0:
    var_78 = 0x0;
    var_A0 = r0;
    var_98 = 0x0;
    r9 = 0x8000000000000000;
    var_90 = 0x0;
    var_88 = 0x8000000000000000;
    if (r8 == 0x0) goto loc_102306c20;
    goto loc_102306bc8;

.l13:
    var_78 = 0x0;
    var_A0 = r0;
    var_98 = 0x0;
    r9 = 0x8000000000000000;
    var_90 = 0x0;
    var_88 = 0x8000000000000000;
    if (r8 == 0x0) goto .l15;
    goto .l19;

loc_102306b78:
    r9 = r0[0x1];
    r9 = *r9;
    r10 = r9[0x1];
    if (SAR(r10 - r9, 0x4) != 0x0) goto .l11;
    goto .l7;

loc_102306c20:
    var_88 = 0x1;
    goto loc_102306c30;

loc_102306bc8:
    if (r8 == 0x2) goto loc_102306bfc;
    goto loc_102306bd0;

.l15:
    var_88 = 0x1;
    goto .l12;

.l19:
    if (r8 == 0x2) goto .l14;
    goto .l18;

.l11:
    var_78 = 0x0;
    var_A0 = r0;
    var_98 = 0x0;
    r9 = 0x8000000000000000;
    var_90 = 0x0;
    var_88 = 0x8000000000000000;
    if (r8 == 0x0) goto .l4;
    goto .l9;

loc_102306c30:
    var_C8 = r0;
    r8 = 0x1;
    var_B0 = 0x1;
    goto loc_102306c3c;

loc_102306bfc:
    r8 = r0[0x1];
    var_90 = *r8;
    var_C8 = r0;
    r9 = 0x8000000000000000;
    var_B0 = 0x8000000000000000;
    r8 = r8[0x1];
    goto loc_102306c3c;

loc_102306bd0:
    if (r8 != 0x1) goto loc_102306c2c;
    goto loc_102306bd8;

.l12:
    var_C8 = r0;
    r8 = 0x1;
    var_B0 = 0x1;
    goto .l16;

.l14:
    r8 = r0[0x1];
    var_90 = *r8;
    var_C8 = r0;
    r9 = 0x8000000000000000;
    var_B0 = 0x8000000000000000;
    r8 = r8[0x1];
    goto .l16;

.l18:
    if (r8 != 0x1) goto .l10;
    goto .l17;

.l4:
    var_88 = 0x1;
    goto .l2;

.l9:
    if (r8 == 0x2) goto .l3;
    goto .l8;

loc_102306c3c:
    r19 = 0x0;
    r27 = 0x0;
    r24 = 0x0;
    while (true) {
            r0 = bool nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const>::operator==<nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const>, (&var_A0);
            if (r0 != 0x0) {
                    if ((r20 & 0x1) != 0x0) {
                            r21 = r24 - r19;
                            r8 = r21 >> 0x2;
                            r9 = 0x1;
                            var_B0 = 0x0;
                            var_A8 = 0x0;
                            if (r8 != 0x0) {
                                    r0 = operator new(r21 & 0x3fffffffc);
                                    var_B0 = r0;
                                    r8 = 0x1;
                                    var_A8 = 0x1;
                                    if (r19 != r24) {
                                            r9 = r21 - 0x4;
                                            if (r9 >= 0x3c) {
                                                    r10 = r0 - r19;
                                                    r8 = r19;
                                                    if (r10 >= 0x40) {
                                                            r9 = (r9 >> 0x2) + 0x1;
                                                            r10 = r9 & 0x7ffffffffffffff0;
                                                            r8 = r19 + (r10 << 0x2);
                                                            r11 = r0 + (r10 << 0x2);
                                                            r12 = r19 + 0x20;
                                                            r13 = r0 + 0x20;
                                                            r14 = r10;
                                                            temp_0 = 0x6;
                                                    }
                                                    else {
                                                            temp_0 = 0x1;
                                                    }
                                            }
                                            else {
                                                    r8 = r19;
                                                    temp_0 = 0x8;
                                            }
                                    }
                                    else {
                                            temp_0 = 0x0;
                                    }
                            }
                            else {
                                    temp_0 = 0x0;
                            }
                    }
                    else {
                            r25 = r24 - r19;
                            r23 = r25 >> 0x2;
                            if (r23 != 0x0) {
                                    r0 = operator new(r25 & 0x3fffffffc);
                                    r21 = r0;
                                    if (r19 != r24) {
                                            r10 = r25 - 0x4;
                                            if (r10 >= 0x3c) {
                                                    r11 = r21 - r19;
                                                    r8 = r19;
                                                    r9 = r21;
                                                    if (r11 >= 0x40) {
                                                            r10 = (r10 >> 0x2) + 0x1;
                                                            r11 = r10 & 0x7ffffffffffffff0;
                                                            r8 = r19 + (r11 << 0x2);
                                                            r9 = r21 + (r11 << 0x2);
                                                            r12 = r19 + 0x20;
                                                            r13 = r21 + 0x20;
                                                            r14 = r11;
                                                            temp_0 = 0x7;
                                                    }
                                                    else {
                                                            temp_0 = 0x3;
                                                    }
                                            }
                                            else {
                                                    r8 = r19;
                                                    r9 = r21;
                                                    temp_0 = 0x9;
                                            }
                                    }
                                    else {
                                            temp_0 = 0x2;
                                    }
                            }
                            else {
                                    r22 = 0x0;
                                    r21 = 0x0;
                                    temp_0 = 0xa;
                            }
                    }
                    break;
            }
            r21 = "bpm";
            r0 = nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const>::operator*();
            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
            var_E0 = 0x0;
            r0 = void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E0);
            r28 = var_E0;
            if (r24 < r27) {
                    *(int32_t *)r24 = r28;
                    r24 = r24 + 0x4;
                    r8 = *(int8_t *)var_A0;
                    if (r8 == 0x2) {
                            r8 = var_90 + 0x10;
                            var_90 = r8;
                            continue;
                    }
                    if (r8 == 0x1) {
                            r8 = var_98 + 0x28;
                            var_98 = r8;
                    }
                    else {
                            r8 = var_88 + 0x1;
                            var_88 = r8;
                    }
                    continue;
            }
            r22 = r24 - r19;
            r24 = SAR(r22, 0x2);
            r8 = r24 + 0x1;
            r9 = r8 >> 0x3e;
            if (r9 != 0x0) {
                    r0 = std::__1::vector<int, std::__1::allocator<int> >::__throw_length_error[abi:v15006]();
                    temp_0 = 0x5;
                    break;
            }
            r9 = r27 - r19;
            r10 = SAR(r9, 0x1);
            if (r10 > r8) {
                    r8 = r10;
            }
            if (r9 >= 0x7ffffffffffffffc) {
                    r27 = 0x3fffffffffffffff;
            }
            else {
                    r27 = r8;
            }
            if (r27 == 0x0) {
                    r27 = 0x0 + r27 * 0x4;
                    *(int32_t *)(0x0 + r24 * 0x4) = r28;
                    r24 = r24 * 0x4 + 0x4;
                    memmove(0x0, r19, r22);
                    var_78 = 0x0;
                    if (r19 != 0x0) {
                            operator delete(r19);
                    }
                    r23 = 0x0;
                    r19 = 0x0;
                    r8 = *(int8_t *)var_A0;
                    if (r8 == 0x2) {
                            r8 = var_90 + 0x10;
                            var_90 = r8;
                            continue;
                    }
                    if (r8 == 0x1) {
                            r8 = var_98 + 0x28;
                            var_98 = r8;
                    }
                    else {
                            r8 = var_88 + 0x1;
                            var_88 = r8;
                    }
                    continue;
            }
            r8 = r27 >> 0x3e;
            if (r8 == 0x0) {
                    r23 = operator new(r27 << 0x2);
                    r27 = r23 + r27 * 0x4;
                    *(int32_t *)(r23 + r24 * 0x4) = r28;
                    r24 = r23 + r24 * 0x4 + 0x4;
                    memmove(r23, r19, r22);
                    var_78 = r23;
                    if (r19 != 0x0) {
                            operator delete(r19);
                    }
                    r19 = r23;
                    r8 = *(int8_t *)var_A0;
                    if (r8 == 0x2) {
                            r8 = var_90 + 0x10;
                            var_90 = r8;
                            continue;
                    }
                    if (r8 == 0x1) {
                            r8 = var_98 + 0x28;
                            var_98 = r8;
                    }
                    else {
                            r8 = var_88 + 0x1;
                            var_88 = r8;
                    }
                    continue;
            }
            r0 = std::__throw_bad_array_new_length[abi:v15006]();
            temp_0 = 0x4;
            break;
    }
    if (temp_0 != 0x0) {
            if (temp_0 != 0x1) {
                    if (temp_0 != 0x2) {
                            if (temp_0 != 0x3) {
                                    if (temp_0 != 0x4 && temp_0 != 0x5) {
                                            if (temp_0 != 0x6) {
                                                    if (temp_0 != 0x7) {
                                                            if (temp_0 != 0x8) {
                                                                    if (temp_0 == 0x9) {
                                                                            do {
                                                                                    r10 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    *(int32_t *)r9 = r10;
                                                                                    r9 = r9 + 0x4;
                                                                            } while (r8 != r24);
                                                                            r22 = 0x1;
                                                                    }
                                                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                                    r24 = var_A0;
                                                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                                    r9 = var_A0;
                                                                    r8 = r9 + zero_extend_64(r23) * 0x4;
                                                                    if (r24 != r8) {
                                                                            asm { ubfx       x10, x25, #0x2, #0x20 };
                                                                            r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                                                            if (r9 < 0x1c) {
                                                                                    d8 = 0x0;
                                                                                    r9 = r24;
                                                                                    do {
                                                                                            r10 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            d8 = d8 + r10;
                                                                                    } while (r9 != r8);
                                                                            }
                                                                            else {
                                                                                    r10 = (r9 >> 0x2) + 0x1;
                                                                                    r11 = r10 & 0x7ffffffffffffff8;
                                                                                    r9 = r24 + r11 * 0x4;
                                                                                    r12 = r24 + 0x10;
                                                                                    v0 = 0x0;
                                                                                    r13 = r11;
                                                                                    v1 = 0x0;
                                                                                    v2 = 0x0;
                                                                                    v3 = 0x0;
                                                                                    do {
                                                                                            r12 = r12 + 0x20;
                                                                                            asm { sshll      v4.2d, v4.2s, #0x0 };
                                                                                            asm { sshll      v5.2d, v5.2s, #0x0 };
                                                                                            asm { sshll      v6.2d, v6.2s, #0x0 };
                                                                                            asm { sshll      v7.2d, v7.2s, #0x0 };
                                                                                            v0 = v0 + v4;
                                                                                            v1 = v1 + v5;
                                                                                            v2 = v2 + v6;
                                                                                            v3 = v3 + v7;
                                                                                            r13 = r13 - 0x8;
                                                                                    } while (r13 != 0x0);
                                                                                    asm { faddp      d8, v0.2d };
                                                                                    if (r10 != r11) {
                                                                                            r10 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            d8 = d8 + r10;
                                                                                            if (r9 != r8) {
                                                                                                    continue;
                                                                                            }
                                                                                            break;
                                                                                    }
                                                                            }
                                                                    }
                                                                    else {
                                                                            d8 = 0x0;
                                                                    }
                                                                    r0 = operator new(0x8);
                                                                    d8 = d8 / r23;
                                                                    *r0 = d8;
                                                                    if ((r20 & 0x1) == 0x0) {
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r22 != 0x0 && r21 != 0x0) {
                                                                                    r0 = r21;
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                                    else {
                                                                            if (var_80 != 0x0) {
                                                                                    r0 = var_88;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                                    r0 = operator delete(var_E0);
                                                                            }
                                                                            if (var_A8 != 0x0) {
                                                                                    r0 = var_B0;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                            }
                                                            else {
                                                                    do {
                                                                            r9 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            *(int32_t *)r0 = r9;
                                                                            r0 = r0 + 0x4;
                                                                    } while (r8 != r24);
                                                                    var_C9 = 0x6;
                                                                    var_E0 = 0x656e696c;
                                                                    r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
                                                                    d8 = *var_88;
                                                                    if ((r20 & 0x1) != 0x0) {
                                                                            if (var_80 != 0x0) {
                                                                                    r0 = var_88;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                                    r0 = operator delete(var_E0);
                                                                            }
                                                                            if (var_A8 != 0x0) {
                                                                                    r0 = var_B0;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                                    else {
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r22 != 0x0 && r21 != 0x0) {
                                                                                    r0 = r21;
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                            }
                                                    }
                                                    else {
                                                            do {
                                                                    q0 = r12[0xfffffffffffffffc];
                                                                    q1 = r12[0xfffffffffffffffe];
                                                                    q2 = *r12;
                                                                    q3 = r12[0x2];
                                                                    r12 = r12 + 0x40;
                                                                    r13[0xfffffffffffffffc] = q0;
                                                                    r13[0xfffffffffffffffe] = q1;
                                                                    *r13 = q2;
                                                                    r13[0x2] = q3;
                                                                    r13 = r13 + 0x40;
                                                                    r14 = r14 - 0x10;
                                                            } while (r14 != 0x0);
                                                            if (r10 != r11) {
                                                                    do {
                                                                            r10 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            *(int32_t *)r9 = r10;
                                                                            r9 = r9 + 0x4;
                                                                    } while (r8 != r24);
                                                            }
                                                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                            r24 = var_A0;
                                                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                            r9 = var_A0;
                                                            r8 = r9 + zero_extend_64(r23) * 0x4;
                                                            if (r24 != r8) {
                                                                    asm { ubfx       x10, x25, #0x2, #0x20 };
                                                                    r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                                                    if (r9 < 0x1c) {
                                                                            d8 = 0x0;
                                                                            r9 = r24;
                                                                            do {
                                                                                    r10 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    d8 = d8 + r10;
                                                                            } while (r9 != r8);
                                                                    }
                                                                    else {
                                                                            r10 = (r9 >> 0x2) + 0x1;
                                                                            r11 = r10 & 0x7ffffffffffffff8;
                                                                            r9 = r24 + r11 * 0x4;
                                                                            r12 = r24 + 0x10;
                                                                            v0 = 0x0;
                                                                            r13 = r11;
                                                                            v1 = 0x0;
                                                                            v2 = 0x0;
                                                                            v3 = 0x0;
                                                                            do {
                                                                                    r12 = r12 + 0x20;
                                                                                    asm { sshll      v4.2d, v4.2s, #0x0 };
                                                                                    asm { sshll      v5.2d, v5.2s, #0x0 };
                                                                                    asm { sshll      v6.2d, v6.2s, #0x0 };
                                                                                    asm { sshll      v7.2d, v7.2s, #0x0 };
                                                                                    v0 = v0 + v4;
                                                                                    v1 = v1 + v5;
                                                                                    v2 = v2 + v6;
                                                                                    v3 = v3 + v7;
                                                                                    r13 = r13 - 0x8;
                                                                            } while (r13 != 0x0);
                                                                            asm { faddp      d8, v0.2d };
                                                                            if (r10 != r11) {
                                                                                    r10 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    d8 = d8 + r10;
                                                                                    if (r9 != r8) {
                                                                                            continue;
                                                                                    }
                                                                                    break;
                                                                            }
                                                                    }
                                                            }
                                                            else {
                                                                    d8 = 0x0;
                                                            }
                                                            r0 = operator new(0x8);
                                                            d8 = d8 / r23;
                                                            *r0 = d8;
                                                            if ((r20 & 0x1) == 0x0) {
                                                                    if (r0 != 0x0) {
                                                                            r0 = operator delete(r0);
                                                                    }
                                                                    if (0x1 != 0x0 && r21 != 0x0) {
                                                                            r0 = r21;
                                                                            r0 = operator delete(r0);
                                                                    }
                                                                    if (r19 != 0x0) {
                                                                            r0 = operator delete(r19);
                                                                    }
                                                            }
                                                            else {
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                    }
                                                                    if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                            r0 = operator delete(var_E0);
                                                                    }
                                                                    if (var_A8 != 0x0) {
                                                                            r0 = var_B0;
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                    }
                                                                    if (r19 != 0x0) {
                                                                            r0 = operator delete(r19);
                                                                    }
                                                            }
                                                    }
                                            }
                                            else {
                                                    do {
                                                            q0 = r12[0xfffffffffffffffc];
                                                            q1 = r12[0xfffffffffffffffe];
                                                            q2 = *r12;
                                                            q3 = r12[0x2];
                                                            r12 = r12 + 0x40;
                                                            r13[0xfffffffffffffffc] = q0;
                                                            r13[0xfffffffffffffffe] = q1;
                                                            *r13 = q2;
                                                            r13[0x2] = q3;
                                                            r13 = r13 + 0x40;
                                                            r14 = r14 - 0x10;
                                                    } while (r14 != 0x0);
                                                    r0 = r11;
                                                    if (r9 != r10) {
                                                            do {
                                                                    r9 = *(int32_t *)r8;
                                                                    r8 = r8 + 0x4;
                                                                    *(int32_t *)r0 = r9;
                                                                    r0 = r0 + 0x4;
                                                            } while (r8 != r24);
                                                    }
                                                    var_C9 = 0x6;
                                                    var_E0 = 0x656e696c;
                                                    r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
                                                    d8 = *var_88;
                                                    if ((r20 & 0x1) != 0x0) {
                                                            if (var_80 != 0x0) {
                                                                    r0 = var_88;
                                                                    if (r0 != 0x0) {
                                                                            r0 = operator delete(r0);
                                                                    }
                                                            }
                                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                    r0 = operator delete(var_E0);
                                                            }
                                                            if (var_A8 != 0x0) {
                                                                    r0 = var_B0;
                                                                    if (r0 != 0x0) {
                                                                            r0 = operator delete(r0);
                                                                    }
                                                            }
                                                            if (r19 != 0x0) {
                                                                    r0 = operator delete(r19);
                                                            }
                                                    }
                                                    else {
                                                            if (r0 != 0x0) {
                                                                    r0 = operator delete(r0);
                                                            }
                                                            if (r22 != 0x0 && r21 != 0x0) {
                                                                    r0 = r21;
                                                                    r0 = operator delete(r0);
                                                            }
                                                            if (r19 != 0x0) {
                                                                    r0 = operator delete(r19);
                                                            }
                                                    }
                                            }
                                    }
                            }
                            else {
                                    do {
                                            r10 = *(int32_t *)r8;
                                            r8 = r8 + 0x4;
                                            *(int32_t *)r9 = r10;
                                            r9 = r9 + 0x4;
                                    } while (r8 != r24);
                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                    r24 = var_A0;
                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                    r9 = var_A0;
                                    r8 = r9 + zero_extend_64(r23) * 0x4;
                                    if (r24 != r8) {
                                            asm { ubfx       x10, x25, #0x2, #0x20 };
                                            r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                            if (r9 < 0x1c) {
                                                    d8 = 0x0;
                                                    r9 = r24;
                                                    do {
                                                            r10 = *(int32_t *)r9;
                                                            r9 = r9 + 0x4;
                                                            d8 = d8 + r10;
                                                    } while (r9 != r8);
                                            }
                                            else {
                                                    r10 = (r9 >> 0x2) + 0x1;
                                                    r11 = r10 & 0x7ffffffffffffff8;
                                                    r9 = r24 + r11 * 0x4;
                                                    r12 = r24 + 0x10;
                                                    v0 = 0x0;
                                                    r13 = r11;
                                                    v1 = 0x0;
                                                    v2 = 0x0;
                                                    v3 = 0x0;
                                                    do {
                                                            r12 = r12 + 0x20;
                                                            asm { sshll      v4.2d, v4.2s, #0x0 };
                                                            asm { sshll      v5.2d, v5.2s, #0x0 };
                                                            asm { sshll      v6.2d, v6.2s, #0x0 };
                                                            asm { sshll      v7.2d, v7.2s, #0x0 };
                                                            v0 = v0 + v4;
                                                            v1 = v1 + v5;
                                                            v2 = v2 + v6;
                                                            v3 = v3 + v7;
                                                            r13 = r13 - 0x8;
                                                    } while (r13 != 0x0);
                                                    asm { faddp      d8, v0.2d };
                                                    if (r10 != r11) {
                                                            r10 = *(int32_t *)r9;
                                                            r9 = r9 + 0x4;
                                                            d8 = d8 + r10;
                                                            if (r9 != r8) {
                                                                    continue;
                                                            }
                                                            break;
                                                    }
                                            }
                                    }
                                    else {
                                            d8 = 0x0;
                                    }
                                    r0 = operator new(0x8);
                                    d8 = d8 / r23;
                                    *r0 = d8;
                                    if ((r20 & 0x1) == 0x0) {
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                            if (0x1 != 0x0 && r21 != 0x0) {
                                                    r0 = r21;
                                                    r0 = operator delete(r0);
                                            }
                                            if (r19 != 0x0) {
                                                    r0 = operator delete(r19);
                                            }
                                    }
                                    else {
                                            if (var_80 != 0x0) {
                                                    r0 = var_88;
                                                    if (r0 != 0x0) {
                                                            r0 = operator delete(r0);
                                                    }
                                            }
                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                    r0 = operator delete(var_E0);
                                            }
                                            if (var_A8 != 0x0) {
                                                    r0 = var_B0;
                                                    if (r0 != 0x0) {
                                                            r0 = operator delete(r0);
                                                    }
                                            }
                                            if (r19 != 0x0) {
                                                    r0 = operator delete(r19);
                                            }
                                    }
                            }
                    }
                    else {
                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                            r24 = var_A0;
                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                            r9 = var_A0;
                            r8 = r9 + zero_extend_64(r23) * 0x4;
                            if (r24 != r8) {
                                    asm { ubfx       x10, x25, #0x2, #0x20 };
                                    r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                    if (r9 < 0x1c) {
                                            d8 = 0x0;
                                            r9 = r24;
                                            do {
                                                    r10 = *(int32_t *)r9;
                                                    r9 = r9 + 0x4;
                                                    d8 = d8 + r10;
                                            } while (r9 != r8);
                                    }
                                    else {
                                            r10 = (r9 >> 0x2) + 0x1;
                                            r11 = r10 & 0x7ffffffffffffff8;
                                            r9 = r24 + r11 * 0x4;
                                            r12 = r24 + 0x10;
                                            v0 = 0x0;
                                            r13 = r11;
                                            v1 = 0x0;
                                            v2 = 0x0;
                                            v3 = 0x0;
                                            do {
                                                    r12 = r12 + 0x20;
                                                    asm { sshll      v4.2d, v4.2s, #0x0 };
                                                    asm { sshll      v5.2d, v5.2s, #0x0 };
                                                    asm { sshll      v6.2d, v6.2s, #0x0 };
                                                    asm { sshll      v7.2d, v7.2s, #0x0 };
                                                    v0 = v0 + v4;
                                                    v1 = v1 + v5;
                                                    v2 = v2 + v6;
                                                    v3 = v3 + v7;
                                                    r13 = r13 - 0x8;
                                            } while (r13 != 0x0);
                                            asm { faddp      d8, v0.2d };
                                            if (r10 != r11) {
                                                    r10 = *(int32_t *)r9;
                                                    r9 = r9 + 0x4;
                                                    d8 = d8 + r10;
                                                    if (r9 != r8) {
                                                            continue;
                                                    }
                                                    break;
                                            }
                                    }
                            }
                            else {
                                    d8 = 0x0;
                            }
                            r0 = operator new(0x8);
                            d8 = d8 / r23;
                            *r0 = d8;
                            if ((r20 & 0x1) == 0x0) {
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                                    if (0x1 != 0x0 && r21 != 0x0) {
                                            r0 = r21;
                                            r0 = operator delete(r0);
                                    }
                                    if (r19 != 0x0) {
                                            r0 = operator delete(r19);
                                    }
                            }
                            else {
                                    if (var_80 != 0x0) {
                                            r0 = var_88;
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                    }
                                    if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                            r0 = operator delete(var_E0);
                                    }
                                    if (var_A8 != 0x0) {
                                            r0 = var_B0;
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                    }
                                    if (r19 != 0x0) {
                                            r0 = operator delete(r19);
                                    }
                            }
                    }
            }
            else {
                    do {
                            r9 = *(int32_t *)r8;
                            r8 = r8 + 0x4;
                            *(int32_t *)r0 = r9;
                            r0 = r0 + 0x4;
                    } while (r8 != r24);
                    var_C9 = 0x6;
                    var_E0 = 0x656e696c;
                    r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
                    d8 = *var_88;
                    if ((r20 & 0x1) != 0x0) {
                            if (var_80 != 0x0) {
                                    r0 = var_88;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                            }
                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                    r0 = operator delete(var_E0);
                            }
                            if (var_A8 != 0x0) {
                                    r0 = var_B0;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                            }
                            if (r19 != 0x0) {
                                    r0 = operator delete(r19);
                            }
                    }
                    else {
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                            if (r22 != 0x0 && r21 != 0x0) {
                                    r0 = r21;
                                    r0 = operator delete(r0);
                            }
                            if (r19 != 0x0) {
                                    r0 = operator delete(r19);
                            }
                    }
            }
    }
    else {
            var_C9 = 0x6;
            var_E0 = 0x656e696c;
            r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
            d8 = *var_88;
            if ((r20 & 0x1) != 0x0) {
                    if (var_80 != 0x0) {
                            r0 = var_88;
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                    }
                    if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                            r0 = operator delete(var_E0);
                    }
                    if (var_A8 != 0x0) {
                            r0 = var_B0;
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                    }
                    if (r19 != 0x0) {
                            r0 = operator delete(r19);
                    }
            }
            else {
                    if (r0 != 0x0) {
                            r0 = operator delete(r0);
                    }
                    if (r22 != 0x0 && r21 != 0x0) {
                            r0 = r21;
                            r0 = operator delete(r0);
                    }
                    if (r19 != 0x0) {
                            r0 = operator delete(r19);
                    }
            }
    }
    return r0;

loc_102306c2c:
    var_88 = 0x0;
    goto loc_102306c30;

loc_102306bd8:
    r8 = r0[0x1];
    var_98 = *r8;
    var_C8 = r0;
    r9 = 0x8000000000000000;
    var_B0 = 0x8000000000000000;
    r8 = r8[0x1];
    goto loc_102306c3c;

.l16:
    r19 = 0x0;
    r27 = 0x0;
    r24 = 0x0;
    while (true) {
            r0 = bool nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const>::operator==<nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const>, (&var_A0);
            if (r0 != 0x0) {
                    if ((r20 & 0x1) != 0x0) {
                            r21 = r24 - r19;
                            r8 = r21 >> 0x2;
                            r9 = 0x1;
                            var_B0 = 0x0;
                            var_A8 = 0x0;
                            if (r8 != 0x0) {
                                    r0 = operator new(r21 & 0x3fffffffc);
                                    var_B0 = r0;
                                    r8 = 0x1;
                                    var_A8 = 0x1;
                                    if (r19 != r24) {
                                            r9 = r21 - 0x4;
                                            if (r9 >= 0x3c) {
                                                    r10 = r0 - r19;
                                                    r8 = r19;
                                                    if (r10 >= 0x40) {
                                                            r9 = (r9 >> 0x2) + 0x1;
                                                            r10 = r9 & 0x7ffffffffffffff0;
                                                            r8 = r19 + (r10 << 0x2);
                                                            r11 = r0 + (r10 << 0x2);
                                                            r12 = r19 + 0x20;
                                                            r13 = r0 + 0x20;
                                                            r14 = r10;
                                                            temp_0 = 0x6;
                                                    }
                                                    else {
                                                            temp_0 = 0x1;
                                                    }
                                            }
                                            else {
                                                    r8 = r19;
                                                    temp_0 = 0x8;
                                            }
                                    }
                                    else {
                                            temp_0 = 0x0;
                                    }
                            }
                            else {
                                    temp_0 = 0x0;
                            }
                    }
                    else {
                            r25 = r24 - r19;
                            r23 = r25 >> 0x2;
                            if (r23 != 0x0) {
                                    r0 = operator new(r25 & 0x3fffffffc);
                                    r21 = r0;
                                    if (r19 != r24) {
                                            r10 = r25 - 0x4;
                                            if (r10 >= 0x3c) {
                                                    r11 = r21 - r19;
                                                    r8 = r19;
                                                    r9 = r21;
                                                    if (r11 >= 0x40) {
                                                            r10 = (r10 >> 0x2) + 0x1;
                                                            r11 = r10 & 0x7ffffffffffffff0;
                                                            r8 = r19 + (r11 << 0x2);
                                                            r9 = r21 + (r11 << 0x2);
                                                            r12 = r19 + 0x20;
                                                            r13 = r21 + 0x20;
                                                            r14 = r11;
                                                            temp_0 = 0x7;
                                                    }
                                                    else {
                                                            temp_0 = 0x3;
                                                    }
                                            }
                                            else {
                                                    r8 = r19;
                                                    r9 = r21;
                                                    temp_0 = 0x9;
                                            }
                                    }
                                    else {
                                            temp_0 = 0x2;
                                    }
                            }
                            else {
                                    r22 = 0x0;
                                    r21 = 0x0;
                                    temp_0 = 0xa;
                            }
                    }
                    break;
            }
            r21 = "bpm";
            r0 = nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const>::operator*();
            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
            var_E0 = 0x0;
            r0 = void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E0);
            r28 = var_E0;
            if (r24 < r27) {
                    *(int32_t *)r24 = r28;
                    r24 = r24 + 0x4;
                    r8 = *(int8_t *)var_A0;
                    if (r8 == 0x2) {
                            r8 = var_90 + 0x10;
                            var_90 = r8;
                            continue;
                    }
                    if (r8 == 0x1) {
                            r8 = var_98 + 0x28;
                            var_98 = r8;
                    }
                    else {
                            r8 = var_88 + 0x1;
                            var_88 = r8;
                    }
                    continue;
            }
            r22 = r24 - r19;
            r24 = SAR(r22, 0x2);
            r8 = r24 + 0x1;
            r9 = r8 >> 0x3e;
            if (r9 != 0x0) {
                    r0 = std::__1::vector<int, std::__1::allocator<int> >::__throw_length_error[abi:v15006]();
                    temp_0 = 0x5;
                    break;
            }
            r9 = r27 - r19;
            r10 = SAR(r9, 0x1);
            if (r10 > r8) {
                    r8 = r10;
            }
            if (r9 >= 0x7ffffffffffffffc) {
                    r27 = 0x3fffffffffffffff;
            }
            else {
                    r27 = r8;
            }
            if (r27 == 0x0) {
                    r27 = 0x0 + r27 * 0x4;
                    *(int32_t *)(0x0 + r24 * 0x4) = r28;
                    r24 = r24 * 0x4 + 0x4;
                    memmove(0x0, r19, r22);
                    var_78 = 0x0;
                    if (r19 != 0x0) {
                            operator delete(r19);
                    }
                    r23 = 0x0;
                    r19 = 0x0;
                    r8 = *(int8_t *)var_A0;
                    if (r8 == 0x2) {
                            r8 = var_90 + 0x10;
                            var_90 = r8;
                            continue;
                    }
                    if (r8 == 0x1) {
                            r8 = var_98 + 0x28;
                            var_98 = r8;
                    }
                    else {
                            r8 = var_88 + 0x1;
                            var_88 = r8;
                    }
                    continue;
            }
            r8 = r27 >> 0x3e;
            if (r8 == 0x0) {
                    r23 = operator new(r27 << 0x2);
                    r27 = r23 + r27 * 0x4;
                    *(int32_t *)(r23 + r24 * 0x4) = r28;
                    r24 = r23 + r24 * 0x4 + 0x4;
                    memmove(r23, r19, r22);
                    var_78 = r23;
                    if (r19 != 0x0) {
                            operator delete(r19);
                    }
                    r19 = r23;
                    r8 = *(int8_t *)var_A0;
                    if (r8 == 0x2) {
                            r8 = var_90 + 0x10;
                            var_90 = r8;
                            continue;
                    }
                    if (r8 == 0x1) {
                            r8 = var_98 + 0x28;
                            var_98 = r8;
                    }
                    else {
                            r8 = var_88 + 0x1;
                            var_88 = r8;
                    }
                    continue;
            }
            r0 = std::__throw_bad_array_new_length[abi:v15006]();
            temp_0 = 0x4;
            break;
    }
    if (temp_0 != 0x0) {
            if (temp_0 != 0x1) {
                    if (temp_0 != 0x2) {
                            if (temp_0 != 0x3) {
                                    if (temp_0 != 0x4 && temp_0 != 0x5) {
                                            if (temp_0 != 0x6) {
                                                    if (temp_0 != 0x7) {
                                                            if (temp_0 != 0x8) {
                                                                    if (temp_0 == 0x9) {
                                                                            do {
                                                                                    r10 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    *(int32_t *)r9 = r10;
                                                                                    r9 = r9 + 0x4;
                                                                            } while (r8 != r24);
                                                                            r22 = 0x1;
                                                                    }
                                                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                                    r24 = var_A0;
                                                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                                    r9 = var_A0;
                                                                    r8 = r9 + zero_extend_64(r23) * 0x4;
                                                                    if (r24 != r8) {
                                                                            asm { ubfx       x10, x25, #0x2, #0x20 };
                                                                            r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                                                            if (r9 < 0x1c) {
                                                                                    d8 = 0x0;
                                                                                    r9 = r24;
                                                                                    do {
                                                                                            r10 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            d8 = d8 + r10;
                                                                                    } while (r9 != r8);
                                                                            }
                                                                            else {
                                                                                    r10 = (r9 >> 0x2) + 0x1;
                                                                                    r11 = r10 & 0x7ffffffffffffff8;
                                                                                    r9 = r24 + r11 * 0x4;
                                                                                    r12 = r24 + 0x10;
                                                                                    v0 = 0x0;
                                                                                    r13 = r11;
                                                                                    v1 = 0x0;
                                                                                    v2 = 0x0;
                                                                                    v3 = 0x0;
                                                                                    do {
                                                                                            r12 = r12 + 0x20;
                                                                                            asm { sshll      v4.2d, v4.2s, #0x0 };
                                                                                            asm { sshll      v5.2d, v5.2s, #0x0 };
                                                                                            asm { sshll      v6.2d, v6.2s, #0x0 };
                                                                                            asm { sshll      v7.2d, v7.2s, #0x0 };
                                                                                            v0 = v0 + v4;
                                                                                            v1 = v1 + v5;
                                                                                            v2 = v2 + v6;
                                                                                            v3 = v3 + v7;
                                                                                            r13 = r13 - 0x8;
                                                                                    } while (r13 != 0x0);
                                                                                    asm { faddp      d8, v0.2d };
                                                                                    if (r10 != r11) {
                                                                                            r10 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            d8 = d8 + r10;
                                                                                            if (r9 != r8) {
                                                                                                    continue;
                                                                                            }
                                                                                            break;
                                                                                    }
                                                                            }
                                                                    }
                                                                    else {
                                                                            d8 = 0x0;
                                                                    }
                                                                    r0 = operator new(0x8);
                                                                    d8 = d8 / r23;
                                                                    *r0 = d8;
                                                                    if ((r20 & 0x1) == 0x0) {
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r22 != 0x0 && r21 != 0x0) {
                                                                                    r0 = r21;
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                                    else {
                                                                            if (var_80 != 0x0) {
                                                                                    r0 = var_88;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                                    r0 = operator delete(var_E0);
                                                                            }
                                                                            if (var_A8 != 0x0) {
                                                                                    r0 = var_B0;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                            }
                                                            else {
                                                                    do {
                                                                            r9 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            *(int32_t *)r0 = r9;
                                                                            r0 = r0 + 0x4;
                                                                    } while (r8 != r24);
                                                                    var_C9 = 0x6;
                                                                    var_E0 = 0x656e696c;
                                                                    r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
                                                                    d8 = *var_88;
                                                                    if ((r20 & 0x1) != 0x0) {
                                                                            if (var_80 != 0x0) {
                                                                                    r0 = var_88;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                                    r0 = operator delete(var_E0);
                                                                            }
                                                                            if (var_A8 != 0x0) {
                                                                                    r0 = var_B0;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                                    else {
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r22 != 0x0 && r21 != 0x0) {
                                                                                    r0 = r21;
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                            }
                                                    }
                                                    else {
                                                            do {
                                                                    q0 = r12[0xfffffffffffffffc];
                                                                    q1 = r12[0xfffffffffffffffe];
                                                                    q2 = *r12;
                                                                    q3 = r12[0x2];
                                                                    r12 = r12 + 0x40;
                                                                    r13[0xfffffffffffffffc] = q0;
                                                                    r13[0xfffffffffffffffe] = q1;
                                                                    *r13 = q2;
                                                                    r13[0x2] = q3;
                                                                    r13 = r13 + 0x40;
                                                                    r14 = r14 - 0x10;
                                                            } while (r14 != 0x0);
                                                            if (r10 != r11) {
                                                                    do {
                                                                            r10 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            *(int32_t *)r9 = r10;
                                                                            r9 = r9 + 0x4;
                                                                    } while (r8 != r24);
                                                            }
                                                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                            r24 = var_A0;
                                                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                            r9 = var_A0;
                                                            r8 = r9 + zero_extend_64(r23) * 0x4;
                                                            if (r24 != r8) {
                                                                    asm { ubfx       x10, x25, #0x2, #0x20 };
                                                                    r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                                                    if (r9 < 0x1c) {
                                                                            d8 = 0x0;
                                                                            r9 = r24;
                                                                            do {
                                                                                    r10 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    d8 = d8 + r10;
                                                                            } while (r9 != r8);
                                                                    }
                                                                    else {
                                                                            r10 = (r9 >> 0x2) + 0x1;
                                                                            r11 = r10 & 0x7ffffffffffffff8;
                                                                            r9 = r24 + r11 * 0x4;
                                                                            r12 = r24 + 0x10;
                                                                            v0 = 0x0;
                                                                            r13 = r11;
                                                                            v1 = 0x0;
                                                                            v2 = 0x0;
                                                                            v3 = 0x0;
                                                                            do {
                                                                                    r12 = r12 + 0x20;
                                                                                    asm { sshll      v4.2d, v4.2s, #0x0 };
                                                                                    asm { sshll      v5.2d, v5.2s, #0x0 };
                                                                                    asm { sshll      v6.2d, v6.2s, #0x0 };
                                                                                    asm { sshll      v7.2d, v7.2s, #0x0 };
                                                                                    v0 = v0 + v4;
                                                                                    v1 = v1 + v5;
                                                                                    v2 = v2 + v6;
                                                                                    v3 = v3 + v7;
                                                                                    r13 = r13 - 0x8;
                                                                            } while (r13 != 0x0);
                                                                            asm { faddp      d8, v0.2d };
                                                                            if (r10 != r11) {
                                                                                    r10 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    d8 = d8 + r10;
                                                                                    if (r9 != r8) {
                                                                                            continue;
                                                                                    }
                                                                                    break;
                                                                            }
                                                                    }
                                                            }
                                                            else {
                                                                    d8 = 0x0;
                                                            }
                                                            r0 = operator new(0x8);
                                                            d8 = d8 / r23;
                                                            *r0 = d8;
                                                            if ((r20 & 0x1) == 0x0) {
                                                                    if (r0 != 0x0) {
                                                                            r0 = operator delete(r0);
                                                                    }
                                                                    if (0x1 != 0x0 && r21 != 0x0) {
                                                                            r0 = r21;
                                                                            r0 = operator delete(r0);
                                                                    }
                                                                    if (r19 != 0x0) {
                                                                            r0 = operator delete(r19);
                                                                    }
                                                            }
                                                            else {
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                    }
                                                                    if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                            r0 = operator delete(var_E0);
                                                                    }
                                                                    if (var_A8 != 0x0) {
                                                                            r0 = var_B0;
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                    }
                                                                    if (r19 != 0x0) {
                                                                            r0 = operator delete(r19);
                                                                    }
                                                            }
                                                    }
                                            }
                                            else {
                                                    do {
                                                            q0 = r12[0xfffffffffffffffc];
                                                            q1 = r12[0xfffffffffffffffe];
                                                            q2 = *r12;
                                                            q3 = r12[0x2];
                                                            r12 = r12 + 0x40;
                                                            r13[0xfffffffffffffffc] = q0;
                                                            r13[0xfffffffffffffffe] = q1;
                                                            *r13 = q2;
                                                            r13[0x2] = q3;
                                                            r13 = r13 + 0x40;
                                                            r14 = r14 - 0x10;
                                                    } while (r14 != 0x0);
                                                    r0 = r11;
                                                    if (r9 != r10) {
                                                            do {
                                                                    r9 = *(int32_t *)r8;
                                                                    r8 = r8 + 0x4;
                                                                    *(int32_t *)r0 = r9;
                                                                    r0 = r0 + 0x4;
                                                            } while (r8 != r24);
                                                    }
                                                    var_C9 = 0x6;
                                                    var_E0 = 0x656e696c;
                                                    r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
                                                    d8 = *var_88;
                                                    if ((r20 & 0x1) != 0x0) {
                                                            if (var_80 != 0x0) {
                                                                    r0 = var_88;
                                                                    if (r0 != 0x0) {
                                                                            r0 = operator delete(r0);
                                                                    }
                                                            }
                                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                    r0 = operator delete(var_E0);
                                                            }
                                                            if (var_A8 != 0x0) {
                                                                    r0 = var_B0;
                                                                    if (r0 != 0x0) {
                                                                            r0 = operator delete(r0);
                                                                    }
                                                            }
                                                            if (r19 != 0x0) {
                                                                    r0 = operator delete(r19);
                                                            }
                                                    }
                                                    else {
                                                            if (r0 != 0x0) {
                                                                    r0 = operator delete(r0);
                                                            }
                                                            if (r22 != 0x0 && r21 != 0x0) {
                                                                    r0 = r21;
                                                                    r0 = operator delete(r0);
                                                            }
                                                            if (r19 != 0x0) {
                                                                    r0 = operator delete(r19);
                                                            }
                                                    }
                                            }
                                    }
                            }
                            else {
                                    do {
                                            r10 = *(int32_t *)r8;
                                            r8 = r8 + 0x4;
                                            *(int32_t *)r9 = r10;
                                            r9 = r9 + 0x4;
                                    } while (r8 != r24);
                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                    r24 = var_A0;
                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                    r9 = var_A0;
                                    r8 = r9 + zero_extend_64(r23) * 0x4;
                                    if (r24 != r8) {
                                            asm { ubfx       x10, x25, #0x2, #0x20 };
                                            r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                            if (r9 < 0x1c) {
                                                    d8 = 0x0;
                                                    r9 = r24;
                                                    do {
                                                            r10 = *(int32_t *)r9;
                                                            r9 = r9 + 0x4;
                                                            d8 = d8 + r10;
                                                    } while (r9 != r8);
                                            }
                                            else {
                                                    r10 = (r9 >> 0x2) + 0x1;
                                                    r11 = r10 & 0x7ffffffffffffff8;
                                                    r9 = r24 + r11 * 0x4;
                                                    r12 = r24 + 0x10;
                                                    v0 = 0x0;
                                                    r13 = r11;
                                                    v1 = 0x0;
                                                    v2 = 0x0;
                                                    v3 = 0x0;
                                                    do {
                                                            r12 = r12 + 0x20;
                                                            asm { sshll      v4.2d, v4.2s, #0x0 };
                                                            asm { sshll      v5.2d, v5.2s, #0x0 };
                                                            asm { sshll      v6.2d, v6.2s, #0x0 };
                                                            asm { sshll      v7.2d, v7.2s, #0x0 };
                                                            v0 = v0 + v4;
                                                            v1 = v1 + v5;
                                                            v2 = v2 + v6;
                                                            v3 = v3 + v7;
                                                            r13 = r13 - 0x8;
                                                    } while (r13 != 0x0);
                                                    asm { faddp      d8, v0.2d };
                                                    if (r10 != r11) {
                                                            r10 = *(int32_t *)r9;
                                                            r9 = r9 + 0x4;
                                                            d8 = d8 + r10;
                                                            if (r9 != r8) {
                                                                    continue;
                                                            }
                                                            break;
                                                    }
                                            }
                                    }
                                    else {
                                            d8 = 0x0;
                                    }
                                    r0 = operator new(0x8);
                                    d8 = d8 / r23;
                                    *r0 = d8;
                                    if ((r20 & 0x1) == 0x0) {
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                            if (0x1 != 0x0 && r21 != 0x0) {
                                                    r0 = r21;
                                                    r0 = operator delete(r0);
                                            }
                                            if (r19 != 0x0) {
                                                    r0 = operator delete(r19);
                                            }
                                    }
                                    else {
                                            if (var_80 != 0x0) {
                                                    r0 = var_88;
                                                    if (r0 != 0x0) {
                                                            r0 = operator delete(r0);
                                                    }
                                            }
                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                    r0 = operator delete(var_E0);
                                            }
                                            if (var_A8 != 0x0) {
                                                    r0 = var_B0;
                                                    if (r0 != 0x0) {
                                                            r0 = operator delete(r0);
                                                    }
                                            }
                                            if (r19 != 0x0) {
                                                    r0 = operator delete(r19);
                                            }
                                    }
                            }
                    }
                    else {
                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                            r24 = var_A0;
                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                            r9 = var_A0;
                            r8 = r9 + zero_extend_64(r23) * 0x4;
                            if (r24 != r8) {
                                    asm { ubfx       x10, x25, #0x2, #0x20 };
                                    r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                    if (r9 < 0x1c) {
                                            d8 = 0x0;
                                            r9 = r24;
                                            do {
                                                    r10 = *(int32_t *)r9;
                                                    r9 = r9 + 0x4;
                                                    d8 = d8 + r10;
                                            } while (r9 != r8);
                                    }
                                    else {
                                            r10 = (r9 >> 0x2) + 0x1;
                                            r11 = r10 & 0x7ffffffffffffff8;
                                            r9 = r24 + r11 * 0x4;
                                            r12 = r24 + 0x10;
                                            v0 = 0x0;
                                            r13 = r11;
                                            v1 = 0x0;
                                            v2 = 0x0;
                                            v3 = 0x0;
                                            do {
                                                    r12 = r12 + 0x20;
                                                    asm { sshll      v4.2d, v4.2s, #0x0 };
                                                    asm { sshll      v5.2d, v5.2s, #0x0 };
                                                    asm { sshll      v6.2d, v6.2s, #0x0 };
                                                    asm { sshll      v7.2d, v7.2s, #0x0 };
                                                    v0 = v0 + v4;
                                                    v1 = v1 + v5;
                                                    v2 = v2 + v6;
                                                    v3 = v3 + v7;
                                                    r13 = r13 - 0x8;
                                            } while (r13 != 0x0);
                                            asm { faddp      d8, v0.2d };
                                            if (r10 != r11) {
                                                    r10 = *(int32_t *)r9;
                                                    r9 = r9 + 0x4;
                                                    d8 = d8 + r10;
                                                    if (r9 != r8) {
                                                            continue;
                                                    }
                                                    break;
                                            }
                                    }
                            }
                            else {
                                    d8 = 0x0;
                            }
                            r0 = operator new(0x8);
                            d8 = d8 / r23;
                            *r0 = d8;
                            if ((r20 & 0x1) == 0x0) {
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                                    if (0x1 != 0x0 && r21 != 0x0) {
                                            r0 = r21;
                                            r0 = operator delete(r0);
                                    }
                                    if (r19 != 0x0) {
                                            r0 = operator delete(r19);
                                    }
                            }
                            else {
                                    if (var_80 != 0x0) {
                                            r0 = var_88;
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                    }
                                    if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                            r0 = operator delete(var_E0);
                                    }
                                    if (var_A8 != 0x0) {
                                            r0 = var_B0;
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                    }
                                    if (r19 != 0x0) {
                                            r0 = operator delete(r19);
                                    }
                            }
                    }
            }
            else {
                    do {
                            r9 = *(int32_t *)r8;
                            r8 = r8 + 0x4;
                            *(int32_t *)r0 = r9;
                            r0 = r0 + 0x4;
                    } while (r8 != r24);
                    var_C9 = 0x6;
                    var_E0 = 0x656e696c;
                    r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
                    d8 = *var_88;
                    if ((r20 & 0x1) != 0x0) {
                            if (var_80 != 0x0) {
                                    r0 = var_88;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                            }
                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                    r0 = operator delete(var_E0);
                            }
                            if (var_A8 != 0x0) {
                                    r0 = var_B0;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                            }
                            if (r19 != 0x0) {
                                    r0 = operator delete(r19);
                            }
                    }
                    else {
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                            if (r22 != 0x0 && r21 != 0x0) {
                                    r0 = r21;
                                    r0 = operator delete(r0);
                            }
                            if (r19 != 0x0) {
                                    r0 = operator delete(r19);
                            }
                    }
            }
    }
    else {
            var_C9 = 0x6;
            var_E0 = 0x656e696c;
            r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
            d8 = *var_88;
            if ((r20 & 0x1) != 0x0) {
                    if (var_80 != 0x0) {
                            r0 = var_88;
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                    }
                    if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                            r0 = operator delete(var_E0);
                    }
                    if (var_A8 != 0x0) {
                            r0 = var_B0;
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                    }
                    if (r19 != 0x0) {
                            r0 = operator delete(r19);
                    }
            }
            else {
                    if (r0 != 0x0) {
                            r0 = operator delete(r0);
                    }
                    if (r22 != 0x0 && r21 != 0x0) {
                            r0 = r21;
                            r0 = operator delete(r0);
                    }
                    if (r19 != 0x0) {
                            r0 = operator delete(r19);
                    }
            }
    }
    return r0;

.l10:
    var_88 = 0x0;
    goto .l12;

.l17:
    r8 = r0[0x1];
    var_98 = *r8;
    var_C8 = r0;
    r9 = 0x8000000000000000;
    var_B0 = 0x8000000000000000;
    r8 = r8[0x1];
    goto .l16;

.l2:
    var_C8 = r0;
    r8 = 0x1;
    var_B0 = 0x1;
    goto .l5;

.l3:
    r8 = r0[0x1];
    var_90 = *r8;
    var_C8 = r0;
    r9 = 0x8000000000000000;
    var_B0 = 0x8000000000000000;
    r8 = r8[0x1];
    goto .l5;

.l8:
    if (r8 != 0x1) goto .l1;
    goto .l6;

.l5:
    r19 = 0x0;
    r27 = 0x0;
    r24 = 0x0;
    while (true) {
            r0 = bool nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const>::operator==<nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const>, (&var_A0);
            if (r0 != 0x0) {
                    if ((r20 & 0x1) != 0x0) {
                            r21 = r24 - r19;
                            r8 = r21 >> 0x2;
                            r9 = 0x1;
                            var_B0 = 0x0;
                            var_A8 = 0x0;
                            if (r8 != 0x0) {
                                    r0 = operator new(r21 & 0x3fffffffc);
                                    var_B0 = r0;
                                    r8 = 0x1;
                                    var_A8 = 0x1;
                                    if (r19 != r24) {
                                            r9 = r21 - 0x4;
                                            if (r9 >= 0x3c) {
                                                    r10 = r0 - r19;
                                                    r8 = r19;
                                                    if (r10 >= 0x40) {
                                                            r9 = (r9 >> 0x2) + 0x1;
                                                            r10 = r9 & 0x7ffffffffffffff0;
                                                            r8 = r19 + (r10 << 0x2);
                                                            r11 = r0 + (r10 << 0x2);
                                                            r12 = r19 + 0x20;
                                                            r13 = r0 + 0x20;
                                                            r14 = r10;
                                                            temp_0 = 0x6;
                                                    }
                                                    else {
                                                            temp_0 = 0x1;
                                                    }
                                            }
                                            else {
                                                    r8 = r19;
                                                    temp_0 = 0x8;
                                            }
                                    }
                                    else {
                                            temp_0 = 0x0;
                                    }
                            }
                            else {
                                    temp_0 = 0x0;
                            }
                    }
                    else {
                            r25 = r24 - r19;
                            r23 = r25 >> 0x2;
                            if (r23 != 0x0) {
                                    r0 = operator new(r25 & 0x3fffffffc);
                                    r21 = r0;
                                    if (r19 != r24) {
                                            r10 = r25 - 0x4;
                                            if (r10 >= 0x3c) {
                                                    r11 = r21 - r19;
                                                    r8 = r19;
                                                    r9 = r21;
                                                    if (r11 >= 0x40) {
                                                            r10 = (r10 >> 0x2) + 0x1;
                                                            r11 = r10 & 0x7ffffffffffffff0;
                                                            r8 = r19 + (r11 << 0x2);
                                                            r9 = r21 + (r11 << 0x2);
                                                            r12 = r19 + 0x20;
                                                            r13 = r21 + 0x20;
                                                            r14 = r11;
                                                            temp_0 = 0x7;
                                                    }
                                                    else {
                                                            temp_0 = 0x3;
                                                    }
                                            }
                                            else {
                                                    r8 = r19;
                                                    r9 = r21;
                                                    temp_0 = 0x9;
                                            }
                                    }
                                    else {
                                            temp_0 = 0x2;
                                    }
                            }
                            else {
                                    r22 = 0x0;
                                    r21 = 0x0;
                                    temp_0 = 0xa;
                            }
                    }
                    break;
            }
            r21 = "bpm";
            r0 = nlohmann::detail::iter_impl<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const>::operator*();
            r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
            var_E0 = 0x0;
            r0 = void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_E0);
            r28 = var_E0;
            if (r24 < r27) {
                    *(int32_t *)r24 = r28;
                    r24 = r24 + 0x4;
                    r8 = *(int8_t *)var_A0;
                    if (r8 == 0x2) {
                            r8 = var_90 + 0x10;
                            var_90 = r8;
                            continue;
                    }
                    if (r8 == 0x1) {
                            r8 = var_98 + 0x28;
                            var_98 = r8;
                    }
                    else {
                            r8 = var_88 + 0x1;
                            var_88 = r8;
                    }
                    continue;
            }
            r22 = r24 - r19;
            r24 = SAR(r22, 0x2);
            r8 = r24 + 0x1;
            r9 = r8 >> 0x3e;
            if (r9 != 0x0) {
                    r0 = std::__1::vector<int, std::__1::allocator<int> >::__throw_length_error[abi:v15006]();
                    temp_0 = 0x5;
                    break;
            }
            r9 = r27 - r19;
            r10 = SAR(r9, 0x1);
            if (r10 > r8) {
                    r8 = r10;
            }
            if (r9 >= 0x7ffffffffffffffc) {
                    r27 = 0x3fffffffffffffff;
            }
            else {
                    r27 = r8;
            }
            if (r27 == 0x0) {
                    r27 = 0x0 + r27 * 0x4;
                    *(int32_t *)(0x0 + r24 * 0x4) = r28;
                    r24 = r24 * 0x4 + 0x4;
                    memmove(0x0, r19, r22);
                    var_78 = 0x0;
                    if (r19 != 0x0) {
                            operator delete(r19);
                    }
                    r23 = 0x0;
                    r19 = 0x0;
                    r8 = *(int8_t *)var_A0;
                    if (r8 == 0x2) {
                            r8 = var_90 + 0x10;
                            var_90 = r8;
                            continue;
                    }
                    if (r8 == 0x1) {
                            r8 = var_98 + 0x28;
                            var_98 = r8;
                    }
                    else {
                            r8 = var_88 + 0x1;
                            var_88 = r8;
                    }
                    continue;
            }
            r8 = r27 >> 0x3e;
            if (r8 == 0x0) {
                    r23 = operator new(r27 << 0x2);
                    r27 = r23 + r27 * 0x4;
                    *(int32_t *)(r23 + r24 * 0x4) = r28;
                    r24 = r23 + r24 * 0x4 + 0x4;
                    memmove(r23, r19, r22);
                    var_78 = r23;
                    if (r19 != 0x0) {
                            operator delete(r19);
                    }
                    r19 = r23;
                    r8 = *(int8_t *)var_A0;
                    if (r8 == 0x2) {
                            r8 = var_90 + 0x10;
                            var_90 = r8;
                            continue;
                    }
                    if (r8 == 0x1) {
                            r8 = var_98 + 0x28;
                            var_98 = r8;
                    }
                    else {
                            r8 = var_88 + 0x1;
                            var_88 = r8;
                    }
                    continue;
            }
            r0 = std::__throw_bad_array_new_length[abi:v15006]();
            temp_0 = 0x4;
            break;
    }
    if (temp_0 != 0x0) {
            if (temp_0 != 0x1) {
                    if (temp_0 != 0x2) {
                            if (temp_0 != 0x3) {
                                    if (temp_0 != 0x4 && temp_0 != 0x5) {
                                            if (temp_0 != 0x6) {
                                                    if (temp_0 != 0x7) {
                                                            if (temp_0 != 0x8) {
                                                                    if (temp_0 == 0x9) {
                                                                            do {
                                                                                    r10 = *(int32_t *)r8;
                                                                                    r8 = r8 + 0x4;
                                                                                    *(int32_t *)r9 = r10;
                                                                                    r9 = r9 + 0x4;
                                                                            } while (r8 != r24);
                                                                            r22 = 0x1;
                                                                    }
                                                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                                    r24 = var_A0;
                                                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                                    r9 = var_A0;
                                                                    r8 = r9 + zero_extend_64(r23) * 0x4;
                                                                    if (r24 != r8) {
                                                                            asm { ubfx       x10, x25, #0x2, #0x20 };
                                                                            r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                                                            if (r9 < 0x1c) {
                                                                                    d8 = 0x0;
                                                                                    r9 = r24;
                                                                                    do {
                                                                                            r10 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            d8 = d8 + r10;
                                                                                    } while (r9 != r8);
                                                                            }
                                                                            else {
                                                                                    r10 = (r9 >> 0x2) + 0x1;
                                                                                    r11 = r10 & 0x7ffffffffffffff8;
                                                                                    r9 = r24 + r11 * 0x4;
                                                                                    r12 = r24 + 0x10;
                                                                                    v0 = 0x0;
                                                                                    r13 = r11;
                                                                                    v1 = 0x0;
                                                                                    v2 = 0x0;
                                                                                    v3 = 0x0;
                                                                                    do {
                                                                                            r12 = r12 + 0x20;
                                                                                            asm { sshll      v4.2d, v4.2s, #0x0 };
                                                                                            asm { sshll      v5.2d, v5.2s, #0x0 };
                                                                                            asm { sshll      v6.2d, v6.2s, #0x0 };
                                                                                            asm { sshll      v7.2d, v7.2s, #0x0 };
                                                                                            v0 = v0 + v4;
                                                                                            v1 = v1 + v5;
                                                                                            v2 = v2 + v6;
                                                                                            v3 = v3 + v7;
                                                                                            r13 = r13 - 0x8;
                                                                                    } while (r13 != 0x0);
                                                                                    asm { faddp      d8, v0.2d };
                                                                                    if (r10 != r11) {
                                                                                            r10 = *(int32_t *)r9;
                                                                                            r9 = r9 + 0x4;
                                                                                            d8 = d8 + r10;
                                                                                            if (r9 != r8) {
                                                                                                    continue;
                                                                                            }
                                                                                            break;
                                                                                    }
                                                                            }
                                                                    }
                                                                    else {
                                                                            d8 = 0x0;
                                                                    }
                                                                    r0 = operator new(0x8);
                                                                    d8 = d8 / r23;
                                                                    *r0 = d8;
                                                                    if ((r20 & 0x1) == 0x0) {
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r22 != 0x0 && r21 != 0x0) {
                                                                                    r0 = r21;
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                                    else {
                                                                            if (var_80 != 0x0) {
                                                                                    r0 = var_88;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                                    r0 = operator delete(var_E0);
                                                                            }
                                                                            if (var_A8 != 0x0) {
                                                                                    r0 = var_B0;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                            }
                                                            else {
                                                                    do {
                                                                            r9 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            *(int32_t *)r0 = r9;
                                                                            r0 = r0 + 0x4;
                                                                    } while (r8 != r24);
                                                                    var_C9 = 0x6;
                                                                    var_E0 = 0x656e696c;
                                                                    r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
                                                                    d8 = *var_88;
                                                                    if ((r20 & 0x1) != 0x0) {
                                                                            if (var_80 != 0x0) {
                                                                                    r0 = var_88;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                                    r0 = operator delete(var_E0);
                                                                            }
                                                                            if (var_A8 != 0x0) {
                                                                                    r0 = var_B0;
                                                                                    if (r0 != 0x0) {
                                                                                            r0 = operator delete(r0);
                                                                                    }
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                                    else {
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r22 != 0x0 && r21 != 0x0) {
                                                                                    r0 = r21;
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                            if (r19 != 0x0) {
                                                                                    r0 = operator delete(r19);
                                                                            }
                                                                    }
                                                            }
                                                    }
                                                    else {
                                                            do {
                                                                    q0 = r12[0xfffffffffffffffc];
                                                                    q1 = r12[0xfffffffffffffffe];
                                                                    q2 = *r12;
                                                                    q3 = r12[0x2];
                                                                    r12 = r12 + 0x40;
                                                                    r13[0xfffffffffffffffc] = q0;
                                                                    r13[0xfffffffffffffffe] = q1;
                                                                    *r13 = q2;
                                                                    r13[0x2] = q3;
                                                                    r13 = r13 + 0x40;
                                                                    r14 = r14 - 0x10;
                                                            } while (r14 != 0x0);
                                                            if (r10 != r11) {
                                                                    do {
                                                                            r10 = *(int32_t *)r8;
                                                                            r8 = r8 + 0x4;
                                                                            *(int32_t *)r9 = r10;
                                                                            r9 = r9 + 0x4;
                                                                    } while (r8 != r24);
                                                            }
                                                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                            r24 = var_A0;
                                                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                                            r9 = var_A0;
                                                            r8 = r9 + zero_extend_64(r23) * 0x4;
                                                            if (r24 != r8) {
                                                                    asm { ubfx       x10, x25, #0x2, #0x20 };
                                                                    r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                                                    if (r9 < 0x1c) {
                                                                            d8 = 0x0;
                                                                            r9 = r24;
                                                                            do {
                                                                                    r10 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    d8 = d8 + r10;
                                                                            } while (r9 != r8);
                                                                    }
                                                                    else {
                                                                            r10 = (r9 >> 0x2) + 0x1;
                                                                            r11 = r10 & 0x7ffffffffffffff8;
                                                                            r9 = r24 + r11 * 0x4;
                                                                            r12 = r24 + 0x10;
                                                                            v0 = 0x0;
                                                                            r13 = r11;
                                                                            v1 = 0x0;
                                                                            v2 = 0x0;
                                                                            v3 = 0x0;
                                                                            do {
                                                                                    r12 = r12 + 0x20;
                                                                                    asm { sshll      v4.2d, v4.2s, #0x0 };
                                                                                    asm { sshll      v5.2d, v5.2s, #0x0 };
                                                                                    asm { sshll      v6.2d, v6.2s, #0x0 };
                                                                                    asm { sshll      v7.2d, v7.2s, #0x0 };
                                                                                    v0 = v0 + v4;
                                                                                    v1 = v1 + v5;
                                                                                    v2 = v2 + v6;
                                                                                    v3 = v3 + v7;
                                                                                    r13 = r13 - 0x8;
                                                                            } while (r13 != 0x0);
                                                                            asm { faddp      d8, v0.2d };
                                                                            if (r10 != r11) {
                                                                                    r10 = *(int32_t *)r9;
                                                                                    r9 = r9 + 0x4;
                                                                                    d8 = d8 + r10;
                                                                                    if (r9 != r8) {
                                                                                            continue;
                                                                                    }
                                                                                    break;
                                                                            }
                                                                    }
                                                            }
                                                            else {
                                                                    d8 = 0x0;
                                                            }
                                                            r0 = operator new(0x8);
                                                            d8 = d8 / r23;
                                                            *r0 = d8;
                                                            if ((r20 & 0x1) == 0x0) {
                                                                    if (r0 != 0x0) {
                                                                            r0 = operator delete(r0);
                                                                    }
                                                                    if (0x1 != 0x0 && r21 != 0x0) {
                                                                            r0 = r21;
                                                                            r0 = operator delete(r0);
                                                                    }
                                                                    if (r19 != 0x0) {
                                                                            r0 = operator delete(r19);
                                                                    }
                                                            }
                                                            else {
                                                                    if (var_80 != 0x0) {
                                                                            r0 = var_88;
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                    }
                                                                    if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                            r0 = operator delete(var_E0);
                                                                    }
                                                                    if (var_A8 != 0x0) {
                                                                            r0 = var_B0;
                                                                            if (r0 != 0x0) {
                                                                                    r0 = operator delete(r0);
                                                                            }
                                                                    }
                                                                    if (r19 != 0x0) {
                                                                            r0 = operator delete(r19);
                                                                    }
                                                            }
                                                    }
                                            }
                                            else {
                                                    do {
                                                            q0 = r12[0xfffffffffffffffc];
                                                            q1 = r12[0xfffffffffffffffe];
                                                            q2 = *r12;
                                                            q3 = r12[0x2];
                                                            r12 = r12 + 0x40;
                                                            r13[0xfffffffffffffffc] = q0;
                                                            r13[0xfffffffffffffffe] = q1;
                                                            *r13 = q2;
                                                            r13[0x2] = q3;
                                                            r13 = r13 + 0x40;
                                                            r14 = r14 - 0x10;
                                                    } while (r14 != 0x0);
                                                    r0 = r11;
                                                    if (r9 != r10) {
                                                            do {
                                                                    r9 = *(int32_t *)r8;
                                                                    r8 = r8 + 0x4;
                                                                    *(int32_t *)r0 = r9;
                                                                    r0 = r0 + 0x4;
                                                            } while (r8 != r24);
                                                    }
                                                    var_C9 = 0x6;
                                                    var_E0 = 0x656e696c;
                                                    r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
                                                    d8 = *var_88;
                                                    if ((r20 & 0x1) != 0x0) {
                                                            if (var_80 != 0x0) {
                                                                    r0 = var_88;
                                                                    if (r0 != 0x0) {
                                                                            r0 = operator delete(r0);
                                                                    }
                                                            }
                                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                                    r0 = operator delete(var_E0);
                                                            }
                                                            if (var_A8 != 0x0) {
                                                                    r0 = var_B0;
                                                                    if (r0 != 0x0) {
                                                                            r0 = operator delete(r0);
                                                                    }
                                                            }
                                                            if (r19 != 0x0) {
                                                                    r0 = operator delete(r19);
                                                            }
                                                    }
                                                    else {
                                                            if (r0 != 0x0) {
                                                                    r0 = operator delete(r0);
                                                            }
                                                            if (r22 != 0x0 && r21 != 0x0) {
                                                                    r0 = r21;
                                                                    r0 = operator delete(r0);
                                                            }
                                                            if (r19 != 0x0) {
                                                                    r0 = operator delete(r19);
                                                            }
                                                    }
                                            }
                                    }
                            }
                            else {
                                    do {
                                            r10 = *(int32_t *)r8;
                                            r8 = r8 + 0x4;
                                            *(int32_t *)r9 = r10;
                                            r9 = r9 + 0x4;
                                    } while (r8 != r24);
                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                    r24 = var_A0;
                                    nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                                    r9 = var_A0;
                                    r8 = r9 + zero_extend_64(r23) * 0x4;
                                    if (r24 != r8) {
                                            asm { ubfx       x10, x25, #0x2, #0x20 };
                                            r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                            if (r9 < 0x1c) {
                                                    d8 = 0x0;
                                                    r9 = r24;
                                                    do {
                                                            r10 = *(int32_t *)r9;
                                                            r9 = r9 + 0x4;
                                                            d8 = d8 + r10;
                                                    } while (r9 != r8);
                                            }
                                            else {
                                                    r10 = (r9 >> 0x2) + 0x1;
                                                    r11 = r10 & 0x7ffffffffffffff8;
                                                    r9 = r24 + r11 * 0x4;
                                                    r12 = r24 + 0x10;
                                                    v0 = 0x0;
                                                    r13 = r11;
                                                    v1 = 0x0;
                                                    v2 = 0x0;
                                                    v3 = 0x0;
                                                    do {
                                                            r12 = r12 + 0x20;
                                                            asm { sshll      v4.2d, v4.2s, #0x0 };
                                                            asm { sshll      v5.2d, v5.2s, #0x0 };
                                                            asm { sshll      v6.2d, v6.2s, #0x0 };
                                                            asm { sshll      v7.2d, v7.2s, #0x0 };
                                                            v0 = v0 + v4;
                                                            v1 = v1 + v5;
                                                            v2 = v2 + v6;
                                                            v3 = v3 + v7;
                                                            r13 = r13 - 0x8;
                                                    } while (r13 != 0x0);
                                                    asm { faddp      d8, v0.2d };
                                                    if (r10 != r11) {
                                                            r10 = *(int32_t *)r9;
                                                            r9 = r9 + 0x4;
                                                            d8 = d8 + r10;
                                                            if (r9 != r8) {
                                                                    continue;
                                                            }
                                                            break;
                                                    }
                                            }
                                    }
                                    else {
                                            d8 = 0x0;
                                    }
                                    r0 = operator new(0x8);
                                    d8 = d8 / r23;
                                    *r0 = d8;
                                    if ((r20 & 0x1) == 0x0) {
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                            if (0x1 != 0x0 && r21 != 0x0) {
                                                    r0 = r21;
                                                    r0 = operator delete(r0);
                                            }
                                            if (r19 != 0x0) {
                                                    r0 = operator delete(r19);
                                            }
                                    }
                                    else {
                                            if (var_80 != 0x0) {
                                                    r0 = var_88;
                                                    if (r0 != 0x0) {
                                                            r0 = operator delete(r0);
                                                    }
                                            }
                                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                                    r0 = operator delete(var_E0);
                                            }
                                            if (var_A8 != 0x0) {
                                                    r0 = var_B0;
                                                    if (r0 != 0x0) {
                                                            r0 = operator delete(r0);
                                                    }
                                            }
                                            if (r19 != 0x0) {
                                                    r0 = operator delete(r19);
                                            }
                                    }
                            }
                    }
                    else {
                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                            r24 = var_A0;
                            nc::NdArrayConstIterator<int, int const*, long>::NdArrayConstIterator(&var_A0);
                            r9 = var_A0;
                            r8 = r9 + zero_extend_64(r23) * 0x4;
                            if (r24 != r8) {
                                    asm { ubfx       x10, x25, #0x2, #0x20 };
                                    r9 = r9 + r10 * 0x4 - r24 - 0x4;
                                    if (r9 < 0x1c) {
                                            d8 = 0x0;
                                            r9 = r24;
                                            do {
                                                    r10 = *(int32_t *)r9;
                                                    r9 = r9 + 0x4;
                                                    d8 = d8 + r10;
                                            } while (r9 != r8);
                                    }
                                    else {
                                            r10 = (r9 >> 0x2) + 0x1;
                                            r11 = r10 & 0x7ffffffffffffff8;
                                            r9 = r24 + r11 * 0x4;
                                            r12 = r24 + 0x10;
                                            v0 = 0x0;
                                            r13 = r11;
                                            v1 = 0x0;
                                            v2 = 0x0;
                                            v3 = 0x0;
                                            do {
                                                    r12 = r12 + 0x20;
                                                    asm { sshll      v4.2d, v4.2s, #0x0 };
                                                    asm { sshll      v5.2d, v5.2s, #0x0 };
                                                    asm { sshll      v6.2d, v6.2s, #0x0 };
                                                    asm { sshll      v7.2d, v7.2s, #0x0 };
                                                    v0 = v0 + v4;
                                                    v1 = v1 + v5;
                                                    v2 = v2 + v6;
                                                    v3 = v3 + v7;
                                                    r13 = r13 - 0x8;
                                            } while (r13 != 0x0);
                                            asm { faddp      d8, v0.2d };
                                            if (r10 != r11) {
                                                    r10 = *(int32_t *)r9;
                                                    r9 = r9 + 0x4;
                                                    d8 = d8 + r10;
                                                    if (r9 != r8) {
                                                            continue;
                                                    }
                                                    break;
                                            }
                                    }
                            }
                            else {
                                    d8 = 0x0;
                            }
                            r0 = operator new(0x8);
                            d8 = d8 / r23;
                            *r0 = d8;
                            if ((r20 & 0x1) == 0x0) {
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                                    if (0x1 != 0x0 && r21 != 0x0) {
                                            r0 = r21;
                                            r0 = operator delete(r0);
                                    }
                                    if (r19 != 0x0) {
                                            r0 = operator delete(r19);
                                    }
                            }
                            else {
                                    if (var_80 != 0x0) {
                                            r0 = var_88;
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                    }
                                    if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                            r0 = operator delete(var_E0);
                                    }
                                    if (var_A8 != 0x0) {
                                            r0 = var_B0;
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                    }
                                    if (r19 != 0x0) {
                                            r0 = operator delete(r19);
                                    }
                            }
                    }
            }
            else {
                    do {
                            r9 = *(int32_t *)r8;
                            r8 = r8 + 0x4;
                            *(int32_t *)r0 = r9;
                            r0 = r0 + 0x4;
                    } while (r8 != r24);
                    var_C9 = 0x6;
                    var_E0 = 0x656e696c;
                    r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
                    d8 = *var_88;
                    if ((r20 & 0x1) != 0x0) {
                            if (var_80 != 0x0) {
                                    r0 = var_88;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                            }
                            if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                                    r0 = operator delete(var_E0);
                            }
                            if (var_A8 != 0x0) {
                                    r0 = var_B0;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                            }
                            if (r19 != 0x0) {
                                    r0 = operator delete(r19);
                            }
                    }
                    else {
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                            if (r22 != 0x0 && r21 != 0x0) {
                                    r0 = r21;
                                    r0 = operator delete(r0);
                            }
                            if (r19 != 0x0) {
                                    r0 = operator delete(r19);
                            }
                    }
            }
    }
    else {
            var_C9 = 0x6;
            var_E0 = 0x656e696c;
            r0 = nc::NdArray<double, std::__1::allocator<double> > nc::percentile<int>(&var_C8, s0, 0x0, &var_E0);
            d8 = *var_88;
            if ((r20 & 0x1) != 0x0) {
                    if (var_80 != 0x0) {
                            r0 = var_88;
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                    }
                    if ((sign_extend_64(var_C9) & 0xffffffff80000000) != 0x0) {
                            r0 = operator delete(var_E0);
                    }
                    if (var_A8 != 0x0) {
                            r0 = var_B0;
                            if (r0 != 0x0) {
                                    r0 = operator delete(r0);
                            }
                    }
                    if (r19 != 0x0) {
                            r0 = operator delete(r19);
                    }
            }
            else {
                    if (r0 != 0x0) {
                            r0 = operator delete(r0);
                    }
                    if (r22 != 0x0 && r21 != 0x0) {
                            r0 = r21;
                            r0 = operator delete(r0);
                    }
                    if (r19 != 0x0) {
                            r0 = operator delete(r19);
                    }
            }
    }
    return r0;

.l1:
    var_88 = 0x0;
    goto .l2;

.l6:
    r8 = r0[0x1];
    var_98 = *r8;
    var_C8 = r0;
    r9 = 0x8000000000000000;
    var_B0 = 0x8000000000000000;
    r8 = r8[0x1];
    goto .l5;
