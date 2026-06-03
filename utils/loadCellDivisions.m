close all
clear all
%% load data
% filepath=('D:\Antonio\deXtrusion\caspase dynamics dataset');
filepath=('D:\Antonio\extrusion systematic characterisation\');
% nf_division = dir(fullfile(filepath,'results','*cell_division.zip'));
nf_division = dir(fullfile(filepath,'input_cellDivision','*cell_division.zip'));

filenames = {nf_division.name};
noDivisions={};

%% Extraction of coordinates (landmarks, cell death events, masks)
% Extraction division coordinates
k = 0; coordinates = [];
for i = 1:length(nf_division)

    % fname = fullfile(filepath,'results',nf_division(i).name);
   fname = fullfile(filepath,'input_cellDivision',nf_division(i).name);

    ROI = ReadImageJROI(fname);
    L(i) = length(ROI);
    for j = 1:L(i)
        k = k + 1;
        coordinates(k,1:2) = ROI{1,j}.mfCoordinates;
        coordinates(k,3) = i;
        coordinates(k,4) = ROI{1,j}.vnPosition(3);
    end
    noDivisions{i}=coordinates(coordinates(:,3)==i,4);
end

names=cellfun(@(x) split(x,'_cell_division.zip'),filenames,'UniformOutput',false);
names=cellfun(@(x) x{1},names,'UniformOutput',false);