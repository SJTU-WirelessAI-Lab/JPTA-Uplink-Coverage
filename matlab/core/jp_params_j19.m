function p = jp_params_j19(band)
%JP_PARAMS_J19  Parameters of J19 (AlAmmouri, Mo et al., IEEE Access 2022).
%
%   p = jp_params_j19()        THz setup   (Table 4)
%   p = jp_params_j19('mmw')   mmWave setup (Sec. VI-B, Fig. 14)
%
%   Every number the paper states is tagged with its source.  The few that
%   the paper leaves open are tagged [assumed] and listed in REPORT.md §9.7.
%
%   Array geometry (Fig. 7 and Sec. V-B):
%     BS = 16 sub-arrays of 8V x 1H  -> 128 elements, one PA + one PS each
%     UE =  2 sub-arrays of 8V x 1H  ->  16 elements
%     "12 dB per sub-array, 24 dB total" is 10log10(8)=9.03 plus a 2.93 dB
%     element gain; the same 2.96 dB element gain gives the UE 15 dB.
%     Verified against the paper's own PAA codebook: 32 beams over 120 deg
%     with 16 horizontal elements gives a 0.69 dB crossover dip, i.e. exactly
%     the stated "max 24 dB, min 23.3 dB".

if nargin < 1, band = 'thz'; end
p.c    = 299792458;
p.band = lower(band);

switch p.band
    case 'thz'
        p.fc  = 140e9;  p.BW = 2e9;   p.SCS = 960e3;   p.tag = 'THz, 140 GHz';
    case 'mmw'
        p.fc  = 28e9;   p.BW = 800e6; p.SCS = 240e3;   p.tag = 'mmWave, 28 GHz';
    otherwise
        error('jp_params_j19:band','band must be ''thz'' or ''mmw''');
end

% ---- OFDM grid ------------------------------------------------------------
p.Nfft = 4096;                          % Table 4
p.Nsc  = floor(p.BW/p.SCS);             % occupied subcarriers
p.Nrb  = floor(p.Nsc/12);               % resource blocks
p.rbBW = 12*p.SCS;                      % 1 RB [Hz]
p.mid  = (p.Nsc-1)/2;
p.f    = p.fc + ((0:p.Nsc-1).' - p.mid)*p.SCS;   % absolute freq [Hz]
p.foff = p.f - p.fc;

% ---- array ---------------------------------------------------------------
p.NvB = 8;   p.NhB = 16;                % BS  8V x 16H   (Fig. 7a)
p.NvU = 8;   p.NhU = 2;                 % UE  8V x 2H    (Fig. 7b)
p.Ndu = p.NhB;                          % 16 delay units, one per column
p.d   = 0.5*p.c/p.fc;                   % lambda/2 in both dims (Sec. V-B)
p.Gbs = 24;                             % BS peak gain [dB]     (Sec. V-B)
p.Gue = 15;                             % UE peak gain [dB]     (Sec. V-B)
p.GelemB = p.Gbs - 10*log10(p.NvB*p.NhB);   % 2.93 dB element gain
p.GelemU = p.Gue - 10*log10(p.NvU*p.NhU);   % 2.96 dB element gain

% ---- link budget ---------------------------------------------------------
p.Ptx  = 18;                            % UE TX power [dBm]     (Table 5a)
p.NF   = 8;                             % BS noise figure [dB]  (Table 5k)
p.N0   = -174;                          % noise PSD [dBm/Hz]    (Table 5d)
p.beta = 3;                             % path-loss exponent    (Sec. VI)

% ---- scheduling ----------------------------------------------------------
p.NUE     = 32;                         % active UEs in the sector (Fig. 13)
p.sector  = 120;                        % sector span [deg]        (Sec. III)
p.Npaa    = 32;                         % PAA analog beams         (Fig. 9)
p.minRB   = 4;                          % minimum allocation       (Sec. V-B)
p.blerTgt = 0.10;                       % BLER constraint          (Table 5)
p.gEdge   = 3;                          % 3 dB subcarrier selection (Sec. V-B)
p.NSZ     = [1 2 4 8 16];               % JPTA codebook sizes      (Sec. V-B)
end
