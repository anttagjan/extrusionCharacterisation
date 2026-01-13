close all
clear all
%% load data
filepath=('D:\Antonio\deXtrusion\tests');
% filepath=('D:\Antonio\extrusion systematic characterisation\projections\');
nf_death = dir(fullfile(filepath,'results','*cell_death.zip'));
% nf_division = dir(fullfile(filepath,'results_cellDivision','*cell_death.zip'));
filenames = {nf_death.name};
noDeath={};
%% Extraction of coordinates (landmarks, cell death events, masks)
% Extraction division coordinates
k = 0; coordinates = [];
for i = 1:length(nf_death)
    fname = fullfile(filepath,'results',nf_death(i).name);
   % fname = fullfile(filepath,'results_cellDivision',nf_division(i).name);
    ROI = ReadImageJROI(fname);
    L(i) = length(ROI);
    for j = 1:L(i)
        k = k + 1;
        coordinates(k,1:2) = ROI{1,j}.mfCoordinates;
        coordinates(k,3) = i;
        coordinates(k,4) = ROI{1,j}.vnPosition(3);
    end
    noDeath{i}=coordinates(coordinates(:,3)==i,4);
end

names=cellfun(@(x) split(x,'_cell_death.zip'),filenames,'UniformOutput',false);
names=cellfun(@(x) x{1},names,'UniformOutput',false);