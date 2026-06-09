function keep = filterExtrusionsByMask(x,y,mask)

xPix = round(x);
yPix = round(y);

keep = false(size(x));

inside = ...
    xPix >= 1 & ...
    xPix <= size(mask,2) & ...
    yPix >= 1 & ...
    yPix <= size(mask,1);

if any(inside)

    idx = sub2ind( ...
        size(mask), ...
        yPix(inside), ...
        xPix(inside));

    keep(inside) = ~mask(idx);

end

end