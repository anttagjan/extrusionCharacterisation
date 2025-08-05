function selectedBins = interactiveZoneSelector(heatmapSum, xCenters, yCenters, nBins, zoneNames, zoneColors)
    % Interactive zone selection GUI
    selectedBins = false(nBins, nBins, 4);

    fig = figure('Color','w', 'Name','Global Heatmap - Selection of 4 zones', 'Position', [100 100 1000 800]);
    set(fig, 'CloseRequestFcn', @closeFigureCallback);

    imagesc(xCenters, yCenters, heatmapSum);
    axis xy

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

    colormap([linspace(1,1,256)', linspace(1,0,256)', linspace(1,0,256)']);
    colorbar;
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