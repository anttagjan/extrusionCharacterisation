[rawImage]=readStackTif(fullfile(filepath,'projections','2025-06-25 s6.tiff'));
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

writeStackTif(uint16(extrusionStack),'stk.tiff');