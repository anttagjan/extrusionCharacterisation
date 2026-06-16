function exportFeatureDistributions(filepath, filenames, allData, selectedBins, timeBins)

nMovies = size(allData,1);
nT      = size(allData,2);
nZones  = size(selectedBins,3);

zoneNames = {'Midline','Posterior','Up','Down'};

features = {'cellArea','cellDensity','eccentricity','aspectRatio','orientation'};

excelRaw  = fullfile(filepath,"dataframes","Feature_RAW.xlsx");
excelNorm = fullfile(filepath,"dataframes","Feature_NORMALISED.xlsx");

% =========================================================
% LOOP ZONES
% =========================================================

for z = 1:nZones

    zoneMask = selectedBins(:,:,z);

    % =========================
    % RAW accumulators
    % =========================
    sumArea   = zeros(length(timeBins), nMovies);
    sumCells  = zeros(length(timeBins), nMovies);
    sumTissue = zeros(length(timeBins), nMovies);

    sumEcc = zeros(length(timeBins), nMovies);
    sumAR  = zeros(length(timeBins), nMovies);
    sumOri = zeros(length(timeBins), nMovies);

    % =========================
    % LOOP DATA
    % =========================

    for m = 1:nMovies
        for t = 1:nT

            d = allData{m,t};
            if isempty(d) || ~isfield(d,'cells') || ~isfield(d,'tissue')
                continue
            end

            c  = d.cells.count;            c(isnan(c)) = 0;
            a  = d.cells.areaSum;          a(isnan(a)) = 0;
            ec = d.cells.eccentricityMean; ec(isnan(ec)) = 0;
            ar = d.cells.aspectRatioMean;  ar(isnan(ar)) = 0;
            or = d.cells.orientationMean;  or(isnan(or)) = 0;

            tissue = d.tissue.area;
            tissue(isnan(tissue)) = 0;

            % apply zone mask
            cZ = c .* zoneMask;
            aZ = a .* zoneMask;
            ecZ = ec .* zoneMask;
            arZ = ar .* zoneMask;
            orZ = or .* zoneMask;
            tZ  = tissue .* zoneMask;

            % RAW
            sumCells(t,m)  = sum(cZ(:));
            sumArea(t,m)   = sum(aZ(:));
            sumEcc(t,m)    = sum(ecZ(:));
            sumAR(t,m)     = sum(arZ(:));
            sumOri(t,m)    = sum(orZ(:));
            sumTissue(t,m) = sum(tZ(:));
        end
    end

    % =========================================================
    % NORMALIZATION (same logic style as your extrusion code)
    % =========================================================

    cellDensity = sumCells ./ max(sumTissue,1);
    meanArea    = sumArea  ./ max(sumCells,1);

    eccNorm = sumEcc ./ max(sumCells,1);
    arNorm  = sumAR  ./ max(sumCells,1);
    oriNorm = sumOri ./ max(sumCells,1);

    % =========================================================
    % WRITE RAW (same structure as extrusion summary)
    % =========================================================

    writeFeatureSheets(excelRaw, zoneNames{z}, ...
        sumCells, sumArea, sumEcc, sumAR, sumOri, sumTissue, ...
        filenames, timeBins);

    % =========================================================
    % WRITE NORMALISED
    % =========================================================

    writeFeatureSheets(excelNorm, zoneNames{z}, ...
        cellDensity, meanArea, eccNorm, arNorm, oriNorm, sumTissue, ...
        filenames, timeBins);

    fprintf('[INFO] Zone %s exported (raw + normalised)\n', zoneNames{z});
end

end