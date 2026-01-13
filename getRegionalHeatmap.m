function getRegionalHeatmap(filepath,filenames,selectedLandmarks,procruste_transformed,allValidN_full,heatmapSum,nBins,timeStep)
totalExtrusions = sum(heatmapSum(:));
fprintf('[INFO] Global number of extrusions: %d\n', totalExtrusions);

movies = unique(procruste_transformed(:,3));
nColors = 256;
cmap = [linspace(1,1,nColors)', linspace(1,0,nColors)', linspace(1,0,nColors)'];
globalMax = prctile(heatmapSum(:), 100);

zoneNames = {'Midline', 'Posterior', 'Up', 'Down'};
zoneColors = [0 0 1; 1 0.5 0; 0 1 0; 1 1 0]; % blue, orange, green, yellow

time = round(procruste_transformed(:,4),4);
timeBins = floor(min(time)):timeStep:ceil(max(time));

Xall = procruste_transformed(:,1);
Yall = procruste_transformed(:,2);

marginX = 0.05 * (max(Xall) - min(Xall));
marginY = 0.05 * (max(Yall) - min(Yall));
xEdges = linspace(min(Xall)-marginX, max(Xall)+marginX, nBins+1);
yEdges = linspace(min(Yall)-marginY, max(Yall)+marginY, nBins+1);
xCenters = (xEdges(1:end-1) + xEdges(2:end))/2;
yCenters = (yEdges(1:end-1) + yEdges(2:end))/2;

% Try loading previous selection
zoneFile = fullfile(filepath,"dataframes","selectedZones",strcat(selectedLandmarks,'_selected_zones.mat'));
selectedBins = false(nBins, nBins, 4);
useSavedZones = false;
if exist(zoneFile, 'file')
    userChoice = questdlg('Previously selected zones found. Load and skip selection?', ...
        'Load Saved Zones', 'Yes', 'No', 'Yes');
    if strcmp(userChoice, 'Yes')
        s = load(zoneFile, 'selectedBins', 'zoneNames');
        if isfield(s, 'selectedBins') && isequal(size(s.selectedBins), [nBins nBins 4])
            selectedBins = s.selectedBins;
            fprintf('[INFO] Loaded saved zone selection from selected_zones.mat\n');
            useSavedZones = true;
        else
            warning('[WARN] Zone file found but format invalid. Ignoring.');
        end
    end
end

if ~useSavedZones
    % Launch interactive selection
    selectedBins = interactiveZoneSelector(heatmapSum, xCenters, yCenters, nBins, ...
        zoneNames, zoneColors);
   
    % Save to reuse later
    save(zoneFile, 'selectedBins', 'zoneNames');
    fprintf('[INFO] Saved zone selection to %s\n', zoneFile);
end
%%
% Assume your data is called:
% C: 15x57 cell array, each cell is a 30x30 double matrix

% Step 1: Get size
[rows, cols] = size(allValidN_full);  % rows=15, cols=57

% Step 2: Initialize a logical mask — true where all are NaN
always_nan_mask = true(nBins, nBins);  % start assuming all are NaN

% Step 3: Loop through the cell array and update the mask
for i = 1:rows
    for j = 1:cols
        current_matrix = allValidN_full{i,j};
        % Update mask: keep only positions that are still NaN
        always_nan_mask = always_nan_mask & isnan(current_matrix);
    end
end

% always_nan_mask is now 30x30, true at positions that are NaN in *all* 15x57 cells
figure,
imagesc(always_nan_mask); axis image;colorbar; colormap gray;
title('Bins that are always NaN in all cells');

%% Excel files
% === Combined Excel with Multi-Sheets ===
excelFileName = strcat('HistogramExtrusions_',num2str(nBins),'x',num2str(nBins),'_',num2str(round(timeStep,4)),'hStep',num2str(max(movies)),'Movies_',selectedLandmarks,'Alignment_Summary.xlsx');
excelFileNameNaN = strcat('HistogramNormalisedExtrusions_',num2str(nBins),'x',num2str(nBins),'_',num2str(round(timeStep,4)),'hStep',num2str(max(movies)),'Movies_',selectedLandmarks,'Alignment_Summary.xlsx');
nZones = size(selectedBins,3);
summaryCounts = zeros(length(timeBins), max(movies));
summaryNormCounts = zeros(length(timeBins), max(movies));
% zoneSums = zeros(length(timeBins), nZones); % For summary sheet
% zoneSumsNaN = zeros(length(timeBins), nZones);  % For summary sheet (NaNs)

for zone = 1:nZones
    zoneMask = selectedBins(:,:,zone);
    zoneMask(always_nan_mask==1)=0;
    countsPerMovie = zeros(length(timeBins), max(movies));
    normCountsPerMovie = zeros(length(timeBins), max(movies));
    if sum(sum(zoneMask))==0
        continue
    end

    for nTime = 1:length(timeBins)
        count = 0;
        normCount= 0;
        for nMovie = 1:max(movies)
            histo = allValidN_full{nMovie,nTime};
                % Count values
            if ~isempty(histo)
                % Count valid
                maskedHisto = histo;
                maskedHisto(isnan(maskedHisto)) = 0;
                maskedHisto = maskedHisto .* zoneMask;
                count = sum(maskedHisto(:));
                countsPerMovie(nTime, nMovie) = count;

                % Count NaNs
                nanMask = isnan(histo) & zoneMask;
                nanCount = sum(nanMask(:))/sum(zoneMask(:));
                
                if nanCount < 1
                normCount = count/(1-nanCount);
                normCountsPerMovie(nTime, nMovie) = normCount;
                else
                normCount = NaN;
                normCountsPerMovie(nTime, nMovie) = normCount; 
                end
            else
                % If histogram is empty (rare), treat entire zone as NaNs
                countsPerMovie(nTime, nMovie) = 0;
                normCountsPerMovie(nTime, nMovie) = 0;
            end

            summaryCounts(nTime, nMovie) = summaryCounts(nTime, nMovie) + count;
            summaryNormCounts(nTime, nMovie) = summaryNormCounts(nTime, nMovie) + normCount;
        end
    end
    T = array2table(countsPerMovie, 'VariableNames', filenames);
    T.Time = round(timeBins(:), 4);
    T = movevars(T, 'Time', 'Before', 1);
    sheetName = zoneNames{zone};
    writetable(T, fullfile(filepath,"dataframes",excelFileName), 'Sheet', sheetName, 'WriteMode', 'overwritesheet');
    fprintf('[INFO] Sheet "%s" exported.\n', sheetName);

     % Save NaN counts table
    T_normalised = array2table(normCountsPerMovie, 'VariableNames', filenames);
    T_normalised.Time = round(timeBins(:), 4);
    T_normalised = movevars(T_normalised, 'Time', 'Before', 1);
    writetable(T_normalised, fullfile(filepath, "dataframes", excelFileNameNaN), ...
               'Sheet', sheetName, 'WriteMode', 'overwritesheet');
    fprintf('[INFO] Sheet "%s" exported to %s.\n', sheetName, excelFileNameNaN);
end

% === Add Summary Sheet ===
Tsum_counts = array2table(summaryCounts, 'VariableNames', filenames);
Tsum_counts.Time = timeBins(:);
Tsum_counts = movevars(Tsum_counts, 'Time', 'Before', 1);
totalRow = array2table(nan(1, width(Tsum_counts)), 'VariableNames', Tsum_counts.Properties.VariableNames);
totalRow{1,2:end} = sum(summaryCounts,1); 
totalRow.Time = "Total sum";
TsumFinal = [Tsum_counts; totalRow];

writetable(TsumFinal, fullfile(filepath, "dataframes", excelFileName), ...
           'Sheet', 'Summary', 'WriteMode', 'overwritesheet');
fprintf('[INFO] Summary sheet exported.\n');

%% === Summary Sheet for NaN Counts ===
Tsum_nan = array2table(summaryNormCounts, 'VariableNames', filenames);
Tsum_nan.Time = timeBins(:);
Tsum_nan = movevars(Tsum_nan, 'Time', 'Before', 1);
totalRowNorm = array2table(nan(1, width(Tsum_nan)), 'VariableNames', Tsum_nan.Properties.VariableNames);
totalRowNorm{1,2:end} = sum(summaryNormCounts, 1, 'omitnan'); 
totalRowNorm.Time = "Total sum";
TsumNaNFinal = [Tsum_nan; totalRowNorm];

writetable(TsumNaNFinal, fullfile(filepath, "dataframes", excelFileNameNaN), ...
           'Sheet', 'Summary_normalised', 'WriteMode', 'overwritesheet');
fprintf('[INFO] Summary_normalised sheet exported.\n');
end