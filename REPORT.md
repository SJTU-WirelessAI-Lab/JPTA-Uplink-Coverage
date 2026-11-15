# Reproduction report — Extending Uplink Coverage Through JPTA

Paper: A. AlAmmouri, J. Mo, V. V. Ratnam, B. L. Ng, R. W. Heath Jr., J. Lee, J. Zhang,
*IEEE Access* 10 (2022), doi 10.1109/ACCESS.2022.3200334.

Environment: MATLAB R2026b Update 1, Windows 11, 16 threads, 32 GB, no toolbox.
Gap numbers **G1–G7** are local to this repository.

**Reproducibility.** The whole tree was re-run from a fresh copy (`run_all`, about 2 min) and
all 14 output files came out byte-identical, timings included: this repository has no run-time
dependent output at all.

---

## 1 What is covered

| Job | Script | Figures / tables | Output |
|---|---|---|---|
| J-1 | `run_j1.m` | Fig. 4, Table 5, Table 6 | `out/j1_fig4_coverage.png`, `out/j1_summary.txt` |
| J-2 | `run_j2.m` | Fig. 5, Fig. 6 | `out/j2_fig56_lls.png`, `out/j2_summary.txt` |
| J-3 | `run_j3.m` | Fig. 9, Fig. 10, 3 dB bandwidth vs fair share | `out/j3_*.png`, `out/j3_summary.txt` |
| J-4 | `run_j4.m` | Fig. 12, Fig. 13, Fig. 14 | `out/j4_*.png`, `out/j4_sls.mat`, `out/j4_summary.txt` |
| J-5 | `run_j5.m` | point-by-point comparison (reads `j4_sls.mat`) | `out/j5_compare.txt` |

Everything the paper publishes a number for is reproduced from the paper's own equations. The
one substitution is the link-level simulator: the paper runs 5G NR PUSCH with HARQ-IR and LDPC
min-sum, this repository reconstructs its three observable consequences instead (§4).

---

## 2 Model

**Gain reference.** The BS is 8V×16H = 128 elements in 16 sub-arrays of 8V×1H, each sub-array
with one PA, one PS and one TTD. With a 2.93 dB element gain on top of the 9.03 dB of the 8
vertical elements, a sub-array gives 12.03 dB and the array 24.00 dB — the paper's "24 dB total"
reading, which is confirmed a posteriori by the PAA envelope (§5).

**Theoretical layer (eqs. 2–9).** With `K = ⌈N_UE/N_SZ⌉` transmission opportunities per message,
the receive SNR gains `10log10(K)` and the coverage radius and area scale as

$$R \propto K^{1/\beta},\qquad A \propto K^{2/\beta}.$$

**Link layer (eqs. 10–11).** Per-subcarrier SNR → EESM over the selected band → BLER with HARQ
combining → throughput; the MCS and the number of RBs are chosen jointly to maximise throughput
subject to BLER ≤ 10% and at least 4 RB.

**System layer (Sec. V-B).** 32 UEs over 120°, a 3 dB band selection per UE, a fair-share cap,
and coverage defined as "throughput ≥ 57 kbps".

---

## 3 Fig. 4 and Table 5: the theory closes exactly

Fig. 4 is eqs. (8)–(9) plotted:

| K | `K^(1/2)` | `K^(1/3)` | `K^(1/4)` | `K^(2/2)` | `K^(2/3)` | `K^(2/4)` |
|---|---|---|---|---|---|---|
| 4 | 2.000 | 1.587 | 1.414 | 4.00 | 2.52 | 2.00 |
| 8 | 2.828 | 2.000 | 1.682 | 8.00 | 4.00 | 2.83 |
| 16 | 4.000 | 2.520 | 2.000 | 16.00 | 6.35 | 4.00 |
| 32 | 5.657 | **3.175** | 2.378 | 32.00 | **10.08** | 5.66 |

The paper's `32^(1/3) ≈ 3.17`, `32^(2/3) ≈ 10.08` and "site density down to 10%" (9.9%) all match.

Table 5 is the informative one: it reduces "coverage" to "MCS 0 reaches 10% BLER on 4 RB
(46.08 MHz)", so every row can be recomputed independently.

| Row | PAA | `N_SZ = 8` | `N_SZ = 1` | Note |
|---|---|---|---|---|
| (f) effective noise power | **−97.36** | −97.36 | −97.36 | `−174 + 10log10(46.08 MHz)`; paper −97.37 |
| (g) `K` | 1 | 4 | 32 | `⌈32/N_SZ⌉` |
| (h) required SNR (here) | **−8.67** | **−14.69** | **−23.72** | |
| (h) required SNR (paper) | −8.67 | −14.59 | −24.07 | |
| (i) sensitivity | −106.03 | −112.06 | −121.09 | (f)+(h); paper −106.04 / −111.96 / −121.44 |
| (l) link margin | **155.03** | **161.06** | **170.09** | (c)−(i)+(j)−(k); paper 155.04 / 160.96 / 170.44 |
| radius, eq. (12), β = 3 | **452 m** | **718 m** | **1436 m** | paper 454 / 715 / 1481 |
| gain over PAA | 1 | **1.59** | **3.17** | paper 1.59 / 3.26; `K^(1/3)`: 1.59 / 3.17 |

1. **Max deviation 0.35 dB, max deviation in distance 3%, no fitted parameter.** (a)–(e) are
   given, (f) is arithmetic, (h) comes from §4, the rest is addition and subtraction.
2. The paper's (h) differs from `−8.67 − 3log2K` by +0.10 / −0.35 dB, in the direction of its
   footnote on extra HARQ-IR coding gain at high MCS. This reproduction models pure energy
   combining, i.e. exactly 3.01 dB per doubling, and therefore lands between the two.
3. **`K^(1/β)` is the ratio of two rows of the same table** — 1481/454 = 3.26, slightly above
   `32^(1/3) = 3.17` because row (h) gains 0.35 dB at high `K`. The claim is arithmetic, not
   simulation.

---

## 4 Fig. 5 and Fig. 6: link abstraction, and the modelling error it exposed

**What is substituted.** The paper's link-level simulation is 5G NR PUSCH + HARQ-IR + LDPC
min-sum (its Table 2). Rather than rebuild an LDPC chain, this reproduction keeps the three
observable consequences:

- the 10%-BLER threshold of MCS 0 is **−8.67 dB** (Table 5, used as the anchor);
- each retransmission is worth **+3 dB** of accumulated SNR;
- the spectral-efficiency ceiling is **0.044 bps/Hz** (Fig. 6).

The relative positions of the 29 MCS entries are obtained by interpolating the 3GPP CQI
operating points in the spectral-efficiency domain, with a Gaussian waterfall of σ = 1.2 dB
(gap **G1**). That independent construction puts MCS 0 at −9.00 dB, 0.33 dB from the anchor —
a check that the abstraction is anchored rather than tuned.

**The error that had to be fixed.** The first version treated the `N` transmissions as
independent events:

$$\mathrm{BLER}=\prod_{n=1}^{N}\varepsilon(n\gamma)
\quad\Longrightarrow\quad \text{shift } 3.3\text{–}3.4\ \mathrm{dB\ per\ doubling}$$

which put row (h) at −15.17 / −25.71 dB and the coverage radius at 745 / 1672 m, i.e. 8% / 13%
off. The physics is wrong: the `n`-th decoding attempt of HARQ-IR uses the **cumulative** SNR
`nγ`, so the failure probability is `ε(nγ)`, not a product of independent failures. With

$$\mathrm{BLER}(N)=\varepsilon(N\gamma),\qquad
E[\text{tx}]=1+\sum_{n=1}^{N-1}\varepsilon(n\gamma),\qquad
\mathrm{SE}(N)=\mathrm{SE}_{\rm ideal}\,\frac{1-\mathrm{BLER}}{E[\text{tx}]}$$

the shift is exactly **3.01 dB per doubling** and Table 5 returns to 0.35 dB. `E[tx]` is what
charges a message for the transmissions it consumes; it is also why the far-distance JPTA
curves in §6 fall onto the 57 kbps threshold without any tuning.

| `N_TR` | 1 | 2 | 4 | 8 | 16 | 32 |
|---|---|---|---|---|---|---|
| 10%-BLER threshold (dB) | −8.67 | −11.68 | −14.69 | −17.70 | −20.71 | −23.72 |
| shift (dB) | 0 | −3.01 | −6.02 | −9.03 | −12.04 | −15.05 |
| SE ceiling (bps/Hz) | 0.0440 | 0.0440 | 0.0440 | 0.0440 | 0.0440 | 0.0440 |

The six BLER curves are exact translates, which is the shape of the paper's Fig. 5; the SE
converges to `2 × 0.029 × (1 − 0.2414) = 0.0440`, matching 0.044.

The 0.2414 overhead is not a free parameter: `1 − 0.044/(2×0.029)` comes from the SE ceiling
itself, and it is 4.6% above what the 225 Mbps plateau of Fig. 13 implies (gap **G2**).

---

## 5 Fig. 9, Fig. 10, Table 6: codebooks

**(a) PAA, 32 beams.** Reading the paper's "16 sub-arrays of 8V×1H, 24 dB total" as
`10log10(8) + 2.93 = 12.03` per sub-array and `10log10(128) + 2.93 = 24.00` in total, the 3 dB
beamwidth of the 16 horizontal elements is `0.886·2/16 = 0.1108` on `u`, while 32 beams over
`[-60°, 60°]` are spaced `1.732/31 = 0.0559`. The ratio is 0.504 and the crossover sits at
**−0.69 dB**, i.e. **max 24.00 dB, min 23.28 dB** — bit for bit the paper's "24 dB / 23.3 dB".

This also pins `N_h = 16` rather than 32: with `N_h = 32` the same 32 beams would drop the
crossover by more than 4 dB.

**(b) JPTA rainbow.** Each sub-band's pointing is set by the 16 delays; the phase shifters
rotate the whole rainbow into the target sector. With per-element phase
`2πfτ_m + φ_m + 2πfdmu/c`, the peak condition gives

$$u(f)=\frac{f_c}{f}S-A,\qquad A=\frac{\delta c}{d},\qquad \tau_m=-m\delta,$$

and the two end points `u(f_lo), u(f_hi)` fix `S` and `δ` in closed form — no search. The
patterns for two beams (`out/j3_fig10_nsz2.png`) have the same shape as the paper's Fig. 10:
beam 1 goes from −60° at the low edge to 0° at the high edge, beam 2 from 0° to +60°, with the
same slope direction. `N_SZ = 1/2/4/8` give 1/2/4/8 parallel ridges (`out/j3_fig10_all.png`),
i.e. `N_SZ` directions covered at the same frequency, and the peak gain stays 24.00 dB, so the
rainbow costs no peak gain.

**(c) Table 6, the delay span.** The `δ` above is 433 ps at `N_SZ = 1`, so the full ramp
`(M−1)δ = 6.50 ns`; but a differential delay pair only provides `±(M−1)δ/2`, i.e. 3.25 ns:

| `N_SZ` | 1 | 2 | 4 | 8 | 16 |
|---|---|---|---|---|---|
| full ramp (ns) | 6.50 | 3.23 | 1.59 | 0.77 | 0.36 |
| **centred (ns)** | **3.25** | **1.61** | **0.80** | **0.39** | **0.18** |
| paper, Table 6 (THz) | 3.52 | 1.67 | 0.71 | 0.32 | 0.16 |
| ratio centred/paper | 0.92 | 0.97 | 1.12 | 1.21 | 1.13 |
| paper (mmWave, 800 MHz) | 8.82 | 4.20 | 1.80 | 0.86 | 0.46 |
| ratio centred/paper | 0.92 | 0.95 | 1.08 | 1.06 | 0.87 |

The centred convention reproduces Table 6 to **8–21%**, and both bands give the same set of
ratios because both scale as `1/W` — 16.24/6.50 = 2.499 = 2 GHz/800 MHz is an internal check.

This corrects an earlier estimate in the companion 2025 report, which guessed "the rainbow needs
tens of ps". That missed that with `d = λ/2` the variable `u` has period 2, so about 60 integer
periods are needed to cover 120°: the correct value is ns, the same order as Table 6.

---

## 6 Fig. 12, 13, 14: system level

**Scheduler.** For each UE at each distance,

$$R=\underbrace{\frac{1}{N_{SZ}}}_{\text{duty}}\cdot B\cdot \mathrm{SE}(N_{TR}=K),\qquad
4\ \mathrm{RB}\le B\le\min\{W N_{SZ}/N_{UE},\ \text{3 dB band width}\},$$

with SE already containing the in-band EESM and the `E[tx]` charge; `K = ⌈N_UE/N_SZ⌉` is also
the HARQ limit. The PAA baseline uses duty `1/N_UE`, `B ≤ W`, `K = 1`, and the best of 32 beams.
Both get the same average bandwidth, so all of the difference is the `K`-fold energy
concentration.

**(a) Fig. 13, THz.**

| Scheme | R@10 m | R@100 m | R@400 m | radius | paper | gain |
|---|---|---|---|---|---|---|
| PAA | 213.7 | 7.39 | 0.102 | **450 m** | 418 m | 1.00 |
| `N_SZ = 1` | 197.7 | 84.75 | 4.384 | **1350 m** | 1500 m | **3.00** |
| `N_SZ = 2` | 197.7 | 60.00 | 2.436 | 1100 m | 1150 m | 2.44 |
| `N_SZ = 4` | 207.6 | 39.01 | 1.304 | 900 m | 900 m | 2.00 |
| `N_SZ = 8` | 212.5 | 23.40 | 0.632 | 700 m | 740 m | 1.56 |
| `N_SZ = 16` | 212.5 | 13.51 | 0.272 | 550 m | 580 m | 1.22 |

- plateau 198–214 Mbps vs 225. The 5% is traceable to one number: Fig. 6's 0.044 implies 24.1%
  overhead, 225 Mbps implies 20.4% (gap **G2**).
- 5 of 6 radii within 5%, `N_SZ = 1` 10% low. Link budget 1436 m vs system simulation 1350 m:
  the ~2 dB is the in-band EESM, i.e. after the 3 dB band selection the effective SNR is below
  the peak.
- **the curves fall onto the 57 kbps line by themselves.** Not tuned: at the edge every UE needs
  all `K` retransmissions, `E[tx] → K`, so the throughput is divided by `K`. This also answers
  the normalisation worry raised in the companion 2025 report.
- internal inconsistency to report: 418 → 1500 m is 3.59×, above both the paper's own 3.17 and
  its Table 5's 3.26, with the two ends biased in opposite directions. This reproduction gives
  3.00 (450 → 1350), below the theoretical value — the direction expected when the system-level
  simulation deducts ~2 dB more than the link budget (gap **G6**).

**(b) Fig. 14, mmWave.**

| Scheme | R@10 m | R@1000 m | radius | paper |
|---|---|---|---|---|
| PAA | 85.6 | 0.20 | **2000 m** | ~2500 m |
| `N_SZ = 1` | 79.1 | 5.51 | **6500 m** | ~7000 m |
| `N_SZ = 2` | 84.0 | 3.12 | 5200 m | ~6000 m |
| `N_SZ = 4` | 84.0 | 1.75 | 4100 m | ~4800 m |
| `N_SZ = 8` | 85.3 | 0.94 | 3300 m | ~3800 m |
| `N_SZ = 16` | 85.3 | 0.43 | 2600 m | ~3000 m |

Plateau ~85 Mbps rather than 225 because the per-UE average bandwidth drops from 62.5 to 25 MHz;
the paper's Fig. 14 also starts at `10^1.9 ≈ 80`. Coverage 6500 vs 7000 m, ratio 3.25, close to
`K^(1/3) = 3.17`. All five radii are 17–20% below the paper's, consistently — the same ~1 dB of
additional loss the THz band shows.

**(c) Fig. 12, best MCS vs distance (PAA, 4 RB).**

| distance (m) | 10 | 50 | 100 | 150 | 200 | 250 | 300 | 350 | 400 | 450 |
|---|---|---|---|---|---|---|---|---|---|---|
| best MCS | 28 | 28 | 20 | 15 | 11 | 8 | 6 | 4 | 2 | 0 |

The paper: "from 28 at the centre (< 60 m) monotonically down to 0 after 400 m". Here 26 at 60 m
and 0 at 450 m; the staircase shape matches within 1–2 MCS, inside the CQI interpolation
uncertainty.

---

## 7 Gaps

| ID | Problem | Handling |
|---|---|---|
| **G1** | waterfall steepness σ not given | σ = 1.2 dB; affects the slope of Fig. 5, no threshold |
| **G2** | overhead inconsistent (24.1% vs 20.4%) | the 0.044 reading is used; plateau 5% low, reported |
| **G3** | Fig. 10's slope is ~45°/GHz (would cover ±90° over 2 GHz) while Table 6 supports 13°/GHz | implemented per Table 6, slope direction only from Fig. 10 |
| **G4** | zone partition rule not given | equal `u`; equal angle would worsen Table 6 by 1.2–1.3× |
| **G5** | UE angular distribution not given | uniform over 120° (3.75° spacing); ~0.7 dB of beam mismatch |
| **G6** | Fig. 13's 3.59× exceeds the paper's own 3.17 / 3.26 | judged a reading artefact of Fig. 13 |
| **G7** | 3 dB band per UE is about 2× its fair share (2:1 overlap) | scheduler caps `B` at `W·N_SZ/N_UE` |

---

## 8 Bugs and pitfalls

| # | Symptom | Root cause |
|---|---|---|
| 1 | all 32 PAA curves horizontal, envelope a constant 23.28 dB | the steering phase in `jp_gain_map` used `2π(d/c)mu` instead of `2πf(d/c)mu`, so the pattern lost all angle and frequency dependence |
| 2 | Table 5 rows (h)/(l) off by 1–2 dB, coverage off by 13% | HARQ as independent events (3.4 dB per doubling) instead of cumulative SNR |
| 3 | EESM returning `Inf` and every throughput zero | `−η log(mean(exp(−γ/η)))` underflows; factor out the minimum |
| 4 | sum of allocated bandwidths exceeding the system bandwidth | the 3 dB band selection overlaps 2:1 between neighbours (G7) |
| 5 | JPTA gain underestimated by ~15 dB | `N_TR` set to 1 instead of `K` |

---

## 9 Relation to the companion papers

| Dimension | this paper | 3-D beamforming (2024) | system design (2025) |
|---|---|---|---|
| array | 8V×16H, 16 sub-arrays, one TTD each | 16×24, one TTD per element | 16V×16H, one TTD per column |
| gain | 24.00 dB (12.03 per sub-array) | 25.84 dB | 28 dB |
| design variables | 16 pairs, closed-form rainbow | 384 pairs | 16 pairs |
| objective | uplink coverage / throughput | 3-D sub-band gain | 2-D codebooks + system level |
| carrier / bandwidth | 140 GHz / 2 GHz (and 28 GHz / 800 MHz) | 28 GHz / 95 MHz | 28 GHz / 400 MHz |
| retransmissions | `N_TR = K = ⌈N_UE/N_SZ⌉` | — | fixed `N_TR` |

This is the paper the other two borrow their link abstraction from: Table 3 (η per MCS) and the
EESM of eq. (11) are used verbatim in both, as `jp_mcs_table.m` and `jp_mcs.m` respectively.
