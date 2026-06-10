function refMovieID = pickReferenceMovie(landmarks, meanShape)

movieIDs = unique(landmarks(:,3));
nMovies = numel(movieIDs);

scores = zeros(nMovies,1);

minPts = size(meanShape,1);

for i = 1:nMovies

    m = movieIDs(i);
    X = landmarks(landmarks(:,3)==m,1:2);

    X = X - mean(X,1);
    X = X ./ max(norm(X), eps);

    X = X(1:minPts,:);

    scores(i) = norm(X - meanShape,'fro');
end

[~,idx] = min(scores);
refMovieID = movieIDs(idx);

end