function cb = jp_j19_codebook(p, kind, NSZ)
%JP_J19_CODEBOOK  Analog beam codebooks of J19.
%
%   cb = jp_j19_codebook(p, 'paa')     32 frequency-flat beams over the sector
%   cb = jp_j19_codebook(p, 'jpta', N) N spatial zones, each covered by one
%                                      frequency-dependent (rainbow) beam
%
%   PAA (Fig. 9): beams uniformly spaced in u = sin(theta) over +-sin(60deg).
%   With NhB = 16 elements the 3 dB beamwidth is 0.886/16 = 0.0554 in u and
%   the spacing is 1.732/31 = 0.0559, so the crossover sits 0.69 dB below the
%   peak -> max 24.0 dB / min 23.3 dB, exactly the paper's numbers.
%
%   JPTA (Fig. 2 / Fig. 10): the 16 delay units make the beam sweep one
%   spatial zone across the band, the phase shifters rotate it.  Steering the
%   peak to u at frequency f requires
%
%       per-element phase = phi_m + 2*pi*f*tau_m + 2*pi*f*d*m*u/c = const
%   =>  u(f) = (fc/f)*S + A,   A = delta*c/d,  tau_m = -m*delta
%
%   The sign of delta is the slope direction: Fig. 10 has the beam sweeping
%   from low to high angle as the frequency rises, which needs tau_m to fall
%   along the array.  Imposing u(fLo) = uLo, u(fHi) = uHi fixes both unknowns
%   in closed form (no search).  The ramp is centred, so the delay unit only
%   has to supply +-(M-1)/2*delta, which is exactly the convention that
%   reproduces J19 Table 6 (see run_j1).

u60 = sind(p.sector/2);
M   = p.Ndu;
m   = (0:M-1).';

if strcmpi(kind,'paa')
    ub = linspace(-u60, u60, p.Npaa).';
    cb.type = 'paa'; cb.nb = p.Npaa; cb.uEdge = ub;
    for i = 1:cb.nb
        cb.b(i).u0  = ub(i);
        cb.b(i).tau = zeros(M,1);
        cb.b(i).phi = -2*pi*(p.fc*p.d/p.c)*m*ub(i);
        cb.b(i).uLo = ub(i);
        cb.b(i).uHi = ub(i);
    end
    return
end

if nargin < 3, error('jp_j19_codebook:NSZ','NSZ required for JPTA'); end
ue  = linspace(-u60, u60, NSZ+1);
fLo = p.f(1);  fHi = p.f(end);
cb.type = 'jpta'; cb.nb = NSZ; cb.NSZ = NSZ; cb.uEdge = ue;

for i = 1:NSZ
    uLo = ue(i); uHi = ue(i+1);          % uLo < uHi ; u rises with f
    S   = -(uHi-uLo)*fLo*fHi/(p.fc*(fHi-fLo));   % PS rotation at fc
    A   = uLo - S*(p.fc/fLo);                    % sweep offset
    delta = A*p.d/p.c;
    cb.b(i).tau = -m*delta;
    cb.b(i).phi = -2*pi*(p.fc*p.d/p.c)*m*S;
    cb.b(i).uLo = uLo;  cb.b(i).uHi = uHi;
    cb.b(i).u0  = (uLo+uHi)/2;
    cb.b(i).delta  = abs(delta);
    cb.b(i).tauSpan = (M-1)*abs(delta);          % full ramp
    cb.b(i).tauMax  = (M-1)/2*abs(delta);        % centred ramp
end
cb.tauMax  = cb.b(1).tauMax;
cb.tauSpan = cb.b(1).tauSpan;
end
