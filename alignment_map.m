function alignment_map(filepath,timeTable)

%% Initialization
nf = dir(fullfile(filepath,'results','*landmarks.zip'));
nf_extrusion = dir(fullfile(filepath,'results','*cell_death.zip'));
nf_masks = dir(fullfile(filepath,'masks','*.tif'));

filenames = {nf_extrusion.name};

if ~exist(fullfile(filepath,'dataframes','data_transformed.mat'),'file')
    %% Extraction of coordinates (landmarks, cell death events, masks)
    % Extraction space landmarks
    k = 0; landmarks = [];
    for i = 1:length(nf)
        fname = fullfile(filepath,'results',nf(i).name);
        Lands = ReadImageJROI(fname);
        L(i) = length(Lands);
        for j = 1:L(i)
            k = k + 1;
            landmarks(k,1:2) = Lands{1,j}.mfCoordinates;
            landmarks(k,3) = i;
        end
    end

    % Extraction extrusion coordinates
    k = 0; coordinates = [];
    for i = 1:length(nf_extrusion)
        fname = fullfile(filepath,'results',nf_extrusion(i).name);
        ROI = ReadImageJROI(fname);
        L(i) = length(ROI);
        for j = 1:L(i)
            k = k + 1;
            coordinates(k,1:2) = ROI{1,j}.mfCoordinates;
            coordinates(k,3) = i;
            coordinates(k,4) = ROI{1,j}.vnPosition(3);
        end
    end

    % Extraction mask coordinates
    masks = cell(1, length(nf_masks));
    for i = 1:length(nf_masks)
        fname = fullfile(filepath,'masks',nf_masks(i).name);
        masks{i} = readStackTif(fname);
    end

    %% Procrustes transformation
    procruste_transformed = [];
    landmarks_transformed = [];
    masks_transformed = cell(1, length(nf_masks));

    for i = 1:length(nf_extrusion)
        [~, ~, transform] = procrustes(landmarks(landmarks(:,3) == 1,1:2), landmarks(landmarks(:,3) == i,1:2));
        Tr(i) = transform;

        % === Transform coordinates ===
        Y = coordinates(coordinates(:,3) == i,1:2);
        Z2 = Tr(i).b * Y * Tr(i).T + Tr(i).c(1,:);
        procruste_transformed = [procruste_transformed; [Z2, ones(size(Z2,1),1)*i]];

        % === Transform landmarks ===
        idx_land = (landmarks(:,3) == i);
        LM = landmarks(idx_land,1:2);
        LM_tr = Tr(i).b * LM * Tr(i).T + Tr(i).c(1,:);
        landmarks_transformed = [landmarks_transformed; LM_tr, ones(size(LM_tr,1),1)*i];

        % === Transform masks ===
        idx_masks = logical(masks{i});  % Ensure binary
        [H, W, T] = size(idx_masks);

        % Build affine2d object from Procrustes
        A = Tr(i).b * Tr(i).T;
        t = Tr(i).c(1,:);  % translation
        tform = affine2d([A, [0;0]; t, 1]);

        % Set a large enough canvas — same size for all masks
        canvasSize = [H*2, W*2];  % You can adjust this margin

        % Center the output reference around the middle of the transformed data
        Rout = imref2d(canvasSize);

        % Preallocate transformed stack
        transformed_mask = false([canvasSize, T]);

        % Apply transformation frame by frame
        for nTime = 1:T
            frame = idx_masks(:,:,nTime);
            transformed_mask(:,:,nTime) = imwarp(frame, tform, ...
                'OutputView', Rout, 'Interp', 'nearest');
        end

        masks_transformed{i} = transformed_mask;
    end

    % Calculate relative time
    timeCoordinates_transformed = zeros(size(procruste_transformed,1),1);
    idx = 1;
    for i = 1:length(coordinates)
        nMovie = coordinates(i,3);
        timepoint = (coordinates(i,4)-timeTable.peaks(nMovie))*5/60;
        timeCoordinates_transformed(idx) = timepoint;
        idx = idx + 1;
    end
    procruste_transformed = [procruste_transformed, timeCoordinates_transformed];

    save(strcat(filepath,'dataframes','data_transformed.mat'),'procruste_transformed', 'landmarks_transformed');
    save(strcat(filepath,'dataframes','masks_transformed.mat'),'masks_transformed', '-v7.3');
    
    getExtrusionHeatmap(filepath,timeTable,procruste_transformed,masks_transformed);
else
    load(fullfile(filepath,'dataframes','data_transformed.mat'));
end
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

% Sliders
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

% Checkboxes pour les fichiers
checkboxHeight = 0.04;
checkboxWidth = 0.15;
checkboxLeft = 0.02;
checkboxBottomStart = 0.85;
checkboxSpacing = 0.06;
checkboxes = gobjects(length(filenames),1);
for i = 1:length(filenames)
    cbBottom = checkboxBottomStart - (i-1)*checkboxSpacing;
    checkboxes(i) = uicontrol('Style','checkbox', 'String', filenames{i}, ...
        'Units','normalized', 'Position', [checkboxLeft cbBottom checkboxWidth checkboxHeight], ...
        'Value', 1, ...
        'Callback', @(src,~) updateScatter());
end

% Data cursor
dcm = datacursormode(fig);
set(dcm, 'Enable', 'on', 'UpdateFcn', @myupdatefcn);

% Fonction de mise à jour
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

% Fonction datatip
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

% Fix to initial
updateScatter();
% assignin('base', 'Tr', Tr);
% assignin('base', 'procruste_transformed', procruste_transformed);
% assignin('base', 'filenames', filenames);
end
