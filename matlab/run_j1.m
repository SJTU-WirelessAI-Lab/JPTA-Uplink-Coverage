% =======================================================================
%  run_j1.m -- Fig. 4 (coverage vs K) and Table 5 (link budget)
%  Pure analysis: eq. (2)-(12) plus the LLS 10%-BLER thresholds of run_j2.
% =======================================================================
addpath(fullfile(fileparts(mfilename('fullpath')),'core'));
addpath(fullfile(fileparts(mfilename('fullpath')),'alg'));
out = fullfile(fileparts(mfilename('fullpath')),'out');
if ~exist(out,'dir'), mkdir(out); end
fid = fopen(fullfile(out,'j1_summary.txt'),'w');

p  = jp_params('thz');
T  = jp_mcs_select();
c  = p.c;

%% ---------------------------------------------------------------- Fig. 4
K  = (1:32).';
bet = [2 3 4];
fprintf(fid,'=== Fig. 4 : coverage extension vs transmission opportunity K ===\n');
fprintf(fid,'     radius K^(1/b)          area K^(2/b)\n');
fprintf(fid,'  K    b=2    b=3    b=4     b=2     b=3     b=4\n');
Rr = K.^(1./bet);  Ra = K.^(2./bet);
for i = [1 4 8 16 32]
    fprintf(fid,'%3d %6.3f %6.3f %6.3f  %6.2f %7.2f %7.2f\n', K(i), Rr(i,:), Ra(i,:));
end
fprintf(fid,'\npaper (Sec. IV, K=32, beta=3): radius 32^(1/3)=%.4f, area 32^(2/3)=%.4f, BS density -> %.1f%%\n\n', ...
        32^(1/3), 32^(2/3), 100/32^(2/3));

%% --------------------------------------------------------------- Table 5
% (f) effective noise power over the 4-RB channel bandwidth
BW4   = 4*12*p.SCS;                       % 46.08 MHz
f_noise = p.N0 + 10*log10(BW4);
% (h) 10%-BLER SNR of MCS 0 for N_TR = K, taken from the LLS of run_j2
Kset  = [1 4 32];
hLls  = zeros(1,3);  hIdeal = T.snrTh(1) - 10*log10(Kset);
for i = 1:3
    hLls(i) = local_snrTh(T, Kset(i));
end
cEirp = p.Ptx + p.Gue;                    % (c) UE EIRP
iSens = f_noise + hLls;                   % (i) receiver sensitivity
lBud  = cEirp - iSens + p.Gbs - p.NF;     % (l) hardware link budget margin

PL0   = -20*log10(c/(4*pi*p.fc));         % free-space loss at 1 m  [dB]
dist  = 10.^((lBud - PL0)./(10*p.beta));

fprintf(fid,'=== Table 5 : coverage through link budget (b = 3) ===\n');
hdr = sprintf('%-34s %10s %12s %12s','quantity','PAA','JPTA NSZ=8','JPTA NSZ=1');
fprintf(fid,'%s\n', hdr);
row = @(nm,v,fmt) fprintf(fid,['%-34s ' fmt '\n'], nm, v);
row('(a) UE TX power [dBm]',      p.Ptx*[1 1 1],            '%10.2f %12.2f %12.2f');
row('(b) UE TX gain [dB]',        p.Gue*[1 1 1],            '%10.2f %12.2f %12.2f');
row('(c) UE EIRP [dBm]',          cEirp*[1 1 1],            '%10.2f %12.2f %12.2f');
row('(d) noise density [dBm/Hz]', p.N0*[1 1 1],             '%10.2f %12.2f %12.2f');
row('(e) channel bandwidth [MHz]',BW4/1e6*[1 1 1],          '%10.2f %12.2f %12.2f');
row('(f) effective noise power [dBm]', f_noise*[1 1 1],     '%10.2f %12.2f %12.2f');
row('(g) repetitions K',          Kset,                     '%10.2f %12.2f %12.2f');
row('(h) required SNR (LLS) [dB]',hLls,                     '%10.2f %12.2f %12.2f');
row('    (paper)',                [-8.67 -14.59 -24.07],    '%10.2f %12.2f %12.2f');
row('(i) receiver sensitivity [dBm]', iSens,                '%10.2f %12.2f %12.2f');
row('(j) RX gain [dB]',           p.Gbs*[1 1 1],            '%10.2f %12.2f %12.2f');
row('(k) RX noise figure [dB]',   p.NF*[1 1 1],             '%10.2f %12.2f %12.2f');
row('(l) HW link budget margin [dB]', lBud,                 '%10.2f %12.2f %12.2f');
row('    (paper)',                [155.04 160.96 170.44],   '%10.2f %12.2f %12.2f');
fprintf(fid,'\ncoverage distance [m]            %10.0f %12.0f %12.0f   (paper 454 / 715 / 1481)\n', dist);
fprintf(fid,'distance gain vs PAA                      %12.2f %12.2f   (paper 1.59 / 3.26)\n', dist(2:3)/dist(1));
fprintf(fid,'K^(1/3) prediction                        %12.2f %12.2f\n', (Kset(2:3)/Kset(1)).^(1/3));
fprintf(fid,'\nLLS check: required SNR - (MCS0, N_TR=1) - 10log10(K) = %s dB\n', ...
        mat2str(round((hLls - hLls(1) - 10*log10(Kset))*100)/100));
fprintf(fid,'           (positive = the paper''s small extra HARQ-IR coding gain)\n');
fclose(fid);

%% ------------------------------------------------------------------ plot
figure('Position',[100 100 900 380],'Color','w');
subplot(1,2,1);
plot(K, Rr, 'LineWidth', 1.6); grid on; xlim([0 32]); ylim([1 6]);
xlabel('K'); ylabel('Coverage radius extension  K^{1/\beta}');
legend(arrayfun(@(b) sprintf('\\beta = %d',b), bet, 'UniformOutput',false),'Location','southeast');
title('(a) radius'); box on;
subplot(1,2,2);
plot(K, Ra, 'LineWidth', 1.6); grid on; xlim([0 32]); ylim([0 32]);
xlabel('K'); ylabel('Coverage area extension  K^{2/\beta}');
legend(arrayfun(@(b) sprintf('\\beta = %d',b), bet, 'UniformOutput',false),'Location','northwest');
title('(b) area'); box on;
print(fullfile(out,'j1_fig4_coverage.png'),'-dpng','-r160');

%% --------------------------------------------------------- Table 6 check
fid = fopen(fullfile(out,'j1_summary.txt'),'a');
fprintf(fid,'\n=== Table 6 : required maximum delay ===\n');
fprintf(fid,'%6s %13s %13s %13s %8s | %12s %8s\n','NSZ','ours ramp[ns]','ours centred[ns]','paper[ns]','c/p','ours mmW[ns]','c/p');
pT = jp_params('thz'); pM = jp_params('mmw');
papT = [3.52 1.67 0.71 0.32 0.16]; papM = [8.82 4.2 1.8 0.86 0.46];
tT = zeros(1,5); tM = zeros(1,5); tC = zeros(1,5);
for i = 1:5
    cbT = jp_codebook(pT,'jpta',pT.NSZ(i));
    cbM = jp_codebook(pM,'jpta',pM.NSZ(i));
    tT(i) = cbT.tauSpan*1e9;  tM(i) = cbM.tauSpan*1e9;   % full ramp (M-1)*delta
    tC(i) = cbT.tauMax*1e9;                              % centred: (M-1)/2*delta
    fprintf(fid,'%6d %13.3f %13.3f %13.2f %8.2f | %12.3f %8.2f\n', pT.NSZ(i), ...
            tT(i), tC(i), papT(i), tC(i)/papT(i), tM(i), tM(i)/2/papM(i));
end
fprintf(fid,'\n(a full ramp tau_m = m*delta, m = 0..15, needs (M-1)*delta; a centred ramp\n');
fprintf(fid,' tau_m = (m-(M-1)/2)*delta needs only (M-1)*delta/2 and is what a differential\n');
fprintf(fid,' TTD pair naturally implements.  NSZ=1: 3.25 vs 3.52 ns (8%%), NSZ=2: 1.64 vs 1.67 (2%%).)\n');
fprintf(fid,'(full-aperture differential delay at 60 deg, 16 sub-arrays x lambda/2: %.3f ps)\n', ...
        15*pT.d*sind(60)/pT.c*1e12);
fclose(fid);

fprintf('run_j1 done\n');

% ------------------------------------------------------------------------
function g = local_snrTh(T, ntr)
% SNR at which BLER(MCS 0, N_TR) crosses 10%
lo = -60; hi = 30;
for it = 1:200
    mid = 0.5*(lo+hi);
    b = jp_lls(T, mid, ntr);
    if b(1) > 0.10, lo = mid; else, hi = mid; end
end
g = 0.5*(lo+hi);
end
