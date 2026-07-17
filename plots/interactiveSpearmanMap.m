function interactiveSpearmanMap(binnedData, params)

% VARIABLE LIST

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

nVars = numel(varNames);

nMovies = size(binnedData,1);
maxN_global = nMovies;

nTimes  = size(binnedData,2);
timeLabels = params.timeBins;

nBins = params.nBins;

%% =========================================================
% PRECOMPUTE STACKS (CLEAN NUMERIC ONLY)
%% =========================================================

stackData = struct();

for v = 1:nVars
    stackData.(varNames{v}) = cell(nTimes,1);
end

for t = 1:nTimes

    for v = 1:nVars

        name = varNames{v};

        stack = nan(nBins, nBins, nMovies);

        for m = 1:nMovies

            d = binnedData{m,t};
            if isempty(d), continue; end

            val = computeFeatureMap(d, name);

            if isempty(val), continue; end

            if iscell(val)
                val = val{1};
            end

            if ~isnumeric(val)
                continue;
            end

            if ~isequal(size(val), [nBins nBins])
                continue;
            end

            stack(:,:,m) = double(val);

        end

        stackData.(name){t} = stack;
    end
end

%% UI

fig = figure('Color','w','Name','Dynamic Spearman Spatial Coupling');

ax = axes('Parent',fig,'Position',[0.1 0.2 0.75 0.7]);
hImg = imagesc(ax, nan(nBins));

hText = gobjects(nBins,nBins);

for i = 1:nBins
    for j = 1:nBins

        hText(i,j) = text(ax,...
            j,...
            i,...
            '',...
            'HorizontalAlignment','center',...
            'VerticalAlignment','middle',...
            'FontSize',7,...
            'Color','k');

    end
end

axis image
colormap(ax, turbo)
colorbar
caxis([-1 1])

txt = uicontrol(fig,'Style','text',...
    'Units','normalized',...
    'Position',[0.1 0.11 0.6 0.03],...
    'BackgroundColor','w');

%% DROPDOWNS
popup1 = uicontrol(fig,'Style','popupmenu',...
    'String',varNames,...
    'Units','normalized',...
    'Position',[0.85 0.7 0.13 0.05]);

popup2 = uicontrol(fig,'Style','popupmenu',...
    'String',varNames,...
    'Units','normalized',...
    'Position',[0.85 0.6 0.13 0.05]);

popupMode = uicontrol(fig,'Style','popupmenu',...
    'String',{'Spearman R','Sample size N'},...
    'Units','normalized',...
    'Position',[0.85 0.5 0.13 0.05]);

popupMode.Callback = @(~,~) update();
%% SLIDER
slider = uicontrol(fig,'Style','slider',...
    'Units','normalized',...
    'Position',[0.2 0.05 0.6 0.05],...
    'Min',1,'Max',nTimes,'Value',1,...
    'SliderStep',[1/max(nTimes-1,1) 5/max(nTimes-1,1)]);
slider.Callback = @(~,~) update();
sliderTooltip = @(t) set(slider,'TooltipString',string(timeLabels{round(t)}));

%% UPDATE FUNCTION

function update()

    t = round(slider.Value);
    t = max(1, min(nTimes, t));

    v1 = varNames{popup1.Value};
    v2 = varNames{popup2.Value};

    A = stackData.(v1){t};
    B = stackData.(v2){t};
    
    P = nan(nBins, nBins);   % p-values
    R = nan(nBins, nBins); % correlation
    N = zeros(nBins, nBins); % number of samples

    for i = 1:nBins
        for j = 1:nBins

            x = squeeze(A(i,j,:));
            y = squeeze(B(i,j,:));

            ok = isfinite(x) & isfinite(y);

            N(i,j) = sum(ok);

            if N(i,j) < 5   % stricter threshold (important!)
                continue
            end
            
            [R(i,j), P(i,j)] = corr(x(ok), y(ok), ...
                'Type','Spearman', 'Rows','complete');

            %% FDR correction

            validP = isfinite(P);

            Pvec = P(validP);

            P_FDR_vec = mafdr(Pvec,'BHFDR',true);

            P_FDR = nan(size(P));

            P_FDR(validP) = P_FDR_vec;

        end
    end

    mode = popupMode.Value;

    if mode == 1
        % =========================
        % SPEARMAN R
        % =========================
        Rplot = R;

        % mask NaNs explicitly
        Rmask = isnan(Rplot);

        hImg.CData = Rplot;

        colormap(ax, blueWhiteRed())
        caxis([-1 1])

        % force NaNs to appear gray
        hImg.AlphaData = ~Rmask;
        set(fig,'Color','w')
        titleStr = 'Spearman R';

        % Remove previous significance boundaries
        delete(findall(ax,'Tag','SigBoundary'));

        % Significant bins
        sigMask = (P_FDR < 0.05) & ~isnan(P_FDR);

        hold(ax,'on')

        for i = 1:nBins
            for j = 1:nBins

                if ~sigMask(i,j)
                    continue
                end

                rectangle(ax,...
                    'Position',[j-0.5, i-0.5, 1, 1],...
                    'EdgeColor','k',...
                    'LineWidth',2,...
                    'Curvature',0,...
                    'Tag','SigBoundary');

            end
        end

        hold(ax,'off')

    elseif mode == 2
        % =========================
        % SAMPLE SIZE
        % =========================
        hImg.CData = N;
        delete(findall(ax,'Tag','SigBoundary'));

        colormap(ax, hot)
        caxis([0 maxN_global])
        titleStr = 'Sample size (N)';
    end

    for i = 1:nBins
        for j = 1:nBins

            if N(i,j) == 0
                hText(i,j).String = '';
                continue
            end

            switch mode

                case 1  % R
                    val = R(i,j);

                    if isnan(val)
                        hText(i,j).String = '';
                    else
                        hText(i,j).String = sprintf('%.2f', val);
                    end

                    hText(i,j).Color = 'k';

                case 2  % N
                    hText(i,j).String = sprintf('%d', N(i,j));

            end

        end
    end
    
    if iscell(timeLabels)
        tLabel = timeLabels{t};
    else
        tLabel = timeLabels(t);
    end
    slider.TooltipString = string(tLabel);
    txt.String = sprintf('Time %s | %s vs %s | %s', ...
    string(tLabel), v1, v2, titleStr);

    drawnow limitrate
end

%% CALLBACKS
slider.Callback = @(~,~) update();
popup1.Callback = @(~,~) update();
popup2.Callback = @(~,~) update();

%% INIT
update();

    function cmap = blueWhiteRed()

        n = 256;

        blue = [0 0.2 1];
        white = [1 1 1];
        red = [1 0 0];

        c1 = [linspace(blue(1), white(1), n/2)' ...
            linspace(blue(2), white(2), n/2)' ...
            linspace(blue(3), white(3), n/2)'];

        c2 = [linspace(white(1), red(1), n/2)' ...
            linspace(white(2), red(2), n/2)' ...
            linspace(white(3), red(3), n/2)'];

        cmap = [c1; c2];

    end
end