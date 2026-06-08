function plotExtrusions(filenames, extrusions_transformed, landmarks_transformed, validBinsMovie)

% colour legend -> time normalisation
t = extrusions_transformed(:,3);
tMin = min(t);
tMax = max(t);
t_norm = (t - tMin) / (tMax - tMin);

nb_colors = 256;
cmap = jet(nb_colors);

color_idx = round(t_norm * (nb_colors - 1)) + 1;
color_idx(color_idx < 1) = 1;
color_idx(color_idx > nb_colors) = nb_colors;

colors_all = cmap(color_idx, :);

%% FIGURE
fig = figure('Color','w','Name','Consensus Map - Interactive Time Filter');

ax = axes('Parent',fig,'Units','normalized','Position',[0.2 0.1 0.75 0.85]);
hold(ax,'on');

set(ax,'YDir','reverse','XAxisLocation','top','xtick',[],'ytick',[]);

%% =========================
% GRID
%% =========================
nBins = size(validBinsMovie,1);

x_all = extrusions_transformed(:,1);
y_all = extrusions_transformed(:,2);

xEdges = linspace(min(x_all), max(x_all), nBins+1);
yEdges = linspace(min(y_all), max(y_all), nBins+1);

for i = 1:length(xEdges)
    xline(ax, xEdges(i), ':', 'Color',[0.75 0.75 0.75], 'HandleVisibility','off');
end

for j = 1:length(yEdges)
    yline(ax, yEdges(j), ':', 'Color',[0.75 0.75 0.75], 'HandleVisibility','off');
end

%% =========================
% BIN OVERLAY (dynamic)
%% =========================
binOverlay = imagesc(ax, xEdges, yEdges, zeros(nBins,nBins));
set(binOverlay,'AlphaData',0.25);
colormap(ax, gray);

%% =========================
% SCATTER
%% =========================
scatter_handle = scatter(ax, nan(size(extrusions_transformed,1),1), ...
    nan(size(extrusions_transformed,1),1), ...
    36, nan(size(extrusions_transformed,1),3), 'filled');

landmarks_scatter = scatter(ax, nan, nan, ...
    60, 'k', 'x', 'LineWidth', 1.5);

%% LIMITS
margin = 0.01;
xrange = max(x_all) - min(x_all);
yrange = max(y_all) - min(y_all);

xlim(ax,[min(x_all)-margin*xrange, max(x_all)+margin*xrange]);
ylim(ax,[min(y_all)-margin*yrange, max(y_all)+margin*yrange]);

%% USERDATA
userDataArr = struct('position',{},'time',{},'filename',{});

for i = 1:size(extrusions_transformed,1)
    userDataArr(i).position = extrusions_transformed(i,1:2);
    userDataArr(i).time = extrusions_transformed(i,3);
    userDataArr(i).filename = filenames{extrusions_transformed(i,4)};
end

scatter_handle.UserData = userDataArr;

%% COLOR
colormap(ax,cmap);
cb = colorbar(ax,'eastoutside');
caxis([tMin tMax]);
cb.Ticks = linspace(tMin,tMax,5);
cb.Label.String = 'relative time (h)';

%% =========================
% UI
%% =========================
nFiles = length(filenames);

panel = uipanel('Parent',fig,'Units','normalized', ...
    'Position',[0.02 0.15 0.20 0.65], ...
    'Title','Movies');

checkboxes = gobjects(nFiles,1);

for i = 1:nFiles
    checkboxes(i) = uicontrol('Parent',panel,'Style','checkbox', ...
        'String',filenames{i}, ...
        'Units','normalized', ...
        'Position',[0.05 1-i*0.05 0.9 0.05], ...
        'Value',1, ...
        'Callback',@(~,~)updateScatter());
end

%% =========================
% CALLBACK
%% =========================
function updateScatter()

    selectedFiles = find(arrayfun(@(c) c.Value, checkboxes));

    %% SCATTER FILTER
    idxFiles = ismember(extrusions_transformed(:,4), selectedFiles);

    scatter_handle.XData = extrusions_transformed(idxFiles,1);
    scatter_handle.YData = extrusions_transformed(idxFiles,2);
    scatter_handle.CData = colors_all(idxFiles,:);
    scatter_handle.UserData = userDataArr(idxFiles);

    idxLandmarks = ismember(landmarks_transformed(:,3), selectedFiles);
    landmarks_scatter.XData = landmarks_transformed(idxLandmarks,1);
    landmarks_scatter.YData = landmarks_transformed(idxLandmarks,2);

    %% =========================
    % VALIDITY MAP UPDATE
    %% =========================
    if isempty(selectedFiles)
        validMap = zeros(nBins,nBins);

    elseif length(selectedFiles) == 1
        validMap = validBinsMovie(:,:,selectedFiles);

    else
        validMap = any(validBinsMovie(:,:,selectedFiles),3);
    end

    set(binOverlay,'CData',validMap);
    uistack(binOverlay,'bottom');

end

%% INIT
updateScatter();

end