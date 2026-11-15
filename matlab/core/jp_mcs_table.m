function T = jp_mcs_table()
%JP_MCS_TABLE  MCS table 3 of this paper with the per-MCS EESM parameter eta.
%
%   eta, modulation order and coding rate are transcribed from Table 3 of
%   the paper.  The same 29 rows are used by the companion reproduction of
%   the 2025 prototyping paper, which delegates its link abstraction here.
%
%   The 10%-BLER SNR thresholds are NOT tabulated in the paper.  They are
%   obtained by interpolating the standard 3GPP CQI->SNR operating points
%   (below) in the spectral-efficiency domain.  This is the one modelling
%   assumption of the link abstraction; this paper's own anchor (-8.67 dB for
%   MCS 0) lands 0.33 dB away from it, see REPORT.md.

% mcs  eta    bits rate   (bits = modulation order: QPSK 2, 16QAM 4, 64QAM 6)
raw = [ 0  1.54   2  0.029
        1  1.55   2  0.039
        2  1.56   2  0.049
        3  1.57   2  0.063
        4  1.58   2  0.076
        5  1.59   2  0.097
        6  1.60   2  0.117
        7  1.61   2  0.153
        8  1.63   2  0.188
        9  1.65   2  0.245
       10  1.67   2  0.301
       11  1.70   2  0.370
       12  1.73   2  0.438
       13  1.76   2  0.514
       14  1.79   2  0.588
       15  3.97   4  0.332
       16  4.27   4  0.369
       17  4.71   4  0.424
       18  5.16   4  0.479
       19  5.66   4  0.540
       20  6.50   4  0.602
       21  9.95   6  0.428
       22 10.97   6  0.455
       23 12.92   6  0.505
       24 14.96   6  0.554
       25 17.06   6  0.602
       26 19.33   6  0.650
       27 21.85   6  0.702
       28 24.51   6  0.754];

T.mcs  = raw(:,1);
T.eta  = raw(:,2);
T.mod  = raw(:,3);
T.rate = raw(:,4);
T.se   = T.mod .* T.rate;   % T.mod is the modulation order in bits
                              % (2/4/6), not the constellation size

% 3GPP-style CQI operating points at 10% BLER (SE, SNR dB)
ref = [0.1523  -6.7
       0.2344  -4.7
       0.3770  -2.3
       0.6016   0.2
       0.8770   2.4
       1.1758   4.3
       1.4766   5.9
       1.9141   8.1
       2.4063  10.3
       2.7305  11.7
       3.3223  14.1
       3.9023  16.3
       4.5234  18.7
       5.1152  21.0
       5.5547  22.7];

T.snrTh = interp1(ref(:,1), ref(:,2), T.se, 'linear', 'extrap');
T.snrTh = T.snrTh(:);

T.blerSigma = 1.2;   % [assumed] BLER waterfall steepness [dB]
T.blerOff   = 1.2816;% Q^-1(0.1): BLER = 0.1 exactly at snrTh
end
