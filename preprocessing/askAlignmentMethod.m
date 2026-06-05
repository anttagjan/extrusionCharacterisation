function [selectedColumn, selectedLandmarks] = askAlignmentMethod()

choice = questdlg('Select time alignment method:', ...
    'Time Alignment', ...
    'Speed peaks', 'Division peaks', 'Speed peaks');

switch choice
    case 'Speed peaks'
        selectedColumn = 'speedPeaks';
        selectedLandmarks = 'speed';
    case 'Division peaks'
        selectedColumn = 'divisionPeaks';
        selectedLandmarks = 'division';
    otherwise
        error('No alignment method selected.');
end

end