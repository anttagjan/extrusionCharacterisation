function [data,Rglobal] = runPreprocessing(filepath, nf_extrusion,nf_division, nf_masks,nf_piv, nf_features, nf_landmarks, timeTable, frameRate,alignMethod)

[landmarks] = loadLandmarks(filepath,alignMethod, nf_landmarks);
[coordinates] = loadExtrusions(filepath, nf_extrusion);
[masks] = loadMasks(filepath, nf_masks);
[features] = loadFeatures(filepath, nf_features);
[division] = loadCellDivisions(filepath, nf_division);
[piv] = loadPIVcoords(filepath, nf_piv);

nMovies = length(nf_extrusion);

extrusions_transformed = [];
divisions_transformed = [];
landmarks_transformed = [];
features_transformed = [];
piv_transformed = [];
masks_transformed = cell(1,nMovies);
masks_relativeTime = cell(1,nMovies);
piv_relativeTime = [];

%% Global reference
% averaging landmark positions and picking as a reference the most central movie in dataset
meanShape = buildMeanMovieShape(landmarks);

refMovieID = pickReferenceMovie(landmarks, meanShape); % medoid reference movie
movieIDs = unique(landmarks(:,3));

Rglobal = computeGlobalCanvas(landmarks, masks, refMovieID, movieIDs);

save(fullfile(filepath,'meanShape_procrustes.mat'), ...
    'meanShape','refMovieID', 'Rglobal');

for i = 1:nMovies

    [Tr, Ext,Dv, LM_tr, feat_tr, mask_tr,piv_tr,timeMask,timePIV] = transformMovie(i, refMovieID, landmarks, coordinates, division,masks, piv,features, timeTable, frameRate, Rglobal);

    extrusions_transformed = [extrusions_transformed; Ext, i*ones(size(Ext,1),1)];
    divisions_transformed = [divisions_transformed; Dv, i*ones(size(Dv,1),1)];
    landmarks_transformed = [landmarks_transformed; LM_tr, i*ones(size(LM_tr,1),1)];
    feat_tr.movie = i * ones(height(feat_tr), 1);
    features_transformed = [features_transformed; feat_tr];
    masks_transformed{i} = mask_tr;
    % piv_transformed{i} = piv_tr;
    masks_relativeTime{i} = timeMask;
    % piv_relativeTime = [piv_relativeTime; timePIV];
end

data.extrusions_transformed = extrusions_transformed;
data.divisions_transformed = divisions_transformed;
data.landmarks_transformed = landmarks_transformed;
data.features_transformed = features_transformed;
data.masks_transformed = masks_transformed;
data.masks_relativeTime = masks_relativeTime;
% data.piv_transformed = piv_transformed;
% data.piv_relativeTime = piv_relativeTime;

data.refMovieID = refMovieID;
data.meanShape = meanShape;
data.Rglobal = Rglobal;

end