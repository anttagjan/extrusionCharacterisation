function interactiveCrossCorrMap(binnedData,params)
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
if isfield(params,'maxLagFrames') && ~isempty(params.maxLagFrames)
    maxLagFrames = min(params.maxLagFrames, nTimes-1);
else
    maxLagFrames = nTimes-1;
end

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

        valid = ~isnan(d.cells.count);

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

            aVals = d.cells.area{idx};
            if ~isempty(aVals)
                meanArea(idx) = mean(aVals);
                cvArea(idx)   = std(aVals)/mean(aVals);
            end

            eVals = d.cells.eccentricity{idx};
            if ~isempty(eVals)
                meanEcc(idx) = mean(eVals);
                cvEcc(idx)   = std(eVals)/mean(eVals);
            end

            oVals = d.cells.orientation{idx};
            if ~isempty(oVals)
                meanOri(idx) = mean(oVals);
                cvOri(idx)   = std(oVals)/mean(oVals);
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
% RÉSUMÉ : meilleur lag pour chaque combinaison de variables
% (score = moyenne des |R| sur tout le tissu)
%% =========================================================

summaryTable = {};

k = 1;

for v1 = 1:nVars

    for v2 = v1+1:nVars

        fprintf('Searching best lag : %s vs %s\n', ...
            varNames{v1}, varNames{v2});

        A = timeSeries.(varNames{v1});
        B = timeSeries.(varNames{v2});

        bestScore = -Inf;
        bestLag   = NaN;
        bestR     = [];
        bestP     = [];
        bestN     = [];

        for lag = -maxLagFrames:maxLagFrames

            [R,P,N] = computeCrossCorr(A,B,lag);

            % Bins valides
            valid = isfinite(R);

            if ~any(valid(:))
                continue
            end

            % Score global du tissu
            meanAbsR = mean(abs(R(valid)));

            % Petit bonus si beaucoup de bins sont significatifs
            nSig = sum(P(valid) < 0.05);

            score = meanAbsR + 1e-5*nSig;

            if score > bestScore

                bestScore = score;
                bestLag   = lag;
                bestR     = R;
                bestP     = P;
                bestN     = N;

            end

        end

        if isempty(bestR)
            continue
        end

        % Informations complémentaires
        valid = isfinite(bestR);

        meanAbsR = mean(abs(bestR(valid)));

        meanSignedR = mean(bestR(valid));

        nSig = sum(bestP(valid) < 0.05);

        % Bin présentant la plus forte corrélation (uniquement informatif)
        [~,idx] = max(abs(bestR(:)));
        [row,col] = ind2sub(size(bestR),idx);
        bestSignedR = bestR(row,col);

        summaryTable{k,1}  = varNames{v1};
        summaryTable{k,2}  = varNames{v2};
        summaryTable{k,3}  = bestLag;
        summaryTable{k,4}  = meanAbsR;
        summaryTable{k,5}  = bestScore;
        summaryTable{k,6}  = row;
        summaryTable{k,7}  = col;
        summaryTable{k,8}  = nSig;
        summaryTable{k,9}  = bestSignedR;
        summaryTable{k,10} = meanSignedR;

        k = k+1;

    end

end

figure('Name','Best Cross-Correlation Summary',...
       'Color','w',...
       'Position',[100 100 1200 600]);

uitable(...
    'Data',summaryTable,...
    'ColumnName',{...
        'Variable 1',...
        'Variable 2',...
        'Best lag',...
        'Mean |R|',...
        'Score',...
        'Best row',...
        'Best column',...
        'Significant bins',...
        'Best bin R',...
        'Mean signed R'},...
    'Units','normalized',...
    'Position',[0 0 1 1]);


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
    'Maximum |R|'
    'Optimal lag'
    'Number of movies'
    'Mean frames/movie'
    'Paired observations'
    }, ...
    'Units','normalized', ...
    'Position',[0.85 0.55 0.13 0.05]);

results = struct();
currentVariables = '';

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