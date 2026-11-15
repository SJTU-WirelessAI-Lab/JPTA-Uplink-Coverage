% =======================================================================
%  run_j2.m -- Figs. 5-6 : link-level abstraction (BLER & SE vs SNR)
% =======================================================================
addpath(fullfile(fileparts(mfilename('fullpath')),'core'));
addpath(fullfile(fileparts(mfilename('fullpath')),'alg'));
out = fullfile(fileparts(mfilename('fullpath')),'out');
if ~exist(out,'dir'), mkdir(out); end
T   = jp_mcs_select();
fid = fopen(fullfile(out,'j2_summary.txt'),'w');

ntr = [1 2 4 8 16 32];
snr = (-40:0.25:5).';

BL = zeros(numel(snr),numel(ntr));
SE = zeros(numel(snr),numel(ntr));
for i = 1:numel(ntr)
    for k = 1:numel(snr)
        [b, s] = jp_lls(T, snr(k), ntr(i));
        BL(k,i) = b(1);  SE(k,i) = s(1);
    end
end

%% ------------------------------------------------------------- summary
fprintf(fid,'=== Figs. 5-6 : MCS 0, HARQ-IR with N_TR transmissions ===\n');
fprintf(fid,'  N_TR   SNR@10%%BLER[dB]   shift[dB]   3log10(N)[dB]   SE_max[bps/Hz]\n');
th = zeros(1,numel(ntr));
for i = 1:numel(ntr)
    lo = -70; hi = 20;
    for it = 1:200
        mid = 0.5*(lo+hi);
        b = jp_lls(T, mid, ntr(i));
        if b(1) > 0.10, lo = mid; else, hi = mid; end
    end
    th(i) = 0.5*(lo+hi);
    fprintf(fid,'%6d %14.2f %12.2f %14.2f %14.4f\n', ntr(i), th(i), th(i)-th(1), ...
            10*log10(ntr(i)), max(SE(:,i)));
end
fprintf(fid,'\npaper: 3 dB per doubling; SE ceiling 0.044 bps/Hz (2*0.029*(1-%.3f) = %.4f)\n', T.oh, T.se(1));
fprintf(fid,'CQI-interpolated MCS-0 threshold before anchoring: %.2f dB (Tab. 5h: %.2f dB)\n\n', ...
        T.snrTh0(1), T.anchor);

% full threshold table (MCS x N_TR) is what the SLS uses internally
fprintf(fid,'10%%-BLER SNR for every MCS (N_TR = 1 / 4 / 32):\n');
fprintf(fid,'%4s %8s %8s %8s\n','MCS','N_TR=1','N_TR=4','N_TR=32');
for im = 1:T.nMcs
    if ~any(im == [1 6 11 15 20 21 25 28 29]), continue; end
    lo = [-70 -70 -70]; hi = [40 40 40]; nt = [1 4 32];
    for j = 1:3
        for it = 1:200
            mid = 0.5*(lo(j)+hi(j));
            b = jp_lls(T, mid, nt(j));
            if b(im) > 0.10, lo(j) = mid; else, hi(j) = mid; end
        end
    end
    fprintf(fid,'%4d %8.2f %8.2f %8.2f\n', T.mcs(im), (lo+hi)/2);
end
fclose(fid);

%% ---------------------------------------------------------------- plots
cols = lines(numel(ntr));
figure('Position',[80 80 900 380],'Color','w');
subplot(1,2,1);
semilogy(snr, max(BL,1e-6), 'LineWidth',1.4); grid on; xlim([-40 5]); ylim([1e-6 1]);
xlabel('SNR (dB)'); ylabel('BLER'); box on;
legend(arrayfun(@(n) sprintf('N_{TR} = %d',n), ntr,'UniformOutput',false),'Location','southwest');
title('(a) BLER vs SNR, MCS 0');
subplot(1,2,2);
semilogy(snr, max(SE,1e-4), 'LineWidth',1.4); grid on; xlim([-40 5]); ylim([1e-2 6e-2]);
xlabel('SNR (dB)'); ylabel('Spectral efficiency (bps/Hz)'); box on;
legend(arrayfun(@(n) sprintf('N_{TR} = %d',n), ntr,'UniformOutput',false),'Location','northwest');
title('(b) SE vs SNR, MCS 0');
print(fullfile(out,'j2_fig56_lls.png'),'-dpng','-r160');

fprintf('run_j2 done\n');
