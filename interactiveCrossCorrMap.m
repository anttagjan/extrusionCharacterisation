function interactiveCrossCorrMap(filepath,binnedData,params)
%INTERACTIVECROSSCORRMAP  Carte spatiale interactive de corrélation croisée

%% =========================================================
% LISTE DES VARIABLES
%% =========================================================

varNames = {
    'extrusions'
    'divisions'
    'mean_area'
    'cv_area'
    'mean_eccentricity'
    'cv_eccentricity'
    'orientation'
    'cv_orientation'
    'mean_cells'
};

nVars   = numel(varNames);
nMovies = size(binnedData,1);
nTimes  = size(binnedData,2);
nBins   = params.nBins;

% Pas de temps réel entre deux frames (juste pour l'affichage du lag)
if isfield(params,'dt') && ~isempty(params.dt)
    dt = params.dt;
else
    dt = 1;
end

% Décalage maximal autorisé (en nombre de frames)
% if isfield(params,'maxLagFrames') && ~isempty(params.maxLagFrames)
%     maxLagFrames = min(params.maxLagFrames, nTimes-1);
% else
%     maxLagFrames = nTimes-1;
% end
maxLagFrames = 6;

if maxLagFrames < 1
    maxLagFrames = 1;   % garde-fou si peu de points temporels
end

%% =========================================================
% PRÉCALCUL : SÉRIES TEMPORELLES PAR BIN / FILM / TEMPS
% (aucune sommation ni moyenne sur le temps : on garde toute la dynamique)
%% =========================================================

timeSeries = struct();
for v = 1:nVars
    timeSeries.(varNames{v}) = nan(nBins,nBins,nTimes,nMovies);
end

for m = 1:nMovies

    fprintf('Traitement du film %d/%d...\n',m,nMovies);

    for t = 1:nTimes

        d = binnedData{m,t};
        if isempty(d)
            continue
        end

        valid = d.tissue.validBinMask;

        c = d.cells.count;
        c(~valid) = NaN;

        e = d.extrusions.count;
        e(~valid) = NaN;

        if isfield(d,'divisions')
            dv = d.divisions.count;
            dv(~valid) = NaN;
        else
            dv = nan(size(c));
        end

        meanArea = nan(nBins);
        cvArea   = nan(nBins);
        meanEcc  = nan(nBins);
        cvEcc    = nan(nBins);
        meanOri  = nan(nBins);
        cvOri    = nan(nBins);

        for idx = 1:numel(c)

            if ~valid(idx)
                continue
            end

            %% AREA

            aVals = d.cells.area{idx};

            if ~isempty(aVals)

                meanVal = mean(aVals);

                if meanVal>0
                    meanArea(idx)=meanVal;
                    cvArea(idx)=std(aVals)/meanVal;
                end

            end

            %% ECCENTRICITY

            eVals = d.cells.eccentricity{idx};

            if ~isempty(eVals)

                meanVal = mean(eVals);

                if meanVal>0
                    meanEcc(idx)=meanVal;
                    cvEcc(idx)=std(eVals)/meanVal;
                end

            end

            %% ORIENTATION

            oVals = d.cells.orientation{idx};

            if ~isempty(oVals)

                meanOri(idx)=mean(oVals);

                meanVal = mean(oVals);

                if meanVal~=0
                    cvOri(idx)=std(oVals)/abs(meanVal);
                end

            end

        end

        timeSeries.extrusions(:,:,t,m)        = e;
        timeSeries.divisions(:,:,t,m)         = dv;
        timeSeries.mean_area(:,:,t,m)         = meanArea;
        timeSeries.cv_area(:,:,t,m)           = cvArea;
        timeSeries.mean_eccentricity(:,:,t,m) = meanEcc;
        timeSeries.cv_eccentricity(:,:,t,m)   = cvEcc;
        timeSeries.orientation(:,:,t,m)       = meanOri;
        timeSeries.cv_orientation(:,:,t,m)    = cvOri;
        timeSeries.mean_cells(:,:,t,m)        = c;
    end
end

clear binnedData   % Allège la sauvegarde .fig

%% =========================================================
% UI
%% =========================================================

fig = figure('Color','w','Name','Interactive Cross-Correlation Map (time-lagged)');

ax = axes('Parent',fig,'Position',[0.1 0.25 0.75 0.65]);
hImg = imagesc(ax, nan(nBins));

hText = gobjects(nBins,nBins);

for i = 1:nBins
    for j = 1:nBins
        hText(i,j) = text(ax, j, i, '', ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontSize',7, ...
            'Color','k');
    end
end

axis(ax,'image')
colormap(ax, turbo)
colorbar
caxis([-1 1])

txt = uicontrol(fig,'Style','text', ...
    'Units','normalized', ...
    'Position',[0.1 0.16 0.6 0.03], ...
    'BackgroundColor','w', ...
    'HorizontalAlignment','left');

%% DROPDOWNS : choix des deux paramètres
popup1 = uicontrol(fig,'Style','popupmenu', ...
    'String',varNames, ...
    'Units','normalized', ...
    'Position',[0.85 0.75 0.13 0.05]);

popup2 = uicontrol(fig,'Style','popupmenu', ...
    'String',varNames, ...
    'Units','normalized', ...
    'Position',[0.85 0.65 0.13 0.05], ...
    'Value',min(2,nVars));

popupMode = uicontrol(fig,'Style','popupmenu', ...
    'String',{
    'Pooled Maximum |R|'
    'Pooled Optimal lag'
    'Number of movies'
    'Mean frames/movie'
    'Paired observations'
    'Median individual R'
    'Median individual lag'
    'Lag variability (IQR)'
    'Fraction negative R'
    'Fraction positive R'
    }, ...
    'Units','normalized', ...
    'Position',[0.85 0.55 0.13 0.05]);

results = struct();
currentVariables = '';

%% =====================================================
% STORAGE FOR PER-MOVIE ANALYSIS
%% =====================================================

movieResults = struct();

saveFolder = 'CrossCorrResults';

if ~exist(fullfile(filepath,saveFolder),'dir')
    mkdir(fullfile(filepath,saveFolder))
end

%% =========================================================
% FONCTION DE MISE À JOUR
%% =========================================================

    function update(~,~)


        v1 = varNames{popup1.Value};
        v2 = varNames{popup2.Value};


        A = timeSeries.(v1);
        B = timeSeries.(v2);



        %% =====================================================
        % COMPUTE ONLY WHEN VARIABLE PAIR CHANGES
        %% =====================================================

        variablePair = [v1 '_' v2];

        if ~strcmp(currentVariables,variablePair)

            fprintf('Computing %s vs %s...\n',v1,v2)


            [results.LagCorr,...
                results.LagP,...
                results.LagN,...
                results.lagValues,...
                results.BestR,...
                results.BestLag,...
                results.BestP,...
                results.BestNobs,...
                results.BestNmovies,...
                results.BestMedianFrames] = ...
                computeOptimalLag(A,B,maxLagFrames);

            %% FDR correction on optimal p-values

            validP = isfinite(results.BestP);
            P_FDR = nan(size(results.BestP));
            P_FDR(validP) = mafdr(...
                results.BestP(validP),...
                'BHFDR',true);

            results.P_FDR = P_FDR;

            %% =====================================================
            % PER MOVIE ANALYSIS
            %% =====================================================

            movieFile = fullfile(filepath, saveFolder,...
                ['MovieLag_' variablePair '.mat']);


            if exist(movieFile,'file')

                fprintf('Loading per-movie results...\n')

                load(movieFile,...
                    'MovieR',...
                    'MovieLag',...
                    'MovieP',...
                    'MovieN');

            else

                fprintf('Computing per-movie lag analysis...\n')

                [MovieR,...
                    MovieLag,...
                    MovieP,...
                    MovieN] = ...
                    computeOptimalLagPerMovie(A,B,maxLagFrames);


                save(movieFile,...
                    'MovieR',...
                    'MovieLag',...
                    'MovieP',...
                    'MovieN',...
                    '-v7.3');

            end

            %% =====================================================
            % SUMMARY ACROSS MOVIES
            %% =====================================================

            MedianMovieR = median(MovieR,3,'omitnan');

            MedianMovieLag = median(MovieLag,3,'omitnan');

            LagVariability = iqr(MovieLag,3);
            Rthreshold = 0.3;
            NegativeFraction = mean(MovieR<-Rthreshold,3,'omitnan');
            PositiveFraction = mean(MovieR>Rthreshold,3,'omitnan');
            DirectionAgreement = max(PositiveFraction,...
                         NegativeFraction);

            movieResults.MovieR = MovieR;
            movieResults.MovieLag = MovieLag;
            movieResults.MovieP = MovieP;
            movieResults.MovieN = MovieN;
            
            movieResults.MedianMovieR = MedianMovieR;
            movieResults.MedianMovieLag = MedianMovieLag;
            movieResults.LagVariability = LagVariability;
            movieResults.NegativeFraction = NegativeFraction;
            movieResults.PositiveFraction = PositiveFraction;
            movieResults.DirectionAgreement = DirectionAgreement;
            
            %% =====================================================
            % WILCOXON SIGNED-RANK ACROSS MOVIES
            %% =====================================================

            MovieP_R = nan(nBins,nBins);

            for i = 1:nBins
                for j = 1:nBins

                    r = squeeze(MovieR(i,j,:));

                    r = r(isfinite(r));


                    % minimum number of movies
                    if numel(r) < 5
                        continue
                    end


                    % test median correlation != 0
                    MovieP_R(i,j) = signrank(r,0);

                end
            end


            %% FDR correction

            validP = isfinite(MovieP_R);

            MovieP_FDR = nan(size(MovieP_R));

            MovieP_FDR(validP) = mafdr(...
                MovieP_R(validP),...
                'BHFDR',true);


            movieResults.MovieP_R = MovieP_R;
            movieResults.MovieP_FDR = MovieP_FDR;

            currentVariables = variablePair;

        end



        BestR   = results.BestR;
        BestLag = results.BestLag;
        BestNobs       = results.BestNobs;
        BestNmovies    = results.BestNmovies;
        BestMedianFrames = results.BestMedianFrames;
        P_FDR   = results.P_FDR;



        mode = popupMode.Value;



        delete(findall(ax,'Tag','SigBoundary'));



        %% =====================================================
        % DISPLAY MODES
        %% =====================================================

        switch mode


            case 1
                % =============================================
                % MAXIMUM CORRELATION
                % =============================================

                hImg.CData = BestR;

                colormap(ax,blueWhiteRed())
                caxis([-1 1])

                hImg.AlphaData = ~isnan(BestR);


                sigMask = (P_FDR <0.05) & isfinite(P_FDR);


                hold(ax,'on')

                for i=1:nBins
                    for j=1:nBins

                        if sigMask(i,j)

                            rectangle(ax,...
                                'Position',[j-0.5 i-0.5 1 1],...
                                'EdgeColor','k',...
                                'LineWidth',2,...
                                'Tag','SigBoundary');

                        end

                    end
                end

                hold(ax,'off')


                titleStr = 'Maximum Spearman R';



            case 2
                % =============================================
                % OPTIMAL LAG
                % =============================================

                hImg.CData = BestLag;

                hImg.AlphaData = ~isnan(BestLag);


                colormap(ax,parula)

                caxis([-maxLagFrames maxLagFrames])


                titleStr = 'Optimal lag (frames)';



            case 3
                % =============================================
                % SAMPLE SIZE
                % =============================================

                hImg.CData = BestNmovies;

                colormap(ax,hot)
                caxis([0 nMovies])

                titleStr = 'Contributing movies';
            case 4 
                hImg.CData = BestMedianFrames;

                colormap(ax,hot)
                caxis([0 max(BestMedianFrames(:),[],'omitnan')])

                titleStr = 'Mean paired frames/movie';
            case 5
                hImg.CData = BestNobs;

                colormap(ax,hot)
                caxis([0 max(BestNobs(:))+eps])

                titleStr = 'Total paired observations';
            case 6

                hImg.CData = movieResults.MedianMovieR;

                colormap(ax,blueWhiteRed())
                caxis([-1 1])

                hImg.AlphaData = isfinite(movieResults.MedianMovieR);


                % Significant bins after FDR correction
                sigMask = movieResults.MovieP_FDR < 0.05;

                hold(ax,'on')

                for i = 1:nBins
                    for j = 1:nBins

                        if sigMask(i,j)

                            rectangle(ax,...
                                'Position',[j-0.5 i-0.5 1 1],...
                                'EdgeColor','k',...
                                'LineWidth',2,...
                                'Tag','SigBoundary');

                        end

                    end
                end

                hold(ax,'off')


                titleStr = 'Median individual R (Wilcoxon FDR<0.05)';

            case 7
                
                sigMask = movieResults.MovieP_FDR < 0.05 & ...
          isfinite(movieResults.MovieP_FDR);
                displayMap = movieResults.MedianMovieLag;
                displayMap(~sigMask) = NaN;

                hImg.CData = displayMap;
                hImg.AlphaData = isfinite(displayMap);

                colormap(ax,parula)

                caxis([-maxLagFrames maxLagFrames])

                titleStr = 'Median individual lag';


            case 8
                
                sigMask = movieResults.MovieP_FDR < 0.05 & ...
          isfinite(movieResults.MovieP_FDR);

                displayMap = movieResults.LagVariability;
                displayMap(~sigMask) = NaN;

                hImg.CData = displayMap;
                hImg.AlphaData = isfinite(displayMap);

                colormap(ax,parula)
                caxis(ax,[0 max(movieResults.LagVariability(:),[],'omitnan')])
                titleStr = 'Lag variability (IQR)';

            case 9
                sigMask = movieResults.MovieP_FDR < 0.05 & ...
          isfinite(movieResults.MovieP_FDR);

                displayMap = movieResults.NegativeFraction;
                 displayMap(~sigMask) = NaN;

                hImg.CData = displayMap;
                hImg.AlphaData = isfinite(displayMap);

                colormap(ax,parula)

                caxis([0 1])

                titleStr = 'Fraction of movies with R<-0.3';
            case 10
                sigMask = movieResults.MovieP_FDR < 0.05 & ...
          isfinite(movieResults.MovieP_FDR);
                
                displayMap = movieResults.PositiveFraction;
                displayMap(~sigMask) = NaN;

                hImg.CData = displayMap;
                hImg.AlphaData = isfinite(displayMap);

                colormap(ax,parula)
                caxis([0 1])

                titleStr='Fraction of movies with R>0.3';

        end



        %% =====================================================
        % TEXT VALUES INSIDE MAP
        %% =====================================================


        for i=1:nBins
            for j=1:nBins


                switch mode


                    case 1

                        if isnan(BestR(i,j))
                            hText(i,j).String='';
                        else
                            hText(i,j).String=sprintf('%.2f',BestR(i,j));
                        end



                    case 2

                        if isnan(BestLag(i,j))
                            hText(i,j).String='';
                        else
                            hText(i,j).String=sprintf('%d',BestLag(i,j));
                        end



                    case 3   % Number of movies

                        if BestNmovies(i,j)==0
                            hText(i,j).String='';
                        else
                            hText(i,j).String=sprintf('%d',BestNmovies(i,j));
                        end


                    case 4   % Mean frames/movie

                        if isnan(BestMedianFrames(i,j))
                            hText(i,j).String='';
                        else
                            hText(i,j).String=sprintf('%.1f',BestMedianFrames(i,j));
                        end


                    case 5   % Total observations

                        if BestNobs(i,j)==0
                            hText(i,j).String='';
                        else
                            hText(i,j).String=sprintf('%d',BestNobs(i,j));
                        end
                    case 6

                        hText(i,j).String = sprintf('%.2f',...
                            movieResults.MedianMovieR(i,j));


                    case 7

                        if ~sigMask(i,j)
                            hText(i,j).String='';
                        else
                            hText(i,j).String = sprintf('%.1f',...
                                movieResults.MedianMovieLag(i,j));
                        end

                    case 8


                        if ~sigMask(i,j)
                            hText(i,j).String='';
                        else
                            hText(i,j).String = sprintf('%.1f',...
                                movieResults.LagVariability(i,j));
                        end

                    case 9

                        if ~sigMask(i,j)
                            hText(i,j).String='';
                        else
                             hText(i,j).String = sprintf('%.0f%%',...
                            100*movieResults.NegativeFraction(i,j));
                        end

                    case 10

                        if ~sigMask(i,j)
                            hText(i,j).String='';
                        else
                            hText(i,j).String=sprintf('%.0f%%',...
                                100*movieResults.PositiveFraction(i,j));
                        end

                end

            end
        end



        txt.String = sprintf(...
            '%s vs %s | %s',...
            v1,v2,titleStr);



        drawnow limitrate


    end

%% =========================================================
% CALLBACKS
%% =========================================================

popup1.Callback    = @update;
popup2.Callback    = @update;
popupMode.Callback = @update;

%% =========================================================
% INIT
%% =========================================================

update();

    function cmap = blueWhiteRed()

        n = 256;

        blue  = [0 0.2 1];
        white = [1 1 1];
        red   = [1 0 0];

        c1 = [linspace(blue(1),  white(1), n/2)' ...
              linspace(blue(2),  white(2), n/2)' ...
              linspace(blue(3),  white(3), n/2)'];

        c2 = [linspace(white(1), red(1), n/2)' ...
              linspace(white(2), red(2), n/2)' ...
              linspace(white(3), red(3), n/2)'];

        cmap = [c1; c2];

    end

fprintf('\n Interactive Cross-Correlation Map: Finished \n')

end