    s1 = arg3;
    s0 = arg2;
    r1 = arg1;
    var_70 = d11;
    decomp_var_68 = d10;
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
    r31 = r31 + 0xffffffffffffff80 - 0x7e0;
    r27 = arg8;
    r24 = arg6;
    r25 = arg5;
    r26 = arg4;
    var_820 = q3;
    s8 = arg7;
    d9 = d1;
    d10 = d0;
    r19 = arg0;
    var_828 = r8;
    r23 = &decomp_var_420;
    var_88 = **___stack_chk_guard;
    r22 = *r1;
    r20 = r1[0x1];
    r21 = r20 - r22;
    var_808 = r21 >> 0x2;
    if (r21 >> 0x2 == 0x0) goto loc_102300e64;
    goto loc_102300de4;

loc_102300e64:
    var_7E8 = 0x0;
    goto loc_102300e80;

loc_102300de4:
    r0 = operator new(r21 & 0x3fffffffc);
    var_7E8 = r0;
    if (r22 == r20) goto loc_102300e80;
    goto loc_102300df8;

loc_102300e80:
    q0 = *(int128_t *)("13" + 0x470);
    var_800 = q0;
    *(int128_t *)(r23 + 0x7c) = q0;
    r0 = operator new(0x8);
    var_390 = r0;
    var_388 = 0x1;
    *r0 = d10;
    *(int128_t *)(r23 + 0x54) = var_800;
    r0 = operator new(0x8);
    var_3B8 = r0;
    var_3B0 = 0x1;
    *r0 = d9;
    *(int128_t *)(r23 + 0x2c) = var_800;
    r0 = operator new(0x4);
    var_3E0 = r0;
    r20 = 0x1;
    var_3D8 = 0x1;
    *(int32_t *)r0 = r26;
    q0 = var_800;
    *(int128_t *)(r23 + 0x4) = q0;
    r0 = operator new(0x4);
    var_408 = r0;
    var_400 = 0x1;
    *(int32_t *)r0 = r25;
    r2 = var_808;
    if (r2 != 0x1) {
            r1 = 0x1;
            r0 = nc::NdArray<double, std::__1::allocator<double> >::repeat(&decomp_var_3a8, 0x1);
            if (var_388 != 0x0) {
                    r0 = var_390;
                    if (r0 != 0x0) {
                            r1 = 0x1;
                            operator delete(r0);
                    }
            }
            *(r23 + 0x7c) = *(r23 + 0xb4);
            *(r23 + 0x84) = *(r23 + 0xbc);
            var_390 = var_358;
            var_388 = var_350;
            r20 = var_3C4;
            r2 = var_808;
    }
    bool_41 = r20 == r2;
    r20 = r2;
    if (!bool_41) {
            r1 = 0x1;
            r0 = nc::NdArray<double, std::__1::allocator<double> >::repeat(&decomp_var_3d0, 0x1);
            if (var_3B0 != 0x0) {
                    r0 = var_3B8;
                    if (r0 != 0x0) {
                            r1 = 0x1;
                            operator delete(r0);
                    }
            }
            *(r23 + 0x54) = *(r23 + 0xb4);
            *(r23 + 0x5c) = *(r23 + 0xbc);
            var_3B8 = var_358;
            var_3B0 = var_350;
    }
    if (var_3EC != r20) {
            r1 = 0x1;
            nc::NdArray<int, std::__1::allocator<int> >::repeat(&decomp_var_3f8, 0x1);
            if (var_3D8 != 0x0) {
                    r0 = var_3E0;
                    if (r0 != 0x0) {
                            r1 = 0x1;
                            operator delete(r0);
                    }
            }
            *(r23 + 0x2c) = *(r23 + 0xb4);
            *(r23 + 0x34) = *(r23 + 0xbc);
            var_3E0 = var_358;
            var_3D8 = var_350;
    }
    if (var_414 != r20) {
            r1 = 0x1;
            r0 = nc::NdArray<int, std::__1::allocator<int> >::repeat(&decomp_var_420, 0x1);
            if (var_400 != 0x0) {
                    r0 = var_408;
                    if (r0 != 0x0) {
                            r1 = 0x1;
                            operator delete(r0);
                    }
            }
            *(r23 + 0x4) = *(r23 + 0xb4);
            *(r23 + 0xc) = *(r23 + 0xbc);
            var_408 = var_358;
            var_400 = var_350;
    }
    nc::NdArray<double, std::__1::allocator<double> > nc::operator/<double>(&decomp_var_3d0, r1);
    var_830 = r27;
    nc::NdArray<double, std::__1::allocator<double> > nc::operator/<double>(&decomp_var_3a8, r1);
    var_480 = 0x0;
    var_488 = 0x0;
    var_478 = 0x0;
    if (r20 != 0x0) {
            r28 = 0x0;
            r20 = &var_1B8 + 0x10c;
            r25 = &var_1B8 + 0x78;
            r27 = &var_1B8 + 0x54;
            r23 = &var_1B8 + 0x2c;
            asm { ubfx       x21, x21, #0x2, #0x20 };
            do {
                    r1 = *(int32_t *)(var_7E8 + (r28 << 0x2));
                    d1 = *(var_458 + (r28 << 0x3));
                    madmom::BarStateSpace::BarStateSpace(&decomp_var_518, s0, s1, r1);
                    madmom::BarTransitionModel::BarTransitionModel(&var_1B8, &decomp_var_518);
                    r0 = madmom::RNNDownBeatTrackingObservationModel::RNNDownBeatTrackingObservationModel(&var_550, &decomp_var_518);
                    var_560 = 0x0;
                    v0 = 0x0;
                    var_580 = q0;
                    r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::HiddenMarkovModel(&var_370, &var_1B8, &var_550);
                    r26 = var_480;
                    if (r26 < var_478) {
                            madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::HiddenMarkovModel(r26);
                            var_480 = r26 + 0x1b8;
                    }
                    else {
                            r0 = void std::__1::vector<madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>, std::__1::allocator<madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel> > >::__push_back_slow_path<madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel> >(&var_488);
                    }
                    madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
                    if (var_560 != 0x0) {
                            r0 = var_568;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
                    var_550 = 0x1052f79b0;
                    if (var_528 != 0x0) {
                            r0 = var_530;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
                    if (var_90 != 0x0) {
                            r0 = var_98;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
                    var_98 = 0x0;
                    var_90 = 0x0;
                    *r20 = 0x0;
                    r20[0x1] = 0x0;
                    madmom::BarStateSpace::~BarStateSpace();
                    if (var_148 != 0x0) {
                            r0 = var_150;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
                    var_150 = 0x0;
                    var_148 = 0x0;
                    *r27 = 0x0;
                    r27[0x1] = 0x0;
                    if (var_170 != 0x0) {
                            r0 = var_178;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
                    var_178 = 0x0;
                    var_170 = 0x0;
                    *r23 = 0x0;
                    r23[0x1] = 0x0;
                    if (var_198 != 0x0) {
                            r0 = var_1A0;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
                    madmom::BarStateSpace::~BarStateSpace();
                    r28 = r28 + 0x1;
            } while (r21 != r28);
    }
    r1 = r19;
    r0 = nc::NdArray<float, std::__1::allocator<float> >::NdArray(&decomp_var_518);
    if (s8 != 0x0) {
            std::__1::tuple<nc::NdArray<float, std::__1::allocator<float> >, int> madmom::threshold_activations<float>(r19, r1);
            r0 = nc::NdArray<float, std::__1::allocator<float> >::operator=(&decomp_var_518);
            r28 = &decomp_var_420;
            r21 = var_348;
            if (var_350 != 0x0) {
                    r0 = var_358;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
    }
    else {
            r21 = 0x0;
            r28 = &decomp_var_420;
    }
    r0 = nc::NdArray<float, std::__1::allocator<float> >::any(&decomp_var_518);
    r0 = var_358;
    r20 = *(int8_t *)r0;
    if (var_350 != 0x0) {
            operator delete(r0);
    }
    if (r20 == 0x0) goto loc_10230140c;
    goto loc_1023012b4;

loc_102300df8:
    r9 = r21 - 0x4;
    if (r9 < 0x3c) goto loc_102300e6c;
    goto loc_102300e04;

loc_10230140c:
    *(int128_t *)(var_828 + 0x4) = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
    var_828[0x3] = 0x0;
    var_828[0x20] = 0x0;
    if (var_4F8 != 0x0) {
            r0 = var_500;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_488;
    if (r20 != 0x0) {
            r0 = var_480;
            r8 = r20;
            if (r0 != r20) {
                    do {
                            r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
                    } while (r0 != r20);
                    r8 = var_488;
            }
            operator delete(r8);
    }
    if (var_450 != 0x0) {
            r0 = var_458;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_808;
    if (var_428 != 0x0) {
            r0 = var_430;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_400 != 0x0) {
            r0 = var_408;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3D8 != 0x0) {
            r0 = var_3E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3B0 != 0x0) {
            r0 = var_3B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_388 != 0x0) {
            r0 = var_390;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_7E8;
    if (r20 != 0x0 && r0 != 0x0) {
            r0 = operator delete(r0);
    }
    if (**___stack_chk_guard != var_88) {
            __stack_chk_fail();
    }
    return r0;

loc_1023012b4:
    var_834 = r21;
    var_590 = 0x0;
    var_598 = 0x0;
    var_588 = 0x0;
    var_5A8 = 0x0;
    var_5B0 = 0x0;
    var_5A0 = 0x0;
    r23 = var_488;
    r20 = var_480;
    if (r23 == r20) goto loc_102301428;
    goto loc_1023012e0;

loc_102300e6c:
    r8 = r0;
    goto loc_102300e70;

loc_102300e04:
    r8 = r0;
    if (r0 - r22 < 0x40) goto .l96;
    goto loc_102300e14;

.l7:
    return r0;

loc_102301428:
    r22 = 0x0;
    var_1A0 = 0x0;
    var_198 = 0x0;
    if (r22 >> 0x3 == 0x0) goto loc_1023014ec;
    goto loc_102301458;

loc_1023012e0:
    r21 = 0x7ffffffffffffff8;
    goto loc_1023012f8;

loc_102300e70:
    r9 = *(int32_t *)r22;
    r22 = r22 + 0x4;
    *(int32_t *)r8 = r9;
    r8 = r8 + 0x4;
    if (r22 != r20) {
            continue;
    }
    break;

.l96:
    do {
            r9 = *(int32_t *)r22;
            r22 = r22 + 0x4;
            *(int32_t *)r8 = r9;
            r8 = r8 + 0x4;
    } while (r22 != r20);
    goto loc_102300e80;

loc_102300e14:
    r9 = (r9 >> 0x2) + 0x1;
    r10 = r9 & 0x7ffffffffffffff0;
    r11 = r22 + (r10 << 0x2);
    r8 = var_7E8 + (r10 << 0x2);
    r12 = r22 + 0x20;
    r13 = var_7E8 + 0x20;
    r14 = r10;
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
    r22 = r11;
    if (r9 != r10) goto .l97;
    goto loc_102300e80;

loc_1023014ec:
    r0 = nc::NdArray<double, std::__1::allocator<double> >::argmax(&var_1B8);
    r0 = var_358;
    r20 = *(int32_t *)r0;
    if (var_350 != 0x0) {
            operator delete(r0);
    }
    var_358 = 0x0;
    var_350 = 0x0;
    *(r28 + 0xbc) = 0x0;
    *(r28 + 0xb4) = 0x0;
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r23 = 0x28 + r23 * r20;
    if (r23[0x3] == 0x0) goto loc_102301d88;
    goto loc_102301548;

loc_102301458:
    r21 = 0x0;
    r20 = 0x0;
    r0 = operator new(r22 & 0x7fffffff8);
    var_1A0 = r0;
    var_198 = 0x1;
    if (0x0 == 0x0) goto loc_1023014ec;
    goto loc_102301474;

loc_1023012f8:
    madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::viterbi(r23);
    r24 = var_590;
    if (r24 != var_588) {
            r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::NdArray(r24);
            var_590 = r24 + 0x28;
    }
    else {
            r0 = void std::__1::vector<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >, std::__1::allocator<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > > >::__push_back_slow_path<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > const&>(&var_598);
    }
    r8 = var_5A8;
    if (r8 != var_5A0) {
            *r8 = var_348;
            var_5A8 = r8 + 0x8;
            r28 = &decomp_var_420;
            if (var_350 != 0x0) {
                    r0 = var_358;
                    if (r0 != 0x0) {
                            r0 = operator delete(r0);
                    }
            }
            r23 = r23 + 0x1b8;
            if (r23 != r20) {
                    continue;
            }
            r20 = var_5A8;
            r21 = var_5B0;
            temp_0 = 0x2;
            break;
    }
    else {
            r24 = var_5B0;
            r25 = r8 - r24;
            r27 = SAR(r25, 0x3);
            r8 = r27 + 0x1;
            if (r8 >> 0x3d == 0x0) {
                    r9 = SAR(r25, 0x2);
                    if (r9 > r8) {
                            r8 = r9;
                    }
                    r21 = 0x7ffffffffffffff8;
                    if (r25 >= 0x7ffffffffffffff8) {
                            r28 = 0x1fffffffffffffff;
                    }
                    else {
                            r28 = r8;
                    }
                    if (r28 != 0x0) {
                            if (r28 >> 0x3d == 0x0) {
                                    r26 = operator new(r28 << 0x3);
                                    *(r26 + r27 * 0x8) = var_348;
                                    r0 = memmove(r26, r24, r25);
                                    var_5B0 = r26;
                                    var_5A8 = r26 + r27 * 0x8 + 0x8;
                                    var_5A0 = r26 + r28 * 0x8;
                                    r28 = &decomp_var_420;
                                    if (r24 != 0x0) {
                                            r0 = operator delete(r24);
                                    }
                                    if (var_350 != 0x0) {
                                            r0 = var_358;
                                            if (r0 != 0x0) {
                                                    r0 = operator delete(r0);
                                            }
                                    }
                                    r23 = r23 + 0x1b8;
                                    if (r23 != r20) {
                                            continue;
                                    }
                                    r20 = var_5A8;
                                    r21 = var_5B0;
                                    temp_0 = 0x2;
                                    break;
                            }
                            else {
                                    r0 = std::__throw_bad_array_new_length[abi:v15006]();
                                    temp_0 = 0x1;
                                    break;
                            }
                    }
                    else {
                            *(0x0 + r27 * 0x8) = var_348;
                            r0 = memmove(0x0, r24, r25);
                            var_5B0 = 0x0;
                            var_5A8 = r27 * 0x8 + 0x8;
                            var_5A0 = 0x0 + r28 * 0x8;
                            r28 = &decomp_var_420;
                            if (r24 != 0x0) {
                                    r0 = operator delete(r24);
                            }
                            if (var_350 != 0x0) {
                                    r0 = var_358;
                                    if (r0 != 0x0) {
                                            r0 = operator delete(r0);
                                    }
                            }
                            r23 = r23 + 0x1b8;
                            if (r23 != r20) {
                                    continue;
                            }
                            r20 = var_5A8;
                            r21 = var_5B0;
                            temp_0 = 0x2;
                            break;
                    }
            }
            else {
                    r0 = std::__1::vector<double, std::__1::allocator<double> >::__throw_length_error[abi:v15006]();
                    temp_0 = 0x0;
                    break;
            }
    }
    goto .l132;

.l97:
    goto .l107;

loc_102301d88:
    *(int128_t *)(var_828 + 0x4) = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
    var_828[0x3] = 0x0;
    var_828[0x20] = 0x0;
    r0 = var_5B0;
    if (r0 != 0x0) {
            operator delete(r0);
    }
    r20 = var_598;
    if (r20 == 0x0) goto .l51;
    goto loc_102302488;

loc_102301548:
    r21 = var_488;
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<double, std::__1::allocator<double> >::operator[]<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >, 0>(0x1b8 * r20 + 0x238);
    r24 = &decomp_var_5d8;
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<double, std::__1::allocator<double> >::astype<int, double, 0, 0, 0>();
    nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_370);
    r22 = var_370;
    r0 = nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_370);
    r26 = &var_650;
    r8 = r24 + 0x18;
    r9 = var_370 + var_5CC * 0x4;
    if (r22 != r9) {
            r11 = r9 - r22 - 0x4;
            r10 = r22;
            if (r11 >= 0x3c) {
                    r11 = (r11 >> 0x2) + 0x1;
                    r12 = r11 & 0x7ffffffffffffff0;
                    r10 = r22 + r12 * 0x4;
                    r13 = r22 + 0x20;
                    v0 = 0x1;
                    r14 = r12;
                    do {
                            q1 = r13[0xfffffffffffffffc];
                            q2 = r13[0xfffffffffffffffe];
                            q3 = *r13;
                            q4 = r13[0x2];
                            v1 = v1 + v0;
                            v2 = v2 + v0;
                            v3 = v3 + v0;
                            v4 = v4 + v0;
                            r13[0xfffffffffffffffc] = q1;
                            r13[0xfffffffffffffffe] = q2;
                            *r13 = q3;
                            r13[0x2] = q4;
                            r13 = r13 + 0x40;
                            r14 = r14 - 0x10;
                    } while (r14 != 0x0);
                    if (r11 != r12) {
                            *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
                            r10 = r10 + 0x4;
                            if (r10 != r9) {
                                    *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
                                    r10 = r10 + 0x4;
                                    if (r10 != r9) {
                                            continue;
                                    }
                                    break;
                            }
                    }
            }
            else {
                    *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
                    r10 = r10 + 0x4;
                    if (r10 != r9) {
                            continue;
                    }
                    break;
            }
    }
    r25 = &decomp_var_768;
    *(r26 + 0xd4) = *(r26 + 0x7c);
    *(r26 + 0xdc) = *(r26 + 0x84);
    var_568 = var_5C0;
    var_560 = var_5B8;
    *(r26 + 0x84) = 0x0;
    *(r26 + 0x7c) = 0x0;
    r8[0x8] = 0x0;
    *r8 = 0x0;
    var_5E8 = 0x0;
    var_5E0 = 0x0;
    *(r26 + 0x5c) = 0x0;
    *(r26 + 0x54) = 0x0;
    if (var_830 == 0x0) goto loc_102301da4;
    goto .l57;

loc_102301474:
    r8 = r22 - 0x8;
    if (r8 < 0x38) goto .l80;
    goto loc_102301480;

.l132:
    if (temp_0 == 0x0 || temp_0 == 0x1) goto .l7;
    goto loc_102301430;

.l107:
    r9 = *(int32_t *)r22;
    r22 = r22 + 0x4;
    *(int32_t *)r8 = r9;
    r8 = r8 + 0x4;
    if (r22 != r20) {
            continue;
    }
    break;

.l51:
    if (var_4F8 != 0x0) {
            r0 = var_500;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_488;
    if (r20 != 0x0) {
            r0 = var_480;
            r8 = r20;
            if (r0 != r20) {
                    do {
                            r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
                    } while (r0 != r20);
                    r8 = var_488;
            }
            operator delete(r8);
    }
    if (var_450 != 0x0) {
            r0 = var_458;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_808;
    if (var_428 != 0x0) {
            r0 = var_430;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_400 != 0x0) {
            r0 = var_408;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3D8 != 0x0) {
            r0 = var_3E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3B0 != 0x0) {
            r0 = var_3B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_388 != 0x0) {
            r0 = var_390;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_7E8;
    if (r20 != 0x0 && r0 != 0x0) {
            r0 = operator delete(r0);
    }
    if (**___stack_chk_guard != var_88) {
            __stack_chk_fail();
    }
    return r0;

loc_102302488:
    r21 = var_590;
    r0 = r20;
    if (r21 != r20) goto .l127;
    goto loc_1023024d8;

loc_102301da4:
    r0 = nc::NdArray<int, std::__1::allocator<int> > nc::diff<int>(&var_580, 0x0);
    nc::NdArray<int, std::__1::allocator<int> >::nonzero();
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::astype<int, unsigned int, 0, 0, 0>();
    nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_628);
    r20 = var_628;
    r0 = nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_628);
    r8 = var_628 + var_75C * 0x4;
    if (r20 != r8) {
            r10 = r8 - r20 - 0x4;
            r9 = r20;
            if (r10 >= 0x3c) {
                    r10 = (r10 >> 0x2) + 0x1;
                    r11 = r10 & 0x7ffffffffffffff0;
                    r9 = r20 + r11 * 0x4;
                    r12 = r20 + 0x20;
                    v0 = 0x1;
                    r13 = r11;
                    do {
                            q1 = r12[0xfffffffffffffffc];
                            q2 = r12[0xfffffffffffffffe];
                            q3 = *r12;
                            q4 = r12[0x2];
                            v1 = v1 + v0;
                            v2 = v2 + v0;
                            v3 = v3 + v0;
                            v4 = v4 + v0;
                            r12[0xfffffffffffffffc] = q1;
                            r12[0xfffffffffffffffe] = q2;
                            *r12 = q3;
                            r12[0x2] = q4;
                            r12 = r12 + 0x40;
                            r13 = r13 - 0x10;
                    } while (r13 != 0x0);
                    if (r10 != r11) {
                            *(int32_t *)r9 = *(int32_t *)r9 + 0x1;
                            r9 = r9 + 0x4;
                            if (r9 != r8) {
                                    *(int32_t *)r9 = *(int32_t *)r9 + 0x1;
                                    r9 = r9 + 0x4;
                                    if (r9 != r8) {
                                            continue;
                                    }
                                    break;
                            }
                    }
            }
            else {
                    *(int32_t *)r9 = *(int32_t *)r9 + 0x1;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    r20 = var_764;
    d8 = *(r25 + 0xc);
    r21 = var_750;
    r22 = var_748;
    var_748 = 0x0;
    var_750 = 0x0;
    r8 = var_5E0;
    if (r8 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
                    r8 = var_748;
                    *(r26 + 0x54) = r20;
                    *(r26 + 0x5c) = d8;
                    var_5E8 = r21;
                    var_5E0 = r22;
                    if (r8 != 0x0) {
                            r0 = var_750;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
            }
            else {
                    *(r26 + 0x54) = r20;
                    *(r26 + 0x5c) = d8;
                    var_5E8 = r21;
                    var_5E0 = r22;
                    if (0x0 != 0x0) {
                            r0 = var_750;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
            }
    }
    else {
            *(r26 + 0x54) = r20;
            *(r26 + 0x5c) = d8;
            var_5E8 = r21;
            var_5E0 = r22;
            if (r8 != 0x0) {
                    r0 = var_750;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
    }
    *(r25 + 0xc) = 0x0;
    if (var_328 != 0x0) {
            r0 = var_330;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_330 = 0x0;
    var_328 = 0x0;
    *(r28 + 0xe4) = 0x0;
    *(r28 + 0xdc) = 0x0;
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xbc) = 0x0;
    *(r28 + 0xb4) = 0x0;
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    nc::NdArray<int, std::__1::allocator<int> >::NdArray(&decomp_var_7e0);
    nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_650);
    r20 = var_650;
    r0 = nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_650);
    r8 = var_650 + var_7D4 * 0x4;
    r14 = var_834;
    if (r20 != r8) {
            r10 = r8 - r20 - 0x4;
            r9 = r20;
            if (r10 >= 0x3c) {
                    r10 = (r10 >> 0x2) + 0x1;
                    r11 = r10 & 0x7ffffffffffffff0;
                    r9 = r20 + r11 * 0x4;
                    asm { dup        v0.4s, w14 };
                    r12 = r20 + 0x20;
                    r13 = r11;
                    do {
                            q1 = r12[0xfffffffffffffffc];
                            q2 = r12[0xfffffffffffffffe];
                            q3 = *r12;
                            q4 = r12[0x2];
                            v1 = v1 + v0;
                            v2 = v2 + v0;
                            v3 = v3 + v0;
                            v4 = v4 + v0;
                            r12[0xfffffffffffffffc] = q1;
                            r12[0xfffffffffffffffe] = q2;
                            *r12 = q3;
                            r12[0x2] = q4;
                            r12 = r12 + 0x40;
                            r13 = r13 - 0x10;
                    } while (r13 != 0x0);
                    if (r10 != r11) {
                            *(int32_t *)r9 = *(int32_t *)r9 + r14;
                            r9 = r9 + 0x4;
                            if (r9 != r8) {
                                    *(int32_t *)r9 = *(int32_t *)r9 + r14;
                                    r9 = r9 + 0x4;
                                    if (r9 != r8) {
                                            continue;
                                    }
                                    break;
                            }
                    }
            }
            else {
                    *(int32_t *)r9 = *(int32_t *)r9 + r14;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    var_7A0 = var_7C8;
    var_798 = var_7C0;
    var_7C0 = 0x0;
    var_7C8 = 0x0;
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<int, std::__1::allocator<int> >::astype<double, int, 0, 0, 0>();
    nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_650);
    r20 = var_650;
    r0 = nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_650);
    r8 = var_650 + var_784 * 0x8;
    if (r20 == r8) goto .l5;
    goto .l2;

.l57:
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::operator[]<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >, 0>(r21 + r20 * 0x1b8 + 0x138);
    r0 = nc::NdArray<bool, std::__1::allocator<bool> > nc::operator>=<unsigned int>(&var_370, 0x1);
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    nc::NdArrayConstIterator<bool, bool const*, long>::NdArrayConstIterator(&var_370);
    r20 = var_370;
    r0 = nc::NdArrayConstIterator<bool, bool const*, long>::NdArrayConstIterator(&var_370);
    if (r20 == var_370 + var_61C) goto .l78;
    goto .l53;

.l80:
    r8 = r21;
    r9 = r0;
    do {
            d0 = *r8;
            r8 = r8 + 0x8;
            *r9 = d0;
            r9 = r9 + 0x8;
    } while (r8 != r20);
    goto loc_1023014ec;

loc_102301480:
    if (r0 - r21 < 0x40) goto loc_1023014d4;
    goto loc_10230148c;

loc_102301430:
    r22 = r20 - r21;
    var_1A0 = 0x0;
    var_198 = 0x0;
    if (r22 >> 0x3 == 0x0) goto .l67;
    goto .l64;

.l127:
    r22 = r21 - 0x28;
    if (r21[0xfffffffffffffff8] != 0x0) {
            r0 = r21[0xfffffffffffffffe];
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r21[0xfffffffffffffffe] = 0x0;
    r21[0xfffffffffffffff8] = 0x0;
    *(r21 + 0xffffffffffffffe4) = 0x0;
    *(r21 + 0xffffffffffffffdc) = 0x0;
    r21 = r22;
    if (r22 != r20) {
            continue;
    }
    break;

loc_1023024d8:
    operator delete(r0);
    goto .l51;

.l5:
    *(r28 + 0xb4) = var_78C;
    *(r28 + 0xbc) = var_784;
    var_358 = var_778;
    var_350 = var_770;
    var_770 = 0x0;
    var_778 = 0x0;
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::NdArray<int, std::__1::allocator<int> >::astype<unsigned int, int, 0, 0, 0>();
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<int, std::__1::allocator<int> >::operator[]<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >, 0>(&var_580);
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<int, std::__1::allocator<int> >::astype<double, int, 0, 0, 0>();
    var_6C8 = &var_370;
    nc::NdArray<double, std::__1::allocator<double> > nc::row_stack<double>(&var_6C8);
    r20 = &var_628 | 0x4;
    r21 = var_620;
    r23 = var_624;
    r8 = r23 * r21;
    var_1A0 = 0x0;
    var_198 = 0x0;
    if (r8 == 0x0) goto .l1;
    goto .l6;

.l2:
    r10 = r8 - r20 - 0x8;
    r9 = r20;
    if (r10 < 0x38) goto .l74;
    goto .l3;

.l78:
    *(int128_t *)(var_828 + 0x4) = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
    var_828[0x3] = 0x0;
    var_828[0x20] = 0x0;
    r20 = 0x1;
    goto loc_102302010;

.l53:
    r21 = &var_1B8;
    r9 = r20 + 0x1;
    goto loc_1023016e4;

loc_1023014d4:
    r8 = r21;
    r9 = r0;
    do {
            d0 = *r8;
            r8 = r8 + 0x8;
            *r9 = d0;
            r9 = r9 + 0x8;
    } while (r8 != r20);
    goto loc_1023014ec;

loc_10230148c:
    r10 = (r8 >> 0x3) + 0x1;
    r11 = r10 & 0x3ffffffffffffff8;
    r8 = r21 + (r11 << 0x3);
    r9 = r0 + (r11 << 0x3);
    r12 = r21 + 0x20;
    r13 = r0 + 0x20;
    r14 = r11;
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
            r14 = r14 - 0x8;
    } while (r14 != 0x0);
    if (r10 != r11) goto .l86;
    goto loc_1023014ec;

.l67:
    r0 = nc::NdArray<double, std::__1::allocator<double> >::argmax(&var_1B8);
    r0 = var_358;
    r20 = *(int32_t *)r0;
    if (var_350 != 0x0) {
            operator delete(r0);
    }
    var_358 = 0x0;
    var_350 = 0x0;
    *(r28 + 0xbc) = 0x0;
    *(r28 + 0xb4) = 0x0;
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r23 = 0x28 + r23 * r20;
    if (r23[0x3] == 0x0) goto .l69;
    goto .l10;

.l64:
    r0 = operator new(r22 & 0x7fffffff8);
    var_1A0 = r0;
    var_198 = 0x1;
    if (r21 == r20) goto .l67;
    goto .l65;
    r0 = var_598;
    goto loc_1023024d8;

.l1:
    r8 = &var_1B8;
    if (r23 == 0x0 || r21 == 0x0) goto .l8;
    goto loc_1023022ac;

.l6:
    r0 = operator new(r8 << 0x3);
    var_1A0 = r0;
    var_198 = 0x1;
    r8 = &var_1B8;
    if (r23 != 0x0) goto loc_1023022a8;
    goto .l8;

.l74:
    d0 = 0x3ff0000000000000 / d1;
    goto .l119;

.l3:
    r10 = (r10 >> 0x3) + 0x1;
    r11 = r10 & 0x3ffffffffffffff8;
    r9 = r20 + r11 * 0x8;
    asm { dup        v0.2d, v0.d[0] };
    v1 = 0x3ff0000000000000;
    v0 = 0x3ff0000000000000 / v0;
    r12 = r20 + 0x20;
    r13 = r11;
    goto .l105;

loc_102302010:
    if (var_608 != 0x0) {
            r0 = var_610;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (r20 != 0x0) goto loc_102302434;
    goto .l26;

loc_1023016e4:
    r10 = r9[0xffffffffffffffff];
    asm { ccmp       x9, x8, #0x4, eq };
    r9 = r9 + 0x1;
    if (asm { ccmp       x9, x8, #0x4, eq }) {
            continue;
    }
    break;

.l86:
    goto .l131;

.l69:
    *(int128_t *)(var_828 + 0x4) = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
    var_828[0x3] = 0x0;
    var_828[0x20] = 0x0;
    r0 = var_5B0;
    if (r0 != 0x0) {
            operator delete(r0);
    }
    r20 = var_598;
    if (r20 != 0x0) {
            r21 = var_590;
            r0 = r20;
            if (r21 != r20) {
                    do {
                            r22 = r21 - 0x28;
                            if (r21[0xfffffffffffffff8] != 0x0) {
                                    r0 = r21[0xfffffffffffffffe];
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                            }
                            r21[0xfffffffffffffffe] = 0x0;
                            r21[0xfffffffffffffff8] = 0x0;
                            *(r21 + 0xffffffffffffffe4) = 0x0;
                            *(r21 + 0xffffffffffffffdc) = 0x0;
                            r21 = r22;
                    } while (r22 != r20);
                    r0 = var_598;
            }
            operator delete(r0);
    }
    if (var_4F8 != 0x0) {
            r0 = var_500;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_488;
    if (r20 != 0x0) {
            r0 = var_480;
            r8 = r20;
            if (r0 != r20) {
                    do {
                            r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
                    } while (r0 != r20);
                    r8 = var_488;
            }
            operator delete(r8);
    }
    if (var_450 != 0x0) {
            r0 = var_458;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_808;
    if (var_428 != 0x0) {
            r0 = var_430;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_400 != 0x0) {
            r0 = var_408;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3D8 != 0x0) {
            r0 = var_3E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3B0 != 0x0) {
            r0 = var_3B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_388 != 0x0) {
            r0 = var_390;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_7E8;
    if (r20 != 0x0 && r0 != 0x0) {
            r0 = operator delete(r0);
    }
    if (**___stack_chk_guard != var_88) {
            __stack_chk_fail();
    }
    return r0;

.l10:
    r21 = var_488;
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<double, std::__1::allocator<double> >::operator[]<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >, 0>(0x1b8 * r20 + 0x238);
    r24 = &decomp_var_5d8;
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<double, std::__1::allocator<double> >::astype<int, double, 0, 0, 0>();
    nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_370);
    r22 = var_370;
    r0 = nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_370);
    r26 = &var_650;
    r8 = r24 + 0x18;
    r9 = var_370 + var_5CC * 0x4;
    if (r22 == r9) goto loc_102301620;
    goto loc_1023015ac;

.l65:
    r8 = r22 - 0x8;
    if (r8 < 0x38) goto .l87;
    goto .l66;

.l8:
    r23 = r8 | 0x4;
    nc::NdArray<float, std::__1::allocator<float> > nc::NdArray<double, std::__1::allocator<double> >::astype<float, double, 0, 0, 0>();
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *r23 = 0x0;
    r23[0x1] = 0x0;
    if (var_608 != 0x0) {
            r0 = var_610;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *r20 = 0x0;
    r20[0x1] = 0x0;
    if (var_328 != 0x0) {
            r0 = var_330;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xe4) = 0x0;
    *(r28 + 0xdc) = 0x0;
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xbc) = 0x0;
    *(r28 + 0xb4) = 0x0;
    if (var_630 != 0x0) {
            r0 = var_638;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r26 + 0xc) = 0x0;
    *(r26 + 0x4) = 0x0;
    if (var_658 != 0x0) {
            r0 = var_660;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_770 != 0x0) {
            r0 = var_778;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_798 != 0x0) {
            r0 = var_7A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_7C0 != 0x0) {
            r0 = var_7C8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_5E0 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_560 != 0x0) {
            r0 = var_568;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_530 != 0x0) {
            r0 = var_538;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_5B0;
    if (r0 != 0x0) {
            operator delete(r0);
    }
    r20 = var_598;
    if (r20 != 0x0) {
            r21 = var_590;
            r0 = r20;
            if (r21 != r20) {
                    do {
                            r22 = r21 - 0x28;
                            if (r21[0xfffffffffffffff8] != 0x0) {
                                    r0 = r21[0xfffffffffffffffe];
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                            }
                            r21[0xfffffffffffffffe] = 0x0;
                            r21[0xfffffffffffffff8] = 0x0;
                            *(r21 + 0xffffffffffffffe4) = 0x0;
                            *(r21 + 0xffffffffffffffdc) = 0x0;
                            r21 = r22;
                    } while (r22 != r20);
                    r0 = var_598;
            }
            operator delete(r0);
    }
    if (var_4F8 != 0x0) {
            r0 = var_500;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_488;
    if (r20 == 0x0) goto loc_10230252c;
    goto loc_1023024fc;

loc_1023022ac:
    r9 = 0x0;
    r10 = var_610;
    goto .l128;

loc_1023022a8:
    if (r21 == 0x0) goto .l8;
    goto .l73;

.l119:
    *r9 = *r9 * d0;
    r9 = r9 + 0x8;
    if (r9 != r8) {
            continue;
    }
    break;

.l105:
    q1 = r12[0xfffffffffffffffc];
    q2 = r12[0xfffffffffffffffe];
    q3 = *r12;
    q4 = r12[0x2];
    v1 = v1 * v0;
    v2 = v2 * v0;
    v3 = v3 * v0;
    v4 = v4 * v0;
    r12[0xfffffffffffffffc] = q1;
    r12[0xfffffffffffffffe] = q2;
    *r12 = q3;
    r12[0x2] = q4;
    r12 = r12 + 0x40;
    r13 = r13 - 0x8;
    if (r13 != 0x0) {
            continue;
    }
    break;

loc_102302434:
    if (var_5E0 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_560 != 0x0) {
            r0 = var_568;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_530 != 0x0) {
            r0 = var_538;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_5B0;
    if (r0 != 0x0) {
            operator delete(r0);
    }
    r20 = var_598;
    if (r20 == 0x0) goto .l42;
    goto .l62;

.l26:
    nc::NdArray<int, std::__1::allocator<int> >::NdArray(&decomp_var_7e0);
    nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_650);
    r20 = var_650;
    r0 = nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_650);
    r8 = var_650 + var_7D4 * 0x4;
    r14 = var_834;
    if (r20 == r8) goto loc_1023020dc;
    goto loc_102302068;
    if (r10 == 0x0) goto loc_102301f3c;
    goto .l56;

.l131:
    d0 = *r8;
    r8 = r8 + 0x8;
    *r9 = d0;
    r9 = r9 + 0x8;
    if (r8 != r20) {
            continue;
    }
    break;

loc_102301620:
    r25 = &decomp_var_768;
    *(r26 + 0xd4) = *(r26 + 0x7c);
    *(r26 + 0xdc) = *(r26 + 0x84);
    var_568 = var_5C0;
    var_560 = var_5B8;
    *(r26 + 0x84) = 0x0;
    *(r26 + 0x7c) = 0x0;
    r8[0x8] = 0x0;
    *r8 = 0x0;
    var_5E8 = 0x0;
    var_5E0 = 0x0;
    *(r26 + 0x5c) = 0x0;
    *(r26 + 0x54) = 0x0;
    if (var_830 == 0x0) goto .l13;
    goto loc_10230166c;

loc_1023015ac:
    r11 = r9 - r22 - 0x4;
    r10 = r22;
    if (r11 < 0x3c) goto .l17;
    goto loc_1023015c0;

.l87:
    r8 = r21;
    r9 = r0;
    goto .l89;

.l66:
    if (r0 - r21 < 0x40) goto .l70;
    goto .l68;

loc_10230252c:
    if (var_450 != 0x0) {
            r0 = var_458;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_808;
    if (var_428 != 0x0) {
            r0 = var_430;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_400 != 0x0) {
            r0 = var_408;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3D8 != 0x0) {
            r0 = var_3E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3B0 != 0x0) {
            r0 = var_3B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_388 != 0x0) {
            r0 = var_390;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_7E8;
    if (r20 != 0x0 && r0 != 0x0) {
            r0 = operator delete(r0);
    }
    if (**___stack_chk_guard != var_88) {
            __stack_chk_fail();
    }
    return r0;

loc_1023024fc:
    r0 = var_480;
    r8 = r20;
    if (r0 == r20) goto loc_102302520;
    goto .l111;

.l128:
    r11 = 0x0;
    r13 = r21 * ((r23 & r9 / 0x80000000) + r9);
    goto .l130;

.l73:
    r9 = 0x0;
    r10 = var_610;
    goto .l117;
    if (r10 != r11) {
            d0 = 0x3ff0000000000000 / d1;
            do {
                    *r9 = *r9 * d0;
                    r9 = r9 + 0x8;
            } while (r9 != r8);
    }
    goto .l5;

.l42:
    if (var_4F8 != 0x0) {
            r0 = var_500;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_488;
    if (r20 != 0x0) {
            r0 = var_480;
            r8 = r20;
            if (r0 != r20) {
                    do {
                            r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
                    } while (r0 != r20);
                    r8 = var_488;
            }
            operator delete(r8);
    }
    if (var_450 != 0x0) {
            r0 = var_458;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_808;
    if (var_428 != 0x0) {
            r0 = var_430;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_400 != 0x0) {
            r0 = var_408;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3D8 != 0x0) {
            r0 = var_3E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3B0 != 0x0) {
            r0 = var_3B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_388 != 0x0) {
            r0 = var_390;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_7E8;
    if (r20 != 0x0 && r0 != 0x0) {
            r0 = operator delete(r0);
    }
    if (**___stack_chk_guard != var_88) {
            __stack_chk_fail();
    }
    return r0;

.l62:
    r21 = var_590;
    r0 = r20;
    if (r21 != r20) goto loc_1023024b8;
    goto .l63;

loc_1023020dc:
    var_7A0 = var_7C8;
    var_798 = var_7C0;
    var_7C0 = 0x0;
    var_7C8 = 0x0;
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<int, std::__1::allocator<int> >::astype<double, int, 0, 0, 0>();
    nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_650);
    r20 = var_650;
    r0 = nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_650);
    r8 = var_650 + var_784 * 0x8;
    if (r20 == r8) goto loc_1023021d4;
    goto loc_102302148;

loc_102302068:
    r10 = r8 - r20 - 0x4;
    r9 = r20;
    if (r10 < 0x3c) goto .l88;
    goto loc_10230207c;

loc_102301f3c:
    *(int128_t *)(var_828 + 0x4) = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
    var_828[0x3] = 0x0;
    var_828[0x20] = 0x0;
    r20 = 0x1;
    goto loc_102302010;

.l56:
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<bool, std::__1::allocator<bool> >::astype<int, bool, 0, 0, 0>();
    r0 = nc::NdArray<int, std::__1::allocator<int> > nc::diff<int>(&var_370, 0x0);
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    nc::NdArray<int, std::__1::allocator<int> >::nonzero();
    if (var_364 == 0x0 || var_33C == 0x0) goto loc_102301f78;
    goto .l52;

.l13:
    r0 = nc::NdArray<int, std::__1::allocator<int> > nc::diff<int>(&var_580, 0x0);
    nc::NdArray<int, std::__1::allocator<int> >::nonzero();
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::astype<int, unsigned int, 0, 0, 0>();
    nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_628);
    r20 = var_628;
    r0 = nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_628);
    r8 = var_628 + var_75C * 0x4;
    if (r20 == r8) goto loc_102301e74;
    goto loc_102301e00;

loc_10230166c:
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::operator[]<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >, 0>(r21 + r20 * 0x1b8 + 0x138);
    r0 = nc::NdArray<bool, std::__1::allocator<bool> > nc::operator>=<unsigned int>(&var_370, 0x1);
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    nc::NdArrayConstIterator<bool, bool const*, long>::NdArrayConstIterator(&var_370);
    r20 = var_370;
    r0 = nc::NdArrayConstIterator<bool, bool const*, long>::NdArrayConstIterator(&var_370);
    if (r20 == var_370 + var_61C) goto .l85;
    goto loc_1023016dc;

.l17:
    *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
    r10 = r10 + 0x4;
    if (r10 != r9) {
            continue;
    }
    break;

loc_1023015c0:
    r11 = (r11 >> 0x2) + 0x1;
    r12 = r11 & 0x7ffffffffffffff0;
    r10 = r22 + r12 * 0x4;
    r13 = r22 + 0x20;
    v0 = 0x1;
    r14 = r12;
    goto loc_1023015dc;

.l89:
    d0 = *r8;
    r8 = r8 + 0x8;
    *r9 = d0;
    r9 = r9 + 0x8;
    if (r8 != r20) {
            continue;
    }
    break;

.l70:
    r8 = r21;
    r9 = r0;
    do {
            d0 = *r8;
            r8 = r8 + 0x8;
            *r9 = d0;
            r9 = r9 + 0x8;
    } while (r8 != r20);
    goto .l67;

.l68:
    r10 = (r8 >> 0x3) + 0x1;
    r11 = r10 & 0x3ffffffffffffff8;
    r8 = r21 + (r11 << 0x3);
    r9 = r0 + (r11 << 0x3);
    r12 = r21 + 0x20;
    r13 = r0 + 0x20;
    r14 = r11;
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
            r14 = r14 - 0x8;
    } while (r14 != 0x0);
    if (r10 != r11) goto .l50;
    goto .l67;

loc_102302520:
    operator delete(r8);
    goto loc_10230252c;

.l111:
    r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
    if (r0 != r20) {
            continue;
    }
    break;

.l130:
    *(0x0 + (r23 + ((r21 & r11 / 0x80000000) + r11) * ((r21 & r11 / 0x80000000) + r11)) * 0x8) = *(r10 + (r13 + (r21 & r11 / 0x80000000) + r11) * 0x8);
    r11 = r11 + 0x1;
    if (r21 != r11) {
            continue;
    }
    break;

.l117:
    r11 = 0x0;
    r13 = r21 * ((r23 & r9 / 0x80000000) + r9);
    goto .l118;

loc_1023024b8:
    r22 = r21 - 0x28;
    if (r21[0xfffffffffffffff8] != 0x0) {
            r0 = r21[0xfffffffffffffffe];
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r21[0xfffffffffffffffe] = 0x0;
    r21[0xfffffffffffffff8] = 0x0;
    *(r21 + 0xffffffffffffffe4) = 0x0;
    *(r21 + 0xffffffffffffffdc) = 0x0;
    r21 = r22;
    if (r22 != r20) {
            continue;
    }
    break;

.l63:
    operator delete(r0);
    goto .l42;

loc_1023021d4:
    *(r28 + 0xb4) = var_78C;
    *(r28 + 0xbc) = var_784;
    var_358 = var_778;
    var_350 = var_770;
    var_770 = 0x0;
    var_778 = 0x0;
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::NdArray<int, std::__1::allocator<int> >::astype<unsigned int, int, 0, 0, 0>();
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<int, std::__1::allocator<int> >::operator[]<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >, 0>(&var_580);
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<int, std::__1::allocator<int> >::astype<double, int, 0, 0, 0>();
    var_6C8 = &var_370;
    nc::NdArray<double, std::__1::allocator<double> > nc::row_stack<double>(&var_6C8);
    r20 = &var_628 | 0x4;
    r21 = var_620;
    r23 = var_624;
    r8 = r23 * r21;
    var_1A0 = 0x0;
    var_198 = 0x0;
    if (r8 == 0x0) goto loc_10230229c;
    goto loc_10230227c;

loc_102302148:
    r10 = r8 - r20 - 0x8;
    r9 = r20;
    if (r10 < 0x38) goto .l77;
    goto loc_10230215c;

.l88:
    do {
            *(int32_t *)r9 = *(int32_t *)r9 + r14;
            r9 = r9 + 0x4;
    } while (r9 != r8);
    goto loc_1023020dc;

loc_10230207c:
    r10 = (r10 >> 0x2) + 0x1;
    r11 = r10 & 0x7ffffffffffffff0;
    r9 = r20 + r11 * 0x4;
    asm { dup        v0.4s, w14 };
    r12 = r20 + 0x20;
    r13 = r11;
    goto loc_102302098;

loc_102301f78:
    *(int128_t *)(var_828 + 0x4) = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
    var_828[0x3] = 0x0;
    var_828[0x20] = 0x0;
    r20 = 0x1;
    goto loc_102301fc4;

.l52:
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::NdArray(&decomp_var_6a0);
    nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_1B8);
    r20 = var_1B8;
    r23 = var_694;
    r0 = nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_1B8);
    r8 = &decomp_var_6a0 + 0x18;
    r9 = var_1B8 + r23 * 0x4;
    if (r20 != r9) {
            r11 = r9 - r20 - 0x4;
            r10 = r20;
            if (r11 >= 0x3c) {
                    r11 = (r11 >> 0x2) + 0x1;
                    r12 = r11 & 0x7ffffffffffffff0;
                    r10 = r20 + r12 * 0x4;
                    r13 = r20 + 0x20;
                    v0 = 0x1;
                    r14 = r12;
                    do {
                            q1 = r13[0xfffffffffffffffc];
                            q2 = r13[0xfffffffffffffffe];
                            q3 = *r13;
                            q4 = r13[0x2];
                            v1 = v1 + v0;
                            v2 = v2 + v0;
                            v3 = v3 + v0;
                            v4 = v4 + v0;
                            r13[0xfffffffffffffffc] = q1;
                            r13[0xfffffffffffffffe] = q2;
                            *r13 = q3;
                            r13[0x2] = q4;
                            r13 = r13 + 0x40;
                            r14 = r14 - 0x10;
                    } while (r14 != 0x0);
                    if (r11 != r12) {
                            *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
                            r10 = r10 + 0x4;
                            if (r10 != r9) {
                                    *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
                                    r10 = r10 + 0x4;
                                    if (r10 != r9) {
                                            continue;
                                    }
                                    break;
                            }
                    }
            }
            else {
                    *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
                    r10 = r10 + 0x4;
                    if (r10 != r9) {
                            continue;
                    }
                    break;
            }
    }
    *(r25 + 0xf4) = *(r25 + 0xcc);
    *(r25 + 0xfc) = *(r25 + 0xd4);
    var_660 = var_688;
    var_658 = var_680;
    *(r25 + 0xd4) = 0x0;
    *(r25 + 0xcc) = 0x0;
    r8[0x8] = 0x0;
    *r8 = 0x0;
    r8 = var_610;
    if (*(int8_t *)r8 != 0x0) {
            q0 = var_800;
            *(int128_t *)(r21 + 0x4) = q0;
            r0 = operator new(0x4);
            var_1A0 = r0;
            var_198 = 0x1;
            *(int32_t *)r0 = 0x0;
            r23 = &var_1B8 + 0x28;
            nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::NdArray(r23);
            var_6F0 = &var_1B8;
            r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::column_stack<unsigned int>(&var_6F0);
            if (var_658 != 0x0) {
                    r0 = var_660;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            *(r25 + 0xf4) = *(r25 + 0xa4);
            *(r25 + 0xfc) = *(r25 + 0xac);
            var_660 = var_6B0;
            var_658 = var_6A8;
            *(r25 + 0xac) = 0x0;
            *(r25 + 0xa4) = 0x0;
            var_6B0 = 0x0;
            var_6A8 = 0x0;
            if (var_170 != 0x0) {
                    r0 = var_178;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            var_178 = 0x0;
            var_170 = 0x0;
            *(r21 + 0x34) = 0x0;
            *(r21 + 0x2c) = 0x0;
            if (var_198 != 0x0) {
                    r0 = var_1A0;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            r8 = var_610;
    }
    if (*(int8_t *)(r8 + (var_61C - 0x1 << r64)) != 0x0) {
            r20 = &var_1B8;
            r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::NdArray(&var_1B8);
            q0 = var_800;
            *(int128_t *)(r21 + 0x2c) = q0;
            r0 = operator new(0x4);
            var_178 = r0;
            var_170 = 0x1;
            *(int32_t *)r0 = var_61C;
            var_6F0 = &var_1B8;
            r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::column_stack<unsigned int>(&var_6F0);
            if (var_658 != 0x0) {
                    r0 = var_660;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            r20 = r20 + 0x2c;
            *(r25 + 0xf4) = *(r25 + 0xa4);
            *(r25 + 0xfc) = *(r25 + 0xac);
            var_660 = var_6B0;
            var_658 = var_6A8;
            *(r25 + 0xac) = 0x0;
            *(r25 + 0xa4) = 0x0;
            var_6B0 = 0x0;
            var_6A8 = 0x0;
            if (var_170 != 0x0) {
                    r0 = var_178;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            var_178 = 0x0;
            var_170 = 0x0;
            *r20 = 0x0;
            r20[0x1] = 0x0;
            if (var_198 != 0x0) {
                    r0 = var_1A0;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
    }
    nc::NdArrayConstIterator<unsigned int, unsigned int const*, long>::NdArrayConstIterator(&var_1B8);
    r20 = var_1B8;
    r0 = nc::NdArrayConstIterator<unsigned int, unsigned int const*, long>::NdArrayConstIterator(&var_1B8);
    if (r20 == var_1B8 + var_66C * 0x4) goto loc_102301fac;
    goto .l54;

loc_102301e74:
    r20 = var_764;
    d8 = *(r25 + 0xc);
    r21 = var_750;
    r22 = var_748;
    var_748 = 0x0;
    var_750 = 0x0;
    r8 = var_5E0;
    if (r8 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
                    r8 = var_748;
                    *(r26 + 0x54) = r20;
                    *(r26 + 0x5c) = d8;
                    var_5E8 = r21;
                    var_5E0 = r22;
                    if (r8 != 0x0) {
                            r0 = var_750;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
            }
            else {
                    *(r26 + 0x54) = r20;
                    *(r26 + 0x5c) = d8;
                    var_5E8 = r21;
                    var_5E0 = r22;
                    if (0x0 != 0x0) {
                            r0 = var_750;
                            if (r0 != 0x0) {
                                    operator delete(r0);
                            }
                    }
            }
    }
    else {
            *(r26 + 0x54) = r20;
            *(r26 + 0x5c) = d8;
            var_5E8 = r21;
            var_5E0 = r22;
            if (r8 != 0x0) {
                    r0 = var_750;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
    }
    *(r25 + 0xc) = 0x0;
    if (var_328 != 0x0) {
            r0 = var_330;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_330 = 0x0;
    var_328 = 0x0;
    *(r28 + 0xe4) = 0x0;
    *(r28 + 0xdc) = 0x0;
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xbc) = 0x0;
    *(r28 + 0xb4) = 0x0;
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    nc::NdArray<int, std::__1::allocator<int> >::NdArray(&decomp_var_7e0);
    nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_650);
    r20 = var_650;
    r0 = nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_650);
    r8 = var_650 + var_7D4 * 0x4;
    r14 = var_834;
    if (r20 != r8) {
            r10 = r8 - r20 - 0x4;
            r9 = r20;
            if (r10 >= 0x3c) {
                    r10 = (r10 >> 0x2) + 0x1;
                    r11 = r10 & 0x7ffffffffffffff0;
                    r9 = r20 + r11 * 0x4;
                    asm { dup        v0.4s, w14 };
                    r12 = r20 + 0x20;
                    r13 = r11;
                    do {
                            q1 = r12[0xfffffffffffffffc];
                            q2 = r12[0xfffffffffffffffe];
                            q3 = *r12;
                            q4 = r12[0x2];
                            v1 = v1 + v0;
                            v2 = v2 + v0;
                            v3 = v3 + v0;
                            v4 = v4 + v0;
                            r12[0xfffffffffffffffc] = q1;
                            r12[0xfffffffffffffffe] = q2;
                            *r12 = q3;
                            r12[0x2] = q4;
                            r12 = r12 + 0x40;
                            r13 = r13 - 0x10;
                    } while (r13 != 0x0);
                    if (r10 != r11) {
                            *(int32_t *)r9 = *(int32_t *)r9 + r14;
                            r9 = r9 + 0x4;
                            if (r9 != r8) {
                                    *(int32_t *)r9 = *(int32_t *)r9 + r14;
                                    r9 = r9 + 0x4;
                                    if (r9 != r8) {
                                            continue;
                                    }
                                    break;
                            }
                    }
            }
            else {
                    *(int32_t *)r9 = *(int32_t *)r9 + r14;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    var_7A0 = var_7C8;
    var_798 = var_7C0;
    var_7C0 = 0x0;
    var_7C8 = 0x0;
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<int, std::__1::allocator<int> >::astype<double, int, 0, 0, 0>();
    nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_650);
    r20 = var_650;
    r0 = nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_650);
    r8 = var_650 + var_784 * 0x8;
    if (r20 != r8) {
            r10 = r8 - r20 - 0x8;
            r9 = r20;
            if (r10 >= 0x38) {
                    r10 = (r10 >> 0x3) + 0x1;
                    r11 = r10 & 0x3ffffffffffffff8;
                    r9 = r20 + r11 * 0x8;
                    asm { dup        v0.2d, v0.d[0] };
                    v1 = 0x3ff0000000000000;
                    v0 = 0x3ff0000000000000 / v0;
                    r12 = r20 + 0x20;
                    r13 = r11;
                    do {
                            q1 = r12[0xfffffffffffffffc];
                            q2 = r12[0xfffffffffffffffe];
                            q3 = *r12;
                            q4 = r12[0x2];
                            v1 = v1 * v0;
                            v2 = v2 * v0;
                            v3 = v3 * v0;
                            v4 = v4 * v0;
                            r12[0xfffffffffffffffc] = q1;
                            r12[0xfffffffffffffffe] = q2;
                            *r12 = q3;
                            r12[0x2] = q4;
                            r12 = r12 + 0x40;
                            r13 = r13 - 0x8;
                    } while (r13 != 0x0);
                    if (r10 != r11) {
                            d0 = 0x3ff0000000000000 / d1;
                            do {
                                    *r9 = *r9 * d0;
                                    r9 = r9 + 0x8;
                            } while (r9 != r8);
                    }
            }
            else {
                    d0 = 0x3ff0000000000000 / d1;
                    do {
                            *r9 = *r9 * d0;
                            r9 = r9 + 0x8;
                    } while (r9 != r8);
            }
    }
    *(r28 + 0xb4) = var_78C;
    *(r28 + 0xbc) = var_784;
    var_358 = var_778;
    var_350 = var_770;
    var_770 = 0x0;
    var_778 = 0x0;
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::NdArray<int, std::__1::allocator<int> >::astype<unsigned int, int, 0, 0, 0>();
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<int, std::__1::allocator<int> >::operator[]<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >, 0>(&var_580);
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<int, std::__1::allocator<int> >::astype<double, int, 0, 0, 0>();
    var_6C8 = &var_370;
    nc::NdArray<double, std::__1::allocator<double> > nc::row_stack<double>(&var_6C8);
    r20 = &var_628 | 0x4;
    r21 = var_620;
    r23 = var_624;
    r8 = r23 * r21;
    var_1A0 = 0x0;
    var_198 = 0x0;
    if (r8 == 0x0) goto .l12;
    goto .l14;

loc_102301e00:
    r10 = r8 - r20 - 0x4;
    r9 = r20;
    if (r10 < 0x3c) goto .l79;
    goto loc_102301e14;

.l85:
    *(int128_t *)(var_828 + 0x4) = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
    var_828[0x3] = 0x0;
    var_828[0x20] = 0x0;
    r20 = 0x1;
    goto .l41;

loc_1023016dc:
    r21 = &var_1B8;
    r9 = r20 + 0x1;
    do {
            r10 = r9[0xffffffffffffffff];
            asm { ccmp       x9, x8, #0x4, eq };
            r9 = r9 + 0x1;
    } while (asm { ccmp       x9, x8, #0x4, eq });
    if (r10 == 0x0) goto .l40;
    goto loc_1023016fc;

loc_1023015dc:
    q1 = r13[0xfffffffffffffffc];
    q2 = r13[0xfffffffffffffffe];
    q3 = *r13;
    q4 = r13[0x2];
    v1 = v1 + v0;
    v2 = v2 + v0;
    v3 = v3 + v0;
    v4 = v4 + v0;
    r13[0xfffffffffffffffc] = q1;
    r13[0xfffffffffffffffe] = q2;
    *r13 = q3;
    r13[0x2] = q4;
    r13 = r13 + 0x40;
    r14 = r14 - 0x10;
    if (r14 != 0x0) {
            continue;
    }
    break;

.l50:
    goto loc_1023014dc;
    r8 = var_488;
    goto loc_102302520;
    r9 = r9 + 0x1;
    if (r9 != r23) {
            continue;
    }
    break;

.l118:
    *(r0 + (r23 + ((r21 & r11 / 0x80000000) + r11) * ((r21 & r11 / 0x80000000) + r11)) * 0x8) = *(r10 + (r13 + (r21 & r11 / 0x80000000) + r11) * 0x8);
    r11 = r11 + 0x1;
    if (r21 != r11) {
            continue;
    }
    break;
    r0 = var_598;
    goto .l63;

loc_10230229c:
    r8 = &var_1B8;
    if (r23 != 0x0 && r21 != 0x0) {
            r9 = 0x0;
            r10 = var_610;
            do {
                    r11 = 0x0;
                    r13 = r21 * ((r23 & r9 / 0x80000000) + r9);
                    do {
                            *(0x0 + (r23 + ((r21 & r11 / 0x80000000) + r11) * ((r21 & r11 / 0x80000000) + r11)) * 0x8) = *(r10 + (r13 + (r21 & r11 / 0x80000000) + r11) * 0x8);
                            r11 = r11 + 0x1;
                    } while (r21 != r11);
                    r9 = r9 + 0x1;
            } while (r9 != r23);
    }
    goto loc_1023022f8;

loc_10230227c:
    r0 = operator new(r8 << 0x3);
    var_1A0 = r0;
    var_198 = 0x1;
    r8 = &var_1B8;
    if (r23 != 0x0) goto .l75;
    goto loc_1023022f8;

.l77:
    d0 = 0x3ff0000000000000 / d1;
    goto .l112;

loc_10230215c:
    r10 = (r10 >> 0x3) + 0x1;
    r11 = r10 & 0x3ffffffffffffff8;
    r9 = r20 + r11 * 0x8;
    asm { dup        v0.2d, v0.d[0] };
    v1 = 0x3ff0000000000000;
    v0 = 0x3ff0000000000000 / v0;
    r12 = r20 + 0x20;
    r13 = r11;
    goto .l108;

loc_102302098:
    q1 = r12[0xfffffffffffffffc];
    q2 = r12[0xfffffffffffffffe];
    q3 = *r12;
    q4 = r12[0x2];
    v1 = v1 + v0;
    v2 = v2 + v0;
    v3 = v3 + v0;
    v4 = v4 + v0;
    r12[0xfffffffffffffffc] = q1;
    r12[0xfffffffffffffffe] = q2;
    *r12 = q3;
    r12[0x2] = q4;
    r12 = r12 + 0x40;
    r13 = r13 - 0x10;
    if (r13 != 0x0) {
            continue;
    }
    break;

loc_102301fc4:
    if (var_328 != 0x0) {
            r0 = var_330;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_330 = 0x0;
    var_328 = 0x0;
    *(r28 + 0xe4) = 0x0;
    *(r28 + 0xdc) = 0x0;
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_630 != 0x0) {
            r0 = var_638;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    goto loc_102302010;

loc_102301fac:
    if (var_658 != 0x0) {
            r0 = var_660;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = 0x0;
    goto loc_102301fc4;

.l54:
    r9 = r20 + 0x4;
    do {
            r10 = r9[0xffffffffffffffff];
            asm { ccmp       x9, x8, #0x4, eq };
            r9 = r9 + 0x4;
    } while (asm { ccmp       x9, x8, #0x4, eq });
    if (r10 == 0x0) goto loc_102301fac;
    goto .l58;

.l12:
    r8 = &var_1B8;
    if (r23 == 0x0 || r21 == 0x0) goto .l15;
    goto .l11;

.l14:
    r0 = operator new(r8 << 0x3);
    var_1A0 = r0;
    var_198 = 0x1;
    r8 = &var_1B8;
    if (r23 != 0x0 && r21 != 0x0) {
            r9 = 0x0;
            r10 = var_610;
            do {
                    r11 = 0x0;
                    r13 = r21 * ((r23 & r9 / 0x80000000) + r9);
                    do {
                            *(r0 + (r23 + ((r21 & r11 / 0x80000000) + r11) * ((r21 & r11 / 0x80000000) + r11)) * 0x8) = *(r10 + (r13 + (r21 & r11 / 0x80000000) + r11) * 0x8);
                            r11 = r11 + 0x1;
                    } while (r21 != r11);
                    r9 = r9 + 0x1;
            } while (r9 != r23);
    }
    goto .l15;

.l79:
    *(int32_t *)r9 = *(int32_t *)r9 + 0x1;
    r9 = r9 + 0x4;
    if (r9 != r8) {
            continue;
    }
    break;

loc_102301e14:
    r10 = (r10 >> 0x2) + 0x1;
    r11 = r10 & 0x7ffffffffffffff0;
    r9 = r20 + r11 * 0x4;
    r12 = r20 + 0x20;
    v0 = 0x1;
    r13 = r11;
    goto loc_102301e30;

.l41:
    if (var_608 != 0x0) {
            r0 = var_610;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (r20 != 0x0) goto .l71;
    goto .l72;

.l40:
    *(int128_t *)(var_828 + 0x4) = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
    var_828[0x3] = 0x0;
    var_828[0x20] = 0x0;
    r20 = 0x1;
    goto .l41;

loc_1023016fc:
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<bool, std::__1::allocator<bool> >::astype<int, bool, 0, 0, 0>();
    r0 = nc::NdArray<int, std::__1::allocator<int> > nc::diff<int>(&var_370, 0x0);
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    nc::NdArray<int, std::__1::allocator<int> >::nonzero();
    if (var_364 == 0x0 || var_33C == 0x0) goto .l84;
    goto loc_102301748;
    if (r11 != r12) {
            *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
            r10 = r10 + 0x4;
            if (r10 != r9) {
                    *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
                    r10 = r10 + 0x4;
                    if (r10 != r9) {
                            continue;
                    }
                    break;
            }
    }
    goto loc_102301620;

loc_1023014dc:
    d0 = *r8;
    r8 = r8 + 0x8;
    *r9 = d0;
    r9 = r9 + 0x8;
    if (r8 != r20) {
            continue;
    }
    break;
    r9 = r9 + 0x1;
    if (r9 != r23) {
            continue;
    }
    break;

loc_1023022f8:
    r23 = r8 | 0x4;
    nc::NdArray<float, std::__1::allocator<float> > nc::NdArray<double, std::__1::allocator<double> >::astype<float, double, 0, 0, 0>();
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *r23 = 0x0;
    r23[0x1] = 0x0;
    if (var_608 != 0x0) {
            r0 = var_610;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *r20 = 0x0;
    r20[0x1] = 0x0;
    if (var_328 != 0x0) {
            r0 = var_330;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xe4) = 0x0;
    *(r28 + 0xdc) = 0x0;
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xbc) = 0x0;
    *(r28 + 0xb4) = 0x0;
    if (var_630 != 0x0) {
            r0 = var_638;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r26 + 0xc) = 0x0;
    *(r26 + 0x4) = 0x0;
    if (var_658 != 0x0) {
            r0 = var_660;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_770 != 0x0) {
            r0 = var_778;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_798 != 0x0) {
            r0 = var_7A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_7C0 != 0x0) {
            r0 = var_7C8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_5E0 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_560 != 0x0) {
            r0 = var_568;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_530 != 0x0) {
            r0 = var_538;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_5B0;
    if (r0 != 0x0) {
            operator delete(r0);
    }
    r20 = var_598;
    if (r20 == 0x0) goto .l49;
    goto .l45;

.l75:
    if (r21 == 0x0) goto loc_1023022f8;
    goto .l76;

.l112:
    *r9 = *r9 * d0;
    r9 = r9 + 0x8;
    if (r9 != r8) {
            continue;
    }
    break;

.l108:
    q1 = r12[0xfffffffffffffffc];
    q2 = r12[0xfffffffffffffffe];
    q3 = *r12;
    q4 = r12[0x2];
    v1 = v1 * v0;
    v2 = v2 * v0;
    v3 = v3 * v0;
    v4 = v4 * v0;
    r12[0xfffffffffffffffc] = q1;
    r12[0xfffffffffffffffe] = q2;
    *r12 = q3;
    r12[0x2] = q4;
    r12 = r12 + 0x40;
    r13 = r13 - 0x8;
    if (r13 != 0x0) {
            continue;
    }
    break;
    if (r10 != r11) {
            *(int32_t *)r9 = *(int32_t *)r9 + r14;
            r9 = r9 + 0x4;
            if (r9 != r8) {
                    *(int32_t *)r9 = *(int32_t *)r9 + r14;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    goto loc_1023020dc;

.l58:
    r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::reshape(&decomp_var_678, 0xffffffff);
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::NdArray(&var_6C8);
    if (var_6C4 == 0x0) goto loc_102301f98;
    goto .l55;

.l15:
    r23 = r8 | 0x4;
    nc::NdArray<float, std::__1::allocator<float> > nc::NdArray<double, std::__1::allocator<double> >::astype<float, double, 0, 0, 0>();
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *r23 = 0x0;
    r23[0x1] = 0x0;
    if (var_608 != 0x0) {
            r0 = var_610;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *r20 = 0x0;
    r20[0x1] = 0x0;
    if (var_328 != 0x0) {
            r0 = var_330;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xe4) = 0x0;
    *(r28 + 0xdc) = 0x0;
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xbc) = 0x0;
    *(r28 + 0xb4) = 0x0;
    if (var_630 != 0x0) {
            r0 = var_638;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r26 + 0xc) = 0x0;
    *(r26 + 0x4) = 0x0;
    if (var_658 != 0x0) {
            r0 = var_660;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_770 != 0x0) {
            r0 = var_778;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_798 != 0x0) {
            r0 = var_7A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_7C0 != 0x0) {
            r0 = var_7C8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_5E0 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_560 != 0x0) {
            r0 = var_568;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_530 != 0x0) {
            r0 = var_538;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_5B0;
    if (r0 != 0x0) {
            operator delete(r0);
    }
    r20 = var_598;
    if (r20 != 0x0) {
            r21 = var_590;
            r0 = r20;
            if (r21 != r20) {
                    do {
                            r22 = r21 - 0x28;
                            if (r21[0xfffffffffffffff8] != 0x0) {
                                    r0 = r21[0xfffffffffffffffe];
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                            }
                            r21[0xfffffffffffffffe] = 0x0;
                            r21[0xfffffffffffffff8] = 0x0;
                            *(r21 + 0xffffffffffffffe4) = 0x0;
                            *(r21 + 0xffffffffffffffdc) = 0x0;
                            r21 = r22;
                    } while (r22 != r20);
                    r0 = var_598;
            }
            operator delete(r0);
    }
    if (var_4F8 != 0x0) {
            r0 = var_500;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_488;
    if (r20 != 0x0) {
            r0 = var_480;
            r8 = r20;
            if (r0 != r20) {
                    do {
                            r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
                    } while (r0 != r20);
                    r8 = var_488;
            }
            operator delete(r8);
    }
    if (var_450 != 0x0) {
            r0 = var_458;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_808;
    if (var_428 != 0x0) {
            r0 = var_430;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_400 != 0x0) {
            r0 = var_408;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3D8 != 0x0) {
            r0 = var_3E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3B0 != 0x0) {
            r0 = var_3B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_388 != 0x0) {
            r0 = var_390;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_7E8;
    if (r20 != 0x0 && r0 != 0x0) {
            r0 = operator delete(r0);
    }
    if (**___stack_chk_guard != var_88) {
            __stack_chk_fail();
    }
    return r0;

.l11:
    r9 = 0x0;
    r10 = var_610;
    goto .l113;

loc_102301e30:
    q1 = r12[0xfffffffffffffffc];
    q2 = r12[0xfffffffffffffffe];
    q3 = *r12;
    q4 = r12[0x2];
    v1 = v1 + v0;
    v2 = v2 + v0;
    v3 = v3 + v0;
    v4 = v4 + v0;
    r12[0xfffffffffffffffc] = q1;
    r12[0xfffffffffffffffe] = q2;
    *r12 = q3;
    r12[0x2] = q4;
    r12 = r12 + 0x40;
    r13 = r13 - 0x10;
    if (r13 != 0x0) {
            continue;
    }
    break;

.l71:
    if (var_5E0 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_560 != 0x0) {
            r0 = var_568;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_530 != 0x0) {
            r0 = var_538;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_5B0;
    if (r0 != 0x0) {
            operator delete(r0);
    }
    r20 = var_598;
    if (r20 != 0x0) {
            r21 = var_590;
            r0 = r20;
            if (r21 != r20) {
                    do {
                            r22 = r21 - 0x28;
                            if (r21[0xfffffffffffffff8] != 0x0) {
                                    r0 = r21[0xfffffffffffffffe];
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                            }
                            r21[0xfffffffffffffffe] = 0x0;
                            r21[0xfffffffffffffff8] = 0x0;
                            *(r21 + 0xffffffffffffffe4) = 0x0;
                            *(r21 + 0xffffffffffffffdc) = 0x0;
                            r21 = r22;
                    } while (r22 != r20);
                    r0 = var_598;
            }
            operator delete(r0);
    }
    if (var_4F8 != 0x0) {
            r0 = var_500;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_488;
    if (r20 == 0x0) goto .l22;
    goto .l16;

.l72:
    nc::NdArray<int, std::__1::allocator<int> >::NdArray(&decomp_var_7e0);
    nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_650);
    r20 = var_650;
    r0 = nc::NdArrayConstIterator<int, int*, long>::NdArrayConstIterator(&var_650);
    r8 = var_650 + var_7D4 * 0x4;
    r14 = var_834;
    if (r20 == r8) goto .l30;
    goto .l24;

.l84:
    *(int128_t *)(var_828 + 0x4) = *(int128_t *)("Window9showAsyncERKN4juce6StringEE3$_0" + 0xff0);
    var_828[0x3] = 0x0;
    var_828[0x20] = 0x0;
    r20 = 0x1;
    goto .l39;

loc_102301748:
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::NdArray(&decomp_var_6a0);
    nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_1B8);
    r20 = var_1B8;
    r23 = var_694;
    r0 = nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_1B8);
    r8 = &decomp_var_6a0 + 0x18;
    r9 = var_1B8 + r23 * 0x4;
    if (r20 == r9) goto loc_102301804;
    goto loc_102301790;

.l49:
    if (var_4F8 != 0x0) {
            r0 = var_500;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_488;
    if (r20 == 0x0) goto .l60;
    goto .l47;

.l45:
    r21 = var_590;
    r0 = r20;
    if (r21 != r20) goto .l110;
    goto .l46;

.l76:
    r9 = 0x0;
    r10 = var_610;
    goto .l121;
    if (r10 == r11) goto loc_1023021d4;
    goto loc_1023021b4;

loc_102301f98:
    if (var_6A8 != 0x0) {
            r0 = var_6B0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    goto loc_102301fac;

.l55:
    r21 = 0x0;
    var_830 = &var_1B8 + 0x28;
    var_848 = &var_740 | 0x4;
    var_840 = &decomp_var_718 | 0x4;
    var_850 = &var_740 + 0x18;
    r19 = &var_1B8 + 0x2c;
    goto loc_102301a9c;

.l113:
    r11 = 0x0;
    r13 = r21 * ((r23 & r9 / 0x80000000) + r9);
    goto .l115;
    if (r10 != r11) {
            *(int32_t *)r9 = *(int32_t *)r9 + 0x1;
            r9 = r9 + 0x4;
            if (r9 != r8) {
                    *(int32_t *)r9 = *(int32_t *)r9 + 0x1;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    goto loc_102301e74;

.l22:
    if (var_450 != 0x0) {
            r0 = var_458;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_808;
    if (var_428 != 0x0) {
            r0 = var_430;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_400 != 0x0) {
            r0 = var_408;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3D8 != 0x0) {
            r0 = var_3E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3B0 != 0x0) {
            r0 = var_3B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_388 != 0x0) {
            r0 = var_390;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_7E8;
    if (r20 != 0x0 && r0 != 0x0) {
            r0 = operator delete(r0);
    }
    if (**___stack_chk_guard != var_88) {
            __stack_chk_fail();
    }
    return r0;

.l16:
    r0 = var_480;
    r8 = r20;
    if (r0 == r20) goto .l20;
    goto .l106;

.l30:
    var_7A0 = var_7C8;
    var_798 = var_7C0;
    var_7C0 = 0x0;
    var_7C8 = 0x0;
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<int, std::__1::allocator<int> >::astype<double, int, 0, 0, 0>();
    nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_650);
    r20 = var_650;
    r0 = nc::NdArrayConstIterator<double, double*, long>::NdArrayConstIterator(&var_650);
    r8 = var_650 + var_784 * 0x8;
    if (r20 == r8) goto .l34;
    goto .l31;

.l24:
    r10 = r8 - r20 - 0x4;
    r9 = r20;
    if (r10 < 0x3c) goto .l28;
    goto .l25;

.l39:
    if (var_328 != 0x0) {
            r0 = var_330;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_330 = 0x0;
    var_328 = 0x0;
    *(r28 + 0xe4) = 0x0;
    *(r28 + 0xdc) = 0x0;
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_630 != 0x0) {
            r0 = var_638;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    goto .l41;

loc_102301804:
    *(r25 + 0xf4) = *(r25 + 0xcc);
    *(r25 + 0xfc) = *(r25 + 0xd4);
    var_660 = var_688;
    var_658 = var_680;
    *(r25 + 0xd4) = 0x0;
    *(r25 + 0xcc) = 0x0;
    r8[0x8] = 0x0;
    *r8 = 0x0;
    r8 = var_610;
    if (*(int8_t *)r8 != 0x0) {
            q0 = var_800;
            *(int128_t *)(r21 + 0x4) = q0;
            r0 = operator new(0x4);
            var_1A0 = r0;
            var_198 = 0x1;
            *(int32_t *)r0 = 0x0;
            r23 = &var_1B8 + 0x28;
            nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::NdArray(r23);
            var_6F0 = &var_1B8;
            r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::column_stack<unsigned int>(&var_6F0);
            if (var_658 != 0x0) {
                    r0 = var_660;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            *(r25 + 0xf4) = *(r25 + 0xa4);
            *(r25 + 0xfc) = *(r25 + 0xac);
            var_660 = var_6B0;
            var_658 = var_6A8;
            *(r25 + 0xac) = 0x0;
            *(r25 + 0xa4) = 0x0;
            var_6B0 = 0x0;
            var_6A8 = 0x0;
            if (var_170 != 0x0) {
                    r0 = var_178;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            var_178 = 0x0;
            var_170 = 0x0;
            *(r21 + 0x34) = 0x0;
            *(r21 + 0x2c) = 0x0;
            if (var_198 != 0x0) {
                    r0 = var_1A0;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            r8 = var_610;
    }
    if (*(int8_t *)(r8 + (var_61C - 0x1 << r64)) != 0x0) {
            r20 = &var_1B8;
            r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::NdArray(&var_1B8);
            q0 = var_800;
            *(int128_t *)(r21 + 0x2c) = q0;
            r0 = operator new(0x4);
            var_178 = r0;
            var_170 = 0x1;
            *(int32_t *)r0 = var_61C;
            var_6F0 = &var_1B8;
            r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::column_stack<unsigned int>(&var_6F0);
            if (var_658 != 0x0) {
                    r0 = var_660;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            r20 = r20 + 0x2c;
            *(r25 + 0xf4) = *(r25 + 0xa4);
            *(r25 + 0xfc) = *(r25 + 0xac);
            var_660 = var_6B0;
            var_658 = var_6A8;
            *(r25 + 0xac) = 0x0;
            *(r25 + 0xa4) = 0x0;
            var_6B0 = 0x0;
            var_6A8 = 0x0;
            if (var_170 != 0x0) {
                    r0 = var_178;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
            var_178 = 0x0;
            var_170 = 0x0;
            *r20 = 0x0;
            r20[0x1] = 0x0;
            if (var_198 != 0x0) {
                    r0 = var_1A0;
                    if (r0 != 0x0) {
                            operator delete(r0);
                    }
            }
    }
    nc::NdArrayConstIterator<unsigned int, unsigned int const*, long>::NdArrayConstIterator(&var_1B8);
    r20 = var_1B8;
    r0 = nc::NdArrayConstIterator<unsigned int, unsigned int const*, long>::NdArrayConstIterator(&var_1B8);
    if (r20 == var_1B8 + var_66C * 0x4) goto .l37;
    goto loc_102301a18;

loc_102301790:
    r11 = r9 - r20 - 0x4;
    r10 = r20;
    if (r11 < 0x3c) goto .l19;
    goto loc_1023017a4;

.l60:
    if (var_450 != 0x0) {
            r0 = var_458;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_808;
    if (var_428 != 0x0) {
            r0 = var_430;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_400 != 0x0) {
            r0 = var_408;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3D8 != 0x0) {
            r0 = var_3E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3B0 != 0x0) {
            r0 = var_3B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_388 != 0x0) {
            r0 = var_390;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_7E8;
    if (r20 != 0x0 && r0 != 0x0) {
            r0 = operator delete(r0);
    }
    if (**___stack_chk_guard != var_88) {
            __stack_chk_fail();
    }
    return r0;

.l47:
    r0 = var_480;
    r8 = r20;
    if (r0 == r20) goto .l59;
    goto loc_10230250c;

.l110:
    r22 = r21 - 0x28;
    if (r21[0xfffffffffffffff8] != 0x0) {
            r0 = r21[0xfffffffffffffffe];
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r21[0xfffffffffffffffe] = 0x0;
    r21[0xfffffffffffffff8] = 0x0;
    *(r21 + 0xffffffffffffffe4) = 0x0;
    *(r21 + 0xffffffffffffffdc) = 0x0;
    r21 = r22;
    if (r22 != r20) {
            continue;
    }
    break;

.l46:
    operator delete(r0);
    goto .l49;

.l121:
    r11 = 0x0;
    r13 = r21 * ((r23 & r9 / 0x80000000) + r9);
    goto .l122;

loc_1023021b4:
    d0 = 0x3ff0000000000000 / d1;
    goto loc_1023021c0;

loc_102301a9c:
    r26 = *(int32_t *)(var_6B0 + var_6C0 * r21 * 0x4);
    r1 = r26;
    asm { bfi        x1, x8, #0x20, #0x20 };
    r24 = r24 & 0xffffffff00000000 | 0x1;
    r23 = r23 & 0xffffffff00000000 | 0x1;
    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator(&decomp_var_518, r1);
    r0 = nc::NdArray<float, std::__1::allocator<float> >::argmax(&var_1B8);
    nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_740);
    r20 = var_740;
    r0 = nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_740);
    r8 = var_740 + var_70C * 0x4;
    if (r20 == r8) goto loc_102301b98;
    goto loc_102301b28;

.l115:
    *(0x0 + (r23 + ((r21 & r11 / 0x80000000) + r11) * ((r21 & r11 / 0x80000000) + r11)) * 0x8) = *(r10 + (r13 + (r21 & r11 / 0x80000000) + r11) * 0x8);
    r11 = r11 + 0x1;
    if (r21 != r11) {
            continue;
    }
    break;

.l20:
    operator delete(r8);
    goto .l22;

.l106:
    r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
    if (r0 != r20) {
            continue;
    }
    break;

.l34:
    *(r28 + 0xb4) = var_78C;
    *(r28 + 0xbc) = var_784;
    var_358 = var_778;
    var_350 = var_770;
    var_770 = 0x0;
    var_778 = 0x0;
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> > nc::NdArray<int, std::__1::allocator<int> >::astype<unsigned int, int, 0, 0, 0>();
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<int, std::__1::allocator<int> >::operator[]<nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >, 0>(&var_580);
    nc::NdArray<double, std::__1::allocator<double> > nc::NdArray<int, std::__1::allocator<int> >::astype<double, int, 0, 0, 0>();
    var_6C8 = &var_370;
    nc::NdArray<double, std::__1::allocator<double> > nc::row_stack<double>(&var_6C8);
    r20 = &var_628 | 0x4;
    r21 = var_620;
    r23 = var_624;
    r8 = r23 * r21;
    var_1A0 = 0x0;
    var_198 = 0x0;
    if (r8 == 0x0) goto .l43;
    goto .l36;

.l31:
    r10 = r8 - r20 - 0x8;
    r9 = r20;
    if (r10 < 0x38) goto .l83;
    goto .l32;

.l28:
    do {
            *(int32_t *)r9 = *(int32_t *)r9 + r14;
            r9 = r9 + 0x4;
    } while (r9 != r8);
    goto .l30;

.l25:
    r10 = (r10 >> 0x2) + 0x1;
    r11 = r10 & 0x7ffffffffffffff0;
    r9 = r20 + r11 * 0x4;
    asm { dup        v0.4s, w14 };
    r12 = r20 + 0x20;
    r13 = r11;
    goto .l109;

.l37:
    if (var_658 != 0x0) {
            r0 = var_660;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = 0x0;
    goto .l39;

loc_102301a18:
    r9 = r20 + 0x4;
    do {
            r10 = r9[0xffffffffffffffff];
            asm { ccmp       x9, x8, #0x4, eq };
            r9 = r9 + 0x4;
    } while (asm { ccmp       x9, x8, #0x4, eq });
    if (r10 == 0x0) goto .l37;
    goto loc_102301a34;

.l19:
    do {
            *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
            r10 = r10 + 0x4;
    } while (r10 != r9);
    goto loc_102301804;

loc_1023017a4:
    r11 = (r11 >> 0x2) + 0x1;
    r12 = r11 & 0x7ffffffffffffff0;
    r10 = r20 + r12 * 0x4;
    r13 = r20 + 0x20;
    v0 = 0x1;
    r14 = r12;
    goto loc_1023017c0;

.l59:
    operator delete(r8);
    goto .l60;

loc_10230250c:
    r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
    if (r0 != r20) {
            continue;
    }
    break;
    r0 = var_598;
    goto .l46;

.l122:
    *(r0 + (r23 + ((r21 & r11 / 0x80000000) + r11) * ((r21 & r11 / 0x80000000) + r11)) * 0x8) = *(r10 + (r13 + (r21 & r11 / 0x80000000) + r11) * 0x8);
    r11 = r11 + 0x1;
    if (r21 != r11) {
            continue;
    }
    break;

loc_1023021c0:
    *r9 = *r9 * d0;
    r9 = r9 + 0x8;
    if (r9 != r8) {
            continue;
    }
    break;

loc_102301b98:
    r20 = *(r25 + 0x54);
    r25 = var_700;
    r27 = var_6F8;
    var_6F8 = 0x0;
    var_700 = 0x0;
    nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_740);
    r22 = var_740;
    r0 = nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_740);
    r9 = s5;
    r10 = var_740;
    r8 = r10 + zero_extend_64(r9) * 0x4;
    if (r22 == r8) goto loc_102301c68;
    goto loc_102301bf0;

loc_102301b28:
    r10 = r8 - r20 - 0x4;
    r9 = r20;
    if (r10 < 0x3c) goto .l21;
    goto loc_102301b3c;
    r9 = r9 + 0x1;
    if (r9 != r23) {
            continue;
    }
    break;
    r8 = var_488;
    goto .l20;

.l43:
    r8 = &var_1B8;
    if (r23 == 0x0 || r21 == 0x0) goto .l35;
    goto .l44;

.l36:
    r0 = operator new(r8 << 0x3);
    var_1A0 = r0;
    var_198 = 0x1;
    r8 = &var_1B8;
    if (r23 != 0x0) goto .l81;
    goto .l35;

.l83:
    d0 = 0x3ff0000000000000 / d1;
    do {
            *r9 = *r9 * d0;
            r9 = r9 + 0x8;
    } while (r9 != r8);
    goto .l34;

.l32:
    r10 = (r10 >> 0x3) + 0x1;
    r11 = r10 & 0x3ffffffffffffff8;
    r9 = r20 + r11 * 0x8;
    asm { dup        v0.2d, v0.d[0] };
    v1 = 0x3ff0000000000000;
    v0 = 0x3ff0000000000000 / v0;
    r12 = r20 + 0x20;
    r13 = r11;
    goto loc_102302184;

.l109:
    q1 = r12[0xfffffffffffffffc];
    q2 = r12[0xfffffffffffffffe];
    q3 = *r12;
    q4 = r12[0x2];
    v1 = v1 + v0;
    v2 = v2 + v0;
    v3 = v3 + v0;
    v4 = v4 + v0;
    r12[0xfffffffffffffffc] = q1;
    r12[0xfffffffffffffffe] = q2;
    *r12 = q3;
    r12[0x2] = q4;
    r12 = r12 + 0x40;
    r13 = r13 - 0x10;
    if (r13 != 0x0) {
            continue;
    }
    break;

loc_102301a34:
    r0 = nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::reshape(&decomp_var_678, 0xffffffff);
    nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::NdArray(&var_6C8);
    if (var_6C4 == 0x0) goto .l38;
    goto loc_102301a58;

loc_1023017c0:
    q1 = r13[0xfffffffffffffffc];
    q2 = r13[0xfffffffffffffffe];
    q3 = *r13;
    q4 = r13[0x2];
    v1 = v1 + v0;
    v2 = v2 + v0;
    v3 = v3 + v0;
    v4 = v4 + v0;
    r13[0xfffffffffffffffc] = q1;
    r13[0xfffffffffffffffe] = q2;
    *r13 = q3;
    r13[0x2] = q4;
    r13 = r13 + 0x40;
    r14 = r14 - 0x10;
    if (r14 != 0x0) {
            continue;
    }
    break;
    r8 = var_488;
    goto .l59;
    r9 = r9 + 0x1;
    if (r9 != r23) {
            continue;
    }
    break;

loc_102301c68:
    var_6D8 = r25;
    var_6D0 = r27;
    if (var_6F8 != 0x0) {
            r0 = var_700;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_700 = 0x0;
    var_6F8 = 0x0;
    *var_840 = 0x0;
    var_840[0x1] = 0x0;
    r26 = &var_650;
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = nc::NdArray<int, std::__1::allocator<int> >::NdArray(&var_1B8);
    r25 = &decomp_var_768;
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::astype<int, unsigned int, 0, 0, 0>();
    var_380 = &var_1B8;
    nc::NdArray<int, std::__1::allocator<int> > nc::column_stack<int>(&var_380);
    if (var_5E0 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r26 + 0x54) = *(r25 + 0x2c);
    *(r26 + 0x5c) = *(r25 + 0x34);
    var_5E8 = var_728;
    var_5E0 = var_720;
    *var_848 = 0x0;
    var_848[0x1] = 0x0;
    var_850[0x8] = 0x0;
    *var_850 = 0x0;
    if (var_170 != 0x0) {
            r0 = var_178;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_178 = 0x0;
    var_170 = 0x0;
    *r19 = 0x0;
    r19[0x1] = 0x0;
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_6D0 != 0x0) {
            r0 = var_6D8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r21 = r21 + 0x1;
    if (r21 < var_6C4) {
            continue;
    }
    break;

loc_102301bf0:
    r10 = r10 + r9 * 0x4 - r22 - 0x4;
    r9 = r22;
    if (r10 < 0x3c) goto .l23;
    goto loc_102301c08;

.l21:
    *(int32_t *)r9 = *(int32_t *)r9 >> 0x1;
    r9 = r9 + 0x4;
    if (r9 != r8) {
            continue;
    }
    break;

loc_102301b3c:
    r10 = (r10 >> 0x2) + 0x1;
    r11 = r10 & 0x7ffffffffffffff0;
    r9 = r20 + r11 * 0x4;
    r12 = r20 + 0x20;
    r13 = r11;
    goto loc_102301b54;

.l35:
    r23 = r8 | 0x4;
    nc::NdArray<float, std::__1::allocator<float> > nc::NdArray<double, std::__1::allocator<double> >::astype<float, double, 0, 0, 0>();
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *r23 = 0x0;
    r23[0x1] = 0x0;
    if (var_608 != 0x0) {
            r0 = var_610;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *r20 = 0x0;
    r20[0x1] = 0x0;
    if (var_328 != 0x0) {
            r0 = var_330;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xe4) = 0x0;
    *(r28 + 0xdc) = 0x0;
    if (var_350 != 0x0) {
            r0 = var_358;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r28 + 0xbc) = 0x0;
    *(r28 + 0xb4) = 0x0;
    if (var_630 != 0x0) {
            r0 = var_638;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r26 + 0xc) = 0x0;
    *(r26 + 0x4) = 0x0;
    if (var_658 != 0x0) {
            r0 = var_660;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_770 != 0x0) {
            r0 = var_778;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_798 != 0x0) {
            r0 = var_7A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_7C0 != 0x0) {
            r0 = var_7C8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_5E0 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_560 != 0x0) {
            r0 = var_568;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_530 != 0x0) {
            r0 = var_538;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_5B0;
    if (r0 != 0x0) {
            operator delete(r0);
    }
    r20 = var_598;
    if (r20 != 0x0) {
            r21 = var_590;
            r0 = r20;
            if (r21 != r20) {
                    do {
                            r22 = r21 - 0x28;
                            if (r21[0xfffffffffffffff8] != 0x0) {
                                    r0 = r21[0xfffffffffffffffe];
                                    if (r0 != 0x0) {
                                            operator delete(r0);
                                    }
                            }
                            r21[0xfffffffffffffffe] = 0x0;
                            r21[0xfffffffffffffff8] = 0x0;
                            *(r21 + 0xffffffffffffffe4) = 0x0;
                            *(r21 + 0xffffffffffffffdc) = 0x0;
                            r21 = r22;
                    } while (r22 != r20);
                    r0 = var_598;
            }
            operator delete(r0);
    }
    if (var_4F8 != 0x0) {
            r0 = var_500;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_488;
    if (r20 != 0x0) {
            r0 = var_480;
            r8 = r20;
            if (r0 != r20) {
                    do {
                            r0 = madmom::HiddenMarkovModel<madmom::BarTransitionModel, madmom::RNNDownBeatTrackingObservationModel>::~HiddenMarkovModel();
                    } while (r0 != r20);
                    r8 = var_488;
            }
            operator delete(r8);
    }
    if (var_450 != 0x0) {
            r0 = var_458;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r20 = var_808;
    if (var_428 != 0x0) {
            r0 = var_430;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_400 != 0x0) {
            r0 = var_408;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3D8 != 0x0) {
            r0 = var_3E0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_3B0 != 0x0) {
            r0 = var_3B8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_388 != 0x0) {
            r0 = var_390;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = var_7E8;
    if (r20 != 0x0 && r0 != 0x0) {
            r0 = operator delete(r0);
    }
    if (**___stack_chk_guard != var_88) {
            __stack_chk_fail();
    }
    return r0;

.l44:
    r9 = 0x0;
    r10 = var_610;
    goto loc_1023022b4;

.l81:
    if (r21 == 0x0) goto .l35;
    goto .l82;

loc_102302184:
    q1 = r12[0xfffffffffffffffc];
    q2 = r12[0xfffffffffffffffe];
    q3 = *r12;
    q4 = r12[0x2];
    v1 = v1 * v0;
    v2 = v2 * v0;
    v3 = v3 * v0;
    v4 = v4 * v0;
    r12[0xfffffffffffffffc] = q1;
    r12[0xfffffffffffffffe] = q2;
    *r12 = q3;
    r12[0x2] = q4;
    r12 = r12 + 0x40;
    r13 = r13 - 0x8;
    if (r13 != 0x0) {
            continue;
    }
    break;
    if (r10 != r11) {
            *(int32_t *)r9 = *(int32_t *)r9 + r14;
            r9 = r9 + 0x4;
            if (r9 != r8) {
                    *(int32_t *)r9 = *(int32_t *)r9 + r14;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    goto .l30;

.l38:
    if (var_6A8 != 0x0) {
            r0 = var_6B0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    goto .l37;

loc_102301a58:
    r21 = 0x0;
    var_830 = &var_1B8 + 0x28;
    var_848 = &var_740 | 0x4;
    var_840 = &decomp_var_718 | 0x4;
    var_850 = &var_740 + 0x18;
    r19 = &var_1B8 + 0x2c;
    goto .l92;
    if (r11 != r12) {
            *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
            r10 = r10 + 0x4;
            if (r10 != r9) {
                    *(int32_t *)r10 = *(int32_t *)r10 + 0x1;
                    r10 = r10 + 0x4;
                    if (r10 != r9) {
                            continue;
                    }
                    break;
            }
    }
    goto loc_102301804;

.l23:
    *(int32_t *)r9 = *(int32_t *)r9 + r26;
    r9 = r9 + 0x4;
    if (r9 != r8) {
            continue;
    }
    break;

loc_102301c08:
    r10 = (r10 >> 0x2) + 0x1;
    r11 = r10 & 0x7ffffffffffffff0;
    r9 = r22 + r11 * 0x4;
    asm { dup        v0.4s, w26 };
    r12 = r22 + 0x20;
    r13 = r11;
    goto loc_102301c24;

loc_102301b54:
    q0 = r12[0xfffffffffffffffc];
    q1 = r12[0xfffffffffffffffe];
    q2 = *r12;
    q3 = r12[0x2];
    asm { ushr       v0.4s, v0.4s, #0x1 };
    asm { ushr       v1.4s, v1.4s, #0x1 };
    asm { ushr       v2.4s, v2.4s, #0x1 };
    asm { ushr       v3.4s, v3.4s, #0x1 };
    r12[0xfffffffffffffffc] = q0;
    r12[0xfffffffffffffffe] = q1;
    *r12 = q2;
    r12[0x2] = q3;
    r12 = r12 + 0x40;
    r13 = r13 - 0x10;
    if (r13 != 0x0) {
            continue;
    }
    break;

loc_1023022b4:
    r11 = 0x0;
    r13 = r21 * ((r23 & r9 / 0x80000000) + r9);
    goto loc_1023022c4;

.l82:
    r9 = 0x0;
    r10 = var_610;
    goto .l124;
    if (r10 == r11) goto .l34;
    goto .l29;

.l92:
    r26 = *(int32_t *)(var_6B0 + var_6C0 * r21 * 0x4);
    r1 = r26;
    asm { bfi        x1, x8, #0x20, #0x20 };
    r24 = r24 & 0xffffffff00000000 | 0x1;
    r23 = r23 & 0xffffffff00000000 | 0x1;
    r0 = nc::NdArray<float, std::__1::allocator<float> >::operator(&decomp_var_518, r1);
    r0 = nc::NdArray<float, std::__1::allocator<float> >::argmax(&var_1B8);
    nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_740);
    r20 = var_740;
    r0 = nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_740);
    r8 = var_740 + var_70C * 0x4;
    if (r20 == r8) goto .l99;
    goto .l91;

loc_102301c24:
    q1 = r12[0xfffffffffffffffc];
    q2 = r12[0xfffffffffffffffe];
    q3 = *r12;
    q4 = r12[0x2];
    v1 = v1 + v0;
    v2 = v2 + v0;
    v3 = v3 + v0;
    v4 = v4 + v0;
    r12[0xfffffffffffffffc] = q1;
    r12[0xfffffffffffffffe] = q2;
    *r12 = q3;
    r12[0x2] = q4;
    r12 = r12 + 0x40;
    r13 = r13 - 0x10;
    if (r13 != 0x0) {
            continue;
    }
    break;
    if (r10 != r11) {
            *(int32_t *)r9 = *(int32_t *)r9 >> 0x1;
            r9 = r9 + 0x4;
            if (r9 != r8) {
                    *(int32_t *)r9 = *(int32_t *)r9 >> 0x1;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    goto loc_102301b98;

loc_1023022c4:
    *(0x0 + (r23 + ((r21 & r11 / 0x80000000) + r11) * ((r21 & r11 / 0x80000000) + r11)) * 0x8) = *(r10 + (r13 + (r21 & r11 / 0x80000000) + r11) * 0x8);
    r11 = r11 + 0x1;
    if (r21 != r11) {
            continue;
    }
    break;

.l124:
    r11 = 0x0;
    r13 = r21 * ((r23 & r9 / 0x80000000) + r9);
    goto .l126;

.l29:
    d0 = 0x3ff0000000000000 / d1;
    goto .l123;

.l99:
    r20 = *(r25 + 0x54);
    r25 = var_700;
    r27 = var_6F8;
    var_6F8 = 0x0;
    var_700 = 0x0;
    nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_740);
    r22 = var_740;
    r0 = nc::NdArrayConstIterator<unsigned int, unsigned int*, long>::NdArrayConstIterator(&var_740);
    r9 = s5;
    r10 = var_740;
    r8 = r10 + zero_extend_64(r9) * 0x4;
    if (r22 == r8) goto .l95;
    goto .l90;

.l91:
    r10 = r8 - r20 - 0x4;
    r9 = r20;
    if (r10 < 0x3c) goto .l103;
    goto .l93;
    if (r10 != r11) {
            *(int32_t *)r9 = *(int32_t *)r9 + r26;
            r9 = r9 + 0x4;
            if (r9 != r8) {
                    *(int32_t *)r9 = *(int32_t *)r9 + r26;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    goto loc_102301c68;
    r9 = r9 + 0x1;
    if (r9 != r23) {
            continue;
    }
    break;

.l126:
    *(r0 + (r23 + ((r21 & r11 / 0x80000000) + r11) * ((r21 & r11 / 0x80000000) + r11)) * 0x8) = *(r10 + (r13 + (r21 & r11 / 0x80000000) + r11) * 0x8);
    r11 = r11 + 0x1;
    if (r21 != r11) {
            continue;
    }
    break;

.l123:
    *r9 = *r9 * d0;
    r9 = r9 + 0x8;
    if (r9 != r8) {
            continue;
    }
    break;

.l95:
    var_6D8 = r25;
    var_6D0 = r27;
    if (var_6F8 != 0x0) {
            r0 = var_700;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_700 = 0x0;
    var_6F8 = 0x0;
    *var_840 = 0x0;
    var_840[0x1] = 0x0;
    r26 = &var_650;
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r0 = nc::NdArray<int, std::__1::allocator<int> >::NdArray(&var_1B8);
    r25 = &decomp_var_768;
    nc::NdArray<int, std::__1::allocator<int> > nc::NdArray<unsigned int, std::__1::allocator<unsigned int> >::astype<int, unsigned int, 0, 0, 0>();
    var_380 = &var_1B8;
    nc::NdArray<int, std::__1::allocator<int> > nc::column_stack<int>(&var_380);
    if (var_5E0 != 0x0) {
            r0 = var_5E8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    *(r26 + 0x54) = *(r25 + 0x2c);
    *(r26 + 0x5c) = *(r25 + 0x34);
    var_5E8 = var_728;
    var_5E0 = var_720;
    *var_848 = 0x0;
    var_848[0x1] = 0x0;
    var_850[0x8] = 0x0;
    *var_850 = 0x0;
    if (var_170 != 0x0) {
            r0 = var_178;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    var_178 = 0x0;
    var_170 = 0x0;
    *r19 = 0x0;
    r19[0x1] = 0x0;
    if (var_198 != 0x0) {
            r0 = var_1A0;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    if (var_6D0 != 0x0) {
            r0 = var_6D8;
            if (r0 != 0x0) {
                    operator delete(r0);
            }
    }
    r21 = r21 + 0x1;
    if (r21 < var_6C4) {
            continue;
    }
    break;

.l90:
    r10 = r10 + r9 * 0x4 - r22 - 0x4;
    r9 = r22;
    if (r10 < 0x3c) goto .l104;
    goto .l98;

.l103:
    *(int32_t *)r9 = *(int32_t *)r9 >> 0x1;
    r9 = r9 + 0x4;
    if (r9 != r8) {
            continue;
    }
    break;

.l93:
    r10 = (r10 >> 0x2) + 0x1;
    r11 = r10 & 0x7ffffffffffffff0;
    r9 = r20 + r11 * 0x4;
    r12 = r20 + 0x20;
    r13 = r11;
    goto .l102;
    r9 = r9 + 0x1;
    if (r9 != r23) {
            continue;
    }
    break;

.l104:
    *(int32_t *)r9 = *(int32_t *)r9 + r26;
    r9 = r9 + 0x4;
    if (r9 != r8) {
            continue;
    }
    break;

.l98:
    r10 = (r10 >> 0x2) + 0x1;
    r11 = r10 & 0x7ffffffffffffff0;
    r9 = r22 + r11 * 0x4;
    asm { dup        v0.4s, w26 };
    r12 = r22 + 0x20;
    r13 = r11;
    goto .l101;

.l102:
    q0 = r12[0xfffffffffffffffc];
    q1 = r12[0xfffffffffffffffe];
    q2 = *r12;
    q3 = r12[0x2];
    asm { ushr       v0.4s, v0.4s, #0x1 };
    asm { ushr       v1.4s, v1.4s, #0x1 };
    asm { ushr       v2.4s, v2.4s, #0x1 };
    asm { ushr       v3.4s, v3.4s, #0x1 };
    r12[0xfffffffffffffffc] = q0;
    r12[0xfffffffffffffffe] = q1;
    *r12 = q2;
    r12[0x2] = q3;
    r12 = r12 + 0x40;
    r13 = r13 - 0x10;
    if (r13 != 0x0) {
            continue;
    }
    break;

.l101:
    q1 = r12[0xfffffffffffffffc];
    q2 = r12[0xfffffffffffffffe];
    q3 = *r12;
    q4 = r12[0x2];
    v1 = v1 + v0;
    v2 = v2 + v0;
    v3 = v3 + v0;
    v4 = v4 + v0;
    r12[0xfffffffffffffffc] = q1;
    r12[0xfffffffffffffffe] = q2;
    *r12 = q3;
    r12[0x2] = q4;
    r12 = r12 + 0x40;
    r13 = r13 - 0x10;
    if (r13 != 0x0) {
            continue;
    }
    break;
    if (r10 != r11) {
            *(int32_t *)r9 = *(int32_t *)r9 >> 0x1;
            r9 = r9 + 0x4;
            if (r9 != r8) {
                    *(int32_t *)r9 = *(int32_t *)r9 >> 0x1;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    goto .l99;
    if (r10 != r11) {
            *(int32_t *)r9 = *(int32_t *)r9 + r26;
            r9 = r9 + 0x4;
            if (r9 != r8) {
                    *(int32_t *)r9 = *(int32_t *)r9 + r26;
                    r9 = r9 + 0x4;
                    if (r9 != r8) {
                            continue;
                    }
                    break;
            }
    }
    goto .l95;
