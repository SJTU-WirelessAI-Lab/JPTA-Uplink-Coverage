function [bler, se] = jp_lls(T, snrDb, ntr)
%JP_LLS  Link-level abstraction , Sec. V-A (HARQ-IR included).
%
%   [bler, se] = jp_lls(T, snrDb, ntr)
%
%   snrDb : per-subcarrier effective SNR of ONE transmission [dB].  May be a
%           column vector of length nMcs (one value per MCS); the EESM output
%           already is.
%   ntr   : maximum number of transmissions N_TR (a.k.a. K in the system runs)
%
%   Model.  A single attempt has the usual dB-domain waterfall
%
%       eps(g) = Q( (g - theta + 1.2816*sigma) / sigma ),   eps(theta) = 0.1
%
%   HARQ-IR / CC accumulates the received energy, so the decoder after the
%   n-th attempt sees the *combined* SNR n*g.  Decoding is attempted after
%   every attempt and stops on success, hence
%
%       BLER(N) = eps(N*g)                       <- shifted copy, 3 dB/doubling
%       E[tx]   = 1 + sum_{n=1..N-1} eps(n*g)     <- because E[tx]=sum P(tx>n)
%       SE(N)   = SE_ideal * (1 - BLER) / E[tx]
%
%   The three statements this paper makes about Figs. 5-6 follow directly: 3 dB per
%   doubling of N_TR (Fig. 5 is a set of shifted copies), SE(N=32) best and
%   converging to SE(N=16,8,...) as the SNR grows, and the 0.044 bps/Hz
%   ceiling of Fig. 6.  Note that the *product* model (independent attempts)
%   is wrong here: it would give 3.3-3.4 dB per doubling instead of 3.0.
%
%   Tab. 5(h) validates the choice: -8.67 / -14.59 / -24.07 dB for
%   N_TR = 1 / 4 / 32, i.e. -8.67 - 3.0*log2(N_TR) to within 0.4 dB.

th  = T.snrTh(:);                       % nMcs x 1
n   = 1:ntr;
gam = snrDb(:) + 10*log10(n);           % nMcs x ntr  (implicit expansion)
arg = (gam - th + 1.2816*T.sigma)/(sqrt(2)*T.sigma);
eps = 0.5*erfc(arg);                    % failure prob of the n-th attempt
eps = min(max(eps,1e-15),1);

bler = eps(:,end);
etx  = 1 + sum(eps(:,1:end-1),2);
se   = T.se(:).*(1-bler)./etx;
end
