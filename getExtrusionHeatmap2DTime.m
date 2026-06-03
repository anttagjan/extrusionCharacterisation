function [allN_full,allValidN_full,heatmapSum,nBins,timeStep]=getExtrusionHeatmap2DTime(filepath,filename,peaks,procruste_transformed,masks_transformed,features_transformed)
%getExtrusionHeatmap Summary of this function goes here
%   Detailed explanation goes here

movies = unique(procruste_transformed(:,3));
procruste_transformed(:,4)=round(procruste_transformed(:,4),4);
allMoviesTime={};
for nMovie= 1: max(movies)
    t0 = peaks.peaks(nMovie);
     movieTime = ((1:size(masks_transformed{nMovie},3))-t0)*5/60;
     allMoviesTime{nMovie} = round(movieTime,4);
end

time = unique(procruste_transformed(:,4));
% timeStep = 5/60;
timeStep = 1;
%tol = 1e-6; % tolerance when comparing time values
nBins = 30;
timeBins = floor(min(time)):timeStep:ceil(max(time))+timeStep;

Xall = procruste_transformed(:,1);
Yall = procruste_transformed(:,2);

% Calculation of edges taking into account a small margin or padding to the
% edges
marginX = 0.01 * (max(Xall) - min(Xall));
marginY = 0.01 * (max(Yall) - min(Yall));

xEdges = linspace(min(Xall)-marginX, max(Xall)+marginX, nBins+1);
yEdges = linspace(min(Yall)-marginY, max(Yall)+marginY, nBins+1);

if ~exist(fullfile(filepath,'dataframes',strcat('heatmap_data_',filename,'timeAlignment',num2str(nBins),'x',num2str(nBins),'_',num2str(timeStep),'hStep.mat')),'file')
    allN_full = cell(max(movies), length(timeBins)-1);
    allValidN_full = cell(max(movies), length(timeBins)-1);
    allMaxCount = cell(max(movies), length(timeBins)-1);
    allValidMaxCount = cell(max(movies), length(timeBins)-1);

    allN_cell = cell(max(movies), length(timeBins)-1);
    allValidN_cell = cell(max(movies), length(timeBins)-1);
    allMaxCellCount = cell(max(movies), length(timeBins)-1);
    allValidMaxCellCount = cell(max(movies), length(timeBins)-1);

    for nMovie = 1:max(movies)
        current_masks= masks_transformed{nMovie};
        for nTime = 1:(length(timeBins)-1)
            timeLimits = [round(timeBins(nTime),4), round(timeBins(nTime)+timeStep,4)];
            
            % % Time index with tolerance
            % t_all = procruste_transformed(:,4);
            % m_all = procruste_transformed(:,3);
            % t_rel = allMoviesTime{nMovie};
            % 
            % if nTime < length(edges)-1
            %     idx = m_all == nMovie & ...
            %         t_all >= timeLimits(1) - tol & ...
            %         t_all <  timeLimits(2) - tol;
            %     timeIndx = t_rel >= timeLimits(1) - tol & ...
            %         t_rel <  timeLimits(2) - tol;
            % else
            %     idx = m_all == nMovie & ...
            %         t_all >= timeLimits(1) - tol & ...
            %         t_all <= timeLimits(2) + tol;
            %     timeIndx = t_rel >= timeLimits(1) - tol & ...
            %         t_rel <= timeLimits(2) + tol;
            % end

            if nTime < length(timeBins)-1
                % death events
                idx = procruste_transformed(:,3)==nMovie & ...
                    procruste_transformed(:,4) >= timeLimits(1) & ...
                    procruste_transformed(:,4) < timeLimits(2);
                timeIndx = allMoviesTime{nMovie} >= timeLimits(1) & allMoviesTime{nMovie} < timeLimits(2);
                % morphological features
                idx_features = features_transformed(:,8)==nMovie & ...
                    features_transformed(:,6) >= timeLimits(1) & ...
                    features_transformed(:,6) < timeLimits(2);
                timeIndx = allMoviesTime{nMovie} >= timeLimits(1) & allMoviesTime{nMovie} < timeLimits(2);

            else
                % Last bin : also include the upper bound
                % death events
                idx = procruste_transformed(:,3)==nMovie & ...
                    procruste_transformed(:,4) >= timeLimits(1) & ...
                    procruste_transformed(:,4) <= timeLimits(2);
                timeIndx = allMoviesTime{nMovie} >= timeLimits(1) & allMoviesTime{nMovie} <= timeLimits(2);
                % morphological features
                idx_features = features_transformed(:,8)==nMovie & ...
                    features_transformed(:,6) >= timeLimits(1) & ...
                    features_transformed(:,6) <= timeLimits(2);
                timeIndx = allMoviesTime{nMovie} >= timeLimits(1) & allMoviesTime{nMovie} <= timeLimits(2);

            end

            if ~isempty(current_masks(:,:,timeIndx))
                validMask=any(current_masks(:,:,timeIndx),3);
            else
                validMask=[];
            end

            X = procruste_transformed(idx,1);
            Y = procruste_transformed(idx,2);

            % Manual assignment of bins
            ix = discretize(X, xEdges);
            iy = discretize(Y, yEdges);

            % Remove points outside (NaN if out of bounds anyway)
            valid = ~isnan(ix) & ~isnan(iy);
            ix = ix(valid);
            iy = iy(valid);

            % Delimiting valid region
            [H, W] = size(validMask);
            [xx, yy] = meshgrid(1:W, 1:H);     % pixel coordinates
            xCoords = xx(validMask);
            yCoords = yy(validMask);

            % Use histcounts2 to project the pixel mask onto bins
            tissueBinCount = histcounts2(yCoords, xCoords, yEdges, xEdges); % Y first
            validBinMask = tissueBinCount > 0; % 1 if tissue present, 0 if not

            % Manual construction of the 2D histogram
            N_full = accumarray([iy, ix], 1, [nBins, nBins]);
            maxCount = prctile(N_full(:), 100);
            validN_full = N_full;
            validN_full(~validBinMask) = NaN;
            if all(isnan(N_full), 'all')
                validMaxCount = 0;
            else
                validMaxCount = prctile(validN_full(~isnan(validN_full)), 100);
            end

            %% Features assignment of bins
            % Manual assignment of bins
            xFeatures = features_transformed(idx_features,1);
            yFeatures = features_transformed(idx_features,2);

            xiFeatures = discretize(xFeatures, xEdges);
            yiFeatures = discretize(yFeatures, yEdges);

            % Remove points outside (NaN if out of bounds anyway)
            valid = ~isnan(xiFeatures) & ~isnan(yiFeatures);
            xiFeatures = xiFeatures(valid);
            yiFeatures = yiFeatures(valid);

            N_cell = accumarray([yiFeatures, xiFeatures], 1, [nBins, nBins]);
            maxCellCount = prctile(N_cell(:), 100);
            validN_cell = N_cell;
            validN_cell(~validBinMask) = NaN;
            if all(isnan(N_cell), 'all')
                validMaxCellCount = 0;
            else
                validMaxCellCount = prctile(validN_cell(~isnan(validN_cell)), 100);
            end

            allN_full{nMovie,nTime} = N_full;
            allValidN_full{nMovie,nTime} = validN_full;
            allMaxCount{nMovie,nTime} = maxCount;
            allValidMaxCount{nMovie,nTime} = validMaxCount;

            allN_cell{nMovie,nTime} = N_cell;
            allValidN_cell{nMovie,nTime} = validN_cell;
            allMaxCellCount{nMovie,nTime} = maxCellCount;
            allValidMaxCellCount{nMovie,nTime} = validMaxCellCount;
        end
    end

    heatmapSum = zeros(nBins, nBins);
    for i = 1:size(allValidN_full,1)
        for j = 1:size(allValidN_full,2)
            current = allValidN_full{i,j};
            current(isnan(current)) = 0;  % exclude NaNs
            heatmapSum = heatmapSum + current;
        end
    end

    heatmapCellSum = zeros(nBins, nBins);
    for i = 1:size(allValidN_cell,1)
        for j = 1:size(allValidN_cell,2)
            current = allValidN_cell{i,j};
            current(isnan(current)) = 0;  % exclude NaNs
            heatmapCellSum = heatmapCellSum + current;
        end
    end
    save(fullfile(filepath,'dataframes',strcat('heatmap_data_',filename,'timeAlignment',num2str(nBins),'x',num2str(nBins),'_',num2str(timeStep),'hStep.mat')),"heatmapSum","heatmapCellSum","nBins","timeStep","allN_full","allValidN_full","allN_cell","allValidN_cell");

else
    load(fullfile(filepath,'dataframes',strcat('heatmap_data_',filename,'timeAlignment',num2str(nBins),'x',num2str(nBins),'_',num2str(timeStep),'hStep.mat')));
end

%% Display
figure;
imagesc(heatmapCellSum);
axis image;
title('Total Extrusion Heatmap');
xlabel('X bins');
ylabel('Y bins');

n = 256;
cmap = [linspace(1,1,n)', linspace(1,0,n)', linspace(1,0,n)'];
colormap(cmap);

% Set color scale limits (e.g., from 0 to 50)
%% Display
figure;
imagesc(heatmapSum);
axis image;
title('Heatmap: total no. Extrusions');
xlabel('X bins');
ylabel('Y bins');

n = 256;
cmap = [linspace(1,1,n)', linspace(1,0,n)', linspace(1,0,n)'];
colormap(cmap);

% Set color scale limits (e.g., from 0 to 50)
% caxis([0 250]);

% Add colorbar and label
cb = colorbar;
ylabel(cb, 'no. extrusions');

end