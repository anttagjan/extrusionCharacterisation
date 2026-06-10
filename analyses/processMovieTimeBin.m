function result = processMovieTimeBin( ...
    movieID, timeIndex, timeBins, ...
    extrusions_transformed, masks_transformed, ...
    features_transformed, grid)

timeLimits = [timeBins(timeIndex), timeBins(timeIndex+1)];

%% --- FILTER DATA ---
idx = extrusions_transformed(:,4)==movieID & ...
      extrusions_transformed(:,3)>=timeLimits(1) & ...
      extrusions_transformed(:,3)<timeLimits(2);

idxF = features_transformed(:,8)==movieID & ...
       features_transformed(:,6)>=timeLimits(1) & ...
       features_transformed(:,6)<timeLimits(2);

%% --- TISSUE MASK ---

mask = masks_transformed{movieID};

if isempty(mask)
    validMask = [];
else
    % mask is assumed: H x W x T logical
    invalidRegion = mask(:,:,timeIndex) == 0;
    validMask = ~invalidRegion;
end

tissue = getTissueMetrics(validMask, grid);

%% --- CELLS ---

xC = features_transformed(idxF,1);
yC = features_transformed(idxF,2);
aC = features_transformed(idxF,4);

cells = getCellMetrics(xC, yC, aC, tissue, grid);

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

%% --- OUTPUT ---

result.tissue = tissue;
result.cells = cells;
result.extrusions = extrusions;
result.validMask = validMask;

result.QC.fractionValid = extrusions.nValid / max(extrusions.nTotal,1);
result.QC.fractionInvalid = extrusions.nInvalid / max(extrusions.nTotal,1);

end