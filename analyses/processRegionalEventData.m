function processRegionalEventData( ...
        filepath,...
        filenames,...
        selectedLandmarksAndSex,...
        events_transformed,...
        binnedData,...
        Rglobal,...
        summary,...
        params,...
        eventName,...
        keepMovies, ...
        selectedLandmarks)

timeStep = params.timeStep;
nBins = params.nBins;

persistent one_time_execution %Variable pour executer une seule fois
if isempty(one_time_execution)
    one_time_execution = "true";
end

if strcmp(eventName,'extrusions')
    heatmapSum = summary.totalExtr;
else
    heatmapSum = summary.totalDiv;
end

eventDist = cell(size(binnedData));

for i = 1:size(binnedData,1)
    for j = 1:size(binnedData,2)

        d = binnedData{i,j};

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
filenamesSex = filenames(keepMovies);
movieIDs = find(keepMovies);

nColors = 256;
cmap = [linspace(1,1,nColors)', linspace(1,0,nColors)', linspace(1,0,nColors)'];
globalMax = prctile(heatmapSum(:), 100);

zoneNames = {'Midline', 'Posterior', 'Up', 'Down'};
zoneColors = [0 0 1; 1 0.5 0; 0 1 0; 1 1 0]; % blue, orange, green, yellow

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
persistent zoneSelectionDone selectedBinsCache zoneFileCache

if isempty(zoneSelectionDone)
    zoneSelectionDone = false;
    selectedBinsCache = [];
    zoneFileCache = "";
end
zoneFile = fullfile(filepath,"dataframes","selectedZones",strcat(selectedLandmarks,'_selected_zones.mat'));
selectedBins = false(nBins, nBins, 4);
useSavedZones = false;

if zoneSelectionDone && ~isempty(selectedBinsCache) ...
        && isequal(zoneFileCache, zoneFile)

    selectedBins = selectedBinsCache;
    useSavedZones = true;

    fprintf('[INFO] Using cached zone selection (no reload)\n');

elseif exist(zoneFile, 'file')

    userChoice = questdlg('Previously selected zones found. Load and skip selection?', ...
        'Load Saved Zones', 'Yes', 'No', 'Yes');

    if strcmp(userChoice, 'Yes')

        s = load(zoneFile, 'selectedBins', 'zoneNames');

        if isfield(s, 'selectedBins') && isequal(size(s.selectedBins), [nBins nBins 4])
            selectedBins = s.selectedBins;

            % cache it for this session
            selectedBinsCache = selectedBins;
            zoneFileCache = zoneFile;
            zoneSelectionDone = true;

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

    % cache for session
    selectedBinsCache = selectedBins;
    zoneFileCache = zoneFile;
    zoneSelectionDone = true;

    fprintf('[INFO] Saved zone selection to %s\n', zoneFile);
end

% if one_time_execution == "true"
%     one_time_execution = "false";
% elseif one_time_execution == "false" %% PARTIE A REVOIR: POUR QUE DIVISION CALCUL AUSSI POUR MALE
%     one_time_execution = "test";
% elseif one_time_execution == "test"
%     one_time_execution = "true";
% end

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
    selectedLandmarksAndSex, ...
    'Alignment_Summary.xlsx');

featuresFileName = strcat( ...
    'Histogram_', ...
    'Features', '_', ...
    num2str(nBins), 'x', num2str(nBins), '_', ...
    num2str(round(timeStep,4)), 'hStep', ...
    num2str(max(movies)), 'Movies_', ...
    selectedLandmarksAndSex, ...
    'Alignment_Summary.xlsx');

nZones = size(selectedBins,3);

for zone = 1:nZones
    zoneMask = selectedBins(:,:,zone);
    countsPerMovie = zeros(length(params.timeBins), max(movies));

    if sum(sum(zoneMask))==0
        continue
    end

    for nTime = 1:length(params.timeBins)

        for k = 1:length(movieIDs)

            nMovie = movieIDs(k);
            histo = eventDist{nMovie,nTime};
                % Count values
            if ~isempty(histo)

                validMask = zoneMask & ~isnan(histo);
                nValidBins = sum(validMask(:));

                if nValidBins > 0
                    count = sum(histo(validMask), 'omitnan');
                    countsPerMovie(nTime, nMovie) = count;
                else
                    countsPerMovie(nTime, nMovie) = NaN;
                end

            else
                countsPerMovie(nTime, nMovie) = NaN;
            end

        end
    end
    T = array2table( ...
        countsPerMovie(:,keepMovies), ...
        'VariableNames', filenamesSex);
    T.Time = round(params.timeBins(:), 4);
    T = movevars(T, 'Time', 'Before', 1);
    sheetName = zoneNames{zone};
    writetable(T, fullfile(filepath,"dataframes",excelFileName), 'Sheet', sheetName, 'WriteMode', 'overwritesheet');
    fprintf('[INFO] Sheet "%s" exported.\n', sheetName);

end

% === Add Global Sheet ===
allCountsPerMovie     = NaN(length(params.timeBins), max(movies));

for nTime = 1:length(params.timeBins)
    for k = 1:length(movieIDs)

        nMovie = movieIDs(k);

        histo = eventDist{nMovie, nTime};

        if isempty(histo)
            continue
        end

        validMask = ~isnan(histo);

        nValidBins = sum(validMask(:));

        if nValidBins > 0
            count = sum(histo(validMask), 'omitnan');
            allCountsPerMovie(nTime, nMovie) = count;
        end
    end
end

% RAW ALL
Tall = array2table( ...
        allCountsPerMovie(:,keepMovies), ...
        'VariableNames', filenamesSex);
Tall.Time = round(params.timeBins(:), 4);
Tall = movevars(Tall, 'Time', 'Before', 1);

writetable(Tall, fullfile(filepath,"dataframes",excelFileName), ...
    'Sheet', 'All', 'WriteMode', 'overwritesheet');
fprintf('[INFO] Sheet "All" exported.\n');

if strcmp(eventName,'extrusions') %Export once
    exportFeatureDistributions( ...
        filepath, filenames,featuresFileName, binnedData, selectedBins, params.timeBins, keepMovies);
end 

end