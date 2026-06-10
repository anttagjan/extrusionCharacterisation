function masks = loadMasks(filepath, nf_masks)

masks = cell(1, length(nf_masks));

for i = 1:length(nf_masks)
    fname = fullfile(filepath,'masks',nf_masks(i).name);
    masks{i} = readStackTif(fname);
    masks{i} = ~masks{i}; % You are loading background 1 and tissue 0. Need to be inverted
end

end