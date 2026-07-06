function summary = aggregateSpatialData(binnedData)

fprintf("Calculating spatial summary...\n")

[nM, nT] = size(binnedData);

initialized = false;

sumCells = [];
sumArea  = [];
sumExtr  = [];
sumDiv   = [];

eccStack = {};
arStack  = {};
oriStack = {};
areaStack = {};
cellStack = [];

% =========================================================
% LOOP OVER MOVIES + TIME
% =========================================================

for i = 1:nM

    movieCells = [];

    for j = 1:nT

        d = binnedData{i,j};
        if isempty(d), continue; end

        % -------------------------
        % INITIALIZATION
        % -------------------------
        if ~initialized

            nBins = size(d.cells.count);

            sumCells = zeros(nBins);
            sumArea  = zeros(nBins);
            sumExtr  = zeros(nBins);
            sumDiv   = zeros(nBins);

            % initialize stacks AFTER knowing nBins
            eccStack = cell(nBins);
            arStack  = cell(nBins);
            oriStack = cell(nBins);
            areaStack = cell(nBins);

            initialized = true;
        end

        if isempty(movieCells)
            movieCells = zeros(nBins);
        end

        % -------------------------
        % LOAD MAPS
        % -------------------------
        c = d.cells.count;   c(isnan(c)) = 0;
        a = d.cells.areaSum; a(isnan(a)) = 0;

        e = d.extrusions.count; e(isnan(e)) = 0;

        if isfield(d,'divisions')
            dv = d.divisions.count;
            dv(isnan(dv)) = 0;
        else
            dv = zeros(size(c));
        end

        valid = ~isnan(d.cells.count);

        % -------------------------
        % ACCUMULATE MAPS
        % -------------------------
        sumCells(valid) = sumCells(valid) + c(valid);
        sumArea(valid)  = sumArea(valid)  + a(valid);
        sumExtr(valid)  = sumExtr(valid)  + e(valid);
        sumDiv(valid)   = sumDiv(valid)   + dv(valid);

        movieCells = movieCells + c;

        % =========================================================
        % STACK RAW FEATURES
        % =========================================================
        [rows, cols] = find(valid);

        for k = 1:length(rows)

            iBin = rows(k);
            jBin = cols(k);

            ecc = d.cells.eccentricity{iBin,jBin};

            if ~isempty(ecc)
                eccStack{iBin,jBin} = [eccStack{iBin,jBin}; ecc(:)];
            end

            ar = d.cells.aspectRatio{iBin,jBin};

            if ~isempty(ar)
                arStack{iBin,jBin} = [arStack{iBin,jBin}; ar(:)];
            end

            ori = d.cells.orientation{iBin,jBin};

            if ~isempty(ori)
                oriStack{iBin,jBin} = [oriStack{iBin,jBin}; ori(:)];
            end

            area = d.cells.area{iBin,jBin};

            if ~isempty(ecc)
                areaStack{iBin,jBin} = [areaStack{iBin,jBin}; area(:)];
            end

        end
    end

    % IMPORTANT: outside time loop
    cellStack(:,:,i) = movieCells;

end

% =========================================================
% OUTPUT MAPS
% =========================================================

summary.totalCells = sumCells;
summary.totalArea  = sumArea;
summary.totalExtr  = sumExtr;
summary.totalDiv   = sumDiv;

summary.cellDensity = sumCells ./ sumArea;
summary.cellDensity(sumArea == 0) = NaN;

summary.extrusionRate = sumExtr ./ sumCells;
summary.extrusionRate(sumCells == 0) = NaN;

summary.divisionRate = sumDiv ./ sumCells;
summary.divisionRate(sumCells == 0) = NaN;

% =========================================================
% STACKED FEATURES MEANS
% =========================================================

summary.meanEccentricity = nan(nBins);
summary.meanAspectRatio   = nan(nBins);
summary.meanOrientation   = nan(nBins);
summary.meanArea   = nan(nBins);


for idx = 1:numel(sumCells)

    if ~isempty(eccStack{idx})
        summary.meanEccentricity(idx) = mean(eccStack{idx},'omitnan');
        summary.cvEccentricity(idx) = std(eccStack{idx},'omitnan') / mean(eccStack{idx},'omitnan');
    end

    if ~isempty(arStack{idx})
        summary.meanAspectRatio(idx) = mean(arStack{idx}, 'omitnan');
        summary.cvAspectRatio(idx) = std(arStack{idx},'omitnan') / mean(arStack{idx},'omitnan');
    end

    if ~isempty(oriStack{idx})
        summary.meanOrientation(idx) = mean(oriStack{idx},'omitnan');
        summary.cvOrientation(idx) = std(oriStack{idx},'omitnan') / mean(oriStack{idx},'omitnan');
    end
    
    if ~isempty(areaStack{idx})
        summary.meanArea(idx) = mean(areaStack{idx},'omitnan');
        summary.cvArea(idx) = std(areaStack{idx},'omitnan') / mean(areaStack{idx},'omitnan');
    end

end

% =========================================================
% ACROSS MOVIES
% =========================================================

summary.cellAverage = mean(cellStack,3);
summary.deviation   = std(cellStack,0,3);

summary.coefVar = summary.deviation ./ summary.cellAverage;
summary.coefVar(summary.cellAverage==0) = NaN;

end