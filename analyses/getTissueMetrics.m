function tissue = getTissueMetrics(validMask, grid)

if isempty(validMask)
    tissue.area = [];
    tissue.validBinMask = [];
    return
end

[H,W] = size(validMask);
[xx,yy] = meshgrid(1:W,1:H);

x = xx(validMask);
y = yy(validMask);

tissue.area = histcounts2( ...
    y, x, ...
    grid.yEdges, grid.xEdges);

tissue.validBinMask = tissue.area > 0;

end