function values = getFeatureOrDefault(featuresTable, fieldName, idx)
% Returns featuresTable.(fieldName)(idx) if the field exists.
% Otherwise returns a NaN vector of matching length.

    n = sum(idx);

    if ismember(fieldName, featuresTable.Properties.VariableNames)
        values = featuresTable.(fieldName)(idx);
    else
        values = nan(n,1);
    end
end