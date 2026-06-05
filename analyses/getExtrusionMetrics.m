function extrusions = getExtrusionMetrics(x,y,tissue,grid)

ix = discretize(x, grid.xEdges);
iy = discretize(y, grid.yEdges);

valid = ~isnan(ix) & ~isnan(iy);

ix = ix(valid);
iy = iy(valid);

nBins = grid.nBins;

extrusions.count = accumarray([iy ix], 1, [nBins nBins], @sum, 0);

extrusions.density = extrusions.count ./ tissue.area;
extrusions.density(tissue.area==0) = NaN;

extrusions.count(~tissue.validBinMask) = NaN;
extrusions.density(~tissue.validBinMask) = NaN;

end