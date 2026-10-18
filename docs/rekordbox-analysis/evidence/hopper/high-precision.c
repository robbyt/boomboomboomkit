    r31 = r31 - 0x120;
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
    r19 = r0;
    juce::String::String(&decomp_var_60);
    (*(*r19 + 0x40))(r19, 0x0, &decomp_var_60, 0x85);
    juce::String::~String();
    var_70 = 0x0;
    r24 = analyzer::BALibWrapper::GetBpm();
    r0 = analyzer::BALibWrapper::GetBeatNum();
    r25 = r0;
    if (r0 > 0x0) {
            r8 = r19[0x5];
            r21 = r8[0x8];
            r23 = r8[0x5];
            r22 = analyzer::BALibWrapper::GetOffsetCalc();
            r8 = r19[0x3];
            r8 = r8[0x1c];
            if (r8 != 0x4) {
                    if (r8 == 0x2) {
                            r20 = analyzer::BALibWrapper::GetBpmHendou();
                    }
                    else {
                            r20 = 0x0;
                    }
            }
            else {
                    r20 = 0x1;
            }
            analyzer::BALibWrapper::SetBpmHendou(r19[0x13]);
            r8 = r19[0x5];
            r8[0x30] = r20;
            r0 = r8[0x2];
            r8 = r8[0x3];
            var_98 = r8;
            if (r8 != 0x0) {
                    asm { ldadd      x9, x8, [x8] };
            }
            (*(*r0 + 0x28))();
            juce::String::toStdString();
            r20 = var_98;
            if (r20 != 0x0) {
                    r8 = r20 + 0x8;
                    asm { ldaddal    x9, x8, [x8] };
                    if (r8 == 0x0) {
                            (*(*r20 + 0x10))(r20);
                            std::__1::__shared_weak_count::__release_weak();
                    }
            }
            juce::String::String();
            juce::String::String();
            r0 = madmom::analyze(&decomp_var_a8, &decomp_var_b0, &var_90, r21, r22, *(int8_t *)(r19[0x5] + 0x30), &var_70);
            r20 = r0;
            juce::String::~String();
            juce::String::~String();
            if ((r20 & 0x1) != 0x0) {
                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&var_70);
                    var_A0 = 0x0;
                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_A0);
                    r19[0x1a] = var_A0;
                    var_F8 = r19 + 0x68;
                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(&var_70);
                    r26 = r0;
                    r8 = *(int8_t *)r0;
                    var_108 = r21;
                    var_110 = r23;
                    var_100 = r25;
                    var_100 = r24;
                    switch (r8) {
                        case 0:
                            r27 = 0x0;
                            break;
                        case 1:
                            r8 = r26[0x1];
                            r8 = *r8;
                            r27 = (SAR(r8[0x1] - r8, 0x3)) * 0xcccccccccccccccd;
                            break;
                        default:
                            if (r8 == 0x2) {
                                    r8 = r26[0x1];
                                    r8 = *r8;
                                    r27 = SAR(r8[0x1] - r8, 0x4);
                            }
                            else {
                                    r27 = 0x1;
                            }
                            break;
                    }
                    var_104 = *(int32_t *)var_F8;
                    asm { sxtw       x8, w27 };
                    asm { umulh      x8, x8, x10 };
                    asm { csinv      x0, x9, xzr, eq };
                    var_F0 = operator new[](r0);
                    if (r27 >= 0x1) {
                            analyzer::AnalyzeJobManager::SetUrahaku(r19[0x4]);
                            r21 = 0x0;
                            r25 = r27 & 0xffffffff;
                            r24 = var_F0 + 0x8;
                            do {
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[](r26);
                                    r28 = r0;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r0);
                                    var_A0 = 0x0;
                                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_A0);
                                    *(int32_t *)r24 = var_A0;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r28);
                                    var_A0 = 0x0;
                                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_A0);
                                    r24[0xfffffffffffffffe] = var_A0;
                                    r0 = nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > > const& nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::operator[]<char const>(r28);
                                    var_A0 = 0x0;
                                    void nlohmann::detail::from_json<nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >, int, 0>(r0, &var_A0);
                                    r24[0xffffffffffffffff] = var_A0;
                                    r21 = r21 + 0x1;
                                    r24 = r24 + 0xc;
                            } while (r25 != r21);
                    }
                    analyzer::BALibWrapper::CalcBeatPos_Focus(r19[0x13], 0x0, var_100, var_100, var_F0, r27);
                    r19[0x1a] = analyzer::BALibWrapper::GetBpm_Focus();
                    r0 = analyzer::BALibWrapper::GetBeatNum_Focus();
                    r22 = var_108;
                    r25 = var_110;
                    r24 = r0;
                    r23 = var_F8 - 0x18;
                    if (r0 > 0x0) {
                            r20 = operator new[](r24 * 0xc);
                            r0 = operator new(0x20);
                            *r0 = 0x1052f7c20;
                            r0[0x1] = 0x0;
                            r0[0x2] = 0x0;
                            r0[0x3] = r20;
                            r21 = r19[0x10];
                            r19[0xf] = r20;
                            r19[0x10] = r0;
                            if (r21 != 0x0) {
                                    r8 = r21 + 0x8;
                                    asm { ldaddal    x9, x8, [x8] };
                                    if (r8 == 0x0) {
                                            (*(*r21 + 0x10))(r21);
                                            std::__1::__shared_weak_count::__release_weak();
                                    }
                                    r20 = r19[0xf];
                                    if (r20 != 0x0) {
                                            analyzer::BALibWrapper::GetBeatPos_Focus(r19[0x13]);
                                            r20 = analyzer::AnalyzeJobBeatDetector::getFirstBeatPos();
                                            juce::String::String(&decomp_var_d0);
                                            (*(*r19 + 0x40))(r19, r20, &decomp_var_d0, 0xd9);
                                            juce::String::~String();
                                            r9 = r19[0xf];
                                            r8 = r19[0x10];
                                            var_E0 = r9;
                                            var_D8 = r8;
                                            if (r8 != 0x0) {
                                                    asm { ldadd      x9, x8, [x8] };
                                            }
                                            analyzer::AnalyzeJobBeatDetector::convertToMicrosec(r19, &var_E0, r24, r22, r25, var_F8);
                                            r20 = var_D8;
                                            if (r20 != 0x0) {
                                                    r8 = r20 + 0x8;
                                                    asm { ldaddal    x9, x8, [x8] };
                                                    if (r8 == 0x0) {
                                                            (*(*r20 + 0x10))(r20);
                                                            std::__1::__shared_weak_count::__release_weak();
                                                    }
                                            }
                                            r0 = r19[0x2];
                                            (*(*r0 + 0x10))(r0, 0x3, r23);
                                            r20 = r19[0x10];
                                            r19[0xf] = 0x0;
                                            r19[0x10] = 0x0;
                                            if (r20 != 0x0) {
                                                    r8 = r20 + 0x8;
                                                    asm { ldaddal    x9, x8, [x8] };
                                                    if (r8 == 0x0) {
                                                            (*(*r20 + 0x10))(r20);
                                                            std::__1::__shared_weak_count::__release_weak();
                                                    }
                                            }
                                            *(r19 + 0x6c) = r22;
                                            r19[0xe] = r25;
                                            juce::String::String(&decomp_var_e8);
                                            r20 = &decomp_var_e8;
                                            r0 = (*(*r19 + 0x40))(r19, 0x0, &decomp_var_e8, 0xe8);
                                            r19 = r0;
                                            juce::String::~String();
                                            operator delete[](var_F0);
                                            if ((sign_extend_64(var_79) & 0xffffffff80000000) != 0x0) {
                                                    operator delete(var_90);
                                            }
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            r0 = r19;
                                    }
                                    else {
                                            r19[0x19] = 0x0;
                                            if (r19[0x18] != 0x0) {
                                                    free(r19[0xb]);
                                                    r19[0xb] = 0x0;
                                            }
                                            r19[0x18] = 0x0;
                                            r19[0x1d] = 0x0;
                                            r0 = r19[0x2];
                                            (*(*r0 + 0x10))(r0, 0x3, r23);
                                            juce::String::String(&decomp_var_c8);
                                            r20 = &decomp_var_c8;
                                            r0 = (*(*r19 + 0x40))(r19, 0x4, &decomp_var_c8, 0xd6);
                                            r19 = r0;
                                            juce::String::~String();
                                            operator delete[](var_F0);
                                            if ((sign_extend_64(var_79) & 0xffffffff80000000) != 0x0) {
                                                    operator delete(var_90);
                                            }
                                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                            r0 = r19;
                                    }
                            }
                            else {
                                    analyzer::BALibWrapper::GetBeatPos_Focus(r19[0x13]);
                                    r20 = analyzer::AnalyzeJobBeatDetector::getFirstBeatPos();
                                    juce::String::String(&decomp_var_d0);
                                    (*(*r19 + 0x40))(r19, r20, &decomp_var_d0, 0xd9);
                                    juce::String::~String();
                                    r9 = r19[0xf];
                                    r8 = r19[0x10];
                                    var_E0 = r9;
                                    var_D8 = r8;
                                    if (r8 != 0x0) {
                                            asm { ldadd      x9, x8, [x8] };
                                    }
                                    analyzer::AnalyzeJobBeatDetector::convertToMicrosec(r19, &var_E0, r24, r22, r25, var_F8);
                                    r20 = var_D8;
                                    if (r20 != 0x0) {
                                            r8 = r20 + 0x8;
                                            asm { ldaddal    x9, x8, [x8] };
                                            if (r8 == 0x0) {
                                                    (*(*r20 + 0x10))(r20);
                                                    std::__1::__shared_weak_count::__release_weak();
                                            }
                                    }
                                    r0 = r19[0x2];
                                    (*(*r0 + 0x10))(r0, 0x3, r23);
                                    r20 = r19[0x10];
                                    r19[0xf] = 0x0;
                                    r19[0x10] = 0x0;
                                    if (r20 != 0x0) {
                                            r8 = r20 + 0x8;
                                            asm { ldaddal    x9, x8, [x8] };
                                            if (r8 == 0x0) {
                                                    (*(*r20 + 0x10))(r20);
                                                    std::__1::__shared_weak_count::__release_weak();
                                            }
                                    }
                                    *(r19 + 0x6c) = r22;
                                    r19[0xe] = r25;
                                    juce::String::String(&decomp_var_e8);
                                    r20 = &decomp_var_e8;
                                    r0 = (*(*r19 + 0x40))(r19, 0x0, &decomp_var_e8, 0xe8);
                                    r19 = r0;
                                    juce::String::~String();
                                    operator delete[](var_F0);
                                    if ((sign_extend_64(var_79) & 0xffffffff80000000) != 0x0) {
                                            operator delete(var_90);
                                    }
                                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                                    r0 = r19;
                            }
                    }
                    else {
                            r19[0x19] = 0x0;
                            if (r19[0x18] != 0x0) {
                                    free(r19[0xb]);
                                    r19[0xb] = 0x0;
                            }
                            r19[0x18] = 0x0;
                            r19[0x1d] = 0x0;
                            r0 = r19[0x2];
                            (*(*r0 + 0x10))(r0, 0x3, r23);
                            juce::String::String(&decomp_var_c0);
                            r20 = &decomp_var_c0;
                            r0 = (*(*r19 + 0x40))(r19, 0x4, &decomp_var_c0, 0xcd);
                            r19 = r0;
                            juce::String::~String();
                            operator delete[](var_F0);
                            if ((sign_extend_64(var_79) & 0xffffffff80000000) != 0x0) {
                                    operator delete(var_90);
                            }
                            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                            r0 = r19;
                    }
            }
            else {
                    r19[0x19] = 0x0;
                    if (r19[0x18] != 0x0) {
                            free(r19[0xb]);
                            r19[0xb] = 0x0;
                    }
                    r19[0x18] = 0x0;
                    r19[0x1d] = 0x0;
                    r0 = r19[0x2];
                    (*(*r0 + 0x10))(r0, 0x3, r19 + 0x50);
                    juce::String::String(&decomp_var_b8);
                    r0 = (*(*r19 + 0x40))(r19, 0x3, &decomp_var_b8, 0xaf);
                    r19 = r0;
                    juce::String::~String();
                    if ((sign_extend_64(var_79) & 0xffffffff80000000) != 0x0) {
                            operator delete(var_90);
                    }
                    nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
                    r0 = r19;
            }
    }
    else {
            r19[0x19] = 0x0;
            if (r19[0x18] != 0x0) {
                    free(r19[0xb]);
                    r19[0xb] = 0x0;
            }
            r19[0x18] = 0x0;
            r19[0x1d] = 0x0;
            r0 = r19[0x2];
            (*(*r0 + 0x10))(r0, 0x3, r19 + 0x50);
            juce::String::String(&decomp_var_78);
            r0 = (*(*r19 + 0x40))(r19, 0x4, &decomp_var_78, 0x8f);
            r19 = r0;
            juce::String::~String();
            nlohmann::basic_json<nlohmann::ordered_map, std::__1::vector, std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >, bool, long long, unsigned long long, double, std::__1::allocator, nlohmann::adl_serializer, std::__1::vector<unsigned char, std::__1::allocator<unsigned char> > >::~basic_json();
            r0 = r19;
    }
    return r0;
