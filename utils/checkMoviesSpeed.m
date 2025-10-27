% Example data
singles = velocity_magnitude;

nArrays = numel(singles);

% --- Step 1. Compute the mean & SD of each array ---
arrayMeans = cellfun(@(x) mean(x(:),'omitnan'), singles);
arraySDs   = cellfun(@(x) std(x(:),'omitnan'), singles);

% --- Step 2. Compute global mean and SD across arrays ---
globalMean = mean(arrayMeans,'omitnan');
globalSD   = std(arrayMeans,0,'omitnan');

% --- Step 3. Smooth the mean trace ---
smoothMeans = smoothdata(arrayMeans, 'movmean', 3); % window=3 arrays

% --- Step 4. Plot ---
x = 1:nArrays;
figure;
plot(x, smoothMeans, 'b-', 'LineWidth', 2); hold on;
plot(x, arrayMeans, 'ko--', 'MarkerSize', 4, 'LineWidth', 1); % raw means

% global mean ± SD lines
yline(globalMean, 'r-', 'LineWidth', 1.5);
yline(globalMean+globalSD, 'r--');
yline(globalMean-globalSD, 'r--');

xlabel('Array index in cell array');
ylabel('Mean value of each array');
legend({'Smoothed mean','Raw means','Global mean','Global mean ± 1 SD'});
title('Mean per Array with Smoothed Trend');