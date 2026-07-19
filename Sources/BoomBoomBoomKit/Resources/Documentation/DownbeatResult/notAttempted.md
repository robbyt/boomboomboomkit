---
id: notAttempted
title: Downbeat Detection Not Attempted
---
**What it does.** Reports that downbeat (bar-start) detection did not run at all: the caller requested beats only, or the downbeat stage was skipped. It is one of three distinct states the type models, and it specifically means the absence of an attempt, carrying no claim about whether downbeats exist. The purpose of the tri-state design is that a consumer can tell this "detection never ran" apart from "detection ran and found nothing".

**When to pick it.** You do not choose this value, the library returns it, but you handle it when your code inspects a _BeatGrid_ that was produced without downbeat detection enabled (the opt-in _Options.detectDownbeats_ was off, keeping the BPM path byte-identical). Treat it as no information: neither a positive nor a negative downbeat result, only a signal that the question was not asked.

**Tradeoff.** The value's risk is entirely on the consuming side: code that conflates _notAttempted_ with _noneDetected_ makes a wrong inference, concluding a track has no clear downbeat when detection never ran, and may wrongly suppress a bar grid that a second pass with detection enabled would have produced. Collapsing the tri-state to a boolean has-downbeats discards the distinction this case exists to preserve, so the failure mode is a consumer that treats an un-asked question as a negative answer.
