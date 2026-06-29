function [diffData,allShiftedDiffData,meanData,sdData,meanRandData,sdRandData,faIndex,faIndexRand,AsymIndex]=getLeftRightAsymmetry()
    % randomShiftExcel: Importa un Excel, verifica que tenga hojas pares
    % y aplica un desplazamiento aleatorio (random shift) entre cada par de hojas.

    % Select Excel file
    [filename, filepath] = uigetfile('*.xlsx', ...
        'Select Excel file', ...
        'D:\Antonio\extrusion systematic characterisation\dataframes\division\');

    if isequal(filename,0)
        error('No file selected.');
    end

    filefolder = fullfile(filepath, filename);

    % Read sheet names
    [~, sheetNames] = xlsfinfo(filefolder);
    nSheets = numel(sheetNames);

    fprintf('Excel file "%s" has %d sheets.\n', filename, nSheets);

    if nSheets < 2
        error('The Excel file must contain at least 2 sheets.');
    end

    % Use first two sheets
    sheet1 = sheetNames{1};
    sheet2 = sheetNames{2};

    fprintf('\nProcessing sheets "%s" and "%s"...\n', sheet1, sheet2);

    % Read data
    data1 = readmatrix(filefolder, 'Sheet', sheet1);
    data2 = readmatrix(filefolder, 'Sheet', sheet2);

    time = data1(:,1);
    data1 = data1(:,2:end);
    data2 = data2(:,2:end);

    % Avoid division by zero
    denominator = data2 + data1;
    denominator(denominator == 0) = NaN;

    diffData = (data2 - data1) ./ denominator;
    diffData = [time diffData];

    % Random shifts
    nIterations = 1000;
    allShiftedDiffData = cell(1, nIterations);
    
    rng(1); % ensures the same randomisation every run

    for i = 1:nIterations

        shiftCols = randi(size(data1,2)) - 1;
        shiftedData1 = circshift(data1, [0 shiftCols]);

        denominatorShift = data2 + shiftedData1;
        denominatorShift(denominatorShift == 0) = NaN;

        shiftedDiffData = (data2 - shiftedData1) ./ denominatorShift;
        shiftedDiffData = [time shiftedDiffData];

        allShiftedDiffData{i} = shiftedDiffData;
    end

    fprintf('\nProcessing complete.\n');

    % % Convert to 3D matrix
    % nShiftedDiffData = cat(3, allShiftedDiffData{:});
    % 
    % % Mean and SD
    % meanData = mean(nShiftedDiffData, 3, 'omitnan');
    % sdData = std(nShiftedDiffData, 0, 3, 'omitnan');
    
    meanRandData = cell2mat(cellfun(@(x) mean(x(:,2:end),2,'omitnan'), allShiftedDiffData, 'UniformOutput', false));
    sdRandData = cell2mat(cellfun(@(x) std(x(:,2:end),0,2,'omitnan'), allShiftedDiffData, 'UniformOutput', false));
    faIndexRand = sdRandData.^2;

    meanData = mean(diffData(:,2:end),2,'omitnan');
    sdData = std(diffData(:,2:end),0,2,'omitnan');
    faIndex = sdData.^2;
    meanAsymRandData = cell2mat(cellfun(@(x) mean(x(:,2:end).^2,2,'omitnan'), allShiftedDiffData, 'UniformOutput', false));
    AsymIndex = (mean(diffData(:,2:end).^2,2,'omitnan')-mean(meanAsymRandData,2))./std(meanAsymRandData,0,2);
end