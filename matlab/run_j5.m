% =======================================================================
%  run_j5.m -- this paper report generator: side-by-side comparison with the paper
%  Reads out/j4_sls.mat (produced by run_j4.m); no simulation here.
% =======================================================================
addpath(fullfile(fileparts(mfilename('fullpath')),'core'));
addpath(fullfile(fileparts(mfilename('fullpath')),'alg'));
out = fullfile(fileparts(mfilename('fullpath')),'out');
S   = load(fullfile(out,'j4_sls.mat'));
fid = fopen(fullfile(out,'j5_compare.txt'),'w');

names = {'PAA','JPTA N_{SZ}=1','JPTA N_{SZ}=2','JPTA N_{SZ}=4','JPTA N_{SZ}=8','JPTA N_{SZ}=16'};
papThz = [418 1500 1150 900 740 580];
papMmw = [2500 7000 6000 4800 3800 3000];

%% ------------------------------------------------------------------ THz
fprintf(fid,'=== Fig. 13 (THz, 2 GHz @ 140 GHz, 32 UEs) vs paper Eq.(2)-(4) ===\n');
fprintf(fid,'%-14s %9s %9s %9s %9s %9s %8s %8s\n','case','R@10m','R@100m','R@400m', ...
        'R@1000m','cover[m]','paper','sig/paa');
Rp = @(o,x) local_at(S.Dthz, o.Rmean/1e6, x);
fprintf(fid,'%-14s %9.1f %9.2f %9.3f %9.3f %9.0f %8d %8.2f\n', names{1}, ...
        Rp(S.thz.paa,10), Rp(S.thz.paa,100), Rp(S.thz.paa,400), Rp(S.thz.paa,1000), ...
        S.thz.paa.dcov, papThz(1), 1);
for k = 1:5
    o = S.thz.j(k);
    fprintf(fid,'%-14s %9.1f %9.2f %9.3f %9.3f %9.0f %8d %8.2f\n', names{k+1}, ...
            Rp(o,10), Rp(o,100), Rp(o,400), Rp(o,1000), o.dcov, papThz(k+1), ...
            o.dcov/S.thz.paa.dcov);
end
fprintf(fid,'\nK^(1/3) predicted coverage gain: ');
fprintf(fid,'%.2f ', ([1 32 16 8 4 2]).^(1/3)); fprintf(fid,'\n');
fprintf(fid,'(paper: 418 -> 1500 m is a 3.59x gain, i.e. larger than its own K^(1/b)=3.17\n');
fprintf(fid,' and larger than the 3.26 of its Table 5; our 450 -> 1350 m is 3.00x)\n\n');

%% ---------------------------------------------------------------- mmWave
fprintf(fid,'=== Fig. 14 (mmWave, 800 MHz @ 28 GHz) ===\n');
fprintf(fid,'%-14s %9s %10s %10s %9s %8s %8s\n','case','R@10m','R@1000m','R@3000m','cover[m]','paper','sig/paa');
Rm = @(o,x) local_at(S.Dmmw, o.Rmean/1e6, x);
fprintf(fid,'%-14s %9.1f %10.2f %10.3f %9.0f %8d %8.2f\n', names{1}, ...
        Rm(S.mmw.paa,10), Rm(S.mmw.paa,1000), Rm(S.mmw.paa,3000), S.mmw.paa.dcov, papMmw(1), 1);
for k = 1:5
    o = S.mmw.j(k);
    fprintf(fid,'%-14s %9.1f %10.2f %10.3f %9.0f %8d %8.2f\n', names{k+1}, ...
            Rm(o,10), Rm(o,1000), Rm(o,3000), o.dcov, papMmw(k+1), o.dcov/S.mmw.paa.dcov);
end
fprintf(fid,'\n(paper Fig. 14 x-axis stops at 7000 m; the NSZ=1 curve reaches the right edge)\n\n');

%% ----------------------------------------------------------------- Fig.12
fprintf(fid,'=== Fig. 12 : best MCS vs distance (PAA, 4 RB) ===\n');
fprintf(fid,'%8s %6s | %8s %6s\n','dist[m]','ours','dist[m]','ours');
ks = [10 50 100 150 200 250 300 350 400 450];
for i = 1:numel(ks)
    fprintf(fid,'%8d %6.1f | %8d %6.1f\n', ks(i), local_at(S.Dm,S.mcsM,ks(i)), ks(i), local_at(S.Dm,S.mcsM,ks(i)));
end
fprintf(fid,'paper: 28 for <60 m, monotone decrease, 0 beyond ~400 m\n\n');

%% ---------------------------------------------- link-budget cross-check
fprintf(fid,'=== cross-checks ===\n');
fprintf(fid,'THz  : PAA %.0f m vs link budget 452 m (paper 418 / 454)\n', S.thz.paa.dcov);
fprintf(fid,'       NSZ=1 %.0f m vs link budget 1436 m (paper 1500 / 1481)\n', S.thz.j(1).dcov);
fprintf(fid,'mmW  : PAA %.0f m vs link budget 2200 m ; NSZ=1 %.0f m vs 7000 m\n', ...
        S.mmw.paa.dcov, S.mmw.j(1).dcov);
fprintf(fid,'K^(1/3) with beta=3 predicts 3.17x; measured THz %.2fx, mmWave %.2fx\n', ...
        S.thz.j(1).dcov/S.thz.paa.dcov, S.mmw.j(1).dcov/S.mmw.paa.dcov);
fclose(fid);
type(fullfile(out,'j5_compare.txt'));

function y = local_at(x, v, xq)
[~,i] = min(abs(x - xq));
y = v(i);
end
