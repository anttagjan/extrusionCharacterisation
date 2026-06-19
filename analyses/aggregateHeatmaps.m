function summary = aggregateHeatmaps(allData)

[nM, nT] = size(allData);

initialized = false;

sumCells = [];
sumArea  = [];
sumExtr  = [];

sumEcc = [];
sumAR  = [];

sumOriX = [];
sumOriY = [];

%% =========================================================
% LOOP OVER DATA
%% =========================================================

for i = 1:nM
    for j = 1:nT

        d = allData{i,j};
        if isempty(d)
            continue
        end

        % --- initialize ---
        if ~initialized
            nBins = size(d.cells.count);

            sumCells = zeros(nBins);
            sumArea  = zeros(nBins);
            sumExtr  = zeros(nBins);

            sumEcc = zeros(nBins);
            sumAR  = zeros(nBins);

            sumOriX = zeros(nBins);
            sumOriY = zeros(nBins);

            initialized = true;
        end

        % --- load data ---
        c  = d.cells.count;            c(isnan(c)) = 0;
        a  = d.cells.areaSum;          a(isnan(a)) = 0;

        ec = d.cells.eccentricityMean; ec(isnan(ec)) = 0;
        ar = d.cells.aspectRatioMean;  ar(isnan(ar)) = 0;
        or = d.cells.orientationMean;  or(isnan(or)) = 0;

        e  = d.extrusions.count;       e(isnan(e)) = 0;

        valid = ~isnan(d.cells.count);

        % --- accumulate ---
        sumCells(valid) = sumCells(valid) + c(valid);
        sumArea(valid)  = sumArea(valid)  + a(valid);
        sumExtr(valid)  = sumExtr(valid)  + e(valid);

        % --- morphology (cell-weighted) ---
        sumEcc(valid) = sumEcc(valid) + ec(valid) .* c(valid);
        sumAR(valid)  = sumAR(valid)  + ar(valid) .* c(valid);

        % --- orientation (CIRCULAR [-90, 90]) ---
        oriRad = deg2rad(or(valid) * 2);

        sumOriX(valid) = sumOriX(valid) + c(valid) .* cos(oriRad);
        sumOriY(valid) = sumOriY(valid) + c(valid) .* sin(oriRad);

    end
end

%% =========================================================
% OUTPUT RAW MAPS
%% =========================================================

summary.totalCells = sumCells;
summary.totalArea  = sumArea;
summary.totalExtr  = sumExtr;

%% =========================================================
% NO CELLS PER AREA 
%% =========================================================

summary.cellDensity = sumCells ./ sumArea;
summary.cellDensity(sumArea == 0) = NaN;

%% =========================================================
% EXTRUSION RATE (YOUR FINAL CHOICE)
%% =========================================================

summary.extrusionRate = sumExtr ./ sumCells;
summary.extrusionRate(sumCells == 0) = NaN;

%% =========================================================
% SHAPE FEATURES (CELL-WEIGHTED)
%% =========================================================

summary.meanArea = sumArea ./ sumCells;
summary.meanEccentricity = sumEcc ./ sumCells;
summary.meanAspectRatio  = sumAR  ./ sumCells;

summary.meanEccentricity(sumCells == 0) = NaN;
summary.meanAspectRatio(sumCells == 0) = NaN;

%% =========================================================
% ORIENTATION (CIRCULAR CORRECT)
%% =========================================================

summary.meanOrientation = rad2deg(0.5 * atan2(sumOriY, sumOriX));

end