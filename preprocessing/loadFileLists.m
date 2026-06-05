function [nf_extrusion, nf_masks, nf_features] = loadFileLists(filepath)

nf_extrusion = dir(fullfile(filepath,'input','*cell_death.zip'));
nf_masks     = dir(fullfile(filepath,'masks','*.tif'));
nf_features  = dir(fullfile(filepath,'features','*.csv'));

end