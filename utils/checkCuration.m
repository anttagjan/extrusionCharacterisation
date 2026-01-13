filepath="D:\Antonio\extrusion systematic characterisation";
%% Paths
folderA = fullfile(filepath,'input_noCurated');
folderB = fullfile(filepath,'input');
outFolder = fullfile(filepath,'input_revision');

if ~exist(outFolder,'dir')
    mkdir(outFolder)
end

%% List ROI files
filesA = dir(fullfile(folderA,'*cell_death.zip'));
filesB = dir(fullfile(folderB,'*cell_death.zip'));

%% Read all ROIs from folder of curated ROIs
    k = 0; coordinatesB = [];
    for i = 1:length(filesB)
        fname = fullfile(filepath,'input',filesB(i).name);
        ROI = ReadImageJROI(fname);
        L(i) = length(ROI);
        for j = 1:L(i)
            k = k + 1;
            coordinatesB(k,1:2) = ROI{1,j}.mfCoordinates;
            coordinatesB(k,3) = i;
            coordinatesB(k,4) = ROI{1,j}.vnPosition(3);
            if coordinatesB(k,4) == 1
                coordinatesB(k,4) = ROI{1,j}.vnPosition(2);
            end

        end
    end

%% Loop over non-curated files
for i = 1:length(filesA)

    fnameA = fullfile(folderA,filesA(i).name);
    ROI_A = ReadImageJROI(fnameA);

    ROIs_to_keep={};

    k2 = 0;

    for j = 1:length(ROI_A)

        coord = [ ...
            ROI_A{j}.mfCoordinates , ...
            i , ...
            ROI_A{j}.vnPosition(3) ];

        isSame = ismember(coord, coordinatesB, 'rows');

        if ~isSame
            k2 = k2 + 1;
            ROIs_to_keep{k2} = ROI_A{j};%#ok<SAGROW>
        end
    end

    %% Save with SAME filename
    if ~isempty(ROIs_to_keep)
        outName = fullfile(outFolder, filesA(i).name);
        writeImageJROI(outName, ROIs_to_keep);
    end
    
end
