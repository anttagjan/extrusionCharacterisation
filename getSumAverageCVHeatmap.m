function getSumAverageCVHeatmap(filepath)

    load(fullfile(filepath,'dataframes','data_transformed.mat'), "procruste_transformed");
    load(fullfile(filepath,'dataframes','heatmap_data.mat'), "allValidN_full","nBins","timeStep");

    movies = unique(procruste_transformed(:,3));
    nMovies = max(movies);

    Xall = procruste_transformed(:,1);
    Yall = procruste_transformed(:,2);

    % Calculation of edges taking into account a small margin or padding to the
    % edges
    marginX = 0.01 * (max(Xall) - min(Xall));
    marginY = 0.01 * (max(Yall) - min(Yall));

    xEdges = linspace(min(Xall)-marginX, max(Xall)+marginX, nBins+1);
    yEdges = linspace(min(Yall)-marginY, max(Yall)+marginY, nBins+1);

    xCenters = (xEdges(1:end-1) + xEdges(2:end))/2;
    yCenters = (yEdges(1:end-1) + yEdges(2:end))/2;

    time = round(procruste_transformed(:,4),4);
    tMin = min(time);
    tMax = max(time);

    nTimeBins = size(allValidN_full, 2);
    timeBins = min(time):timeStep:max(time)+timeStep;
    % timeBins = linspace(tMin, tMax, nTimeBins+1);
    timeCenters = timeBins(1:end-1) + timeStep / 2;

    % Create figure and axis
    fig = figure('Name', 'Interactive Heatmap Viewer', 'Color', 'w', ...
                 'Position', [100, 100, 800, 700]);
    ax = axes('Parent', fig, 'Position', [0.1, 0.3, 0.8, 0.65]);

    % UI: Popup to choose data type
    popup = uicontrol('Style', 'popupmenu', 'String', {'CV', 'Mean', 'Sum'}, ...
        'Units', 'normalized', 'Position', [0.1 0.22 0.2 0.05], ...
        'Callback', @(src,~) updateHeatmap());

    % UI: Sliders and labels
    frameStep = timeStep;
    sliderRange = tMax - tMin;
    smallStep = frameStep / sliderRange;

    sliderMin = uicontrol('Style', 'slider', 'Units', 'normalized', ...
        'Position', [0.1 0.12 0.3 0.04], ...
        'Min', tMin, 'Max', tMax, 'Value', tMin, ...
        'SliderStep', [smallStep, 5*smallStep], ...
        'Callback', @(src,~) updateHeatmap());

    labelMin = uicontrol('Style','text','Units','normalized','Position',[0.1 0.07 0.3 0.03], ...
        'String', sprintf('Start time: %.2f h', tMin));

    sliderMax = uicontrol('Style', 'slider', 'Units', 'normalized', ...
        'Position', [0.5 0.12 0.3 0.04], ...
        'Min', tMin, 'Max', tMax, 'Value', tMax, ...
        'SliderStep', [smallStep, 5*smallStep], ...
        'Callback', @(src,~) updateHeatmap());

    labelMax = uicontrol('Style','text','Units','normalized','Position',[0.5 0.07 0.3 0.03], ...
        'String', sprintf('End time: %.2f h', tMax));

    % Initial display
    updateHeatmap();

    % --- Nested update function ---
    function updateHeatmap()
        tStart = sliderMin.Value;
        tEnd = sliderMax.Value;

        if tStart > tEnd
            tmp = tStart;
            tStart = tEnd;
            tEnd = tmp;
            sliderMin.Value = tStart;
            sliderMax.Value = tEnd;
        end

        labelMin.String = sprintf('Start time: %.2f h', tStart);
        labelMax.String = sprintf('End time: %.2f h', tEnd);

        filteredHistograms = zeros(nBins, nBins, nMovies);
        for nMovie = 1:nMovies
            sumHisto = zeros(nBins, nBins);
            validHisto = zeros(nBins);
            for t = 1:nTimeBins
                currentTime = timeCenters(t);
                if currentTime >= tStart && currentTime < tEnd + eps
                    h = allValidN_full{nMovie, t};
                   
                    if isempty(h)
                        continue;
                    end

                    nanMask = ~isnan(h);
                    temp = h;
                    temp(~nanMask) = 0;
                    sumHisto = sumHisto + temp;
                    validHisto = validHisto + nanMask;
                end
            end
            sumHisto(validHisto == 0) = NaN;
            filteredHistograms(:,:,nMovie) = sumHisto;
        end

        % Compute CV, mean, sum
        meanHist = mean(filteredHistograms, 3, 'omitnan');
        stdHist = std(filteredHistograms, 0, 3, 'omitnan');
        cvHist = 100 * stdHist ./ meanHist;
        cvHist(isnan(cvHist)) = 0;
        sumHist = sum(filteredHistograms, 3, 'omitnan');

        % Choose which to display
        val = popup.Value;
        cb = colorbar;
switch val
    case 1  % CV
        dataToShow = cvHist;
        titleStr = sprintf('CV [%.2f – %.2f] h', tStart, tEnd);
        cmap = customCvColormap();
        cb.Label.String = 'Coefficient of Variation (%)';
    case 2  % Mean
        dataToShow = meanHist;
        titleStr = sprintf('Mean [%.2f – %.2f] h', tStart, tEnd);
        cmap = customRedColormap();
        cb.Label.String = 'average no. extrusions';
    case 3  % Sum
        dataToShow = sumHist;
        titleStr = sprintf('Sum [%.2f – %.2f] h', tStart, tEnd);
        cmap = customRedColormap();
        cb.Label.String = 'no. extrusions';
end

% Compute color limits dynamically based on visible data
nonNanVals = dataToShow(~isnan(dataToShow));
if isempty(nonNanVals)
    clim = [0 1];  % fallback
else
    clim = [min(nonNanVals), max(nonNanVals)];
    % Optional: soften extremes using percentiles
    clim = prctile(nonNanVals, [2 98]);
end

        % Display
        cla(ax, 'reset');
        imagesc(ax, xCenters, yCenters, dataToShow);
        colormap(ax, cmap);       % <-- Now applied after imagesc
        caxis(ax, clim);
        axis(ax, 'ij');
        xlabel(ax, 'X');
        ylabel(ax, 'Y');
        title(ax, titleStr);
        colorbar(ax);
    end
end

% --- Colormap functions ---
function cmap = customCvColormap()
    nColors = 256;
    startColor = [1 1 1];     % white
    endColor   = [0 0.2 0.8]; % deep blue
    r = linspace(startColor(1), endColor(1), nColors);
    g = linspace(startColor(2), endColor(2), nColors);
    b = linspace(startColor(3), endColor(3), nColors);
    cmap = [r', g', b'];
end

function cmap = customRedColormap()
    nColors = 256;
    startColor = [1 1 1];     % white
    endColor   = [0.8 0 0];   % strong red
    r = linspace(startColor(1), endColor(1), nColors);
    g = linspace(startColor(2), endColor(2), nColors);
    b = linspace(startColor(3), endColor(3), nColors);
    cmap = [r', g', b'];
end