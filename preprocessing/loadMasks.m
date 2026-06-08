function masks = extractMasks(filepath, nf_masks)

masks = cell(1, length(nf_masks));

for i = 1:length(nf_masks)
    fname = fullfile(filepath,'masks',nf_masks(i).name);
    masks{i} = readStackTif(fname);
end

end