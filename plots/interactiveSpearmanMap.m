function interactiveSpearmanMap(binnedData, nBins)

[nMovies, nTimes] = size(binnedData);

%% =========================================================
% VARIABLE LIST
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

nVars = numel(varNames);

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

%% =========================================================
% FIGURE
%% =========================================================

fig = figure('Color','w','Name','Spearman Spatial Coupling (Across Movies)');

ax = axes('Parent',fig,'Position',[0.1 0.2 0.75 0.7]);
hImg = imagesc(nan(nBins));
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

%% SLIDER
slider = uicontrol(fig,'Style','slider',...
    'Units','normalized',...
    'Position',[0.2 0.05 0.6 0.05],...
    'Min',1,'Max',nTimes,'Value',1,...
    'SliderStep',[1/max(nTimes-1,1) 5/max(nTimes-1,1)]);

%% OPTIONAL: sample size map (VERY useful)
fig2 = figure('Color','w','Name','Sample size per bin');
ax2 = axes('Parent',fig2);
hImgN = imagesc(zeros(nBins));
axis image
colorbar
title('n movies contributing per bin')

%% =========================================================
% UPDATE FUNCTION
%% =========================================================

function update()

    t = round(slider.Value);
    t = max(1, min(nTimes, t));

    v1 = varNames{popup1.Value};
    v2 = varNames{popup2.Value};

    A = stackData.(v1){t};
    B = stackData.(v2){t};

    R = nan(nBins, nBins);
    N = zeros(nBins, nBins);

    for i = 1:nBins
        for j = 1:nBins

            x = squeeze(A(i,j,:));
            y = squeeze(B(i,j,:));

            ok = isfinite(x) & isfinite(y);

            N(i,j) = sum(ok);

            if N(i,j) < 5   % stricter threshold (important!)
                continue
            end

            R(i,j) = corr(x(ok), y(ok), 'Type','Spearman');

        end
    end

    hImg.CData = R;
    hImgN.CData = N;

    txt.String = sprintf('Time %d | %s vs %s', t, v1, v2);

    drawnow limitrate
end

%% CALLBACKS
slider.Callback = @(~,~) update();
popup1.Callback = @(~,~) update();
popup2.Callback = @(~,~) update();

%% INIT
update();

end