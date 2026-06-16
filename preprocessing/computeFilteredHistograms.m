function filteredHistograms = computeFilteredHistograms(tStart, tEnd)

filteredHistograms = nan(nBins, nBins, nMovies);

for m = 1:nMovies

    sumH = zeros(nBins);
    countH = zeros(nBins);

    for t = 1:nTimeBins

        currentTime = timeCenters(t);

        if currentTime < tStart || currentTime > tEnd
            continue;
        end

        h = allValidN_full{m,t};
        if isempty(h)
            continue;
        end

        validMask = ~isnan(h);

        % --- ONLY add real values ---
        sumH(validMask) = sumH(validMask) + h(validMask);
        countH(validMask) = countH(validMask) + 1;
    end

    % --- mean per movie ---
    meanH = nan(nBins);
    idx = countH > 0;
    meanH(idx) = sumH(idx) ./ countH(idx);

    filteredHistograms(:,:,m) = meanH;

end
end