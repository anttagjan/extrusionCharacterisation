function result = processMovieTimeBin( ...
    movieID, timeIndex, timeBins, ...
    extrusions_transformed, masks_transformed, masks_relativeTime, ...
    features_transformed, grid)

timeLimits = [timeBins(timeIndex), timeBins(timeIndex+1)];

%% --- FILTER DATA ---
idx = extrusions_transformed(:,4)==movieID & ...
      extrusions_transformed(:,3)>=timeLimits(1) & ...
      extrusions_transformed(:,3)<timeLimits(2);

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