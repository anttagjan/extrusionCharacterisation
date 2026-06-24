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

xC = features_transformed.x(idxF);
yC = features_transformed.y(idxF);
aC = features_transformed.area(idxF);
eC = features_transformed.eccentricity(idxF);
arC = features_transformed.aspect_ratio(idxF);
oC= features_transformed.orientation(idxF);

cells = getCellMetrics(xC, yC, aC,eC,arC,oC, tissue, grid);

%% --- EXTRUSIONS ---

xEall = extrusions_transformed(idx,1);
yEall = extrusions_transformed(idx,2);

keep = false(size(xEall));

if ~isempty(validMask)

    xPix = round(xEall);
    yPix = round(yEall);

    insideImage = ...
        xPix >= 1 & xPix <= size(validMask,2) & ...
        yPix >= 1 & yPix <= size(validMask,1);

    if any(insideImage)

        idxPixels = sub2ind( ...
            size(validMask), ...
            yPix(insideImage), ...
            xPix(insideImage));

        keep(insideImage) = validMask(idxPixels);

    end
end

xEvalid = xEall(keep);
yEvalid = yEall(keep);

xEinvalid = xEall(~keep);
yEinvalid = yEall(~keep);

extrusions = getExtrusionMetrics( ...
    xEvalid, yEvalid, tissue, grid);

%% --- DIVISIONS --- RAJOUT


xDall = divisions_transformed(idxD,1);
yDall = divisions_transformed(idxD,2);


keepD = false(size(xDall));

if ~isempty(validMask)

    xPix = round(xDall);
    yPix = round(yDall);

    insideImage = ...
        xPix >= 1 & xPix <= size(validMask,2) & ...
        yPix >= 1 & yPix <= size(validMask,1);

    if any(insideImage)

        idxPixels = sub2ind( ...
            size(validMask), ...
            yPix(insideImage), ...
            xPix(insideImage));

        keepD(insideImage) = validMask(idxPixels);

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