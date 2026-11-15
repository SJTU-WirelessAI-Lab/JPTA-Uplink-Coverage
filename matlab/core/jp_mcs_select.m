function T = jp_mcs_select()
%JP_MCS  MCS table 3 of this paper, plus the 10%-BLER thresholds of its LLS.
%
%   The 29 (eta, modulation, coding rate) rows are Table 3 of this paper and are
%   shared verbatim with the system-design repository (jp_mcs.m).  Two things are specific to this paper:
%
%   1. The absolute SNR scale.  Tab. 5(h) of this paper states the required SNR at
%      10% BLER for MCS 0 with one transmission: -8.67 dB.  The CQI-domain
%      interpolation of jp_mcs_table lands at -9.00 dB unaided, i.e. 0.33 dB
%      away, which is a useful independent check; the table below is then
%      rigidly shifted so that MCS 0 sits exactly on the published -8.67 dB.
%
%   2. The overhead.  Fig. 6 of this paper shows the MCS-0 spectral efficiency
%      saturating at 0.044 bps/Hz against an ideal 2*0.029 = 0.058, i.e. a
%      0.2414 CP+DMRS overhead.  That single factor is applied to every MCS.

T0 = jp_mcs_table();          % 29 rows: eta, mod order, rate, CQI-interp thresholds

T      = T0;
T.oh   = 1 - 0.044/(2*0.029);           % 0.2414, from Fig. 6
T.seIf = T.mod .* T.rate;               % ideal spectral efficiency
T.se   = T.seIf*(1 - T.oh);             % 0.0441 for MCS 0

T.anchor  = -8.67;                      % Tab. 5(h), PAA column
T.shift   = T.anchor - T0.snrTh(1);     % +0.33 dB
T.snrTh   = T0.snrTh + T.shift;         % 10%-BLER point, N_TR = 1
T.snrTh0  = T0.snrTh;                   % un-anchored (for the sanity check)
T.sigma   = 1.2;                        % [assumed] waterfall steepness [dB]
T.nMcs    = numel(T.mcs);
end
