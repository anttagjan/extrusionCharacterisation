function cells = getCellMetrics(x,y,area,eccentricity,aspectRatio,orientation,tissue,grid)

ix = discretize(x, grid.xEdges);
iy = discretize(y, grid.yEdges);

valid = ~isnan(ix) & ~isnan(iy);

ix = ix(valid);
iy = iy(valid);

area = area(valid);
eccentricity = eccentricity(valid);
aspectRatio = aspectRatio(valid);
orientation = abs(90-abs(orientation(valid))); %Change orientation

nBins = grid.nBins;

%% Count features 
% each bin store the sum of values
cells.count = accumarray([iy ix], 1, [nBins nBins], @sum, 0);
cells.areaSum = accumarray([iy ix], area, [nBins nBins], @sum, 0);

%% Continuous features 
% each bin stores vector of values
cells.area      = accumarray([iy ix], area,        [nBins nBins], @(x){x}, {[]});
cells.eccentricity = accumarray([iy ix], eccentricity, [nBins nBins], @(x){x}, {[]});
cells.aspectRatio  = accumarray([iy ix], aspectRatio,  [nBins nBins], @(x){x}, {[]});
cells.orientation = accumarray([iy ix], orientation, [nBins nBins], @(x){x}, {[]});

%% Cell density
cells.cellDensity = cells.count ./ cells.areaSum;
cells.cellDensity(cells.areaSum == 0) = NaN;

%% Apply tissue mask
cells.count(~tissue.validBinMask) = NaN;
cells.areaSum(~tissue.validBinMask) = NaN;
cells.cellDensity(~tissue.validBinMask) = NaN;

cells.area(~tissue.validBinMask) = {[]};
cells.eccentricity(~tissue.validBinMask) = {[]};
cells.aspectRatio(~tissue.validBinMask) = {[]};
cells.orientation(~tissue.validBinMask) = {[]};

end