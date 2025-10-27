function [diffData,allShiftedDiffData,meanData,sdData]=getDiffExtrusions()
    % randomShiftExcel: Importa un Excel, verifica que tenga hojas pares
    % y aplica un desplazamiento aleatorio (random shift) entre cada par de hojas.

    % Leer nombres de hojas
    filepath='D:\Antonio\extrusion systematic characterisation\dataframes\only ROI PosteriorLeft Vs PosteriorRight';
    filename='\HistogramNormalisedExtrusions_30x30_1hStep15Movies_Summary.xlsx';
    filename=strcat(filepath,filename);
    [~, sheetNames] = xlsfinfo(filename);
    nSheets = numel(sheetNames)-1;

    fprintf('Excel file "%s" have %d sheets.\n', filename, nSheets);

    % % verify even sheets
    % if mod(nSheets, 2) ~= 0
    %     error('El número de hojas debe ser par.');
    % end

    % Iterar por pares de hojas
        sheet1 = sheetNames{1};
        sheet2 = sheetNames{2};
        fprintf('\nProcess sheets "%s" y "%s"...\n', sheet1, sheet2);

        % read_data
        data1 = readmatrix(filename, 'Sheet', sheet1);
        data2 = readmatrix(filename, 'Sheet', sheet2);
        time = data1(:,1);
        data1=data1(:,2:end);
        data2=data2(:,2:end);

        diffData = (data2 - data1)./(data2 + data1);
        diffData=[time diffData];
        allShiftedDiffData={};
    for i = 1:100
        % circular shift
        shiftCols = randi(size(data1,2)) - 1;
        shiftedData1 = circshift(data1, [0 shiftCols]);

        % diff extrusions

        shiftedDiffData = (data2-shiftedData1)./(data2+shiftedData1);
        shiftedDiffData = [time shiftedDiffData];
        allShiftedDiffData{i}=shiftedDiffData;
    end

    fprintf('\nProcess complete\n');
    nShiftedDiffData = cat(3, allShiftedDiffData{:});

    % Compute the mean probability of at least one positive neighbor
    meanData = mean(nShiftedDiffData, 3,'omitnan');
    sdData = std(nShiftedDiffData, 0, 3,'omitnan');
end