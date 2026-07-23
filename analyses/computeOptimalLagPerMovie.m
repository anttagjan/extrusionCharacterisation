function [MovieR,MovieLag,MovieP,MovieN] = ...
    computeOptimalLagPerMovie(A,B,maxLag)


% Dimensions:
% A,B = nBins x nBins x nTimes x nMovies


nBins  = size(A,1);
nTimes = size(A,3);
nMovies = size(A,4);


MovieR   = nan(nBins,nBins,nMovies);
MovieLag = nan(nBins,nBins,nMovies);
MovieP   = nan(nBins,nBins,nMovies);
MovieN   = zeros(nBins,nBins,nMovies);



lagValues = -maxLag:maxLag;



for m = 1:nMovies

    fprintf('Movie %d/%d\n',m,nMovies);


    for i = 1:nBins

        for j = 1:nBins


            bestR = NaN;
            bestLag = NaN;
            bestP = NaN;
            bestN = 0;


            xFull = squeeze(A(i,j,:,m));
            yFull = squeeze(B(i,j,:,m));


            for lag = lagValues


                if lag >= 0

                    idxA = 1:(nTimes-lag);
                    idxB = (1+lag):nTimes;

                else

                    L = -lag;

                    idxA = (1+L):nTimes;
                    idxB = 1:(nTimes-L);

                end


                x = xFull(idxA);
                y = yFull(idxB);


                ok = isfinite(x) & isfinite(y);


                if sum(ok)<5
                    continue
                end


                [R,P] = corr(x(ok),y(ok),...
                    'Type','Spearman');


                if isnan(bestR) || abs(R)>abs(bestR)

                    bestR = R;
                    bestLag = lag;
                    bestP = P;
                    bestN = sum(ok);

                end

            end


            MovieR(i,j,m)=bestR;
            MovieLag(i,j,m)=bestLag;
            MovieP(i,j,m)=bestP;
            MovieN(i,j,m)=bestN;


        end
    end
end


fprintf('Per movie optimal lag finished\n')

end