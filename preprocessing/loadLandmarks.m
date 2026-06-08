function landmarks = loadLandmarks(filepath,alignMethod, nf_landmarks)

k = 0;
landmarks = [];

for i = 1:length(nf_landmarks)

    fname = fullfile(filepath,'input',alignMethod,nf_landmarks(i).name);
    Lands = ReadImageJROI(fname);

    for j = 1:length(Lands)
        k = k + 1;
        landmarks(k,1:2) = Lands{1,j}.mfCoordinates;
        landmarks(k,3) = i;
    end
end

end