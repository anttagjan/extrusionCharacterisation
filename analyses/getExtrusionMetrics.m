function extrusions = getExtrusionMetrics(x,y,cells,grid)

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

extrusions.rate = extrusions.count ./ cells.count;
extrusions.rate(cells.count==0) = NaN;

extrusions.count(~tissue.validBinMask) = NaN;
extrusions.rate(~tissue.validBinMask) = NaN;

end