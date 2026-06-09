function plotExtrusionsQualityControl( ...
    allData, ...
    filenames, ...
    landmarks, ...
    timeBins)

%% =========================================================
% ROBUST MOVIE INDEXING (CRITICAL FIX)
%% =========================================================

[nMovies,nTimes] = size(allData);

% detect valid movie indices (rows that actually exist)
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

        if m > size(allData,1) || t > size(allData,2)
            continue
        end

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
dx = range(allX);
dy = range(allY);

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
% SCATTERS
%% =========================================================

scValid = scatter(ax,nan,nan,20,'k','filled');
scInvalid = scatter(ax,nan,nan,20,'r','filled','MarkerFaceAlpha',0.4);
scLand = scatter(ax,nan,nan,50,'bx','LineWidth',1.5);

legend(ax,[scValid scInvalid],{'Valid','Invalid'},'Location','best');

%% =========================================================
% UI
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

    %% --------------------------------------
    % COLLECT DATA
    %% --------------------------------------

    for mi = 1:numel(selectedMovies)

        m = selectedMovies(mi);

        if r1.Value == 1
            tRange = 1:currentBin;
        else
            tRange = currentBin;
        end

        for t = tRange

            if m > size(allData,1) || t > size(allData,2)
                continue
            end

            d = allData{m,t};

            if isempty(d) || ~isfield(d,'extrusions')
                continue
            end

            if isfield(d.extrusions,'validX')
                validX = [validX; d.extrusions.validX(:)];
                validY = [validY; d.extrusions.validY(:)];
            end

            if isfield(d.extrusions,'invalidX')
                invalidX = [invalidX; d.extrusions.invalidX(:)];
                invalidY = [invalidY; d.extrusions.invalidY(:)];
            end

        end
    end

    %% --------------------------------------
    % UPDATE SCATTERS
    %% --------------------------------------

    scValid.XData = validX;
    scValid.YData = validY;

    scInvalid.XData = invalidX;
    scInvalid.YData = invalidY;

    %% --------------------------------------
    % LANDMARKS
    %% --------------------------------------

    if ~isempty(landmarks)

        idx = ismember(landmarks(:,3), selectedMovies);

        scLand.XData = landmarks(idx,1);
        scLand.YData = landmarks(idx,2);

    else
        scLand.XData = [];
        scLand.YData = [];
    end

    %% --------------------------------------
    % TEXT
    %% --------------------------------------

    nV = numel(validX);
    nI = numel(invalidX);

    frac = 100 * nV / max(nV+nI,1);

    if r1.Value == 1

        txt.String = sprintf( ...
            'Cumulative | Valid %.1f%% (%d/%d)', ...
            frac, nV, nV+nI);

    else

        txt.String = sprintf( ...
            'Bin %d | Valid %.1f%% (%d/%d)', ...
            currentBin, frac, nV, nV+nI);

    end

    drawnow limitrate;

end

%% =========================================================
% CALLBACKS
%% =========================================================

slider.Callback = @(~,~) update();
r1.Callback = @(~,~) update();
r2.Callback = @(~,~) update();

for mi = 1:nMoviesPlot
    checkboxes(mi).Callback = @(~,~) update();
end

%% =========================================================
% INIT
%% =========================================================

update();

end