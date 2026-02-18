function alignment_map(filenames,procruste_transformed,landmarks_transformed)

% colour legend -> time normalisation
t = procruste_transformed(:,4);
tMin = min(t);
tMax = max(t);
t_norm = (t - tMin) / (tMax - tMin);
nb_colors = 256;
cmap = jet(nb_colors);
color_idx = round(t_norm * (nb_colors - 1)) + 1;
color_idx(color_idx < 1) = 1;           % sécurité
color_idx(color_idx > nb_colors) = nb_colors;
colors_all = cmap(color_idx, :);

%% Plot of all transformed landmarks and extrusions
fig = figure('Color','w','Name','Consensus Map - Interactive Time Filter');
ax = axes('Parent',fig, 'Units','normalized', 'Position',[0.2 0.1 0.75 0.85]);
hold(ax,'on');
set(ax, 'YDir','reverse', 'XAxisLocation','top', 'xtick', [], 'ytick', []);

% Scatter vide à remplir
scatter_handle = scatter(ax, nan(size(procruste_transformed,1),1), ...
    nan(size(procruste_transformed,1),1), ...
    36, nan(size(procruste_transformed,1),3), 'filled');

% Landmarks (croix noires)
landmarks_scatter = scatter(ax, nan, nan, ...
    60, 'k', 'x', 'LineWidth', 1.5);

% Fixer les axes (cadre) définitivement
x_all = procruste_transformed(:,1);
y_all = procruste_transformed(:,2);
margin = 0.01;
xrange = max(x_all) - min(x_all);
yrange = max(y_all) - min(y_all);
xlim(ax, [min(x_all) - margin*xrange, max(x_all) + margin*xrange]);
ylim(ax, [min(y_all) - margin*yrange, max(y_all) + margin*yrange]);

% UserData pour datatips
userDataArr = struct('position',{},'time',{},'filename',{});
for i = 1:size(procruste_transformed,1)
    userDataArr(i).position = procruste_transformed(i,1:2);
    userDataArr(i).time = procruste_transformed(i,4);
    userDataArr(i).filename = filenames{procruste_transformed(i,3)};
end
scatter_handle.UserData = userDataArr;

% Colorbar avec caxis fixé
colormap(ax, cmap);
cb = colorbar(ax,'eastoutside');
caxis([tMin tMax]);  % fixe échelle couleur
cb.Ticks = linspace(tMin,tMax,5);
cb.Label.String = 'relative time (h)';

% Time Sliders
frameStep = 5 / 60;  % 5 minutes in hours
sliderRange = tMax - tMin;
stepSmall = frameStep / sliderRange;
sliderMin = uicontrol('Style','slider', ...
    'Min', tMin, 'Max', tMax, 'Value', tMin, ...
    'SliderStep', [stepSmall, 5*stepSmall], ...
    'Units','normalized', 'Position', [0.22 0.02 0.3 0.04], ...
    'Callback', @(src,~) updateScatter());

labelMin = uicontrol('Style','text', 'Units','normalized', ...
    'Position', [0.22 0.07 0.3 0.03], ...
    'String', sprintf('min time (h): %.2f', tMin));

sliderMax = uicontrol('Style','slider', ...
    'Min', tMin, 'Max', tMax, 'Value', tMax, ...
    'SliderStep', [stepSmall, 5*stepSmall], ...
    'Units','normalized', 'Position', [0.55 0.02 0.3 0.04], ...
    'Callback', @(src,~) updateScatter());

labelMax = uicontrol('Style','text', 'Units','normalized', ...
    'Position', [0.55 0.07 0.3 0.03], ...
    'String', sprintf('max time (h): %.2f', tMax));

%% ===== Scrollable checkbox panel =====
nFiles = length(filenames);

panelLeft   = 0.02;
panelBottom = 0.15;
panelWidth  = 0.20;
panelHeight = 0.65;

checkboxHeight  = 0.05;
checkboxSpacing = 0.01;
contentHeight = nFiles * (checkboxHeight + checkboxSpacing);

panel = uipanel('Parent',fig, ...
    'Units','normalized', ...
    'Position',[panelLeft panelBottom panelWidth panelHeight], ...
    'Title','Movies');

scrollbar = uicontrol('Style','slider', ...
    'Units','normalized', ...
    'Position',[panelLeft+panelWidth panelBottom 0.015 panelHeight], ...
    'Min',0,'Max',max(0,contentHeight-panelHeight),'Value',0, ...
    'Callback',@(~,~)scrollCheckboxes());

checkboxes = gobjects(nFiles,1);
for i = 1:nFiles
    y = contentHeight - i*(checkboxHeight+checkboxSpacing);
    checkboxes(i) = uicontrol('Parent',panel, ...
        'Style','checkbox', ...
        'String',filenames{i}, ...
        'Units','normalized', ...
        'Position',[0.05 y/panelHeight 0.9 checkboxHeight/panelHeight], ...
        'Value',1, ...
        'Callback',@(~,~)updateScatter());
end

%% ===== Auto-sweep + record button =====
btnAutoSweep = uicontrol('Style','pushbutton', ...
    'String','Auto-sweep & Record', ...
    'Units','normalized', ...
    'Position',[0.85 0.02 0.12 0.05], ...
    'Callback',@(src,event)autoSweepAndRecord());

%% ===== Collect UI controls for hiding =====
uiControls = [sliderMin, sliderMax, labelMin, labelMax, checkboxes', scrollbar, btnAutoSweep];
% Data cursor
dcm = datacursormode(fig);
set(dcm, 'Enable', 'on', 'UpdateFcn', @myupdatefcn);

%% ===== Callbacks =====
    function scrollCheckboxes()
        offset = scrollbar.Value;
        for i = 1:nFiles
            pos = checkboxes(i).Position;
            pos(2) = (contentHeight - i*(checkboxHeight+checkboxSpacing) - offset)/panelHeight;
            checkboxes(i).Position = pos;
        end
    end

    function updateScatter()
        tMinVal = sliderMin.Value;
        tMaxVal = sliderMax.Value;
        if tMinVal > tMaxVal
            tmp = tMinVal;
            tMinVal = tMaxVal;
            tMaxVal = tmp;
            sliderMin.Value = tMinVal;
            sliderMax.Value = tMaxVal;
        end

        labelMin.String = sprintf('min time: %.2f', tMinVal);
        labelMax.String = sprintf('max time: %.2f', tMaxVal);

        idxTime = (procruste_transformed(:,4) >= tMinVal) & (procruste_transformed(:,4) <= tMaxVal);
        selectedFiles = find(arrayfun(@(c) c.Value, checkboxes));
        idxFiles = ismember(procruste_transformed(:,3), selectedFiles);
        idxFilt = idxTime & idxFiles;

        scatter_handle.XData = procruste_transformed(idxFilt,1);
        scatter_handle.YData = procruste_transformed(idxFilt,2);
        scatter_handle.CData = colors_all(idxFilt,:);
        scatter_handle.UserData = userDataArr(idxFilt);

        idxLandmarks = ismember(landmarks_transformed(:,3), selectedFiles);
        landmarks_scatter.XData = landmarks_transformed(idxLandmarks,1);
        landmarks_scatter.YData = landmarks_transformed(idxLandmarks,2);
    end

    function txt = myupdatefcn(~, event_obj)
        target = get(event_obj, 'Target');
        pos = event_obj.Position;
        UD = target.UserData;
        if isempty(UD)
            txt = {'No data'};
            return;
        end
        dist = arrayfun(@(u) norm(u.position - pos), UD);
        [~, ind] = min(dist);
        txt = {
            ['X: ', num2str(UD(ind).position(1),3)], ...
            ['Y: ', num2str(UD(ind).position(2),3)], ...
            ['relative time: ', num2str(UD(ind).time,3)], ...
            ['Fichier: ', UD(ind).filename]};
    end

function autoSweepAndRecord()
        % --- hide all UI and panel title ---
        set(uiControls,'Visible','off');
        panel.Visible = 'off';  % hide the panel completely

        % --- setup video ---
        v = VideoWriter('alignment_map_autosweep.mp4','MPEG-4');
        v.FrameRate = 10;
        open(v);

        sliderMin.Enable = 'off';
        sliderMax.Enable = 'off';

        tMinVal = sliderMin.Value;
        nSteps = 120;
        tVals = linspace(tMinVal,tMax,nSteps);

        % --- create text label for max time ---
    hTimeLabel = text(ax, 0.05, 0.95, '', 'Units','normalized', ...
                      'FontSize',14, 'FontWeight','bold', 'Color','k');

        for k = 1:nSteps
            sliderMax.Value = tVals(k);
            updateScatter();
            hTimeLabel.String = sprintf('Max time: %.2f h', tVals(k));
            drawnow;
            writeVideo(v,getframe(fig));
        end

        close(v);

        % --- restore UI ---
        set(uiControls,'Visible','on');
        panel.Visible = 'on';
        sliderMin.Enable = 'on';
        sliderMax.Enable = 'on';
        delete(hTimeLabel); % remove label after recording

        disp('Saved video: alignment_map_autosweep.mp4');
    end

%% Init
scrollCheckboxes();
updateScatter();

end
