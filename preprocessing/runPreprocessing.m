function data = runPreprocessing(filepath, nf_extrusion, nf_masks, nf_features, nf_landmarks, timeTable, frameRate)

[landmarks] = extractLandmarks(filepath, nf_landmarks);
[coordinates] = extractExtrusions(filepath, nf_extrusion);
[masks] = extractMasks(filepath, nf_masks);
[features] = extractFeatures(filepath, nf_features);

nMovies = length(nf_extrusion);

procruste_transformed = [];
landmarks_transformed = [];
features_transformed = [];
masks_transformed = cell(1,nMovies);

for i = 1:nMovies

    [Tr, Z2, LM_tr, feat_tr, mask_tr] = transformMovie(i, landmarks, coordinates, masks, features, timeTable, frameRate);

    procruste_transformed = [procruste_transformed; Z2, i*ones(size(Z2,1),1)];
    landmarks_transformed = [landmarks_transformed; LM_tr, i*ones(size(LM_tr,1),1)];
    features_transformed = [features_transformed; feat_tr, i*ones(size(feat_tr,1),1)];
    masks_transformed{i} = mask_tr;

end

data.procruste_transformed = procruste_transformed;
data.landmarks_transformed = landmarks_transformed;
data.features_transformed = features_transformed;
data.masks_transformed = masks_transformed;

end