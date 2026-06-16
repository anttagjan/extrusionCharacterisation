function summary = aggregateHeatmaps(allData)

[nM, nT] = size(allData);

initialized = false;

sumCells = [];
sumArea = [];
sumExtr = [];
sumTissue   = [];
weight      = [];

% shape features (all scalar → weighted means)
sumEcc      = [];
sumAR       = [];
sumOri      = [];

%% =========================================================
% ACCUMULATION LOOP
%% =========================================================

for i = 1:nM
    for j = 1:nT

        d = allData{i,j};
        if isempty(d)
            continue
        end

        % --- initialize once ---
        if ~initialized
            nBins = size(d.cells.count);

            sumCells  = zeros(nBins);
            sumArea   = zeros(nBins);
            sumExtr   = zeros(nBins);
            sumTissue = zeros(nBins);
            weight    = zeros(nBins);

            sumEcc = zeros(nBins);
            sumAR  = zeros(nBins);
            sumOri = zeros(nBins);

            initialized = true;
        end

        % --- extract maps ---
        c = d.cells.count;      c(isnan(c)) = 0;
        a = d.cells.areaSum;    a(isnan(a)) = 0;
        ec = d.cells.eccentricityMean;    ec(isnan(ec)) = 0;
        ar = d.cells.aspectRatioMean;    ar(isnan(ar)) = 0;
        or = d.cells.orientationMean;    or(isnan(or)) = 0;

        e = d.extrusions.count; e(isnan(e)) = 0;
        t = d.tissue.area;      t(isnan(t)) = 0;

        valid = ~isnan(d.tissue.area);

        % --- accumulate ---
        sumCells(valid)  = sumCells(valid)  + c(valid);
        sumArea(valid)   = sumArea(valid)   + a(valid);
        sumExtr(valid)   = sumExtr(valid)   + e(valid);
        sumTissue(valid) = sumTissue(valid) + t(valid);

        % --- shape features (weighted by cell count) ---
        sumEcc(valid) = sumEcc(valid) + ec(valid) .* c(valid);
        sumAR(valid)  = sumAR(valid)  + ar(valid) .* c(valid);
        sumOri(valid) = sumOri(valid) + or(valid) .* c(valid);
        
        % --- observation count ---
        weight(valid) = weight(valid) + 1;
    end
end

%% =========================================================
% OUTPUT RAW CUMULATIVE MAPS
%% =========================================================

summary.totalCells       = sumCells;
summary.totalCellArea    = sumArea;
summary.totalExtrusions  = sumExtr;
summary.totalTissueArea  = sumTissue;

%% =========================================================
% NORMALIZED METRICS (OPTIONAL BUT IMPORTANT)
%% =========================================================

summary.cellDensity = sumCells ./ sumTissue;
summary.extrusionDensity = sumExtr ./ sumTissue;

summary.cellDensity(sumTissue == 0) = NaN;
summary.extrusionDensity(sumTissue == 0) = NaN;

summary.meanCellArea = sumArea ./ sumCells;
summary.meanCellArea(sumCells == 0) = NaN;

%% =========================================================
% SHAPE FEATURES (WEIGHTED MEANS)
%% =========================================================

summary.meanEccentricity = sumEcc ./ sumCells;
summary.meanAspectRatio  = sumAR  ./ sumCells;
summary.meanOrientation  = sumOri ./ sumCells;

summary.meanEccentricity(sumCells == 0) = NaN;
summary.meanAspectRatio(sumCells == 0) = NaN;
summary.meanOrientation(sumCells == 0) = NaN;

%% =========================================================
% SUPPORT MAP (QUALITY CONTROL)
%% =========================================================

summary.observationCount = weight;

end