function getRegionalHeatmap(filepath)
    load(fullfile(filepath,'data_transformed.mat'));
    load(fullfile(filepath,'heatmap_data.mat'), "allValidN_full","nBins","heatmapSum");
    %% === Display of the total number of extrusions ===
    totalExtrusions = sum(heatmapSum(:));
    fprintf('[INFO] Global number of extrusions: %d\n', totalExtrusions);

    movies = unique(procruste_transformed(:,3));
    % Colours
    nColors = 256;
    cmap = [linspace(1,1,nColors)', linspace(1,0,nColors)', linspace(1,0,nColors)'];
    globalMax = prctile(heatmapSum(:), 100);

    selectedBins = false(nBins, nBins, 4);
    zoneNames = {'Midline', 'Posterior', 'Up', 'Down'};
    zoneColors = [0 0 1; 1 0 0; 0 1 0; 1 1 0]; % bleu, rouge, vert, jaune

        time = unique(procruste_transformed(:,4));
    timeStep = 1;
    nBins = 30;
    edges = floor(min(time)):timeStep:ceil(max(time));

    Xall = procruste_transformed(:,1);
    Yall = procruste_transformed(:,2);

    % Calcul plus robuste des bords avec marge relative (1%)
    % Calcul des bords en tenant compte d’un offset vertical
    yOffset = -99; % décalage vers le haut (à ajuster)

    xEdges = linspace(min(Xall)*0.80, max(Xall)*1.2, nBins+1);
    yEdges = linspace(min(Yall), max(Yall), nBins+1) + yOffset;

    xCenters = (xEdges(1:end-1) + xEdges(2:end))/2;
    yCenters = (yEdges(1:end-1) + yEdges(2:end))/2;

    %% Figure
    fig = figure('Color','w', 'Name','Global Heatmap - Selection of 4 zones', 'Position', [100 100 1000 800]);
    set(fig, 'CloseRequestFcn', @closeFigureCallback);

    imagesc(xCenters, yCenters, heatmapSum);
    axis xy;

    % Display of the number of extrusions in each bin
    for i = 1:nBins
        for j = 1:nBins
            count = heatmapSum(i,j);
            if count > 0
                text(xCenters(j), yCenters(i), num2str(count), ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontSize', 8, ...
                    'Color', 'k');
            end
        end
    end

    colormap(cmap);
    colorbar;
    clim([0 globalMax]);
    xlabel('X');
    ylabel('Y');

    activeZone = 1;
    title({'Global Heatmap (spatio-temporal alignment of all movies)', ...
           ['Selected Zone : ' zoneNames{activeZone}], ...
           'Click left: add region, click right: remove region, press 1-4 keys to change zone'});

    hold on;
    for z = 1:4
        plot(nan, nan, 's', 'MarkerFaceColor', zoneColors(z,:), 'MarkerEdgeColor', 'k', ...
             'DisplayName', zoneNames{z}, 'MarkerSize', 10);
    end
    legend('Location', 'eastoutside');

    hSelected = imagesc(xCenters, yCenters, zeros(nBins, nBins, 3));
    set(hSelected, 'AlphaData', zeros(nBins, nBins));
    hold off;

    % Save data for callbacks
    data.xCenters = xCenters;
    data.yCenters = yCenters;
    data.selectedBins = selectedBins;
    data.hSelected = hSelected;
    data.activeZone = activeZone;
    data.nBins = nBins;
    data.zoneNames = zoneNames;
    data.zoneColors = zoneColors;
    data.isDragging = false;
    data.dragAction = 'add';
    guidata(fig, data);

    set(fig, 'WindowKeyPressFcn', @keyPressCallback);
    set(hSelected, 'ButtonDownFcn', @mouseDownCallback);
    set(fig, 'WindowButtonUpFcn', @mouseUpCallback);
    set(fig, 'WindowButtonMotionFcn', @mouseMoveCallback);

    waitfor(fig);

    data = getappdata(0, 'zoneSelectionData');
    selectedBins = data.selectedBins;

    % Save results from each zone in CSV files
    nZones = 4;
    nMovie = max(movies);
    timeLabels = edges(1:end-1) + timeStep/2;

    fileNames = evalin('base', 'filenames');
    if iscell(fileNames)
        fileNames = string(fileNames);
    elseif ischar(fileNames)
        fileNames = string(cellstr(fileNames));
    end
    if size(fileNames, 1) == 1
        fileNames = fileNames';
    end

    for zone = 1:nZones
        zoneMask = selectedBins(:,:,zone);
        countsPerMovie = zeros(length(timeLabels), nMovie);

        for nTime = 1:length(timeLabels)
            for n = 1:nMovie
                histo = allValidN_full{n,nTime};
                noValidHisto = isnan(histo);
                histo(noValidHisto==1)=0;
                histoMasked = histo .* zoneMask;
                countsPerMovie(nTime, n) = sum(histoMasked(:));
            end
        end

        T = array2table(countsPerMovie, 'VariableNames', fileNames);
        T.Time = timeLabels(:);
        T = movevars(T, 'Time', 'Before', 1);

        filenameOut = sprintf('Histogram2D_TimeXMovie_%s.csv', zoneNames{zone});
        writetable(T, filenameOut, 'Delimiter', ';');
        fprintf('Exporté : %s\n', filenameOut);
    end
end

function mouseDownCallback(src, ~)
    fig = ancestor(src, 'figure');
    data = guidata(fig);
    data.isDragging = true;

    clickType = get(fig, 'SelectionType');
    if strcmp(clickType, 'normal')
        data.dragAction = 'add';
    elseif strcmp(clickType, 'alt')
        data.dragAction = 'remove';
    else
        data.dragAction = 'none';
    end

    guidata(fig, data);
    applySelection(fig);
end

function mouseUpCallback(src, ~)
    fig = src;
    data = guidata(fig);
    data.isDragging = false;
    guidata(fig, data);
end

function mouseMoveCallback(src, ~)
    fig = src;
    data = guidata(fig);
    if data.isDragging
        applySelection(fig);
    end
end

function applySelection(fig)
    data = guidata(fig);
    if strcmp(data.dragAction, 'none')
        return;
    end
    ax = gca;
    pt = get(ax, 'CurrentPoint');
    xClick = pt(1,1);
    yClick = pt(1,2);

    [~, ix] = min(abs(data.xCenters - xClick));
    [~, iy] = min(abs(data.yCenters - yClick));

    if ix < 1 || ix > data.nBins || iy < 1 || iy > data.nBins
        return;
    end

    selBins = data.selectedBins(:,:,data.activeZone);

    if strcmp(data.dragAction, 'add')
        selBins(iy, ix) = true;
    elseif strcmp(data.dragAction, 'remove')
        selBins(iy, ix) = false;
    end

    data.selectedBins(:,:,data.activeZone) = selBins;

    alphaMap = zeros(size(selBins));
    imgRGB = zeros([size(selBins), 3]);

    for z = 1:4
        mask = data.selectedBins(:,:,z);
        for c = 1:3
            imgRGB(:,:,c) = imgRGB(:,:,c) + mask * data.zoneColors(z,c);
        end
        alphaMap = max(alphaMap, mask*0.5);
    end

    set(data.hSelected, 'CData', imgRGB);
    set(data.hSelected, 'AlphaData', alphaMap);

    guidata(fig, data);
end

function keyPressCallback(src, event)
    data = guidata(src);
    switch event.Key
        case {'1','2','3','4'}
            data.activeZone = str2double(event.Key);
            title({'Global Heatmap (spatio-temporal alignment of all movies)', ...
                ['Selected Zone : ' data.zoneNames{data.activeZone}], ...
                'Click left: add region, click right: remove region, press 1-4 keys to change zone'});
            guidata(src, data);
    end
end

function closeFigureCallback(src, ~)
    data = guidata(src);
    setappdata(0, 'zoneSelectionData', data);
    delete(src);
end
