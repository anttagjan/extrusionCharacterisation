function coordinates = loadExtrusions(filepath, nf_extrusion)

k = 0;
coordinates = [];

for i = 1:length(nf_extrusion)

    fname = fullfile(filepath,'input',nf_extrusion(i).name);
    ROI = ReadImageJROI(fname);

    for j = 1:length(ROI)
        k = k + 1;

        coordinates(k,1:2) = ROI{1,j}.mfCoordinates;
        coordinates(k,3)   = i;

        z = ROI{1,j}.vnPosition(3);
        if z == 1
            z = ROI{1,j}.vnPosition(2);
        end

        coordinates(k,4) = z;
    end
end

end