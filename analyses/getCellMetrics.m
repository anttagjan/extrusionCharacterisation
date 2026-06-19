function cells = getCellMetrics(x,y,area,eccentricity,aspectRatio,orientation,tissue,grid)

ix = discretize(x, grid.xEdges);
iy = discretize(y, grid.yEdges);

valid = ~isnan(ix) & ~isnan(iy);

ix = ix(valid);
iy = iy(valid);

area = area(valid);
eccentricity = eccentricity(valid);
aspectRatio = aspectRatio(valid);
orientation = orientation(valid);

nBins = grid.nBins;

% --- basic maps ---
cells.count = accumarray([iy ix], 1, [nBins nBins], @sum, 0);
cells.areaSum = accumarray([iy ix], area, [nBins nBins], @sum, 0);

cells.areaMean = accumarray([iy ix], area, [nBins nBins], @mean, NaN);
cells.eccentricityMean = accumarray([iy ix], eccentricity, [nBins nBins], @mean, NaN);
cells.aspectRatioMean = accumarray([iy ix], aspectRatio, [nBins nBins], @mean, NaN);

% =========================================================
% CELL DENSITY (your chosen definition)
% =========================================================

cells.cellDensity = cells.count ./ cells.areaSum;
cells.cellDensity(cells.areaSum == 0) = NaN;

% =========================================================
% ORIENTATION (CORRECT CIRCULAR AXIAL)
% =========================================================

oriRad = deg2rad(orientation * 2);

cosComp = accumarray([iy ix], cos(oriRad), [nBins nBins], @sum, 0);
sinComp = accumarray([iy ix], sin(oriRad), [nBins nBins], @sum, 0);

cells.orientationMean = rad2deg(0.5 * atan2(sinComp, cosComp));

% =========================================================
% APPLY TISSUE MASK
% =========================================================

cells.count(~tissue.validBinMask) = NaN;
cells.areaSum(~tissue.validBinMask) = NaN;
cells.areaMean(~tissue.validBinMask) = NaN;
cells.eccentricityMean(~tissue.validBinMask) = NaN;
cells.aspectRatioMean(~tissue.validBinMask) = NaN;
cells.orientationMean(~tissue.validBinMask) = NaN;
cells.cellDensity(~tissue.validBinMask) = NaN;

end