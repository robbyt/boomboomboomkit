# Input reconciliation: `Finetune_AST_for_BPM_Regression.ipynb`

**Date:** 2026-07-29
**Input:** `/Users/rterhaar/Downloads/Finetune_AST_for_BPM_Regression.ipynb` (17 cells, executed on a Colab T4, all outputs stored)
**Targets reconciled against:** `prd.md` (§7 Non-Goals, §4.3, AS-2) and `addendum.md` §A
**Method:** full read of every code, markdown and output cell; the notebook's train/val split was independently reproduced from the local GiantSteps checkout (`/Users/rterhaar/Dropbox/research/giantsteps-tempo-dataset`, `annotations_v2`, seed 42, `val_split=0.1`) so every number below is verified rather than read off the notebook's prose.

---

## 0. Verdict in one paragraph

The PRD's characterization is **wrong in its headline numbers, wrong in its central mechanism, and unsupported in its conclusion.**

- The PRD quotes **MAE 20.2 BPM and 4/10 at 4%**. Those are a **10-track eyeball subsample**, not the held-out result. The actual held-out result over the full 66-track validation set is **MAE 13.50 BPM and Acc1 40.9% (27/66)** — printed verbatim in the notebook's own training log, which neither document reads.
- The PRD says predictions **"collapse toward the corpus mean."** They do not. A constant-mean predictor on the *same* 66 tracks scores **MAE 17.74 / Acc1 25.8% (17/66)**. The model beats that baseline by 4.24 BPM and +10 tracks, with R² ≈ 0.27. The notebook's own markdown defines the pass criterion as beating the mean-guess, and by that criterion **this run passes**.
- The PRD says the failure is **"the head, not the backbone."** The notebook runs **exactly one configuration** and ablates nothing. It never trains a classification head, never varies the window, never varies the corpus. It cannot separate head from backbone from data volume from window length. That attribution is an inference presented as a reproduction.

The notebook *does* show AST-as-regression underperforming — 40.9% Acc1 is 12 points below the project's own failed v2 model (52.6%) and 41 points below TempoCNN. The conclusion "don't do this" survives. The **stated reasons for it do not.**

---

## 1. What the notebook actually is

A self-contained Colab tutorial, written to be run by someone else, not an experiment designed to falsify anything.

- **Cell 0:** fine-tunes `MIT/ast-finetuned-audioset-10-10-0.4593` (AST base, ~87M params) "to predict BPM (tempo) instead of AudioSet class labels."
- **Cell 5 markdown:** *"These are the same `finetune_ast_bpm.py` / `download_giantsteps_bpm_dataset.py` scripts from the repo, written to disk here so the notebook is self-contained."* It is a packaging of an existing repo, not a bespoke study.
- Its prose is diagnostic, not evaluative. Cell 11: *"watch that it actually drops epoch over epoch and settles well below what you'd get from guessing the dataset's mean BPM every time. If it stays flat near a large value, something's off."* Cell 13: *"If every prediction comes out nearly identical, the model didn't learn."*

**Reconciliation note.** The addendum's judgement that the notebook is "competently built" is fair and I concur. But it is a template with a worked example, and both documents treat it as an independent experimental confirmation. It was not designed as one, and the author never claims a finding.

---

## 2. Held-out results the documents never captured

The PRD and addendum cite only Cell 14 (the 10-track sanity check). **Cell 12 contains a complete 20-epoch training log with per-epoch held-out metrics on all 66 validation tracks.** Neither document reads it.

### 2.1 The final number

Last line of Cell 12:

> `Final validation metrics: {'eval_loss': 0.6066284775733948, 'eval_mse': 414.34918212890625, 'eval_mae': 13.498428344726562, 'eval_accuracy': 0.4090909090909091, 'eval_runtime': 7.6029, ...}`

`eval_accuracy` is defined in the training script (Cell 6) as exactly the project's metric:

> ```python
> # "Accuracy1" from tempo-estimation literature: fraction of predictions
> # within accuracy_tolerance (default 4%) of the true BPM.
> within_tolerance = np.abs(predictions - labels) <= accuracy_tolerance * labels
> ```

So the held-out result is **Acc1 = 40.9% (27/66), MAE = 13.50 BPM, MSE = 414.3**.

The PRD's **MAE 20.2 / 4-of-10** is a different, worse, and much noisier statistic.

### 2.2 The full per-epoch curve (extracted from Cell 12)

| Epoch | train loss | eval_mae | eval_acc | Epoch | train loss | eval_mae | eval_acc |
|---|---|---|---|---|---|---|---|
| 1 | 4.43 | 14.06 | 0.439 | 11 | 0.148 | 14.31 | 0.364 |
| 2 | 2.80 | 14.80 | 0.364 | 12 | 0.199 | 14.44 | 0.333 |
| 3 | 1.73 | **23.26** | **0.045** | 13 | 0.131 | 14.14 | 0.349 |
| 4 | 1.67 | 14.01 | 0.349 | 14 | 0.067 | 14.16 | 0.394 |
| 5 | 0.889 | 15.09 | 0.333 | 15 | 0.061 | 14.42 | 0.288 |
| 6 | 0.636 | 14.74 | 0.318 | 16 | 0.050 | **13.42** | 0.379 |
| 7 | 0.808 | 15.12 | 0.288 | 17 | 0.037 | 13.55 | 0.379 |
| 8 | 0.302 | 14.50 | 0.349 | 18 | 0.026 | 13.58 | 0.409 |
| 9 | 0.296 | 14.54 | 0.364 | 19 | 0.014 | 13.49 | 0.455 |
| 10 | 0.316 | 14.29 | 0.364 | 20 | 0.0067 | 13.50 | 0.424 |

Two things fall straight out of this table and appear in neither document:

1. **Held-out MAE was 14.06 after one epoch and 13.50 after twenty.** Nineteen epochs of training bought 0.56 BPM. The metric was effectively flat from epoch 1.
2. **Train loss fell from 7.34 to 0.0067 — a factor of ~1100 — while held-out loss sat at ~0.60 throughout.** That is textbook memorization of 595 examples by an 87M-parameter model.

**This is a generalization/data-volume signature, not a head-shape signature.** A scalar head that cannot represent the target would show a *training* loss floor. This training loss goes to zero. The head fits the training data perfectly; it just doesn't transfer. Attributing that to the head rather than to 595 examples is not supported by the evidence in front of us.

### 2.3 Training instability the documents miss

Epoch 3 collapsed: `eval_mae 23.26, eval_accuracy 0.045`. Gradient-norm spikes precede it (`grad_norm 186.1` at epoch 2.8, `213.4` at epoch 3.2) under `fp16=True` with **no warmup** (`TrainingArguments` default `warmup_steps=0`) at `lr=5e-5`. This is a run that was fighting its own optimizer configuration.

---

## 3. The mean-collapse claim is false

### 3.1 The claim

> **prd.md §7:** *"AST-as-regression. Rejected on head shape; an external notebook independently reproduced the predicted mean-collapse (71 BPM → 133.5, 89 → 129.2, MAE 20.2)."*
>
> **addendum.md §A:** *"Tracks near the corpus central tempo are accurate to a few BPM; tracks far from it collapse toward ~125-135. This is regression to the conditional mean on a multimodal target."*

### 3.2 The measurement

I reproduced the exact split (deterministic: `pd.read_csv(...).sample(frac=1.0, random_state=42)` over `sorted(glob("*.bpm"))`, first 10% held out) and scored a constant-mean predictor against the same 66 tracks.

| System | held-out MAE | held-out Acc1 | normalized MSE |
|---|---|---|---|
| **Constant = train mean (138.90)** | **17.74 BPM** | **25.8% (17/66)** | 0.834 |
| **AST regression (best checkpoint)** | **13.50 BPM** | **40.9% (27/66)** | 0.607 |
| Delta | **−4.24 BPM** | **+15.1 pp (+10 tracks)** | — |

R² against the validation set's own variance = **0.271**.

A model that had collapsed to the mean would score MAE ≈ 17.7 and Acc1 ≈ 25.8%. It scores 13.50 and 40.9%. **It has not collapsed.** It is a weak but genuinely predictive model.

The notebook's author anticipated exactly this test in Cell 11 — *"settles well below what you'd get from guessing the dataset's mean BPM every time"* — and by that stated criterion the run **passes**. The documents adopt the author's framing device and then report the opposite outcome.

### 3.3 Why the PRD got MAE 20.2

Cell 14 draws `sample_df = eval_df.sample(n=10, random_state=0)`. That draw is badly unrepresentative:

| Band | val set (66) | the 10-sample | over-representation |
|---|---|---|---|
| <100 | 4 (6%) | 2 (20%) | 3.3× |
| 100-120 | 6 (9%) | 2 (20%) | 2.2× |
| 120-140 | 35 (53%) | 4 (40%) | 0.8× |
| 140-160 | 8 (12%) | 2 (20%) | 1.6× |
| 160-175 | 12 (18%) | 0 | 0× |

It drew **half of all sub-100 tracks in the validation set** and a third of the 100-120 band — precisely the tails where a regressor's shrinkage is worst — and zero tracks from the 160-175 band. On that subsample the model scores MAE 20.21 against a constant-mean baseline of 21.26, i.e. it looks near-useless. On the other 56 tracks the implied mean absolute error is 12.30 BPM.

**The PRD's headline number is a tail-weighted 10-track draw that happens to land within 1 BPM of the naive baseline.** The full-set number is 35% better than the baseline. Nothing in either document flags that 20.2 is a subsample.

### 3.4 The addendum's own table contains two counterexamples it does not annotate

Corpus mean = 138.90. The addendum labels rows "near corpus mean", "pulled toward mean", "collapsed to mean". Two rows carry no note — and they are the two that refute the reading:

| True | Pred | Direction relative to the 138.90 mean | Addendum note |
|---|---|---|---|
| 117 | **93.5** | **45.4 BPM *below* the mean** — moves *away* | *(blank)* |
| 121 | **161.8** | **22.9 BPM *above* the mean** — moves *away* | *(blank)* |

A model collapsing to 138.90 cannot emit 93.5. Prediction spread on the sample is **σ = 16.95** against label spread **σ = 22.84** — compressed by 26%, which is ordinary regression shrinkage, not collapse. The two unannotated rows are the ones that had to be left unannotated for the "collapse" reading to hold.

### 3.5 The "decisive" 71 BPM case is not decisive

> **addendum.md §A:** *"The 71 BPM case is decisive — the prediction is 133.5, which is neither 71 nor its octave 142. An octave error would at least be musically meaningful and Acc2-recoverable; this value corresponds to nothing."*

Measured:

| True | Pred | ratio | distance from 2× | distance from 1.5× |
|---|---|---|---|---|
| 71 | 133.5 | **1.880** | 8.5 BPM (**6.0%**) | 27.0 (25.4%) |
| 89 | 129.2 | **1.452** | 48.8 (27.4%) | 4.3 BPM (**3.2%**) |

- **71 → 133.5 is within 6.0% of its octave partner.** It misses Acc2's 4% window by two points. Calling it "neither 71 nor its octave" is literally true and materially misleading — it is a near-miss octave, and 71 BPM in an EDM corpus is itself very likely a half-time annotation.
- **89 → 129.2 is within 3.2% of exactly 1.5× the label.** That is a triplet / dotted metrical relation, and it lands squarely inside the phenomenon the PRD's own **Q9** flags as unexamined (*"the ~1.5x cluster of 222 tracks in the non-Rekordbox pool"*). The one case the addendum calls meaningless is a clean instance of the open question the PRD says it cannot yet account for.

Both "collapsed to mean" cases are better read as **metrical-level errors**, which is exactly what this epic is about — and which makes the notebook more relevant to Epic 12, not less.

---

## 4. The head-vs-backbone attribution is unsupported

> **addendum.md §A:** *"Conclusion carried into the PRD: the failure is the head, not the backbone."*

The notebook contains **one** training run:

- one head type (scalar regression, `num_labels=1, problem_type="regression"`)
- one backbone (`MIT/ast-finetuned-audioset-10-10-0.4593`)
- one corpus (GiantSteps, 595 train)
- one window (see §5)
- one seed (42), one lr, one schedule

No classification head is ever built. No ablation of any kind is run. **There is no experimental contrast in the notebook from which head-versus-backbone could be inferred.** The addendum's own caveat paragraph concedes the confounds and then draws the conclusion regardless:

> *"...20 epochs over 664 tracks is thin; and the evaluation is a random 10% split of the same corpus... **None of these rescues a scalar head**, but all would matter if the head were swapped for classification."*

"None of these rescues a scalar head" is asserted, not shown. The evidence in §2.2 — train loss → 0.0067 while held-out loss is flat from epoch 1 — points at **data volume and generalization** as the operative constraint, which is a confound the same paragraph lists and then dismisses.

The PRD's Non-Goals wording compounds this by describing an inference as an observation: *"an external notebook independently reproduced the predicted mean-collapse."* It reproduced neither the collapse (§3) nor an attribution.

---

## 5. Architecture, hyperparameters and setup the documents omit entirely

Neither document records the training configuration. Extracted from Cells 6, 11 and 12:

| Item | Value | Source |
|---|---|---|
| Backbone | `MIT/ast-finetuned-audioset-10-10-0.4593` (AST base, ~87M params) | Cell 6 default |
| Head | `ASTConfig(num_labels=1, problem_type="regression")`, `ignore_mismatched_sizes=True` | Cell 6 |
| Head init | `classifier.dense.{weight,bias}` reinit from `[527,768]`→`[1,768]` | Cell 12 LOAD REPORT |
| Loss | MSE on **z-scored** labels (train-set μ=138.90, σ=26.13) | Cell 6 |
| Input | 16 kHz mono WAV (`ffmpeg -ar 16000 -ac 1`) | Cell 7 |
| **Input window** | **1024 frames = 10.24 s** (see §5.1) | HF `preprocessor_config.json` |
| lr | 5e-5, linear decay, **no warmup** | Cell 6 / HF default |
| Precision | fp16 | Cell 6 |
| Batch | 6 × 4 accum = **effective 24** | Cell 12 |
| Steps | 500 (25/epoch × 20) | Cell 12 |
| Epochs | 20 | Cell 12 |
| Grad checkpointing | on | Cell 12 |
| Seed | 42 | Cell 6 default |
| Checkpoint selection | `load_best_model_at_end`, `metric_for_best_model="mae"` | Cell 6 |
| Wall clock | 3140 s (52 min) on a Tesla T4 | Cell 12 |
| Corpus | GiantSteps `annotations_v2`, **661** usable tracks (595 train / 66 val) | Cell 12 |
| Augmentation | **none** | Cell 6 |

Notes:

- **661, not 664.** Cell 12 prints `Train examples: 595 | Validation examples: 66`. Three tracks drop out (`bpm <= 0` or missing audio). The addendum says "664 tracks". Confirmed against the local checkout: 661 rows.
- **The notebook's own markdown is internally inconsistent** — Cell 11 says "gradient accumulation to reach an effective batch of 16"; the command it precedes runs 6 × 4 = 24.
- **`annotations_v2`** is the 2018 crowdsourced-corrections version (Cell 7 default). This matters for **FR-60**: §4.3 records a ~6-point Acc1 swing from annotation version alone, and neither document tags the AST figure with its version.

### 5.1 The model saw only the first 10.24 seconds of every track — confirmed

The addendum hedges this:

> *"The AST feature extractor's default input window is short relative to a two-minute clip, so the model **may** only see the head of each track"*

It is not a *may*. Fetched from `huggingface.co/MIT/ast-finetuned-audioset-10-10-0.4593/raw/main/preprocessor_config.json`:

```json
{"feature_extractor_type": "ASTFeatureExtractor", "max_length": 1024,
 "num_mel_bins": 128, "sampling_rate": 16000, "do_normalize": true, ...}
```

`ASTFeatureExtractor` computes Kaldi fbank at a 10 ms frame shift and pads/truncates to `max_length`. The notebook calls it with no override, in both the training dataset (Cell 6) and the sanity check (Cell 14):

```python
inputs = self.feature_extractor(waveform, sampling_rate=target_sr, return_tensors="pt")
```

**1024 frames × 10 ms = 10.24 seconds.** Every two-minute GiantSteps preview is silently truncated to its first 10.24 s. Tempo is being estimated from a fixed ~10-second head window, with no multi-window aggregation and no evidence the window contains a stable drum pattern.

This should be promoted from a hedge to a stated fact, because it materially changes what the run measures. It is also a direct instance of the axis **FR-57** requires the reference-gap differential to cover — *"input representation and window policy"*.

---

## 6. Evaluation-protocol defects neither document notes

### 6.1 Near-duplicate leakage across the split

GiantSteps track names are Beatport IDs. Consecutive IDs are the same release (alternate mixes, radio edits, remixes of one track). Measured on the reproduced split:

- **36 clusters of near-consecutive IDs (≤10 apart) covering 81 of 661 tracks.**
- **6 clusters straddle the train/val boundary**, so **7 of the 66 validation tracks (10.6%) have a same-release sibling in training**: `2088281`, `3475672`, `4018083`, `4018085`, `5137158`, `3368053`, `4014747`.

The random split makes no attempt to separate them. So **13.50 MAE / 40.9% Acc1 is optimistic**, and the addendum's framing of the split as "the most favourable protocol available" is correct but understated — the specific mechanism is leakage, and it is quantifiable.

`5137158` appears in the PRD's own 10-row table (true 139, predicted 130.9) and has three siblings in training.

### 6.2 Validation set doubles as model-selection set

`load_best_model_at_end=True, metric_for_best_model="mae"` selects the best of 20 checkpoints **on the same 66 tracks that are then reported as the held-out result**. There is no test set. The reported 13.50/40.9% is a best-of-20 validation figure presented as a generalization estimate — the notebook's own instance of **FR-69c item 3** ("repeated screening inflates significance").

Also: the checkpoint actually loaded was epoch 19 (`eval_loss 0.6066` matches the final evaluate exactly), not epoch 16, which logged the lower MAE (13.42 vs 13.49). Minor, and it does not change any conclusion.

### 6.3 No Acc2, no octave-tolerant metric of any kind

`compute_metrics` (Cell 6) emits `mse`, `mae`, `accuracy` — nothing octave-aware. The notebook therefore **cannot distinguish an octave error from a magnitude error**, which is the entire subject of Epic 12 and is what **FR-61** makes a first-class requirement. Both §3.5 cases above only became legible by computing ratios by hand.

Any future use of this notebook as evidence must add Acc2 before its numbers mean anything to this epic.

### 6.4 Checkpoint-reload warning — investigated, benign

Cell 12 emits `There were unexpected keys in the checkpoint model loaded: [...all 12 encoder layers...]` at the `load_best_model_at_end` reload, and Cell 14 reloads from the same directory. I checked whether the Cell 14 predictions could come from a partly-uninitialized encoder: the 10-sample MAE of 20.21 implies mean |error| of 12.30 on the remaining 56 tracks, consistent with the 13.50 full-set figure. **The sample composition (§3.3) fully explains the gap; the warning is a transformers base-prefix logging artifact, not a real failure.** Recording this so it is not raised again.

---

## 7. What the notebook supports that the PRD does not harvest

### 7.1 It is direct evidence for AS-2 — and the PRD cites only published work

**prd.md AS-2:** *"Capacity is not the constraint."* **§4.3:** *"Böck & Davies TCN: GiantSteps Acc1 87.0 at ~33k parameters... Ours: 315k parameters, 52.6."*

The notebook adds an owned data point at the far end of that curve:

| System | params | GiantSteps Acc1 |
|---|---|---|
| Böck TCN | ~33k | 87.0 (PUBLISHED, AS-3 secondary) |
| TempoCNN | — | 82.1 (PUBLISHED) |
| **Our v2** | **315k** | **52.6** (MEASURED) |
| **AST regression** | **~87M** | **40.9** (MEASURED, this notebook, 66-track split) |
| MULE 1-NN | large | 35.9 (PUBLISHED) |

An 87M-parameter transformer scoring 41 while a 33k-parameter TCN scores 87 is the strongest single illustration of AS-2 the project owns, and it is **measured, not cited**. The PRD supports AS-2 entirely on published figures — one of which (AS-3, the 33k count) it flags as secondary-source and uncertain. This is free corroboration the PRD leaves on the table.

Caveats to state if it is used: different denominators (66 vs 661), a 10.24 s window, and the leakage in §6.1.

### 7.2 The 40.9% sits in a meaningful band, not at chance

Against `addendum.md` §D's comparison table, 40.9% sits between MULE 1-NN (35.9) and Quinton SSL (47.0) — i.e. in the range of self-supervised and embedding-probe baselines, well above chance. "Collapse" implies chance-level behaviour and misrepresents where this result sits.

The useful framing is: **an 87M AudioSet transformer with a scalar head, on a 10-second window and 595 examples, reaches roughly embedding-probe territory and remains 12 points below our own failed model.** That is a sufficient reason to reject the direction, and it is defensible.

---

## 8. Recommended corrections

Ordered by how load-bearing they are.

**C1 — Replace the headline numbers (prd.md §7, addendum.md §A).**
Strike "MAE 20.2" and "4 of 10". Use: *held-out over 66 tracks, Acc1 40.9% (27/66), MAE 13.50 BPM, GiantSteps `annotations_v2`.* Retain the 10-row table if useful, but label it explicitly as a tail-weighted 10-track subsample whose MAE (20.21) is not the held-out MAE.

**C2 — Withdraw "mean-collapse."**
It is measurably false: the constant-mean baseline on the same tracks is MAE 17.74 / Acc1 25.8%, and the model beats it by 4.24 BPM and 10 tracks (R² 0.27). Replace with the accurate claim: *tail shrinkage plus metrical-level errors, at an accuracy well below both our DSP path and our own failed v2 model.*

**C3 — Withdraw "the failure is the head, not the backbone."**
The notebook has no ablation and cannot support it. If the direction is still rejected — and it should be — reject it on the measured 40.9%, on 87M parameters buying nothing, and on the training-curve evidence that 595 examples cannot finetune this backbone. State head-versus-backbone as **UNTESTED**.

**C4 — Rewrite the addendum's §A "decisive" paragraph.**
71 → 133.5 is within **6.0%** of the octave partner, and 89 → 129.2 is within **3.2%** of 1.5×. Neither "corresponds to nothing". The 1.5× case is a live instance of open question **Q9** and should be cross-referenced there.

**C5 — Promote the window caveat to a fact.**
`max_length=1024` at a 10 ms frame shift = **10.24 s**, confirmed from the checkpoint's `preprocessor_config.json`. Every 2-minute clip was truncated to its first 10.24 s. Fold this into **FR-57**'s window-policy axis.

**C6 — Add the protocol defects.**
7 of 66 validation tracks (10.6%) have a same-release Beatport-ID sibling in training; the validation set also served as the checkpoint-selection set; there is no Acc2. All three make the reported numbers optimistic and none is currently recorded.

**C7 — Add the omitted setup facts.**
661 tracks (not 664); 595/66 split; effective batch 24; lr 5e-5, no warmup, fp16; 20 epochs / 500 steps / 52 min on a T4; no augmentation; `annotations_v2`. Tag the figure with its annotation version per **FR-60**.

**C8 — Harvest the AS-2 corroboration.**
Add the AST run to §4.3's capacity evidence as a **MEASURED** point (87M params → 40.9%), with the denominator, window and leakage caveats attached. It partially de-risks AS-3, whose secondary-source status the PRD already flags.

**C9 — Correct the framing of what the notebook is.**
It is a self-contained tutorial packaging scripts from an existing repo, with one worked example. It is not an independent falsification experiment and its author advances no finding. "Independently reproduced" overstates it in both documents.

---

## 9. What survives unchanged

- **The direction stays rejected.** 40.9% Acc1 on a favourable, leaky, same-corpus split is 12 points below our own failed v2 model and 41 below TempoCNN. Nothing here argues for pursuing AST-as-regression.
- **The addendum's assessment of the notebook's craft is fair** — md5-verified download, correct z-score label normalization, faithfully reconstructed split, honest diagnostic prose. All verified.
- **The addendum's three caveats were the right three** (short window, thin training, favourable split). Two are now quantified (10.24 s; 10.6% leakage) and the third is confirmed (595 examples, memorized by epoch 8). The caveats were correct; the decision to override them was not.
- **The hybrid-head idea stays open and out of scope.** Untouched by any of this.
