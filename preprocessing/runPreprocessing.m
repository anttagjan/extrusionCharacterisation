function data = runPreprocessing(filepath, nf_extrusion,nf_division, nf_masks, nf_features, nf_landmarks, timeTable, frameRate,alignMethod)

[landmarks] = loadLandmarks(filepath,alignMethod, nf_landmarks);
[coordinates] = loadExtrusions(filepath, nf_extrusion);
[masks] = loadMasks(filepath, nf_masks);
[features] = loadFeatures(filepath, nf_features);
[division] = loadCellDivisions(filepath, nf_division);

nMovies = length(nf_extrusion);

extrusions_transformed = [];
divisions_transformed = [];
landmarks_transformed = [];
features_transformed = [];
%piv_transformed = [];
masks_transformed = cell(1,nMovies);

for i = 1:nMovies

    [Tr, Ext,Dv, LM_tr, feat_tr, mask_tr] = transformMovie(i, landmarks, coordinates, division,masks, features, timeTable, frameRate);

    extrusions_transformed = [extrusions_transformed; Ext, i*ones(size(Ext,1),1)];
    divisions_transformed = [divisions_transformed; Dv, i*ones(size(Dv,1),1)];
    landmarks_transformed = [landmarks_transformed; LM_tr, i*ones(size(LM_tr,1),1)];
    features_transformed = [features_transformed; feat_tr, i*ones(size(feat_tr,1),1)];
    masks_transformed{i} = mask_tr;

end

data.extrusions_transformed = extrusions_transformed;
data.divisions_transformed = divisions_transformed;
data.landmarks_transformed = landmarks_transformed;
data.features_transformed = features_transformed;
data.masks_transformed = masks_transformed;

end