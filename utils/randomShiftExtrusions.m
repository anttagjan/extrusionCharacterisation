function [diffData,allShiftedDiffData]=getDiffExtrusions()
    % randomShiftExcel: Importa un Excel, verifica que tenga hojas pares
    % y aplica un desplazamiento aleatorio (random shift) entre cada par de hojas.

    % Leer nombres de hojas
    filepath='D:\Antonio\extrusion systematic characterisation\dataframes\LeftVsRight';
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

        diffData = (data1 - data2)/(data1 + data2);
        diffData=[time; diffData];
        allShiftedDiffData={};
    for i = 1:100
        % circular shift
        shiftCols = randi(size(data1,2)) - 1;
        shiftedData2 = circshift(data2, [0 shiftCols]);

        % diff extrusions

        shiftedDiffData = (data1 - shiftedData2)/(data1+shiftedData2);
        shiftedDiffData = [time;shiftedDiffData];
        allShiftedDiffData{i}=shiftedDiffData;
    end

    fprintf('\nProcess complete\n');
end