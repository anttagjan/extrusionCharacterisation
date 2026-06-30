function summary = aggregateSpatialData(binnedData)
fprintf("Calculating spatial summary...\n")

[nM, nT] = size(binnedData);

initialized = false;

sumCells = [];
sumArea  = [];
sumExtr  = [];
sumDiv  = [];

eccStack = cell(nBins);
arStack  = cell(nBins);
oriStack = cell(nBins);
cellStack = [];

% Loop over all movies + time

for i = 1:nM %Movie
    movieCells = [];

    for j = 1:nT %Time

        d = binnedData{i,j};
        if isempty(d)
            continue
        end

        % --- initialize ---
        if ~initialized
            nBins = size(d.cells.count);

            sumCells = zeros(nBins);
            sumArea  = zeros(nBins);
            sumExtr  = zeros(nBins);
            sumDiv  = zeros(nBins);

            initialized = true;
        end

        if isempty(movieCells)
            movieCells = zeros(nBins);
        end

        % --- load data ---
        c  = d.cells.count;            c(isnan(c)) = 0;
        a  = d.cells.areaSum;          a(isnan(a)) = 0;

        movieCells = movieCells + c; %additionne à chaque temps les cellules (add each time bin, cells)

        e  = d.extrusions.count;       e(isnan(e)) = 0;
        if isfield(d,'divisions')

            dv = d.divisions.count;
            dv(isnan(dv)) = 0;

        else

            dv = zeros(size(c));

        end

        valid = ~isnan(d.cells.count);

        % --- accumulate ---
        sumCells(valid) = sumCells(valid) + c(valid);
        sumArea(valid)  = sumArea(valid)  + a(valid);
        sumExtr(valid)  = sumExtr(valid)  + e(valid);
        sumDiv(valid)  = sumDiv(valid)  + dv(valid);

        %% stack continous features from raw data
        for idx = find(valid)'

            % ---- eccentricity ----
            ecc = d.cells.eccentricity{idx};
            if ~isempty(ecc)
                eccStack{idx,1} = [eccStack{idx,1}; ecc(:)];
            end

            % ---- aspect ratio ----
            ar = d.cells.aspectRatio{idx};
            if ~isempty(ar)
                arStack{idx,1} = [arStack{idx,1}; ar(:)];
            end

            % ---- orientation----
            ori = d.cells.orientation{idx};

            if ~isempty(ori)
                oriStack{idx,1} = [oriStack{idx,1}; ori(:)];
            end

        end
    end
        cellStack(:,:,i) = movieCells;
    end

%% Output

% total
summary.totalCells = sumCells;
summary.totalArea  = sumArea;
summary.totalExtr  = sumExtr;
summary.totalDiv  = sumDiv;

% rates per number cells
summary.cellDensity = sumCells ./ sumArea;
summary.cellDensity(sumArea == 0) = NaN;

summary.extrusionRate = sumExtr ./ sumCells;
summary.extrusionRate(sumCells == 0) = NaN;

summary.divisionRate = sumDiv ./ sumCells;
summary.divisionRate(sumCells == 0) = NaN;

% area
summary.meanArea = sumArea ./ sumCells;
summary.meanArea(sumCells == 0) = NaN;

% average of stacked features
summary.meanEccentricity = nan(nBins);
summary.meanAspectRatio  = nan(nBins);
summary.meanOrientation = nan(nBins);

for idx = 1:numel(sumCells)

    if ~isempty(eccStack{idx})
        summary.meanEccentricity(idx) = mean(eccStack{idx});
    end

    if ~isempty(arStack{idx})
        summary.meanAspectRatio(idx) = mean(arStack{idx});
    end

    if ~isempty(oriStack{idx})
        summary.meanOrientation(idx) = mean(oriStack{idx});
    end

end

%% =========================================================
% Average across movies
%% =========================================================
summary.cellAverage = mean(cellStack,3);
summary.deviation   = std(cellStack,0,3);
summary.coefVar     = summary.deviation ./ summary.cellAverage;
summary.coefVar(summary.cellAverage==0)=NaN;

end