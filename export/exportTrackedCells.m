function exportTrackedCells()

filepath=('D:\Antonio\epyseg\ecadGFP/raw');
% filepath=('D:\Antonio\caspase dynamics\datasets\kd 5 inx2 v2_normalised\input');
fileData = dir(fullfile(filepath,'labeled','*.tif'));

area_threshold = 2000;

for nFile = 56:size(fileData,1)
    
    disp(fileData(nFile).name);
    
    %   Load files
    fileName=split(fileData(nFile).name,'_labeled.tif');
    if ~exist(fullfile(filepath,'tracked',strcat(fileName{1},'_tracked.tif')),'file')
        [segmentedImage] = readStackTif(fullfile(fileData(nFile).folder,fileData(nFile).name));
        trackedCells = readtable(fullfile(filepath,'dataframes',strcat(fileName{1},'.csv')));

        % Remove bigger cells
        invalidLabels = trackedCells.particle(trackedCells.area> area_threshold);
        invalidLabels=[];


        % Track and export Cells
        trackedCells(ismember(trackedCells.particle,invalidLabels),:)=[];
        [trackedImage] = cellTrackingRelabeling(segmentedImage,trackedCells);
        writeStackTif(uint16(trackedImage),fullfile(filepath,'tracked',strcat(fileName{1},'_tracked.tif')));

        % if min(trackedCells.frame) < 1
        %     trackedCells.frame=trackedCells.frame+1;
        % end
        % 
        % areaImage=zeros(size(trackedImage));
        % disp('Processing MORPHOLOGY features...');
        % 
        % for nFrame = 1:size(trackedImage,3)
        %     actualImg = trackedImage(:,:,nFrame);
        %     actualLabels = unique(actualImg);
        %     actualLabels(actualLabels==0) = [];
        % 
        %     actualAreaImage      = zeros(size(actualImg));
        %     actualPerimeterImage = zeros(size(actualImg));
        % 
        %     for nCell = 1:length(actualLabels)
        %         label = actualLabels(nCell);
        %         indx  = find(trackedCells.frame==nFrame & trackedCells.particle==label);
        %         if ~isempty(indx)
        %             mask = actualImg == label;
        %             actualAreaImage(mask)      = trackedCells.area(indx);
        %             actualPerimeterImage(mask) = trackedCells.perimeter(indx);
        %         end
        %     end
        % 
        %     areaImage(:,:,nFrame)      = actualAreaImage;
        % 
        %     disp(['MORPHO → Frame ' num2str(nFrame)]);
        % end

        % Export
        % writeStackTif(uint16(areaImage),fullfile(filepath,'area',strcat(fileName{1},'_area.tif')));
        % disp('Exported MORPHOLOGY and tracking');
    end
end