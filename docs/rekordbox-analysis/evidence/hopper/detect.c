    r31 = r31 - 0x40;
    var_10 = r20;
    decomp_var_8 = r19;
    saved_fp = r29;
    decomp_var_m8 = r30;
    r19 = r0;
    juce::String::String(&decomp_var_18);
    (*(*r19 + 0x40))(r19, 0x0, &decomp_var_18, 0x2b);
    juce::String::~String();
    if (((*(*r19 + 0x48))(r19) & 0x1) != 0x0) {
            if (r19[0x13] != 0x0) {
                    if (*(int32_t *)(r19[0x3] + 0x70) <= 0x4) {
                            if (analyzer::AnalyzeJobBeatDetector::highPrecisionBeatAnalyze() != 0x0) {
                                    r0 = (*(*r19 + 0x28))(r19);
                                    r0 = r0;
                            }
                            else {
                                    juce::String::String(&decomp_var_30);
                                    r0 = (*(*r19 + 0x40))(r19, 0x0, &decomp_var_30, 0x43);
                                    r19 = r0;
                                    juce::String::~String();
                                    r0 = r19;
                            }
                    }
                    else {
                            if (analyzer::AnalyzeJobBeatDetector::legacyBeatAnalyze() == 0x0) {
                                    juce::String::String(&decomp_var_30);
                                    r0 = (*(*r19 + 0x40))(r19, 0x0, &decomp_var_30, 0x43);
                                    r19 = r0;
                                    juce::String::~String();
                                    r0 = r19;
                            }
                            else {
                                    r0 = (*(*r19 + 0x28))(r19);
                                    r0 = r0;
                            }
                    }
            }
            else {
                    juce::String::String(&decomp_var_28);
                    r0 = (*(*r19 + 0x40))(r19, 0x1, &decomp_var_28, 0x32);
                    r19 = r0;
                    juce::String::~String();
                    r0 = r19;
            }
    }
    else {
            juce::String::String(&decomp_var_20);
            r0 = (*(*r19 + 0x40))(r19, 0x1, &decomp_var_20, 0x2e);
            r19 = r0;
            juce::String::~String();
            r0 = r19;
    }
    return r0;
