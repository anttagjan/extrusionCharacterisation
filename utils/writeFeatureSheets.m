function writeFeatureSheets(excelFile, zoneName, filenames, timeBins, featureStruct)

fields = fieldnames(featureStruct);

for f = 1:numel(fields)

    data = featureStruct.(fields{f});

    % skip empty
    if isempty(data)
        continue
    end

    % -------------------------
    % BUILD TABLE
    % -------------------------
    nCols = size(data,2);

    % fix mismatch safely
    if length(filenames) ~= nCols
        filenames = filenames(1:nCols);
    end

    T = array2table(data, 'VariableNames', filenames);
    T.Time = timeBins(:);
    T = movevars(T,'Time','Before',1);

    % -------------------------
    % WRITE SHEET
    % -------------------------
    sheetName = strcat(zoneName,'_',fields{f});

    writetable(T, excelFile, ...
        'Sheet', sheetName, ...
        'WriteMode','overwritesheet');

end

end