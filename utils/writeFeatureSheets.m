function writeFeatureSheets(excelFile, zoneName, ...
    meanCells,totalCells, meanArea, ecc, ori, filenames, timeBins)

% =========================
% CELL NUMBER
% =========================

T = array2table(meanCells, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

writetable(T, excelFile, ...
    'Sheet', strcat(zoneName,'_AverageCells'), ...
    'WriteMode','overwritesheet');

% =========================
% TOTAL CELLS
% =========================

T = array2table(totalCells, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

writetable(T, excelFile, ...
    'Sheet', strcat(zoneName,'_TotalCells'), ...
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
% ORIENTATION
% =========================

T = array2table(ori, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

writetable(T, excelFile, ...
    'Sheet', strcat(zoneName,'_Orientation'), ...
    'WriteMode','overwritesheet');

end