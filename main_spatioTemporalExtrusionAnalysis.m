close all
%% load data
filepath=('D:\Antonio\extrusion systematic characterisation\test');
timeDataframe = readtable(fullfile(filepath,'dataframes','timeAlignment.xlsx'));

%% Initialization
nf_extrusion = dir(fullfile(filepath,'input','*cell_death.zip'));
nf_masks = dir(fullfile(filepath,'masks','*.tif'));
nf_features = dir(fullfile(filepath,'features','*.csv'));
frameRate=5;

filenames = {nf_extrusion.name};

%% Ask user for time alignment method
choice = questdlg('Select time alignment method:', ...
                  'Time Alignment', ...
                  'Speed peaks', 'Division peaks', 'Speed peaks');

switch choice
    case 'Speed peaks'
        selectedColumn = 'speedPeaks';
        selectedLandmarks = 'speed';
    case 'Division peaks'
        selectedColumn = 'divisionPeaks';
        selectedLandmarks = 'division';
    otherwise
        error('No alignment method selected. Script aborted.');
end

movieNames = timeDataframe{:,1};  
alignmentValues = timeDataframe{:, selectedColumn};

timeTable = table(movieNames, alignmentValues, ...
                  'VariableNames', {'name', 'peaks'});

% Load landmarks depending on the time alignment
nf = dir(fullfile(filepath,'input',selectedLandmarks,'*landmarks.zip'));

if ~exist(fullfile(filepath,'dataframes',strcat('data_',selectedLandmarks,'_transformed.mat')),'file')
    %% Extraction of coordinates (landmarks, cell death events, masks)
    % Extraction space landmarks
    k = 0; landmarks = [];
    for i = 1:length(nf)
        fname = fullfile(filepath,'input',selectedLandmarks,nf(i).name);
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
        fname = fullfile(filepath,'input',nf_extrusion(i).name);
        ROI = ReadImageJROI(fname);
        L(i) = length(ROI);
        for j = 1:L(i)
            k = k + 1;
            coordinates(k,1:2) = ROI{1,j}.mfCoordinates;
            coordinates(k,3) = i;
            coordinates(k,4) = ROI{1,j}.vnPosition(3);
            if coordinates(k,4) == 1
                coordinates(k,4) = ROI{1,j}.vnPosition(2);
            end
        end
    end

    % Extraction mask coordinates
    masks = cell(1, length(nf_masks));
    for i = 1:length(nf_masks)
        fname = fullfile(filepath,'masks',nf_masks(i).name);
        masks{i} = readStackTif(fname);
    end

    % Extraction features coordinates
   dataframeFeatures = cell(1, length(nf_features));
    for i = 1:length(nf_features)
        fname = fullfile(filepath,'features',nf_features(i).name);
        dataframeFeatures{i} = readtable(fname);
    end

    %% Procrustes transformation
    features_transformed=[];
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
        idx_masks = logical(~masks{i});  % Ensure binary
        [H, W, T] = size(idx_masks);

        % === Transform features ===
        csv_features= (dataframeFeatures{i});
        xyCells = [csv_features.y csv_features.x];
        features_tr = Tr(i).b * xyCells * Tr(i).T + Tr(i).c(1,:);
        csv_features.y=features_tr(:,1);
        csv_features.x=features_tr(:,2);
        csv_features.file=[];
        csv_features.frame = (csv_features.frame-timeTable.peaks(i))*frameRate/60;
        features_transformed = [features_transformed;table2array(csv_features), ones(size(csv_features,1),1)*i];

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
        timepoint = (coordinates(i,4)-timeTable.peaks(nMovie))*frameRate/60;
        timeCoordinates_transformed(idx) = timepoint;
        idx = idx + 1;
    end
    procruste_transformed = [procruste_transformed, timeCoordinates_transformed];

    save(fullfile(filepath,'dataframes',strcat('data_',selectedLandmarks,'_transformed.mat')),'procruste_transformed','landmarks_transformed','masks_transformed','features_transformed','-v7.3');
    
    % if ~exist(fullfile(filepath,'dataframes','data_transformed.mat'),'file') 
    %     save(strcat(filepath,'dataframes','masks_transformed.mat'),'masks_transformed', '-v7.3');
    % end
    [allN_full,allValidN_full,heatmapSum,nBins,timeStep]=getExtrusionHeatmap2DTime(filepath,selectedLandmarks,timeTable,procruste_transformed,masks_transformed,features_transformed);
    alignment_map(filenames,procruste_transformed,landmarks_transformed)
else
    load(fullfile(filepath,'dataframes',strcat('data_',selectedLandmarks,'_transformed.mat')));
    [allN_full,allValidN_full,heatmapSum,nBins,timeStep]=getExtrusionHeatmap2DTime(filepath,selectedLandmarks,timeTable,procruste_transformed,masks_transformed,features_transformed);
end

%getSumAverageCVHeatmap(procruste_transformed,allValidN_full,nBins,timeStep);
getRegionalHeatmap(filepath,filenames,selectedLandmarks,procruste_transformed,allValidN_full,heatmapSum,nBins,timeStep);

