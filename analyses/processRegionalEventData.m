function processRegionalEventData( ...
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

featuresFileName = strcat( ...
    'Histogram_', ...
    'Features', '_', ...
    num2str(nBins), 'x', num2str(nBins), '_', ...
    num2str(round(timeStep,4)), 'hStep', ...
    num2str(max(movies)), 'Movies_', ...
    selectedLandmarks, ...
    'Alignment_Summary.xlsx');

nZones = size(selectedBins,3);

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

                validMask = zoneMask & ~isnan(histo);

                nValidBins = sum(validMask(:));
                nZoneBins  = sum(zoneMask(:));

                if nValidBins > 0
                    count = sum(histo(validMask), 'omitnan');
                    countsPerMovie(nTime, nMovie) = count;

                    fracValid = nValidBins / nZoneBins;
                    normCountsPerMovie(nTime, nMovie) = count / fracValid;
                else
                    countsPerMovie(nTime, nMovie) = NaN;
                    normCountsPerMovie(nTime, nMovie) = NaN;
                end

            else
                countsPerMovie(nTime, nMovie) = NaN;
                normCountsPerMovie(nTime, nMovie) = NaN;
            end

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

% === Add Global Sheet ===
allMask = true(nBins, nBins);
allMask(always_nan_mask == 1) = 0;

allCountsPerMovie     = NaN(length(timeBins), max(movies));
allNormCountsPerMovie = NaN(length(timeBins), max(movies));

for nTime = 1:length(timeBins)
    for nMovie = 1:max(movies)

        histo = eventDist{nMovie, nTime};

        if isempty(histo)
            continue
        end

        validMask = allMask & ~isnan(histo);

        nValidBins = sum(validMask(:));
        nAllBins   = sum(allMask(:));

        if nValidBins > 0
            count = sum(histo(validMask), 'omitnan');
            allCountsPerMovie(nTime, nMovie) = count;

            fracValid = nValidBins / nAllBins;
            allNormCountsPerMovie(nTime, nMovie) = count / fracValid;
        end
    end
end

% RAW ALL
Tall = array2table(allCountsPerMovie, 'VariableNames', filenames);
Tall.Time = round(timeBins(:), 4);
Tall = movevars(Tall, 'Time', 'Before', 1);

writetable(Tall, fullfile(filepath,"dataframes",excelFileName), ...
    'Sheet', 'All', 'WriteMode', 'overwritesheet');
fprintf('[INFO] Sheet "All" exported.\n');

% NORMALISED ALL
TallNorm = array2table(allNormCountsPerMovie, 'VariableNames', filenames);
TallNorm.Time = round(timeBins(:), 4);
TallNorm = movevars(TallNorm, 'Time', 'Before', 1);

writetable(TallNorm, fullfile(filepath,"dataframes",excelFileNameNaN), ...
    'Sheet', 'All', 'WriteMode', 'overwritesheet');
fprintf('[INFO] Sheet "All" exported to %s.\n', excelFileNameNaN);

if strcmp(eventName,'extrusions') %Export once
    exportFeatureDistributions( ...
        filepath, filenames,featuresFileName, allData, selectedBins, timeBins);
end 

end