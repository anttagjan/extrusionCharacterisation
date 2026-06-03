filepath=('D:\Antonio\extrusion systematic characterisation\');
nf_masks = dir(fullfile(filepath,'masks','*.tif'));

for nMask = 1:size(nf_masks,1)
    fileNameTif=nf_masks(nMask).name;
    fileName= erase(fileNameTif, '.tif');
    inPath =fullfile('D:\Antonio\extrusion systematic characterisation\time_alignment\PIV\masks',fileName);
 
    if ~exist(inPath,'dir') 
        outputpath=fullfile('D:\Antonio\extrusion systematic characterisation\time_alignment\PIV\masks',fileName);
        mkdir(outputpath)
        mask=readStackTif(fullfile(filepath,"masks",fileNameTif));
        for t=1:size(mask,3)
            frameName = sprintf('%s%03d.bmp', strcat(fileName,'_'), t);
            imwrite(uint8(mask(:,:,t)) ,fullfile(outputpath,frameName))
        end
    end
end

nf_raw = dir(fullfile(filepath,'projections','*.tif'));

for nMask = 1:size(nf_raw,1)
    fileNameTif=nf_raw(nMask).name;
    fileName= erase(fileNameTif, '.tif');
    inPath =fullfile('D:\Antonio\extrusion systematic characterisation\time_alignment\PIV\raw',fileName);
 
    if ~exist(inPath,'dir') 
        outputpath=fullfile('D:\Antonio\extrusion systematic characterisation\time_alignment\PIV\raw',fileName);
        mkdir(outputpath)
        % mask=readStackTif(fullfile(filepath,"projections",fileNameTif));
        % for t=1:size(mask,3)
        %     frameName = sprintf('%s%03d.bmp', strcat(fileName,'_'), t);
        %     imwrite(uint8(mask(:,:,t)) ,fullfile(outputpath,frameName))
        % end
    end
end