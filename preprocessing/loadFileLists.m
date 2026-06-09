function [nf_extrusions,nf_divisions, nf_masks,nf_piv, nf_features] = loadFileLists(filepath)

nf_extrusions = dir(fullfile(filepath,'input','*cell_death.zip'));
nf_divisions = dir(fullfile(filepath,'input_CellDivision','*cell_division.zip'));
nf_masks     = dir(fullfile(filepath,'masks','*.tif'));
nf_piv = dir(fullfile(filepath,'piv','*.mat'));
nf_features  = dir(fullfile(filepath,'features','*.csv'));

end