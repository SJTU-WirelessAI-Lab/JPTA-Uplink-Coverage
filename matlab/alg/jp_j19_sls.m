function out = jp_j19_sls(p, T, kind, NSZ, D, thDeg)
%JP_J19_SLS  System-level simulator of J19 Sec. V-B.
%
%   out = jp_j19_sls(p, T, 'paa',  [], D, thDeg)
%   out = jp_j19_sls(p, T, 'jpta', N,  D, thDeg)
%
%   Per UE and per distance:
%     1. serving beam = the codebook beam with the largest gain (Sec. V-B)
%     2. keep the subcarriers within 3 dB of that beam's peak, drop the rest
%     3. for every candidate bandwidth B (>= 4 RB, <= the 3 dB bundle and
%        <= the UE's fair share) the UE's 18 dBm is spread over B, the
%        subcarrier SNRs are combined by EESM, and B x MCS is chosen to
%        maximise  R = duty * B * SE  subject to BLER <= 10%
%
%   duty = 1/N_UE for PAA (the UE owns 1 of the 32 slots) and 1/NSZ for JPTA
%   (the UE is served in 1 of the NSZ zone slots, over W*NSZ/N_UE of the
%   band).  Both give the same average bandwidth W/N_UE, which is eq. (2)/(3)
%   of the paper; the JPTA gain is the K = N_UE/NSZ fold energy aggregation.
%
%   K = ceil(NUE/NSZ) is also the maximum number of HARQ transmissions
%   (the paper's rule for equalising the message delay, Sec. V-B).

if strcmpi(kind,'paa')
    cb    = jp_j19_codebook(p,'paa');
    duty  = 1/p.NUE;
    K     = 1;
    bCap  = p.Nrb;                     % the UE owns the whole band in its slot
    bName = 'PAA';
else
    cb    = jp_j19_codebook(p,'jpta',NSZ);
    duty  = 1/NSZ;
    K     = ceil(p.NUE/NSZ);
    bCap  = floor(p.Nrb*NSZ/p.NUE);    % W*NSZ/N_UE, the fair share
    bName = sprintf('JPTA N_{SZ}=%d',NSZ);
end
nU = numel(thDeg);

% ---- candidate bandwidths (RB) ------------------------------------------
cand = unique([4 5 6 8 10 12 16 24 32 48 64 96 128 p.Nrb bCap]);
cand = cand(cand >= p.minRB & cand <= max(bCap,p.minRB));

% ---- serving beam + 3 dB bundle + EESM table (shift invariant in dB) ----
eff0 = cell(nU,1);  nsc = cell(nU,1);  gmaxU = zeros(nU,1);  bnd = zeros(nU,1);
for iu = 1:nU
    u  = sind(thDeg(iu));
    gb = -inf; ib = 1;
    for b = 1:cb.nb
        gg = jp_j19_gain(p, cb.b(b).tau, cb.b(b).phi, u);
        if max(gg) > gb, gb = max(gg); ib = b; end
    end
    g   = jp_j19_gain(p, cb.b(ib).tau, cb.b(ib).phi, u);
    ok  = find(g >= max(g) - p.gEdge);
    [~,ord] = sort(g(ok),'descend');
    idx = ok(ord);
    gmaxU(iu) = max(g);
    bnd(iu)   = numel(idx);
    E = nan(numel(cand), T.nMcs);
    n = zeros(numel(cand),1);
    for ic = 1:numel(cand)
        nb = 12*cand(ic);
        if nb > numel(idx), continue; end
        sel = idx(1:nb);
        snr0 = p.Ptx - 10*log10(nb*p.SCS) + g(sel) + p.Gue - p.N0 - p.NF;
        lin  = 10.^(snr0/10);
        for im = 1:T.nMcs
            E(ic,im) = jp_eesm(lin, T.eta(im));
        end
        n(ic) = nb;
    end
    eff0{iu} = E;  nsc{iu} = n;
end

% ---- distance sweep -----------------------------------------------------
Gh = 20*log10(p.c/(4*pi*p.fc)) - 10*p.beta*log10(D);
R  = zeros(numel(D),nU);  mcsU = zeros(numel(D),nU);  rbU = zeros(numel(D),nU);
effU = zeros(numel(D),nU);

for id = 1:numel(D)
    for iu = 1:nU
        E = eff0{iu};
        best = 0; bm = 0; br = 0; be = NaN;
        for ic = 1:numel(cand)
            if isnan(E(ic,1)), continue; end
            eff = E(ic,:).' + Gh(id);
            [bler, se] = jp_j19_lls(T, eff, K);     % vectorised over MCS
            % lls expects a scalar SNR: fall back to a loop when eff varies
            gain = duty*nsc{iu}(ic)*p.SCS * se .* (bler <= p.blerTgt);
            [v, im] = max(gain);
            if v > best
                best = v; bm = T.mcs(im); br = cand(ic); be = eff(im);
            end
        end
        R(id,iu) = best;  mcsU(id,iu) = bm;  rbU(id,iu) = br;  effU(id,iu) = be;
    end
end

out.R = R;  out.mcs = mcsU;  out.rb = rbU;  out.eff = effU;
out.name = bName;  out.K = K;  out.duty = duty;
out.Rmean = mean(R,2);
out.mcsMean = mean(mcsU,2);
out.gmax = gmaxU;  out.bundle = bnd;
end
