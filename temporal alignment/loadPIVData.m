function results = loadPIVData(filepath,span)

mat_files = dir(fullfile(filepath,'*.mat'));

results = struct([]);

for ii = 1:length(mat_files)

    load(fullfile(filepath,mat_files(ii).name));

    rowInit = 1;
    rowFin = height(x{1,1});

    nt = size(velocity_magnitude,1);
    t = (1:nt);

    v_mean = nan(nt,1);

    for k = 1:nt
        umask = u_original{k}./u_original{k};
        v_mag_masked = umask .* velocity_magnitude{k}(rowInit:rowFin,:);
        v_mean(k) = mean(v_mag_masked(:),'omitnan');
    end

    v_smooth = smooth(v_mean, span, 'rlowess');

    results(ii).name = mat_files(ii).name;
    results(ii).t = t;
    results(ii).raw = v_mean;
    results(ii).smooth = v_smooth;
    results(ii).ylabel = 'Speed';
end
end