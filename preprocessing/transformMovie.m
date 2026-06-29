function [Ext,Dv, LM_tr, feat_tr, mask_tr,piv_tr, timeMask,timePIV] = transformMovie( ...
    i,  refMovie,landmarks, coordinates,division, masks,piv, dataframeFeatures, timeTable, frameRate, Rglobal)

%% --- Procrustes transformation ---
mov = landmarks(landmarks(:,3)==i,1:2);

[~,~,Tr] = procrustes(refMovie,mov, ...
    'Scaling',true, ...
    'Reflection',false);

A = Tr.b * Tr.T;
t = Tr.c(1,:);

Afull = [A, [0;0]; t, 1];
tform = affine2d(Afull);

timeFactor = frameRate / 60;
shift = [Rglobal.XWorldLimits(1), Rglobal.YWorldLimits(1)]; % shift respect global canvas

%% --- Transform extrusions ---
coord_i = coordinates(coordinates(:,3) == i,:);
Ext = coord_i(:, 1:2) * A + t;
Ext = [Ext, (coord_i(:,4) - timeTable.peaks(i)) * timeFactor];

%% --- Transform divisions ---
division_i = division(division(:,3) == i, :);
Dv = division_i(:, 1:2) * A + t; 
Dv = [Dv (division_i(:,4) - timeTable.peaks(i)) * timeFactor];

%% --- Transform landmarks ---
LM_tr = mov * A + t;

%% --- Transform features ---
csv = dataframeFeatures{i};

xy = [csv.x, csv.y];

feat_tr = xy * A + t;
feat_tr = feat_tr - shift;
csv.x = feat_tr(:,1);
csv.y = feat_tr(:,2);

if ismember('file', csv.Properties.VariableNames)
    csv = removevars(csv, 'file');
end

csv.frame = (csv.frame - timeTable.peaks(i)) * frameRate / 60;

feat_tr = csv;

%% --- Transform masks ---
maskStack = masks{i};   % H x W x T logical
[H, W, T] = size(maskStack);

Rin = imref2d([H W]);
Hg = Rglobal.ImageSize(1);
Wg = Rglobal.ImageSize(2);

mask_tr = false(Hg, Wg, T);

%mask_tr = false([size(Rglobal.ImageSize,1:2) T]);

for k = 1:T
    mask_tr(:,:,k) = logical(imwarp(maskStack(:,:,k), Rin, tform, ...
        'OutputView', Rglobal, ...
        'InterpolationMethod','nearest'));
    % mask_tr(:,:,k) = imwarp(maskStack(:,:,k), Rin, tform, ...
    % 'InterpolationMethod','nearest');
end

% time vector stays separate 
timeMask = ((1:T) - timeTable.peaks(i)) * timeFactor;

%% --- Transform PIV vectors ---
% pivData = piv{i};   % cell array: 1 x T, each 74x74 single
% Tp = size(pivData.v_original,1);
% 
% % [Hp, Wp] = size(pivData.v_original{1});
% 
% % Rin = imref2d([H W]);  % original image space
% 
% piv_tr = cell(1,Tp);

% for k = 1:Tp
% 
%     Z = pivData.v_original{k};
% 
%     % ---------------------------------------------------------
%     % STEP 1: warp scalar field into GLOBAL canvas
%     % ---------------------------------------------------------
%     Zwarp = imwarp(Z, Rin, tform, ...
%         'OutputView', Rglobal, ...
%         'InterpolationMethod', 'bilinear');
% 
%     piv_tr{k}.Z = Zwarp;
% 
%     % ---------------------------------------------------------
%     % STEP 2: ALSO store coordinates if needed (optional)
%     % ---------------------------------------------------------
%     piv_tr{k}.Ref = Rglobal;
% 
% end

% timePIV = timeMask+timeFactor; % PIV is always measured refered to the t-1 
timePIV=[];
piv_tr=[];

% Align transformation respect global canvas
Ext(:,1:2) = Ext(:,1:2) - shift;
Dv(:,1:2)  = Dv(:,1:2)  - shift;
LM_tr  = LM_tr  - shift;

end