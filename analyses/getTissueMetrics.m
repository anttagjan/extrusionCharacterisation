function tissue = getTissueMetrics(validMask, grid)

if isempty(validMask)
    tissue.area = [];
    tissue.validBinMask = [];
    return
end

% Fraction of valid pixels required
threshold = 0.75;      % 0.50

nY = numel(grid.yEdges)-1;
nX = numel(grid.xEdges)-1;

tissue.area = zeros(nY,nX);
tissue.validBinMask = false(nY,nX);

for iy = 1:nY

    y1 = max(1, floor(grid.yEdges(iy)));
    y2 = min(size(validMask,1), ceil(grid.yEdges(iy+1))-1);

    for ix = 1:nX

        x1 = max(1, floor(grid.xEdges(ix)));
        x2 = min(size(validMask,2), ceil(grid.xEdges(ix+1))-1);

        block = validMask(y1:y2,x1:x2);

        tissue.area(iy,ix) = sum(block(:));

        fracValid = mean(block(:));

        tissue.validBinMask(iy,ix) = fracValid >= threshold;

    end
end

end