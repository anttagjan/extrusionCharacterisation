function Rglobal = computeGlobalCanvas(landmarks, masks, refMovieID, movieIDs)

allCorners = [];

for i = 1:numel(movieIDs)

    id = movieIDs(i);

    ref = landmarks(landmarks(:,3)==refMovieID,1:2);
    mov = landmarks(landmarks(:,3)==id,1:2);

    [~,~,Tr] = procrustes(ref, mov, ...
        'Scaling',true,'Reflection',false);

    A = Tr.b * Tr.T;
    t = Tr.c(1,:);

    maskStack = masks{id};
    [H,W,~] = size(maskStack);

    corners = [1 1; W 1; 1 H; W H];
    cornersT = corners * A + t;

    allCorners = [allCorners; cornersT];
end

xmin = min(allCorners(:,1));
xmax = max(allCorners(:,1));
ymin = min(allCorners(:,2));
ymax = max(allCorners(:,2));

width  = round(xmax - xmin + 1);
height = round(ymax - ymin + 1);

Rglobal = imref2d([height width], [xmin xmax], [ymin ymax]);

end