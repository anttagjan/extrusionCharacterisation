function plotEventsQualityControl( ...
    allData, ...
    filenames, ...
    landmarks, ...
    spatialGrid, ...
    eventName, ...
    sex_icon,...
    filepath)
%%Dessin du plot quality control pour division + extrusions
%% EventName etc...
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
        if isempty(d) || ~isfield(d, eventName)
            continue
        end
        ev = d.(eventName);
        allX = [allX; ev.allX(:)];
        allY = [allY; ev.allY(:)];
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

fig = figure('Color','w','Name',[eventName 'QC Viewer']);

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

%% CHECKBOX (QC TOGGLE)
qcToggle = uicontrol(fig,'Style','checkbox',...
    'String','Show QC map',...
    'Units','normalized',...
    'Position',[0.82 0.11 0.15 0.03],...
    'Value',1);

showDataToggle = uicontrol(fig,'Style','checkbox',...
    'String','Show datapoints',...
    'Units','normalized',...
    'Position',[0.82 0.15 0.15 0.03],...
    'Value',1);

btnAll = uicontrol(fig,'Style','pushbutton',...
    'String','Select all',...
    'Units','normalized',...
    'Position',[0.02 0.92 0.09 0.04],...
    'Callback',@(~,~) setAllMovies(1));

btnNone = uicontrol(fig,'Style','pushbutton',...
    'String','Deselect all',...
    'Units','normalized',...
    'Position',[0.11 0.92 0.09 0.04],...
    'Callback',@(~,~) setAllMovies(0));

%% =========================================================
% MOVIE CHECKBOXES
%% =========================================================

movieList = uicontrol(fig,...
    'Style','listbox',...
    'Units','normalized',...
    'Position',[0.02 0.15 0.18 0.75],...
    'String',filenames(validMovieRows),...
    'Max',2,...      % Multiple selection
    'Min',0,...
    'Value',1:nMoviesPlot);   % All selected initially

%% =========================================================
% UPDATE FUNCTION
%% =========================================================

function update()

    selectedIdx = movieList.Value;

    if isempty(selectedIdx)

        scValid.XData = [];
        scValid.YData = [];

        scInvalid.XData = [];
        scInvalid.YData = [];

        qcHandle.CData = zeros(nBins^2,1);

        txt.String = 'No movies selected';

        drawnow;
        return

    end
    
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

            if isfield(d, eventName)
                ev = d.(eventName);
                validX = [validX; ev.validX(:)];
                validY = [validY; ev.validY(:)];
                invalidX = [invalidX; ev.invalidX(:)];
                invalidY = [invalidY; ev.invalidY(:)];
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
    
    persistent qcFig qcAx qcImg

    if isempty(qcFig) || ~isvalid(qcFig)

        qcFig = figure('Color','w','Name','QC Fraction Map');

        qcAx = axes('Parent',qcFig);
        axis(qcAx,'image');
        set(qcAx,'YDir','reverse');
        box(qcAx,'on');

        qcImg = imagesc(qcAx, QCplot);
        colormap(qcAx, gray);
        colorbar(qcAx);
        caxis(qcAx,[0 1]); % fraction range

        title(qcAx,'Fraction of valid bins (movie + time pooled)');

    else
        set(qcImg,'CData',QCplot);
    end

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

    %% DATA VISIBILITY TOGGLE
    if showDataToggle.Value == 1
        scValid.Visible = 'on';
        scInvalid.Visible = 'on';
        scLand.Visible = 'on';
    else
        scValid.Visible = 'off';
        scInvalid.Visible = 'off';
        scLand.Visible = 'off';
    end

end

%% =========================================================
% CALLBACKS
%% =========================================================

slider.Callback = @(~,~) update();
r1.Callback = @(~,~) update();
r2.Callback = @(~,~) update();
qcToggle.Callback = @(~,~) update();

movieList.Callback = @(~,~) update();

slider.Callback = @(~,~) update();
r1.Callback = @(~,~) update();
r2.Callback = @(~,~) update();
qcToggle.Callback = @(~,~) update();

showDataToggle.Callback = @(~,~) update();

%% INIT
update();


saveFolder = fullfile(filepath,'figures_program');

if ~exist(saveFolder,'dir') %Si le dossier existe pas, le créer
    mkdir(saveFolder)
    fprintf("création par quality control")
end

savefig(gcf,...
    fullfile(saveFolder,...
    [eventName '_qualityControl_' sex_icon '.fig']))

function setAllMovies(val)

    if val
        movieList.Value = 1:nMoviesPlot;
    else
        movieList.Value = [];
    end

    update();

end


end