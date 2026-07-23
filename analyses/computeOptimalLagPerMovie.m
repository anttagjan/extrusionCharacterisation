function [MovieR,MovieLag,MovieP,MovieN] = ...
    computeOptimalLagPerMovie(A,B,maxLag)


% Dimensions:
% A,B = nBins x nBins x nTimes x nMovies


nBins  = size(A,1);
nMovies = size(A,4);
minFrames =5;

MovieR   = nan(nBins,nBins,nMovies);
MovieLag = nan(nBins,nBins,nMovies);
MovieP   = nan(nBins,nBins,nMovies);
MovieN   = zeros(nBins,nBins,nMovies);

lagValues = -maxLag:maxLag;

for m = 1:nMovies

    for i = 1:nBins
        for j = 1:nBins

            xFull = reshape(A(i,j,:,m),[],1);
            yFull = reshape(B(i,j,:,m),[],1);

            Rcurve = nan(length(lagValues),1);
            Pcurve = nan(length(lagValues),1);
            Ncurve = zeros(length(lagValues),1);


            for k=1:length(lagValues)

                lag = lagValues(k);

                if lag>=0
                    x=xFull(1:end-lag);
                    y=yFull(1+lag:end);
                else
                    L=-lag;
                    x=xFull(1+L:end);
                    y=yFull(1:end-L);
                end


                ok=isfinite(x)&isfinite(y);

                if sum(ok)<minFrames
                    continue
                end


                [Rcurve(k),Pcurve(k)] = corr(...
                    x(ok),y(ok),...
                    'Type','Spearman','Rows','complete');


                Ncurve(k)=sum(ok);

            end


            valid=isfinite(Rcurve);

            if ~any(valid)
                continue
            end


            [~,idx]=max(abs(Rcurve(valid)));

            lagIdx=find(valid);
            lagIdx=lagIdx(idx);


            if abs(Rcurve(lagIdx))<0.3
                continue
            end


            MovieR(i,j,m)=Rcurve(lagIdx);
            MovieLag(i,j,m)=lagValues(lagIdx);
            MovieP(i,j,m)=Pcurve(lagIdx);
            MovieN(i,j,m)=Ncurve(lagIdx);

        end
    end
end


fprintf('Per movie optimal lag finished\n')

end