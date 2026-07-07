function interactiveSpearmanMap_summary(binnedData,params)

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

nBins = params.nBins;

%% =========================================================
% PRECOMPUTE STACKS (SUMMARY PER MOVIE)
%% =========================================================

stackData = struct();

for v = 1:nVars
    stackData.(varNames{v}) = nan(nBins,nBins,nMovies);
end

for m = 1:nMovies

    fprintf('Summarizing movie %d/%d...\n',m,nMovies);

    %---------------------------------------
    % Initialize accumulators
    %---------------------------------------
    sumCells = zeros(nBins);
    sumArea  = zeros(nBins);
    sumExtr  = zeros(nBins);
    sumDiv   = zeros(nBins);

    eccStack = cell(nBins);
    areaStack = cell(nBins);
    oriStack = cell(nBins);

    %---------------------------------------
    % Loop over time
    %---------------------------------------
    for t = 1:nTimes

        d = binnedData{m,t};
        if isempty(d), continue; end

        valid = ~isnan(d.cells.count);

        c = d.cells.count;
        c(~valid)=0;

        a = d.cells.areaSum;
        a(~valid)=0;

        e = d.extrusions.count;
        e(~valid)=0;

        if isfield(d,'divisions')
            dv = d.divisions.count;
            dv(~valid)=0;
        else
            dv = zeros(size(c));
        end

        sumCells(valid)=sumCells(valid)+c(valid);
        sumArea(valid)=sumArea(valid)+a(valid);
        sumExtr(valid)=sumExtr(valid)+e(valid);
        sumDiv(valid)=sumDiv(valid)+dv(valid);

        [r,cbin]=find(valid);

        for k=1:numel(r)

            ii=r(k);
            jj=cbin(k);

            areaStack{ii,jj}=[areaStack{ii,jj}; d.cells.area{ii,jj}(:)];
            eccStack{ii,jj} =[eccStack{ii,jj}; d.cells.eccentricity{ii,jj}(:)];
            oriStack{ii,jj} =[oriStack{ii,jj}; d.cells.orientation{ii,jj}(:)];

        end
    end

    %---------------------------------------
    % Compute summary maps
    %---------------------------------------

    meanArea = sumArea./sumCells;
    meanArea(sumCells==0)=NaN;

    cvArea = nan(nBins);
    meanEcc = nan(nBins);
    cvEcc = nan(nBins);
    meanOri = nan(nBins);
    cvOri = nan(nBins);

    for idx=1:numel(sumCells)

        if ~isempty(areaStack{idx})
            cvArea(idx)=std(areaStack{idx})/mean(areaStack{idx});
        end

        if ~isempty(eccStack{idx})
            meanEcc(idx)=mean(eccStack{idx});
            cvEcc(idx)=std(eccStack{idx})/mean(eccStack{idx});
        end

        if ~isempty(oriStack{idx})
            meanOri(idx)=mean(oriStack{idx});
            cvOri(idx)=std(oriStack{idx})/mean(oriStack{idx});
        end

    end

    stackData.extrusions(:,:,m)=sumExtr;
    stackData.divisions(:,:,m)=sumDiv;
    stackData.mean_area(:,:,m)=meanArea;
    stackData.cv_area(:,:,m)=cvArea;
    stackData.mean_eccentricity(:,:,m)=meanEcc;
    stackData.cv_eccentricity(:,:,m)=cvEcc;
    stackData.orientation(:,:,m)=meanOri;
    stackData.cv_orientation(:,:,m)=cvOri;
    stackData.mean_cells(:,:,m)=sumCells;

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
    'String',{'Spearman R', 'Sample size N'},...
    'Units','normalized',...
    'Position',[0.85 0.5 0.13 0.05]);

popupMode.Callback = @(~,~) update();

%% update function

function update()

    v1 = varNames{popup1.Value};
    v2 = varNames{popup2.Value};

    A = stackData.(v1);
    B = stackData.(v2);
    
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
        sigMask = (P < 0.05) & ~isnan(P);

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
    
    txt.String = sprintf('Whole movie | %s vs %s | %s',...
    v1,v2,titleStr);

    drawnow limitrate
end

%% CALLBACKS
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