function val = computeFeatureMap(d, featureName)

switch featureName

    case 'mean_area'
        val = cellfun(@(x) mean(x,'omitnan'), d.cells.area);

    case 'cv_area'
        val = cellfun(@(x) std(x,'omitnan') ./ mean(x,'omitnan'), d.cells.area);

    case 'mean_eccentricity'
        val = cellfun(@(x) mean(x,'omitnan'), d.cells.eccentricity);

    case 'cv_eccentricity'
        val = cellfun(@(x) std(x,'omitnan') ./ mean(x,'omitnan'), d.cells.eccentricity);

    case 'orientation'
        val = cellfun(@(x) mean(x,'omitnan'), d.cells.orientation);

    case 'cv_orientation'
        val = cellfun(@(x) std(x,'omitnan') ./ mean(x,'omitnan'), d.cells.orientation);

    case 'extrusions'
        val = d.extrusions.count;

    case 'divisions'
        val = d.divisions.count;

    case 'mean_cells'
        val = d.cells.count;

end

% enforce scalar-per-bin rule
% if ~isscalar(val)
%     val = NaN;
% end

end