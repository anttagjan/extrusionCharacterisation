function extrusions = getExtrusionMetrics(x,y,tissue,grid)

ix = discretize(x, grid.xEdges);
iy = discretize(y, grid.yEdges);

valid = ~isnan(ix) & ~isnan(iy);

ix = ix(valid);
iy = iy(valid);

nBins = grid.nBins;

if isempty(ix)
    extrusions.count = zeros(nBins, nBins);
else
    extrusions.count = accumarray([iy ix], 1, [nBins nBins], @sum, 0);
end

extrusions.density = extrusions.count ./ tissue.area;
extrusions.density(tissue.area==0) = NaN;

extrusions.count(~tissue.validBinMask) = NaN;
extrusions.density(~tissue.validBinMask) = NaN;

end