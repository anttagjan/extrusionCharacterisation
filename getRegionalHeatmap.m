function getRegionalHeatmap(filepath)
load(fullfile(filepath,"dataframes",'data_transformed.mat'), "procruste_transformed");
load(fullfile(filepath,"dataframes",'heatmap_data.mat'), "allValidN_full","nBins","heatmapSum","timeStep");

nf_extrusion = dir(fullfile(filepath,'results','*cell_death.zip'));
filenames = {nf_extrusion.name};

totalExtrusions = sum(heatmapSum(:));
fprintf('[INFO] Global number of extrusions: %d\n', totalExtrusions);

movies = unique(procruste_transformed(:,3));
nColors = 256;
cmap = [linspace(1,1,nColors)', linspace(1,0,nColors)', linspace(1,0,nColors)'];
globalMax = prctile(heatmapSum(:), 100);

zoneNames = {'Midline', 'Posterior', 'Up', 'Down'};
zoneColors = [0 0 1; 1 0 0; 0 1 0; 1 1 0]; % blue, red, green, yellow

time = round(procruste_transformed(:,4),4);
timeBins = min(time):timeStep:max(time);

Xall = procruste_transformed(:,1);
Yall = procruste_transformed(:,2);

marginX = 0.05 * (max(Xall) - min(Xall));
marginY = 0.05 * (max(Yall) - min(Yall));
xEdges = linspace(min(Xall)-marginX, max(Xall)+marginX, nBins+1);
yEdges = linspace(min(Yall)-marginY, max(Yall)+marginY, nBins+1);
xCenters = (xEdges(1:end-1) + xEdges(2:end))/2;
yCenters = (yEdges(1:end-1) + yEdges(2:end))/2;

% Try loading previous selection
zoneFile = fullfile(filepath,"dataframes",'selected_zones.mat');
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

% === Combined Excel with Multi-Sheets ===
excelFileName = strcat('HistogramExtrusions_',num2str(round(timeStep*60,4)),'MinTime',num2str(max(movies)),'Movies_Summary.xlsx');
nZones = size(selectedBins,3);
zoneSums = zeros(length(timeBins), nZones); % For summary sheet

for zone = 1:nZones
    zoneMask = selectedBins(:,:,zone);
    countsPerMovie = zeros(length(timeBins), max(movies));

    for nTime = 1:length(timeBins)
        total = 0;
        for nMovie = 1:max(movies)
            histo = allValidN_full{nMovie,nTime};
            histo(isnan(histo)) = 0;
            histoMasked = histo .* zoneMask;
            count = sum(histoMasked(:));
            countsPerMovie(nTime, nMovie) = count;
            total = total + count;
        end
        zoneSums(nTime, zone) = total;
    end

    T = array2table(countsPerMovie, 'VariableNames', filenames);
    T.Time = timeBins(:);
    T = movevars(T, 'Time', 'Before', 1);

    sheetName = zoneNames{zone};
    writetable(T, fullfile(filepath,"dataframes",excelFileName), 'Sheet', sheetName, 'WriteMode', 'overwritesheet');
    fprintf('[INFO] Sheet "%s" exported.\n', sheetName);
end

% === Add Summary Sheet ===
zoneSums(:,nZones+1)=sum(zoneSums,2);
zoneNames{1,nZones+1}='All zones';
Tsum = array2table(zoneSums, 'VariableNames', zoneNames);
Tsum.Time = round(timeBins(:),4);
Tsum = movevars(Tsum, 'Time', 'Before', 1);

% Add final row with global sum
totalRow = array2table(nan(1, width(Tsum)), 'VariableNames', Tsum.Properties.VariableNames);
totalRow{1,2:end} = sum(zoneSums, 1);
totalRow.Time = "Total sum";
TsumFinal = [Tsum; totalRow];

writetable(TsumFinal, fullfile(filepath,"dataframes",excelFileName), 'Sheet', 'Summary', 'WriteMode', 'overwritesheet');
fprintf('[INFO] Summary sheet exported.\n');
end