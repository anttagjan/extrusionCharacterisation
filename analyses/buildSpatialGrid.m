function grid = buildSpatialGrid(procruste_transformed, nBins)

X = procruste_transformed(:,1);
Y = procruste_transformed(:,2);

marginX = 0.01 * (max(X)-min(X));
marginY = 0.01 * (max(Y)-min(Y));

grid.xEdges = linspace(min(X)-marginX, max(X)+marginX, nBins+1);
grid.yEdges = linspace(min(Y)-marginY, max(Y)+marginY, nBins+1);

grid.nBins = nBins;

end