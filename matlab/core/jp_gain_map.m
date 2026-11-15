function G = jp_gain_map(p, tau, phi, uVec, fidx)
%JP_GAIN_MAP  Gain [dB] of one analog beam over a grid of directions.
%
%   G = jp_gain_map(p, tau, phi, uVec)        -> numel(f) x numel(uVec)
%   G = jp_gain_map(p, tau, phi, uVec, fidx)  -> 1        x numel(uVec)
%
%   Same model as jp_gain, evaluated for many angles (and sub-carriers)
%   at once:
%
%       AF(f,u) = sum_m exp(j(phi_m + 2*pi*f*tau_m + 2*pi*f*d*m*u/c))
%
%   The steering phase carries the carrier, not just d/c -- dropping that
%   factor makes the pattern frequency- and angle-independent (a bug that
%   silently produced perfectly flat "beams").

M = numel(tau);
if nargin < 5 || isempty(fidx), f = p.f; else, f = p.f(fidx); end
u = uVec(:).';
af = zeros(numel(f), numel(u));
for mm = 0:M-1
    af = af + exp(1j*(2*pi*f*tau(mm+1) + phi(mm+1) + ...
                       2*pi*(f*p.d/p.c)*mm*u));
end
af = abs(af).^2/M^2;
G  = p.Gbs + 10*log10(max(af,1e-30));
end
