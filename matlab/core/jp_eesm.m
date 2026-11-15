function effDb = jp_eesm(lin, eta)
%JP_EESM  Numerically stable exponential effective SNR mapping.
%
%   eff = -eta*log(mean(exp(-lin/eta)))            (J19 eq. (11))
%
%   Evaluated directly this underflows as soon as the SNR exceeds a few
%   hundred in linear scale (exp(-lin/eta) becomes exactly 0 for every
%   subcarrier and the result is Inf).  Factoring out the smallest SNR,
%
%       eff = c - eta*log(mean(exp(-(lin-c)/eta))),   c = min(lin),
%
%   is algebraically identical, never overflows, and -- crucially -- keeps
%   the exact dB shift invariance that the distance sweep relies on.

c   = min(lin);
eff = c - eta*log(mean(exp(-(lin-c)/eta)));
if ~isfinite(eff) || eff <= 0
    eff = c;
end
effDb = 10*log10(eff);
end
