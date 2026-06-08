function dataframeFeatures = loadFeatures(filepath, nf_features)

dataframeFeatures = cell(1, length(nf_features));

for i = 1:length(nf_features)
    fname = fullfile(filepath,'features',nf_features(i).name);
    dataframeFeatures{i} = readtable(fname);
end

end