function exportFeatureDistributions(filepath, filenames, allData, selectedBins, timeBins)

nMovies = size(allData,1);
nT      = size(allData,2);

% =========================================================
% ADD GLOBAL ZONE (ALL SPACE)
% =========================================================

allMask = true(size(selectedBins(:,:,1)));
selectedBins = cat(3, selectedBins, allMask);

zoneNames = {'Midline','Posterior','Up','Down','All'};
nZones = size(selectedBins,3);

excelRaw = fullfile(filepath,"dataframes","Feature_RAW.xlsx");

% =========================================================
% LOOP ZONES
% =========================================================

for z = 1:nZones

    zoneMask = double(selectedBins(:,:,z));
    zoneMask(~zoneMask) = NaN;

    % =====================================================
    % OUTPUT MATRICES
    % =====================================================

    meanCells  = NaN(length(timeBins), nMovies);
    meanArea   = NaN(length(timeBins), nMovies);

    meanEcc = NaN(length(timeBins), nMovies);
    meanOri = NaN(length(timeBins), nMovies);

    % =====================================================
    % LOOP DATA
    % =====================================================

    for m = 1:nMovies
        for t = 1:nT

            d = allData{m,t};

            if isempty(d) || ~isfield(d,'cells') || ~isfield(d,'tissue')
                continue
            end

            % ----------------------------
            % LOAD MAPS
            % ----------------------------

            c  = d.cells.count;
            a  = d.cells.areaSum;

            ec = d.cells.eccentricityMean;
            or = d.cells.orientationMean;

            tissue = d.tissue.area;

            % ----------------------------
            % CLEAN NaNs
            % ----------------------------

            c(isnan(c)) = 0;
            a(isnan(a)) = 0;

            ec(isnan(ec)) = 0;
            or(isnan(or)) = 0;

            tissue(isnan(tissue)) = 0;

            % ----------------------------
            % APPLY MASK
            % ----------------------------

            cZ = c .* zoneMask;
            aZ = a .* zoneMask;
            ecZ = ec .* zoneMask;
            orZ = or .* zoneMask;

            % =================================================
            % BASIC METRICS
            % =================================================

            meanCells(t,m)  = mean(cZ(cZ>0),'omitnan');

            nCells = nansum(cZ(:));
            totalCells(t,m) = nCells;

            if nCells > 0

                % ----------------------------
                % AREA PER CELL
                % ----------------------------
                meanArea(t,m) = nansum(aZ(:)) / nCells;

                % ----------------------------
                % ECCENTRICITY (cell-weighted)
                % ----------------------------
                meanEcc(t,m) = nansum(ecZ(:) .* cZ(:)) / nCells;

                % ----------------------------
                % ORIENTATION (CIRCULAR [-90,90])
                % ----------------------------

                valid = cZ(:) > 0;

                if any(valid)

                    weights = cZ(valid);
                    angles  = deg2rad(orZ(valid) * 2);

                    x = nansum(weights .* cos(angles));
                    y = nansum(weights .* sin(angles));

                    meanOri(t,m) = abs(rad2deg(0.5 * atan2(y, x)));

                end
            end

        end
    end

    % =====================================================
    % EXPORT
    % =====================================================

    writeFeatureSheets( ...
        excelRaw, ...
        zoneNames{z}, ...
        meanCells, ...
        totalCells, ...
        meanArea, ...
        meanEcc, ...
        meanOri, ...
        filenames, ...
        timeBins);

    fprintf('[INFO] Zone %s exported\n', zoneNames{z});

end

end