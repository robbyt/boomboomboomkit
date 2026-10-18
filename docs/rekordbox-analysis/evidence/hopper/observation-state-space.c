    r31 = r31 - 0x170;
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
    r21 = r2;
    r20 = arg1;
    r19 = arg0;
    arg0[0x4] = 0x0;
    arg0[0x28] = 0x0;
    *(arg0 + 0x14) = 0x0;
    *(arg0 + 0xc) = 0x0;
    *arg0 = 0x1052f7970;
    arg0[0xc] = r2;
    r24 = arg1[0x16];
    var_78 = 0x0;
    var_70 = 0x0;
    if (r24 != 0x0) {
            r0 = operator new(r24 << 0x2);
            r22 = r0;
            var_78 = r0;
            var_70 = 0x1;
    }
    else {
            r22 = 0x0;
    }
    nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_B8);
    r23 = var_B8;
    r0 = nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_B8);
    r8 = var_B8 + r24 * 0x4 - r23;
    if (r8 >= 0x1) {
            r9 = r8 >> 0x2;
            if (r8 > 0x3) {
                    r8 = 0x1;
            }
            bzero(r23, (r9 - r8 << 0x2) + 0x4);
    }
    r20 = r20 + 0x8;
    nc::NdArray<double, std::__1::allocator<double> >::NdArray(&decomp_var_108);
    nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_68);
    r25 = var_68;
    r1 = var_F0;
    nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_68);
    d8 = 0x3ff0000000000000 / r21;
    r21 = var_68 + var_FC * 0x8;
    if (r25 != r21) {
            r8 = r21 - r25 - 0x8;
            r22 = r25;
            if (r8 >= 0x38) {
                    r23 = (r8 >> 0x3) + 0x1;
                    r24 = r23 & 0x3ffffffffffffff8;
                    r22 = r25 + r24 * 0x8;
                    r25 = r25 + 0x20;
                    r26 = r24;
                    do {
                            var_120 = r25[0x1];
                            fmod(s0, s1);
                            fmod(s0, s1);
                            var_150 = q0;
                            fmod(s0, s1);
                            fmod(s0, s1);
                            var_140 = q0;
                            fmod(s0, s1);
                            fmod(s0, s1);
                            var_130 = q0;
                            fmod(s0, s1);
                            q0 = var_120;
                            fmod(s0, s1);
                            r25[0xfffffffffffffffc] = var_150;
                            r25[0xfffffffffffffffe] = var_140;
                            *r25 = var_130;
                            r25[0x2] = q0;
                            r25 = r25 + 0x40;
                            r26 = r26 - 0x8;
                    } while (r26 != 0x0);
                    if (r23 != r24) {
                            fmod(s0, s1);
                            *r22 = d0;
                            r22 = r22 + 0x8;
                            if (r22 != r21) {
                                    do {
                                            fmod(s0, s1);
                                            *r22 = d0;
                                            r22 = r22 + 0x8;
                                    } while (r22 != r21);
                            }
                    }
            }
            else {
                    do {
                            fmod(s0, s1);
                            *r22 = d0;
                            r22 = r22 + 0x8;
                    } while (r22 != r21);
            }
    }
    var_C8 = var_F0;
    var_C0 = var_E8;
    var_E8 = 0x0;
    var_F0 = 0x0;
    nc::NdArray<bool, std::__1::allocator<bool> > nc::operator< <double>(&var_E0, r1);
    r1 = &var_B8;
    r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::putMask(&decomp_var_90, r1);
    if (var_98 != 0x0) {
            r0 = var_A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_A0 = 0x0;
    var_98 = 0x0;
    if (var_C0 != 0x0) {
            r0 = var_C8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_E8 != 0x0) {
            r0 = var_F0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    nc::NdArray<bool, std::__1::allocator<bool> > nc::operator< <double>(r20, r1);
    r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::putMask(&decomp_var_90, &var_B8);
    if (var_98 != 0x0) {
            r0 = var_A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::operator=(r19 + 0x8);
    if (var_70 != 0x0) {
            r0 = var_78;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = r19;
    return r0;
