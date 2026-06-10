function meanShape = buildMeanMovieShape(landmarks)

movieIDs = unique(landmarks(:,3));
nMovies = numel(movieIDs);

shapes = cell(nMovies,1);

for i = 1:nMovies
    m = movieIDs(i);
    X = landmarks(landmarks(:,3)==m,1:2);

    % normalize per movie (centroid + scale)
    X = X - mean(X,1);
    X = X ./ max(norm(X), eps);

    shapes{i} = X;
end

% pad to same number of points (important fix)
minPts = min(cellfun(@(x) size(x,1), shapes));

stack = zeros(minPts,2,nMovies);

for i = 1:nMovies
    stack(:,:,i) = shapes{i}(1:minPts,:);
end

meanShape = mean(stack,3);

end