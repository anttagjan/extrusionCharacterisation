[coordinates]=loadCellsDivisions();
coordinates2=coordinates;
coordinates = coordinates(coordinates(:,3)==5,:);
% filepath=('D:\Antonio\extrusion systematic characterisation');
% [rawImage]=readStackTif(fullfile(filepath,'projections','2025-06-25 s6.tiff'));
[rawImage]=readStackTif(fullfile(filepath,'wt 1.tif'));
height = size(rawImage,1);
width=size(rawImage,2);
extrusionStack = zeros(size(rawImage));
se = strel('disk', 15);
k=1;
for t = 1:size(rawImage,3)
    frameCoords = coordinates(coordinates(:,4) == t, 1:2);

% Create empty frame
    frameMat = zeros(height, width);

    % Round coordinates to nearest pixel
    inds = round(frameCoords);
    
    % Make sure coordinates are within image bounds
    inds(inds(:,1)<1,1) = 1; inds(inds(:,1)>width,1) = width;
    inds(inds(:,2)<1,2) = 1; inds(inds(:,2)>height,2) = height;

    % Set points to 1
    for p = 1:size(inds,1)
        frameMat(inds(p,2), inds(p,1)) = k; 
        k = k + 1;
    end
    % linearInd = sub2ind([height, width], inds(:,2), inds(:,1));
    % frameMat(linearInd) = 1;

    % Dilate points
    frameMat = imdilate(frameMat, se);

    % Assign to stack
    extrusionStack(:,:,t) = frameMat;
end

writeStackTif(uint16(extrusionStack),'stk3.tiff');

dataFrame = readtable(strcat(filepath,'/dataframes/DataFrame_interpolated_and_smoothed_relevant_cells.xlsx'));
if min(dataFrame.frame) < 1
    dataFrame.frame=dataFrame.frame+1;
end

caspaseStack = zeros(size(rawImage));
for nCell = 1:size(validOnLabels)
     t = validOnLabels.t0(nCell); 

    % Extract coordinates for this cell at that frame
    coords = dataFrame( ...
        dataFrame.frame == t & ...
        dataFrame.particle == validOnLabels.label(nCell), ...
        {'x','y'} ...
    );

    if isempty(coords)
        continue
    end

    coordinatesCaspase = [coords.x coords.y];
    % Create empty frame
    frameMat = zeros(height, width);

    % Round coordinates
    inds = round(coordinatesCaspase);

    % Clamp to image bounds
    inds(:,1) = max(1, min(width, inds(:,1)));
    inds(:,2) = max(1, min(height, inds(:,2)));

    % Convert to linear indices (vectorized, faster)
    linearInd = sub2ind([height, width], inds(:,2), inds(:,1));

    % Set points (binary is enough before dilation)
    frameMat(linearInd) = 1;

    % Dilate
    frameMat = imdilate(frameMat, se);

    % Accumulate into stack (important if multiple cells per frame)
    caspaseStack(:,:,t) = caspaseStack(:,:,t) | frameMat;
end