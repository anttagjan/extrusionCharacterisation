function results = loadDivisionFreqData(filepath,span)

xlsx_file = dir(fullfile(filepath,'*cell_division.xlsx'));

data = readtable(fullfile(xlsx_file.folder,xlsx_file.name),'VariableNamingRule','preserve');

names = data.Properties.VariableNames;

results = struct([]);

for ii = 2:size(data,2)

    freq = table2array(data(:,ii));
    t = (1:length(freq))';

    f_smooth = smooth(freq, span, 'moving');

    results(ii-1).name = names{ii};
    results(ii-1).t = t;
    results(ii-1).raw = freq;
    results(ii-1).smooth = f_smooth;
    results(ii-1).ylabel = 'Division frequency';
end
end