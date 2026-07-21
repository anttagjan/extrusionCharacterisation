function [LagCorr,LagP,LagN,lagValues,...
          BestR,BestLag,BestP,...
          BestNobs,BestNmovies,BestMedianFrames] = computeOptimalLag(A,B,maxLag)

% A and B dimensions:
% nBins x nBins x nTimes x nMovies

nBins = size(A,1);
nT    = size(A,3);


%% =========================================================
% LAG AXIS
%% =========================================================

lagValues = -maxLag:maxLag;
nLag = length(lagValues);


%% =========================================================
% STORAGE
%% =========================================================

% Full lag profile
LagCorr = nan(nBins,nBins,nLag);
LagP    = nan(nBins,nBins,nLag);
LagN    = zeros(nBins,nBins,nLag);


% Optimal lag results
BestR   = nan(nBins,nBins);
BestLag = nan(nBins,nBins);
BestP   = nan(nBins,nBins);
BestNobs        = zeros(nBins);
BestNmovies     = zeros(nBins);
BestMedianFrames  = nan(nBins);



%% =========================================================
% LOOP OVER ALL LAGS
%% =========================================================

for k = 1:nLag

    lag = lagValues(k);

    fprintf('Computing lag %d / %d : %d frames\n',...
        k,nLag,lag);


    %% Temporal alignment

    if lag >= 0

        % A(t) vs B(t+lag)
        idxA = 1:(nT-lag);
        idxB = (1+lag):nT;

    else

        % A(t-lag) vs B(t)
        L = -lag;

        idxA = (1+L):nT;
        idxB = 1:(nT-L);

    end


    Asub = A(:,:,idxA,:);
    Bsub = B(:,:,idxB,:);



    %% =====================================================
    % CORRELATION FOR EACH BIN
    %% =====================================================

    for i = 1:nBins

        for j = 1:nBins
            
            movieCounts = zeros(size(A,4),1);

            for m = 1:size(A,4)

                xx = squeeze(Asub(i,j,:,m));
                yy = squeeze(Bsub(i,j,:,m));

                movieCounts(m) = sum(isfinite(xx) & isfinite(yy));

            end

            % Number of movies contributing enough data
            nMovieValid = sum(movieCounts >= 5);

            % Require at least 5 movies
            if nMovieValid < 5
                continue
            end

            x = squeeze(Asub(i,j,:,:));
            y = squeeze(Bsub(i,j,:,:));


            % concatenate time and movies
            x = x(:);
            y = y(:);


            valid = isfinite(x) & isfinite(y);

            N = sum(valid);


            if N < 5
                continue
            end



            [R,P] = corr(x(valid),y(valid),...
                'Type','Spearman',...
                'Rows','complete');



            %% Store complete lag profile

            LagCorr(i,j,k) = R;
            LagP(i,j,k)    = P;
            LagN(i,j,k)    = N;



            %% Store best lag

            if isnan(BestR(i,j)) || abs(R) > abs(BestR(i,j))

                BestR(i,j)   = R;
                BestLag(i,j) = lag;
                BestP(i,j)   = P;

                % total paired observations
                BestNobs(i,j) = N;

                % ---- number of movies contributing ----
                BestNmovies(i,j) = sum(movieCounts > 0);

                if BestNmovies(i,j) > 0
                    BestMedianFrames(i,j) = median(movieCounts(movieCounts>0));
                end

            end


        end

    end

end


fprintf('Optimal lag computation finished.\n')

end