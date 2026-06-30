function exportFeatureDistributions( ...
    filepath,...
    filenames,...
    featuresFileName,...
    binnedData,...
    selectedBins,...
    timeBins,...
    keepMovies)

selectedMovies = find(keepMovies);

nMovies = length(selectedMovies);
nT      = size(binnedData,2);

% =========================================================
% ADD GLOBAL ZONE
% =========================================================

allMask = true(size(selectedBins(:,:,1)));
selectedBins = cat(3, selectedBins, allMask);

zoneNames = {'Midline','Posterior','Up','Down','All'};
nZones = size(selectedBins,3);

excelRaw = fullfile(filepath,"dataframes",featuresFileName);

filenamesSex = filenames(selectedMovies);

% =========================================================
% LOOP ZONES
% =========================================================

for z = 1:nZones

    zoneMask = double(selectedBins(:,:,z));
    zoneMask(~zoneMask) = NaN;

    % =====================================================
    % OUTPUT MATRICES
    % =====================================================

    meanCells = NaN(length(timeBins), nMovies);
    totalCells = NaN(length(timeBins), nMovies);

    meanArea = NaN(length(timeBins), nMovies);
    meanEcc  = NaN(length(timeBins), nMovies);
    meanOri  = NaN(length(timeBins), nMovies);

    % =====================================================
    % LOOP MOVIES
    % =====================================================

    for k = 1:nMovies

        m = selectedMovies(k);

        for t = 1:nT

            d = binnedData{m,t};

            if isempty(d)
                continue
            end

            if ~isfield(d,'cells')
                continue
            end

            % ----------------------------
            % LOAD MAPS
            % ----------------------------

            c  = d.cells.count;
            a  = d.cells.areaSum;

            c(isnan(c)) = 0;
            a(isnan(a)) = 0;


            % ----------------------------
            % APPLY MASK
            % ----------------------------

            cZ  = c  .* zoneMask;
            aZ  = a  .* zoneMask;

            % =================================================
            % CELL NUMBER
            % =================================================

            meanCells(t,k) = mean(cZ(cZ>0),'omitnan');

            nCells = nansum(cZ(:));
            totalCells(t,k) = nCells;

            if nCells > 0

                % ----------------------------
                % STACK FEATURES
                % ----------------------------

                areaValues = [];
                eccValues = [];
                oriValues = [];

                validBins = find(~isnan(zoneMask) & c>0);

                for idx = validBins'

                    if ~isempty(d.cells.area{idx})
                        areaValues = [areaValues; d.cells.area{idx}(:)];
                    end

                    if ~isempty(d.cells.eccentricity{idx})
                        eccValues = [eccValues; d.cells.eccentricity{idx}(:)];
                    end

                    if ~isempty(d.cells.orientation{idx})
                        oriValues = [oriValues; d.cells.orientation{idx}(:)];
                    end

                end

                % ----------------------------
                % AREA
                % ----------------------------
                if ~isempty(areaValues)
                    meanArea(t,k) = mean(areaValues);
                    cvArea(t,k)   = std(areaValues) / mean(areaValues);
                else
                    meanArea(t,k) = NaN;
                    cvArea(t,k)   = NaN;
                end

                % ----------------------------
                % ECCENTRICITY
                % ----------------------------

                if ~isempty(eccValues)
                    meanEcc(t,k) = mean(eccValues);
                    cvEcc(t,k)   = std(eccValues) / mean(eccValues);
                else
                    meanEcc(t,k) = NaN;
                    cvEcc(t,k)   = NaN;
                end

                % ----------------------------
                % ORIENTATION
                % ----------------------------

                if ~isempty(oriValues)
                    meanOri(t,k) = mean(oriValues);
                    cvOri(t,k)   = std(oriValues) / mean(oriValues);
                else
                    meanOri(t,k) = NaN;
                    cvOri(t,k)   = NaN;
                end

            end

        end

    end

    % =====================================================
    % EXPORT
    % =====================================================
    featureStruct.meanCells   = meanCells;
    featureStruct.totalCells  = totalCells;
    featureStruct.meanArea    = meanArea;
    featureStruct.meanEcc     = meanEcc;
    featureStruct.cvEcc       = cvEcc;
    featureStruct.meanOri     = meanOri;
    featureStruct.cvOri       = cvOri;
    featureStruct.cvArea      = cvArea;

    writeFeatureSheets(excelRaw, zoneNames{z}, filenames, timeBins, featureStruct);

    fprintf('[INFO] Zone %s exported\n', ...
        zoneNames{z});

end

end