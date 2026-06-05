function result = processMovieTimeBin( ...
    movieID, timeIndex, timeBins, ...
    procruste_transformed, masks_transformed, ...
    features_transformed, peaks, grid)

timeLimits = [timeBins(timeIndex), timeBins(timeIndex+1)];

% --- FILTER DATA ---
idx = procruste_transformed(:,3)==movieID & ...
      procruste_transformed(:,4)>=timeLimits(1) & ...
      procruste_transformed(:,4)<timeLimits(2);

idxF = features_transformed(:,8)==movieID & ...
       features_transformed(:,6)>=timeLimits(1) & ...
       features_transformed(:,6)<timeLimits(2);

% --- TISSUE MASK ---
mask = masks_transformed{movieID};

if ~isempty(mask)
    validMask = any(mask(:,:,1:end),3);
else
    validMask = [];
end

tissue = getTissueMetrics(validMask, grid);

% --- CELLS ---
xC = features_transformed(idxF,1);
yC = features_transformed(idxF,2);
aC = features_transformed(idxF,4);

cells = getCellMetrics(xC,yC,aC,tissue,grid);

% --- EXTRUSIONS ---
xE = procruste_transformed(idx,1);
yE = procruste_transformed(idx,2);

extrusions = getExtrusionMetrics(xE,yE,tissue,grid);

% --- OUTPUT ---
result.tissue = tissue;
result.cells = cells;
result.extrusions = extrusions;

end