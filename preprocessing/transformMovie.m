function [Tr, Ext,Dv, LM_tr, feat_tr, mask_tr] = transformMovie( ...
    i, landmarks, coordinates,division, masks, dataframeFeatures, timeTable, frameRate)

%% --- Procrustes alignment ---
ref = landmarks(landmarks(:,3) == 1, 1:2);
mov = landmarks(landmarks(:,3) == i, 1:2);

[~, ~, transform] = procrustes(ref, mov);
Tr = transform;

A = Tr.b * Tr.T;
t = Tr.c(1,:);

%% --- Transform extrusions ---
coord_i = coordinates(coordinates(:,3) == i,:);
Y = coord_i(:, 1:2);
Ext = Y * A + t;
alignedTime = (coord_i(:,4) - timeTable.peaks(i)) * frameRate / 60;
Ext = [Ext alignedTime];

%% --- Transform divisions ---
division_i = division(division(:,3) == i, :);
D = division_i(:, 1:2);
Dv = D * A + t; 
alignedTime = (division_i(:,4) - timeTable.peaks(i)) * frameRate / 60;
Dv = [Dv alignedTime];

%% --- Transform landmarks ---
LM = mov;
LM_tr = LM * A + t;

%% --- Transform features ---
csv_features = dataframeFeatures{i};
xy = [csv_features.y, csv_features.x];

xy_tr = xy * A + t;

csv_features.y = xy_tr(:,1);
csv_features.x = xy_tr(:,2);

csv_features.file = [];

csv_features.frame = (csv_features.frame - timeTable.peaks(i)) * frameRate / 60;

feat_tr = table2array(csv_features);

%% --- Transform masks ---
maskStack = masks{i};   % H x W x T logical
[H, W, T] = size(maskStack);

Afull = [A, [0;0]; t, 1];
tform = affine2d(Afull);

canvasSize = [H*2, W*2];
Rout = imref2d(canvasSize);

mask_tr = false([canvasSize, T]);

for k = 1:T
    mask_tr(:,:,k) = imwarp(maskStack(:,:,k), tform, ...
        'OutputView', Rout, 'Interp', 'nearest');
end

end