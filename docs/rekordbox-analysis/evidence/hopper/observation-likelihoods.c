    r31 = r31 - 0x110;
    var_40 = d9;
    decomp_var_38 = d8;
    var_30 = r28;
    decomp_var_28 = r27;
    var_20 = r22;
    decomp_var_18 = r21;
    var_10 = r20;
    decomp_var_8 = r19;
    saved_fp = r29;
    decomp_var_m8 = r30;
    r20 = r1;
    r21 = arg0;
    r19 = r8;
    r22 = r1[0x1];
    *(r19 + 0x4) = r22;
    r19[0x1] = 0x3;
    r8 = r22 + r22 * 0x2;
    *(r19 + 0xc) = r8;
    r19[0x2] = 0x0;
    r19[0x3] = 0x0;
    r19[0x20] = 0x0;
    if (r8 != 0x0) {
            r19[0x3] = operator new(r8 << 0x2);
            r19[0x20] = 0x1;
    }
    var_58 = r22 << 0x20;
    nc::NdArray<float, std::__1::allocator<float> >::sum(r20);
    nc::NdArray<float, std::__1::allocator<float> > nc::operator-<float>(&var_F8, r1);
    s8 = r21[0xc];
    nc::NdArrayConstIterator<float, float*, long>::NdArrayConstIterator(&var_48);
    r21 = var_48;
    nc::NdArrayConstIterator<float, float*, long>::NdArrayConstIterator(&var_48);
    r8 = var_48 + var_C4 * 0x4;
    if (r21 != r8) {
            s0 = s8 + 0xbff0000000000000;
            r10 = r8 - r21 - 0x4;
            r9 = r21;
            if (r10 >= 0x3c) {
                    r10 = (r10 >> 0x2) + 0x1;
                    r11 = r10 & 0x7ffffffffffffff0;
                    r9 = r21 + r11 * 0x4;
                    asm { dup        v1.4s, v0.s[0] };
                    v2 = 0x3ff0000000000000;
                    v1 = 0x3ff0000000000000 / v1;
                    r12 = r21 + 0x20;
                    r13 = r11;
                    do {
                            q2 = r12[0xfffffffffffffffc];
                            q3 = r12[0xfffffffffffffffe];
                            q4 = *r12;
                            q5 = r12[0x2];
                            v2 = v2 * v1;
                            v3 = v3 * v1;
                            v4 = v4 * v1;
                            v5 = v5 * v1;
                            r12[0xfffffffffffffffc] = q2;
                            r12[0xfffffffffffffffe] = q3;
                            *r12 = q4;
                            r12[0x2] = q5;
                            r12 = r12 + 0x40;
                            r13 = r13 - 0x10;
                    } while (r13 != 0x0);
                    if (r10 != r11) {
                            s0 = 0x3ff0000000000000 / s0;
                            do {
                                    *(int32_t *)r9 = *(int32_t *)r9 * s0;
                                    r9 = r9 + 0x4;
                            } while (r9 != r8);
                    }
            }
            else {
                    s0 = 0x3ff0000000000000 / s0;
                    do {
                            *(int32_t *)r9 = *(int32_t *)r9 * s0;
                            r9 = r9 + 0x4;
                    } while (r9 != r8);
            }
    }
    var_90 = var_B8;
    var_88 = var_B0;
    var_B0 = 0x0;
    var_B8 = 0x0;
    r0 = auto nc::log<float>(&decomp_var_a8);
    r21 = &decomp_var_80;
    nc::NdArray<float, std::__1::allocator<float> >::put(r19, &var_58, 0x0);
    if (var_60 != 0x0) {
            r0 = var_68;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_68 = 0x0;
    var_60 = 0x0;
    *(r21 + 0xc) = 0x0;
    if (var_88 != 0x0) {
            r0 = var_90;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_90 = 0x0;
    var_88 = 0x0;
    if (var_B0 != 0x0) {
            r0 = var_B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_D8 != 0x0) {
            r0 = var_E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_F8 = r19[0x1] << 0x20;
    nc::NdArray<float, std::__1::allocator<float> >::operator(r20, r20[0x1] << 0x20);
    r0 = auto nc::log<float>(&decomp_var_a8);
    nc::NdArray<float, std::__1::allocator<float> >::put(r19, &var_F8, 0x1);
    if (var_60 != 0x0) {
            r0 = var_68;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_68 = 0x0;
    var_60 = 0x0;
    *(r21 + 0xc) = 0x0;
    if (var_88 != 0x0) {
            r0 = var_90;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_F8 = r19[0x1] << 0x20;
    nc::NdArray<float, std::__1::allocator<float> >::operator(r20, r20[0x1] << 0x20);
    auto nc::log<float>(&decomp_var_a8);
    r0 = nc::NdArray<float, std::__1::allocator<float> >::put(r19, &var_F8, 0x2);
    if (var_60 != 0x0) {
            r0 = var_68;
            if (r0 != 0x0) {
                    r0 = operator delete(r0);
            }
    }
    *(r21 + 0xc) = 0x0;
    if (var_88 != 0x0) {
            r0 = var_90;
            if (r0 != 0x0) {
                    r0 = operator delete(r0);
            }
    }
    return r0;
