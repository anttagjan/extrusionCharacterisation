function result = processMovieTimeBin( ...
    movieID, timeIndex, timeBins, ...
    extrusions_transformed, divisions_transformed, masks_transformed, masks_relativeTime, ...
    features_transformed, grid)

timeLimits = [timeBins(timeIndex), timeBins(timeIndex+1)];

%% --- FILTER DATA ---
idx = extrusions_transformed(:,4)==movieID & ...
      extrusions_transformed(:,3)>=timeLimits(1) & ...
      extrusions_transformed(:,3)<timeLimits(2);
% Division x,y, temps, numero film
idxD = divisions_transformed(:,4)==movieID & ...
       divisions_transformed(:,3)>=timeLimits(1) & ...
       divisions_transformed(:,3)<timeLimits(2);

idxF = features_transformed.movie==movieID & ...
       features_transformed.frame>=timeLimits(1) & ...
       features_transformed.frame<timeLimits(2);

%% --- TISSUE MASK ---
mask = masks_transformed{movieID};
tm = masks_relativeTime{movieID}';

maskFrames =  ...
    tm >= timeLimits(1) & ...
    tm < timeLimits(2);

if isempty(mask)
    validMask = [];
else
    validMask = any(mask(:,:,maskFrames),3);
    % validMask = imdilate(validMask, strel('disk',6));
end

tissue = getTissueMetrics(validMask, grid);

%% --- CELLS ---

xC = getFeatureOrDefault(features_transformed, 'x', idxF);
yC = getFeatureOrDefault(features_transformed, 'y', idxF);
aC = getFeatureOrDefault(features_transformed, 'area', idxF);

% Optional features: if missing, fill with NaNs
eC  = getFeatureOrDefault(features_transformed, 'eccentricity', idxF);
arC = getFeatureOrDefault(features_transformed, 'aspect_ratio', idxF);
oC  = getFeatureOrDefault(features_transformed, 'orientation', idxF);

keepF = false(size(xC));

for i = 1:numel(xC)

    ix = find(xC(i) >= grid.xEdges(1:end-1) & ...
              xC(i) <  grid.xEdges(2:end), 1);

    iy = find(yC(i) >= grid.yEdges(1:end-1) & ...
              yC(i) <  grid.yEdges(2:end), 1);

    if ~isempty(ix) && ~isempty(iy)
        keepF(i) = tissue.validBinMask(iy, ix);
    end
end

% apply same filter to all features
xC  = xC(keepF);
yC  = yC(keepF);
aC  = aC(keepF);
eC  = eC(keepF);
arC = arC(keepF);
oC  = oC(keepF);

cells = getCellMetrics(xC, yC, aC,eC,arC,oC, tissue, grid);

%% --- EXTRUSIONS ---

xEall = extrusions_transformed(idx,1);
yEall = extrusions_transformed(idx,2);

% Classify extrusions using valid bins

keep = false(size(xEall));

for i = 1:numel(xEall)

    ix = find(xEall(i) >= grid.xEdges(1:end-1) & ...
              xEall(i) <  grid.xEdges(2:end), 1);

    iy = find(yEall(i) >= grid.yEdges(1:end-1) & ...
              yEall(i) <  grid.yEdges(2:end), 1);

    if ~isempty(ix) && ~isempty(iy)
        keep(i) = tissue.validBinMask(iy, ix);
    end

end

xEvalid = xEall(keep);
yEvalid = yEall(keep);

xEinvalid = xEall(~keep);
yEinvalid = yEall(~keep);

extrusions = getExtrusionMetrics( ...
    xEvalid, yEvalid, tissue,cells, grid);

%% --- DIVISIONS --- 

xDall = divisions_transformed(idxD,1);
yDall = divisions_transformed(idxD,2);


% Classify divisions using valid bins

keepD = false(size(xDall));

for i = 1:numel(xDall)

    ix = find(xDall(i) >= grid.xEdges(1:end-1) & ...
              xDall(i) <  grid.xEdges(2:end), 1);

    iy = find(yDall(i) >= grid.yEdges(1:end-1) & ...
              yDall(i) <  grid.yEdges(2:end), 1);

    if ~isempty(ix) && ~isempty(iy)
        keepD(i) = tissue.validBinMask(iy, ix);
    end

end

xDvalid = xDall(keepD);
yDvalid = yDall(keepD);

xDinvalid = xDall(~keepD);
yDinvalid = yDall(~keepD);

divisions = getDivisionMetrics( ...
    xDvalid,...
    yDvalid,...
    tissue,...
    cells,...
    grid);

result.divisions = divisions;

%% --- QC INFO ---

extrusions.allX = xEall;
extrusions.allY = yEall;

extrusions.validX = xEvalid;
extrusions.validY = yEvalid;

extrusions.invalidX = xEinvalid;
extrusions.invalidY = yEinvalid;

extrusions.nTotal = numel(xEall);
extrusions.nValid = numel(xEvalid);
extrusions.nInvalid = numel(xEinvalid);

%RAJOUT
divisions.allX = xDall;
divisions.allY = yDall;

divisions.validX = xDvalid;
divisions.validY = yDvalid;

divisions.invalidX = xDinvalid;
divisions.invalidY = yDinvalid;

divisions.nTotal = numel(xDall);
divisions.nValid = numel(xDvalid);
divisions.nInvalid = numel(xDinvalid);

%% --- OUTPUT ---

result.tissue = tissue;
result.cells = cells;
result.extrusions = extrusions;
result.divisions = divisions;
result.validMask = validMask;

result.QC.fractionValid = extrusions.nValid / max(extrusions.nTotal,1);
result.QC.fractionInvalid = extrusions.nInvalid / max(extrusions.nTotal,1);
result.QC.divisionFractionValid = ...
    divisions.nValid / max(divisions.nTotal,1);

result.QC.divisionFractionInvalid = ...
    divisions.nInvalid / max(divisions.nTotal,1);
end