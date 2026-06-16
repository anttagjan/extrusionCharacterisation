function writeFeatureSheets(excelFile, zoneName, ...
    cellDensity, meanArea, ecc, ar, ori, tissue, filenames, timeBins)

% =========================
% CELL DENSITY
% =========================
T = array2table(cellDensity, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

totalRow = array2table(nan(1,width(T)), 'VariableNames', T.Properties.VariableNames);
totalRow{1,2:end} = sum(cellDensity,1,'omitnan');
totalRow.Time = "Total sum";

Tfinal = [T; totalRow];

writetable(Tfinal, excelFile, ...
    'Sheet', strcat(zoneName,'_CellDensity'), ...
    'WriteMode','overwritesheet');

% =========================
% MEAN AREA
% =========================
T = array2table(meanArea, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

totalRow{1,2:end} = sum(meanArea,1,'omitnan');
Tfinal = [T; totalRow];

writetable(Tfinal, excelFile, ...
    'Sheet', strcat(zoneName,'_MeanArea'), ...
    'WriteMode','overwritesheet');

% =========================
% ECCENTRICITY
% =========================
T = array2table(ecc, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

totalRow{1,2:end} = sum(ecc,1,'omitnan');
Tfinal = [T; totalRow];

writetable(Tfinal, excelFile, ...
    'Sheet', strcat(zoneName,'_Eccentricity'), ...
    'WriteMode','overwritesheet');

% =========================
% ASPECT RATIO
% =========================
T = array2table(ar, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

totalRow{1,2:end} = sum(ar,1,'omitnan');
Tfinal = [T; totalRow];

writetable(Tfinal, excelFile, ...
    'Sheet', strcat(zoneName,'_AspectRatio'), ...
    'WriteMode','overwritesheet');

% =========================
% ORIENTATION
% =========================
T = array2table(ori, 'VariableNames', filenames);
T.Time = timeBins(:);
T = movevars(T,'Time','Before',1);

totalRow{1,2:end} = sum(ori,1,'omitnan');
Tfinal = [T; totalRow];

writetable(Tfinal, excelFile, ...
    'Sheet', strcat(zoneName,'_Orientation'), ...
    'WriteMode','overwritesheet');

end