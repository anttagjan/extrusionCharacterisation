function [Tr, Ext,Dv, LM_tr, feat_tr, mask_tr,piv_tr, timeMask,timePIV] = transformMovie( ...
    i, landmarks, coordinates,division, masks,piv, dataframeFeatures, timeTable, frameRate)

%% --- Procrustes alignment ---
ref = landmarks(landmarks(:,3) == 1, 1:2);
mov = landmarks(landmarks(:,3) == i, 1:2);

[~, ~, transform] = procrustes(ref, mov);
Tr = transform;

A = Tr.b * Tr.T;
t = Tr.c(1,:);

%% --- Temporal alignment ---
timeFactor = frameRate / 60;

%% --- Transform extrusions ---
coord_i = coordinates(coordinates(:,3) == i,:);
Y = coord_i(:, 1:2);
Ext = Y * A + t;
alignedTime = (coord_i(:,4) - timeTable.peaks(i)) * timeFactor;
Ext = [Ext alignedTime];

%% --- Transform divisions ---
division_i = division(division(:,3) == i, :);
D = division_i(:, 1:2);
Dv = D * A + t; 
alignedTime = (division_i(:,4) - timeTable.peaks(i)) * timeFactor;
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

% IMPORTANT: input spatial reference (pixel grid original)
Rin = imref2d([H W]);

mask_tr = false(H, W, T);

for k = 1:T
    mask_tr(:,:,k) = imwarp(maskStack(:,:,k), Rin, tform, ...
        'OutputView', Rin, ...
        'InterpolationMethod', 'nearest');
end

% time vector stays separate 
timeMask = ((1:T) - timeTable.peaks(i)) * timeFactor;

%% --- Transform PIV vectors ---
pivData = piv{i};   % cell array: 1 x T, each 74x74 single
Tp = size(pivData.v_original,1);

[Hp, Wp] = size(pivData.v_original{1});

%% --- affine transform (same as everything else) ---
Afull = [A, [0;0]; t, 1];
tform = affine2d(Afull);

%% --- build PIV grid in ORIGINAL image space ---
% (same reference as masks BEFORE transform)
[xPIV, yPIV] = meshgrid( ...
    linspace(1, W, Wp), ...
    linspace(1, H, Hp));

pts = [xPIV(:), yPIV(:)];
ptsT = pts * A + t;

Xp = reshape(ptsT(:,1), size(xPIV));
Yp = reshape(ptsT(:,2), size(yPIV));

%% --- transform scalar fields in time ---
piv_tr = cell(1, Tp);

for k = 1:Tp

    Z = pivData.v_original{k};   % 74x74 scalar field

    % no value transform, only spatial alignment
    piv_tr{k}.Z = Z;
    piv_tr{k}.Xp = Xp;
    piv_tr{k}.Yp = Yp;

end

timePIV = timeMask+timeFactor; % PIV is always measured refered to the t-1 
end