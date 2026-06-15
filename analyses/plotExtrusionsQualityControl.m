function plotExtrusionsQualityControl( ...
    allData, ...
    filenames, ...
    landmarks, ...
    spatialGrid)

%% =========================================================
% ROBUST MOVIE INDEXING
%% =========================================================

[nMovies,nTimes] = size(allData);

validMovieRows = find(any(~cellfun(@isempty, allData),2));
nMoviesPlot = numel(validMovieRows);

%% =========================================================
% GLOBAL LIMITS
%% =========================================================

allX = [];
allY = [];

for mi = 1:nMoviesPlot
    m = validMovieRows(mi);

    for t = 1:nTimes

        d = allData{m,t};
        if isempty(d) || ~isfield(d,'extrusions')
            continue
        end

        allX = [allX; d.extrusions.allX(:)];
        allY = [allY; d.extrusions.allY(:)];
    end
end

xmin = min(allX); xmax = max(allX);
ymin = min(allY); ymax = max(allY);

pad = 0.02;
dx = range(allX); dy = range(allY);

xmin = xmin - pad*dx;
xmax = xmax + pad*dx;
ymin = ymin - pad*dy;
ymax = ymax + pad*dy;

%% =========================================================
% FIGURE
%% =========================================================

fig = figure('Color','w','Name','Extrusion QC Viewer');

ax = axes('Parent',fig,'Units','normalized','Position',[0.22 0.12 0.73 0.8]);
hold(ax,'on');
axis(ax,'equal');
set(ax,'YDir','reverse');
box(ax,'on'); grid(ax,'on');

xlim(ax,[xmin xmax]);
ylim(ax,[ymin ymax]);

%% =========================================================
% GRID
%% =========================================================

for i = 1:length(spatialGrid.xEdges)
    xline(ax,spatialGrid.xEdges(i),'Color',[0.9 0.9 0.9]);
end

for i = 1:length(spatialGrid.yEdges)
    yline(ax,spatialGrid.yEdges(i),'Color',[0.9 0.9 0.9]);
end

%% =========================================================
% QC GRAYSCALE MAP
%% =========================================================

nBins = spatialGrid.nBins;

xCenters = (spatialGrid.xEdges(1:end-1) + spatialGrid.xEdges(2:end)) / 2;
yCenters = (spatialGrid.yEdges(1:end-1) + spatialGrid.yEdges(2:end)) / 2;

[xg, yg] = meshgrid(xCenters, yCenters);

qcHandle = scatter(ax, ...
    xg(:), yg(:), ...
    80, zeros(nBins^2,1), ...
    's','filled');

colormap(ax,gray);
cb = colorbar;
cb.Label.String = 'Valid movies per bin';

qcHandle.Visible = 'on';

%% =========================================================
% EXTRUSIONS
%% =========================================================

scValid = scatter(ax,nan,nan,20,'k','filled');
scInvalid = scatter(ax,nan,nan,20,'r','filled','MarkerFaceAlpha',0.4);

scLand = scatter(ax,nan,nan,50,'bx','LineWidth',1.5);

legend(ax,[scValid scInvalid],{'Valid','Invalid'},'Location','best');

%% =========================================================
% UI CONTROLS
%% =========================================================

slider = uicontrol('Style','slider',...
    'Units','normalized','Position',[0.25 0.03 0.5 0.04],...
    'Min',1,'Max',nTimes,'Value',1,...
    'SliderStep',[1/max(nTimes-1,1) 5/max(nTimes-1,1)]);

txt = uicontrol('Style','text',...
    'Units','normalized','Position',[0.25 0.075 0.5 0.03],...
    'BackgroundColor','w');

bg = uibuttongroup(fig,'Position',[0.8 0.02 0.18 0.08]);

r1 = uicontrol(bg,'Style','radiobutton','String','Cumulative',...
    'Units','normalized','Position',[0.05 0.55 0.9 0.4],'Value',1);

r2 = uicontrol(bg,'Style','radiobutton','String','Single',...
    'Units','normalized','Position',[0.05 0.05 0.9 0.4]);

%% 🔥 NEW CHECKBOX (QC TOGGLE)
qcToggle = uicontrol(fig,'Style','checkbox',...
    'String','Show QC map',...
    'Units','normalized',...
    'Position',[0.82 0.11 0.15 0.03],...
    'Value',1);

%% =========================================================
% MOVIE CHECKBOXES
%% =========================================================

panel = uipanel(fig,'Position',[0.02 0.15 0.18 0.75],'Title','Movies');

checkboxes = gobjects(nMoviesPlot,1);

for mi = 1:nMoviesPlot
    checkboxes(mi) = uicontrol(panel,...
        'Style','checkbox',...
        'String',filenames{validMovieRows(mi)},...
        'Value',1,...
        'Units','normalized',...
        'Position',[0.05 0.95-mi*0.05 0.9 0.05]);
end

%% =========================================================
% UPDATE FUNCTION
%% =========================================================

function update()

    selectedIdx = find(arrayfun(@(c)c.Value,checkboxes));
    selectedMovies = validMovieRows(selectedIdx);

    currentBin = round(slider.Value);
    currentBin = max(1,min(currentBin,nTimes));

    validX = [];
    validY = [];
    invalidX = [];
    invalidY = [];

    QC = zeros(nBins,nBins);
    nUsed = 0;

    isCumulative = (r1.Value == 1);

    for mi = 1:numel(selectedMovies)

        m = selectedMovies(mi);

        if isCumulative
            tRange = 1:currentBin;
        else
            tRange = currentBin;
        end

        for t = tRange

            d = allData{m,t};
            if isempty(d), continue; end

            if isfield(d,'extrusions')

                validX = [validX; d.extrusions.validX(:)];
                validY = [validY; d.extrusions.validY(:)];
                invalidX = [invalidX; d.extrusions.invalidX(:)];
                invalidY = [invalidY; d.extrusions.invalidY(:)];
            end

            if isfield(d,'tissue') && isfield(d.tissue,'validBinMask')

                QC = QC + double(d.tissue.validBinMask);
                nUsed = nUsed + 1;
            end
        end
    end

    %% NORMALIZE QC
    if nUsed > 0
        QCplot = QC ./ nUsed;
    else
        QCplot = QC;
    end

    qcHandle.CData = QCplot(:);

    %% EXTRUSIONS
    scValid.XData = validX;
    scValid.YData = validY;

    scInvalid.XData = invalidX;
    scInvalid.YData = invalidY;

    %% LANDMARKS
    if ~isempty(landmarks)
        idx = ismember(landmarks(:,3), selectedMovies);
        scLand.XData = landmarks(idx,1);
        scLand.YData = landmarks(idx,2);
    end

    %% QC TOGGLE (NEW)
    if qcToggle.Value == 1
        qcHandle.Visible = 'on';
    else
        qcHandle.Visible = 'off';
    end

    %% TEXT
    txt.String = sprintf('Bin %d | Valid %d | Invalid %d', ...
        currentBin, numel(validX), numel(invalidX));

    drawnow limitrate;

end

%% =========================================================
% CALLBACKS
%% =========================================================

slider.Callback = @(~,~) update();
r1.Callback = @(~,~) update();
r2.Callback = @(~,~) update();
qcToggle.Callback = @(~,~) update();

for mi = 1:nMoviesPlot
    checkboxes(mi).Callback = @(~,~) update();
end

%% INIT
update();

end