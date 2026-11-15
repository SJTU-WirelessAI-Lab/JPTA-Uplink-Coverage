% =======================================================================
%  run_j3.m -- Figs. 9-10 : PAA and JPTA codebooks
% =======================================================================
addpath(fullfile(fileparts(mfilename('fullpath')),'core'));
addpath(fullfile(fileparts(mfilename('fullpath')),'alg'));
out = fullfile(fileparts(mfilename('fullpath')),'out');
if ~exist(out,'dir'), mkdir(out); end
p   = jp_params('thz');
fid = fopen(fullfile(out,'j3_summary.txt'),'w');
imid = round(p.Nsc/2);

%% ------------------------------------------------------------ PAA (Fig. 9)
cbP = jp_codebook(p,'paa');
th  = -60:0.02:60;
G   = zeros(numel(th), cbP.nb);
for i = 1:cbP.nb
    G(:,i) = jp_gain_map(p, cbP.b(i).tau, cbP.b(i).phi, sind(th), imid).';
end
env  = max(G,[],2);
du   = (sind(60)-sind(-60))/(cbP.nb-1);
dip  = 20*log10(abs(sin(pi*p.NhB*du/2)/(p.NhB*sin(pi*du/2))));
fprintf(fid,'=== Fig. 9 : 32-beam PAA codebook at fc ===\n');
fprintf(fid,'beam spacing in u        : %.4f   (3 dB width 0.886/Nh = %.4f)\n', du, 0.886/p.NhB);
fprintf(fid,'envelope over +-60 deg   : max %.2f dB, min %.2f dB   (paper 24 / 23.3)\n', max(env), min(env));
fprintf(fid,'predicted crossover dip  : %.2f dB\n\n', dip);

figure('Position',[100 100 760 420],'Color','w');
plot(th, G, 'LineWidth',0.6); hold on;
plot(th, env, 'k-', 'LineWidth',2.2);
grid on; xlim([-62 62]); ylim([5 25.2]);
xlabel('Angle (deg)'); ylabel('Beam gain (dB)');
title(sprintf('PAA: %d frequency-flat beams, envelope %.1f..%.1f dB', cbP.nb, min(env), max(env)));
print(fullfile(out,'j3_fig9_paa.png'),'-dpng','-r160');

%% ----------------------------------------------------------- JPTA (Fig. 10)
thG  = -60:0.25:60;
cb2  = jp_codebook(p,'jpta',2);
figure('Position',[80 80 950 350],'Color','w');
for i = 1:2
    Gm = jp_gain_map(p, cb2.b(i).tau, cb2.b(i).phi, sind(thG));
    subplot(1,2,i);
    imagesc(thG, p.foff/1e9, Gm); axis xy; caxis([12 p.Gbs]); colorbar;
    xlabel('Angle (deg)'); ylabel('Frequency offset (GHz)');
    title(sprintf('JPTA beam %d  (zone %.0f..%.0f deg)', i, asind(cb2.b(i).uLo), asind(cb2.b(i).uHi)));
end
print(fullfile(out,'j3_fig10_nsz2.png'),'-dpng','-r170');

figure('Position',[60 60 1000 660],'Color','w');
for k = 1:4
    NS = p.NSZ(k);
    cb = jp_codebook(p,'jpta',NS);
    Gm = -inf(numel(p.foff), numel(thG));
    for i = 1:NS
        Gm = max(Gm, jp_gain_map(p, cb.b(i).tau, cb.b(i).phi, sind(thG)));
    end
    subplot(2,2,k);
    imagesc(thG, p.foff/1e9, Gm); axis xy; caxis([12 p.Gbs]); colorbar;
    xlabel('Angle (deg)'); ylabel('Frequency offset (GHz)');
    title(sprintf('N_{SZ}=%d: \\Delta\\tau=%.2f ps, \\tau_{max}=%.1f ps', NS, cb.b(1).delta*1e12, cb.tauMax*1e12));
end
print(fullfile(out,'j3_fig10_all.png'),'-dpng','-r150');

%% --------------------------- 3 dB bundle vs the paper's fair share -------
fprintf(fid,'=== JPTA 3 dB bundle per UE vs the fair share W*NSZ/N_UE ===\n');
fprintf(fid,'%5s %16s %16s %16s %8s\n','NSZ','bundle@centre','bundle@0.9 zone','W*NSZ/NUE','ratio');
bun = zeros(1,5); bunE = zeros(1,5); gpk = zeros(1,5);
for k = 1:5
    NS = p.NSZ(k);
    cb = jp_codebook(p,'jpta',NS);
    for j = 1:2
        uu = cb.b(1).uLo + (0.5 + 0.4*(j-1))*(cb.b(1).uHi-cb.b(1).uLo);
        g  = jp_gain_map(p, cb.b(1).tau, cb.b(1).phi, uu).';
        nb = sum(g >= max(g)-p.gEdge);
        if j == 1, bun(k) = nb*p.SCS/1e6; else, bunE(k) = nb*p.SCS/1e6; end
    end
    gg = -inf;
    for i = 1:NS
        Gi = jp_gain_map(p, cb.b(i).tau, cb.b(i).phi, sind(0:0.05:60));
        gg = max(gg, max(Gi(:)));
    end
    gpk(k) = gg;
    fprintf(fid,'%5d %16.1f %16.1f %16.1f %8.2f\n', NS, bun(k), bunE(k), p.BW*NS/p.NUE/1e6, bun(k)/(p.BW*NS/p.NUE/1e6));
end
fprintf(fid,'\n(ratio ~2 means the +/-3 dB band of one UE is about twice its fair share, so\n');
fprintf(fid,' neighbouring allocations overlap 2:1 -- the SLS therefore caps B at the fair\n');
fprintf(fid,' share W*NSZ/N_UE, exactly as eq. (3) of the paper does.)\n');
fprintf(fid,'\npeak gain over all beams/angles: ');
fprintf(fid,'%.2f ', gpk); fprintf(fid,' dB  (PAA peak %.2f dB)\n', p.Gbs);
fprintf(fid,'JPTA beam gain loss vs PAA: %.2f dB\n', p.Gbs - min(gpk));
fclose(fid);

figure('Position',[100 100 640 360],'Color','w');
bar([bun; bunE].'); grid on;
set(gca,'XTickLabel',arrayfun(@(n) sprintf('N_{SZ}=%d',n), p.NSZ,'UniformOutput',false));
ylabel('3 dB band per UE (MHz)');
legend({'zone centre','90% of zone'},'Location','northwest');
title('JPTA usable band per UE vs the fair share W\cdotN_{SZ}/N_{UE}');
print(fullfile(out,'j3_bundle.png'),'-dpng','-r160');

fprintf('run_j3 done\n');
