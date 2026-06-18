function writeFeatureSheets(excelFile, zoneName, ...
    cellDensity, meanArea, ecc, ar, ori, tissue, filenames, timeBins)

% =========================
% CELL DENSITY
% =========================

T = array2table(cellDensity, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

writetable(T, excelFile, ...
    'Sheet', strcat(zoneName,'_CellDensity'), ...
    'WriteMode','overwritesheet');

% =========================
% MEAN AREA
% =========================

T = array2table(meanArea, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

writetable(T, excelFile, ...
    'Sheet', strcat(zoneName,'_MeanArea'), ...
    'WriteMode','overwritesheet');

% =========================
% ECCENTRICITY
% =========================

T = array2table(ecc, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

writetable(T, excelFile, ...
    'Sheet', strcat(zoneName,'_Eccentricity'), ...
    'WriteMode','overwritesheet');

% =========================
% ASPECT RATIO
% =========================

T = array2table(ar, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

writetable(T, excelFile, ...
    'Sheet', strcat(zoneName,'_AspectRatio'), ...
    'WriteMode','overwritesheet');

% =========================
% ORIENTATION
% =========================

T = array2table(ori, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

writetable(T, excelFile, ...
    'Sheet', strcat(zoneName,'_Orientation'), ...
    'WriteMode','overwritesheet');

end