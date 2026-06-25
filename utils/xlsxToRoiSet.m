filepath = "D:\Antonio\caspase dynamics\alignment\input";

%% Paths
% inputFolder = fullfile(filepath,'xlsx_input');   % folder containing .xlsx files
% outFolder   = fullfile(filepath,'roi_output');   % folder to save RoiSet.zip

% if ~exist(outFolder,'dir')
%     mkdir(outFolder)
% end

%% List xlsx files
filesXLSX = dir(fullfile(filepath,'*.xlsx'));

%% Loop over Excel files
for i = 1:length(filesXLSX)

    % Full path of current Excel file
    xlsxFile = fullfile(filepath, filesXLSX(i).name);

    % Read table
    T = readtable(xlsxFile);

    % ------------------------------------------------------------
    % EXPECTED COLUMNS
    % Adjust these names to match your Excel file:
    %   T.X   -> X coordinate
    %   T.Y   -> Y coordinate
    %   T.T   -> frame / slice / time position
    %
    % If your file has different names (e.g. xcoord, ycoord, frame),
    % replace them below.
    % ------------------------------------------------------------

    x = T.X;
    y = T.Y;

    % If there is a time/frame column use it, otherwise set all to 1
    if ismember('frame', T.Properties.VariableNames)
        t = T.frame;
    else
        t = ones(height(T),1);
    end

    %% Create ROI cell array
    ROIs = cell(1,height(T));

    for j = 1:height(T)

        % Create a point ROI structure compatible with writeImageJROI
        roi = struct();

        % ROI type
        roi.strType = 'Point';

        % Coordinates
        roi.mfCoordinates = [x(j), y(j)];

        % Position vector [channel slice frame]
        % Adjust if your workflow expects something else
        roi.vnPosition = [1 1 t(j)];

        % Optional name
        roi.strName = sprintf('ROI_%03d', j);

        ROIs{j} = roi;
    end

    %% Save with same base name as xlsx
    [~, baseName, ~] = fileparts(filesXLSX(i).name);
    outName = fullfile(filepath, [strcat(baseName,'_cell_death') '.zip']);

    writeImageJROI(outName, ROIs);

    fprintf('Saved: %s\n', outName);
end