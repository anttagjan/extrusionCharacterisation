function writeImageJROI(zipFilename, ROIs)
% Writes ImageJ ROI zip with .roi files at the root (no subfolder)

if isempty(ROIs)
    return
end

if ~iscell(ROIs)
    ROIs = {ROIs};
end

tmpDir = tempname;
mkdir(tmpDir)

roiFiles = cell(numel(ROIs),1);

for k = 1:numel(ROIs)
    roiFiles{k} = fullfile(tmpDir,[ROIs{k}.strName '.roi']);
    writeSinglePointROI(roiFiles{k}, ROIs{k});
end

% ---- ZIP ONLY FILES (not directory) ----
zip(zipFilename, roiFiles)

% % Cleanup
% delete(roiFiles{:})
% rmdir(tmpDir)
end
