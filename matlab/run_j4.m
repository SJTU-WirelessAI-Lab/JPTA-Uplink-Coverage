% =======================================================================
%  run_j4.m -- Figs. 12-14 : system level (best MCS, throughput, mmWave)
% =======================================================================
addpath(fullfile(fileparts(mfilename('fullpath')),'core'));
addpath(fullfile(fileparts(mfilename('fullpath')),'alg'));
out = fullfile(fileparts(mfilename('fullpath')),'out');
if ~exist(out,'dir'), mkdir(out); end
T   = jp_mcs_select();
fid = fopen(fullfile(out,'j4_summary.txt'),'w');

Rmin = 57e3;    % minimum rate for coverage (Sec. VI-B)

%% ================================================== THz : Fig. 12 and 13
p    = jp_params('thz');
th   = -60 + 120*((0:p.NUE-1)+0.5)/p.NUE;         % uniform drop in the sector
Dthz = unique([5:5:100, 120:20:300, 350:50:1500]);

fprintf(fid,'=== Fig. 13 : THz, %d UEs, W=2 GHz, fc=140 GHz ===\n', p.NUE);
fprintf(fid,'UE angles (deg): %s\n\n', mat2str(round(th*10)/10));

thz = struct();
for k = 0:5
    if k == 0
        o = jp_sls(p, T, 'paa', [], Dthz, th);
    else
        o = jp_sls(p, T, 'jpta', p.NSZ(k), Dthz, th);
    end
    ok = find(o.Rmean > 0, 1, 'last');
    dcov = Dthz(min(ok,numel(Dthz)));
    fprintf(fid,'%-16s K=%2d duty=%.4f  coverage %5.0f m  R(100m)=%8.2f  R(400m)=%8.3f Mbps\n', ...
            o.name, o.K, o.duty, dcov, local_at(Dthz,o.Rmean,100)/1e6, local_at(Dthz,o.Rmean,400)/1e6);
    o.dcov = dcov;
    if k == 0, thz.paa = o; else, thz.j(k) = o; end
end
fprintf(fid,'\npaper: PAA 418 m, JPTA NSZ=1 1500 m ; centre throughput 225 Mbps per UE ; Rmin = %.0f kbps\n', Rmin/1e3);
fprintf(fid,'       ratio JPTA/PAA at 1500 m: ');
for k = 1:5
    r = local_at(Dthz,thz.j(k).Rmean,1480)/max(local_at(Dthz,thz.paa.Rmean,1480),eps);
    fprintf(fid,'NSZ=%d:%.0fx  ', p.NSZ(k), r);
end
fprintf(fid,'\n\n');

figure('Position',[80 80 620 440],'Color','w');
lg = {};
semilogy(Dthz, thz.j(1).Rmean/1e6,'LineWidth',1.7); hold on; lg{end+1}='JPTA N_{SZ}=1';
cols = {[0.85 0.33 0.10],[0.93 0.69 0.13],[0.49 0.18 0.56],[0.47 0.67 0.19]};
for k = 2:5
    semilogy(Dthz, thz.j(k).Rmean/1e6,'LineWidth',1.7,'Color',cols{k-1}); lg{end+1}=sprintf('JPTA N_{SZ}=%d',p.NSZ(k));
end
semilogy(Dthz, thz.paa.Rmean/1e6,'k-','LineWidth',1.7); lg{end+1}='PAA';
semilogy(Dthz, Rmin/1e6*ones(size(Dthz)),'k--','LineWidth',1.3); lg{end+1}='Min throughput';
set(gca,'YScale','log'); grid on; xlim([0 1500]); ylim([1e-2 2e3]);
xlabel('Distance (m)'); ylabel('Throughput per UE (Mbps)');
legend(lg,'Location','northeast'); title('THz: 2 GHz @ 140 GHz, 32 UEs, 32-beam PAA vs JPTA');
print(fullfile(out,'j4_fig13_thz.png'),'-dpng','-r165');

%% ------------------------------------------------- Fig. 12 : best MCS vs d
cbP  = jp_codebook(p,'paa');
Dm   = 0:5:500;
mcsM = zeros(numel(Dm),1);  nrb4 = p.minRB;
for id = 1:numel(Dm)
    Gh = 20*log10(p.c/(4*pi*p.fc)) - 10*p.beta*log10(max(Dm(id),1));
    ms = zeros(1,numel(th));
    for iu = 1:numel(th)
        u  = sind(th(iu));  gb = -inf;
        for b = 1:cbP.nb
            gg = jp_gain(p, cbP.b(b).tau, cbP.b(b).phi, u);
            if max(gg) > gb, gb = max(gg); ib = b; end
        end
        g = jp_gain(p, cbP.b(ib).tau, cbP.b(ib).phi, u);
        ok = find(g >= max(g) - p.gEdge);
        [~,ord] = sort(g(ok),'descend'); idx = ok(ord);
        nb = 12*nrb4;  if nb > numel(idx), nb = numel(idx) - mod(numel(idx),12); end
        if nb < 12, ms(iu) = 0; continue; end
        snr = p.Ptx - 10*log10(nb*p.SCS) + g(idx(1:nb)) + p.Gue - p.N0 - p.NF + Gh;
        eff = jp_eesm(10.^(snr/10), T.eta(end));
        buf = zeros(1,T.nMcs);
        for im = 1:T.nMcs
            e2 = jp_eesm(10.^(snr/10), T.eta(im));
            [b, s] = jp_lls(T, e2, 1);
            if b(im) <= p.blerTgt, buf(im) = s(im); end
        end
        if any(buf > 0), ms(iu) = T.mcs(find(buf == max(buf),1)); else, ms(iu) = 0; end
    end
    mcsM(id) = mean(ms);
end
fprintf(fid,'=== Fig. 12 : best MCS vs distance (PAA, 4 RB = 46 MHz) ===\n');
fprintf(fid,'MCS at  10 m = %.1f  |  60 m = %.1f  | 100 m = %.1f  | 200 m = %.1f  | 300 m = %.1f  | 400 m = %.1f\n', ...
        local_at(Dm,mcsM,10), local_at(Dm,mcsM,60), local_at(Dm,mcsM,100), ...
        local_at(Dm,mcsM,200), local_at(Dm,mcsM,300), local_at(Dm,mcsM,400));
fprintf(fid,'(paper: starts at 28 for <60 m, reaches 0 beyond ~400 m)\n\n');

figure('Position',[80 80 560 340],'Color','w');
plot(Dm, mcsM, 'k-','LineWidth',1.7); grid on; xlim([0 500]); ylim([0 30]);
xlabel('Distance (m)'); ylabel('Best MCS');
title('PAA: best MCS vs distance (32-beam codebook, 4 RB)');
print(fullfile(out,'j4_fig12_mcs.png'),'-dpng','-r160');

%% ================================================== mmWave : Fig. 14
pm   = jp_params('mmw');
Dmmw = unique([10:10:200, 250:50:1000, 1100:100:7000]);
fprintf(fid,'=== Fig. 14 : mmWave, 800 MHz @ 28 GHz, SCS 240 kHz ===\n');
mmw = struct();
for k = 0:5
    if k == 0, o = jp_sls(pm, T, 'paa', [], Dmmw, th);
    else,      o = jp_sls(pm, T, 'jpta', pm.NSZ(k), Dmmw, th);
    end
    ok = find(o.Rmean > 0, 1, 'last');
    dcov = Dmmw(min(ok,numel(Dmmw)));
    fprintf(fid,'%-16s K=%2d  coverage %5.0f m   R(1000m)=%8.2f Mbps\n', o.name, o.K, dcov, ...
            local_at(Dmmw,o.Rmean,1000)/1e6);
    o.dcov = dcov;
    if k == 0, mmw.paa = o; else, mmw.j(k) = o; end
end
fprintf(fid,'(paper: curves extend to about 7000 m for NSZ=1 and about 2500 m for PAA)\n\n');

figure('Position',[80 80 620 440],'Color','w');
lg = {};
semilogy(Dmmw, mmw.j(1).Rmean/1e6,'LineWidth',1.7); hold on; lg{end+1}='JPTA N_{SZ}=1';
for k = 2:5
    semilogy(Dmmw, mmw.j(k).Rmean/1e6,'LineWidth',1.7,'Color',cols{k-1}); lg{end+1}=sprintf('JPTA N_{SZ}=%d',pm.NSZ(k));
end
semilogy(Dmmw, mmw.paa.Rmean/1e6,'k-','LineWidth',1.7); lg{end+1}='PAA';
semilogy(Dmmw, Rmin/1e6*ones(size(Dmmw)),'k--','LineWidth',1.3); lg{end+1}='Min throughput';
set(gca,'YScale','log'); grid on; xlim([0 7000]); ylim([1e-2 2e3]);
xlabel('Distance (m)'); ylabel('Throughput per UE (Mbps)');
legend(lg,'Location','northeast'); title('mmWave: 800 MHz @ 28 GHz, 32 UEs');
print(fullfile(out,'j4_fig14_mmw.png'),'-dpng','-r165');

%% ---------------------------------------------------------------- export
save(fullfile(out,'j4_sls.mat'),'Dthz','thz','Dmmw','mmw','Dm','mcsM');
fclose(fid);
fprintf('run_j4 done\n');

% ------------------------------------------------------------------------
function y = local_at(x, v, xq)
[~,i] = min(abs(x - xq));
y = v(i);
end
