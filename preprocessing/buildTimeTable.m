function timeTable = buildTimeTable(timeDataframe, selectedColumn)

movieNames = timeDataframe{:,1};
alignmentValues = timeDataframe{:, selectedColumn};

timeTable = table(movieNames, alignmentValues, ...
    'VariableNames', {'name', 'peaks'});

end