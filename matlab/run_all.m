function run_all(what)
%RUN_ALL  Single entry point for every experiment in this repository.
%
%   run_all            run everything (about 6 min, Fig. 13/14 dominate)
%   run_all('fig4')    Fig. 4, Table 5 and Table 6: theory and link budget   ~10 s
%   run_all('fig5')    Fig. 5 and Fig. 6: BLER and spectral efficiency       ~5 s
%   run_all('fig9')    Fig. 9 and Fig. 10: PAA and JPTA codebooks            ~30 s
%   run_all('fig12')   Fig. 12, Fig. 13 and Fig. 14: system level            ~5 min
%   run_all('compare') point-by-point table against the paper (needs fig12)
%
%   Every job writes its figures and tables into matlab/out/.

if nargin < 1 || isempty(what), what = 'all'; end
here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fullfile(here,'core'));
addpath(fullfile(here,'alg'));

% key, script, kind ('f' = function file, 's' = script file), description
jobs = {
    'fig4',    'run_j1', 's', 'Fig. 4 (coverage vs K), Table 5 (link budget), Table 6 (delay)'
    'fig5',    'run_j2', 's', 'Fig. 5 and Fig. 6: BLER and spectral efficiency vs SNR'
    'fig9',    'run_j3', 's', 'Fig. 9 (32-beam PAA) and Fig. 10 (rainbow beams)'
    'fig12',   'run_j4', 's', 'Fig. 12 (best MCS), Fig. 13 (THz) and Fig. 14 (mmWave)'
    'compare', 'run_j5', 's', 'point-by-point comparison table, needs out/j4_sls.mat'
};

if strcmpi(what,'all')
    sel = true(size(jobs,1),1);
else
    sel = strcmpi(jobs(:,1), what);
    if ~any(sel)
        fprintf('known jobs: all, %s\n', strjoin(jobs(:,1).', ', '));
        return
    end
end

for k = find(sel).'
    fprintf('\n########## %s : %s ##########\n', jobs{k,1}, jobs{k,4});
    t0 = tic;
    switch jobs{k,3}
        case 'f', feval(jobs{k,2});
        case 's', evalin('base', sprintf('run(''%s'')', fullfile(here,[jobs{k,2} '.m'])));
        %  A script file runs in the workspace of its caller, so it would overwrite the
        %  loop index and the timer of this function.  Evaluating it in the base workspace
        %  keeps run_all itself intact; all paths are global, so nothing else is needed.
    end
    fprintf('########## %s done in %.1f s ##########\n', jobs{k,1}, toc(t0));
end
