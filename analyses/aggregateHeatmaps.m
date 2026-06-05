function summary = aggregateHeatmaps(allData)

[nM,nT] = size(allData);

initialized = false;

for i = 1:nM
    for j = 1:nT

        if isempty(allData{i,j})
            continue
        end

        if ~initialized
            nBins = size(allData{i,j}.cells.count,1);

            sumCells = zeros(nBins);
            sumArea  = zeros(nBins);
            sumExtr  = zeros(nBins);
            sumTissue = zeros(nBins);

            initialized = true;
        end

        c = allData{i,j}.cells.count;       c(isnan(c)) = 0;
        a = allData{i,j}.cells.areaSum;     a(isnan(a)) = 0;

        e = allData{i,j}.extrusions.count;  e(isnan(e)) = 0;

        t = allData{i,j}.tissue.area;       t(isnan(t)) = 0;

        sumCells   = sumCells + c;
        sumArea    = sumArea + a;
        sumExtr    = sumExtr + e;
        sumTissue  = sumTissue + t;

    end
end

% -------- FINAL METRICS --------
summary.totalCells = sumCells;
summary.totalCellArea = sumArea;

summary.totalExtrusions = sumExtr;
summary.totalTissueArea = sumTissue;

% densities
summary.cellDensity = sumCells ./ sumTissue;
summary.extrusionDensity = sumExtr ./ sumTissue;

summary.cellDensity(sumTissue==0) = NaN;
summary.extrusionDensity(sumTissue==0) = NaN;

% mean cell size
summary.meanCellArea = sumArea ./ sumCells;
summary.meanCellArea(sumCells==0) = NaN;

end