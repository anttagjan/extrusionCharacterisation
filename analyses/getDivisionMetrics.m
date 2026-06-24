
%% Convertit coo, dans une matrice (colonne/lignes) + supp point hors image
function divisions = getDivisionMetrics(x,y,tissue,grid)

ix = discretize(x, grid.xEdges);
iy = discretize(y, grid.yEdges);

valid = ~isnan(ix) & ~isnan(iy);

ix = ix(valid);
iy = iy(valid);

nBins = grid.nBins;

if isempty(ix)
    divisions.count = zeros(nBins, nBins);
else
    divisions.count = accumarray([iy ix], 1, [nBins nBins], @sum, 0);
end

divisions.density = divisions.count ./ tissue.area;
divisions.density(tissue.area==0) = NaN;

divisions.count(~tissue.validBinMask) = NaN;
divisions.density(~tissue.validBinMask) = NaN;

end