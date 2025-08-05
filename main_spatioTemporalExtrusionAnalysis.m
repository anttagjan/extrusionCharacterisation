close all
%% load data
filepath=('D:\Antonio\extrusion systematic characterisation\');
timeTable = readtable(fullfile(filepath,'dataframes','speed_peaks.xlsx'));

alignment_map(filepath,timeTable);
getSumAverageCVHeatmap(filepath);
getRegionalHeatmap(filepath);

