function getRegionalHeatmap( ...
        filepath,...
        filenames,...
        selectedLandmarks,...
        events_transformed,...
        allData,...
        Rglobal,...
        summary,...
        params,...
        eventName)


persistent one_time_execution %Variable pour executer une seule fois
if isempty(one_time_execution)
    one_time_execution = "true";
end


if strcmp(eventName,'extrusions')
    heatmapSum = summary.totalExtr;
else
    heatmapSum = summary.totalDiv;
end

eventDist = cell(size(allData));

for i = 1:size(allData,1)
    for j = 1:size(allData,2)

        d = allData{i,j};

        if isempty(d)
            continue
        end

        if isfield(d,eventName)
            eventDist{i,j} = d.(eventName).count;
        end
    end
end

totalEvents = sum(heatmapSum(:),'omitnan');

fprintf('\n[INFO] Global number of %s: %d\n', ...
    eventName,...
    totalEvents);

movies = unique(events_transformed(:,4));
timeStep = params.timeStep;
nBins = params.nBins;

nColors = 256;
cmap = [linspace(1,1,nColors)', linspace(1,0,nColors)', linspace(1,0,nColors)'];
globalMax = prctile(heatmapSum(:), 100);

zoneNames = {'Midline', 'Posterior', 'Up', 'Down'};
zoneColors = [0 0 1; 1 0.5 0; 0 1 0; 1 1 0]; % blue, orange, green, yellow

time = round(events_transformed(:,3),4);
timeBins = floor(min(time)):timeStep:ceil(max(time));

spatialGrid.nBins = params.nBins;

spatialGrid.xEdges = linspace( ...
    Rglobal.XWorldLimits(1), ...
    Rglobal.XWorldLimits(2), ...
    params.nBins+1);

spatialGrid.yEdges = linspace( ...
    Rglobal.YWorldLimits(1), ...
    Rglobal.YWorldLimits(2), ...
    params.nBins+1);
xCenters = (spatialGrid.xEdges (1:end-1) + spatialGrid.xEdges (2:end))/2;
yCenters = (spatialGrid.yEdges (1:end-1) + spatialGrid.yEdges (2:end))/2;


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
[rows, cols] = size(eventDist);

always_nan_mask = true(nBins, nBins);

for i = 1:rows
    for j = 1:cols

        current_matrix = eventDist{i,j};

        if isempty(current_matrix)
            continue
        end

        if ~isequal(size(current_matrix), [nBins nBins])
            continue
        end

        always_nan_mask = ...
            always_nan_mask & isnan(current_matrix);

    end
end

% always_nan_mask is now 30x30, true at positions that are NaN in *all* 15x57 cells



if one_time_execution == "true"
    figure,
    imagesc(always_nan_mask); axis image;colorbar; colormap gray;
    title('Bins that are always NaN in all cells');
    one_time_execution = "false";


elseif one_time_execution == "false" %% PARTIE A REVOIR: POUR QUE DIVISION CALCUL AUSSI POUR MALE
    one_time_execution = "test";
elseif one_time_execution == "test"
    one_time_execution = "true";
end

%% Excel files
% === Combined Excel with Multi-Sheets ===
eventLabel = lower(eventName);
eventLabel(1) = upper(eventLabel(1));

excelFileName = strcat( ...
    'Histogram', ...
    eventLabel, '_', ...
    num2str(nBins), 'x', num2str(nBins), '_', ...
    num2str(round(timeStep,4)), 'hStep', ...
    num2str(max(movies)), 'Movies_', ...
    selectedLandmarks, ...
    'Alignment_Summary.xlsx');

excelFileNameNaN = strcat( ...
    'HistogramNormalised', ...
    eventLabel, '_', ...
    num2str(nBins), 'x', num2str(nBins), '_', ...
    num2str(round(timeStep,4)), 'hStep', ...
    num2str(max(movies)), 'Movies_', ...
    selectedLandmarks, ...
    'Alignment_Summary.xlsx');



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
            histo = eventDist{nMovie,nTime};
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


if strcmp(eventName,'extrusions') %Export qu'une fois
    exportFeatureDistributions( ...
        filepath, filenames, allData, selectedBins, timeBins);
end 

end