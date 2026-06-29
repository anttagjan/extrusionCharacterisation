close all;
clear;

filepath = 'D:\Antonio\extrusion systematic characterisation\time_alignment';

[selectedColumn, selectedLandmarks] = askAlignmentMethod();

outputPath = fullfile(filepath,selectedLandmarks,'output_1_50');

if ~exist(outputPath,'dir')
    mkdir(outputPath)
end

fitFile = fullfile(outputPath,'fit_results.mat');

if strcmp(selectedLandmarks, 'speed')
    inPath = fullfile(filepath,'speed');
    span=21;  %window width for smoothing
    inputData = loadPIVData(inPath,span);

elseif strcmp(selectedLandmarks, 'division')
    inPath = fullfile(filepath,'division');
    span = 10;  %window width for smoothing
    inputData = loadDivisionFreqData(inPath,span);
else
    error('Invalid selection');
end

prevFits = [];
if exist(fitFile,'file')
    tmp = load(fitFile,'results');
    prevFits = tmp.results;
    fprintf('Loaded previous fits: %d datasets\n', length(prevFits));
end

results = fitTemporalAlignment(inputData,prevFits);
skippedMask = arrayfun(@(r) isfield(r,'skip') && ~isempty(r.skip) && r.skip, results);
skippedLog = results(skippedMask);
save('skipped_log.mat','skippedLog');

results = results(~skippedMask);
save(fitFile,'results');

runTemporalPlots(results, outputPath);

disp('DONE');