function g = jp_gain(p, tau, phi, u, fidx)
%JP_GAIN  Array gain [dB] of one analog beam, per subcarrier.
%
%   g = jp_gain(p, tau, phi, u, fidx) with
%       tau, phi : M x 1 delay [s] and PS phase [rad] per sub-array
%       u        : sin(theta) of the observation direction
%       fidx     : subcarrier indices (default: all)
%
%   Horizontal response only: the 8 vertical elements of every sub-array are
%   fed by one PA/PS, so the elevation pattern is fixed and contributes
%   Gbs - 10log10(NhB) dB.  Gain is normalised so that a perfectly steered
%   beam at the carrier peaks at exactly p.Gbs.

if nargin < 5 || isempty(fidx), fidx = (1:p.Nsc).'; end
f = p.f(fidx);
M = numel(tau);
m = (0:M-1).';
A = exp(1j*(2*pi*(f*tau(:).') + phi(:).' + 2*pi*(f*p.d/p.c)*(m.')*u));
af = abs(sum(A,2)).^2/M^2;
g  = p.Gbs + 10*log10(max(af,1e-30));
end
