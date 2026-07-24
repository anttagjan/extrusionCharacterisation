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
    'cells'
};

nVars = numel(varNames);

nMovies = size(binnedData,1);
minN = ceil(0.7*nMovies);

nTimes  = size(binnedData,2);

nBins = params.nBins;

%% =========================================================
% PRECOMPUTE STACKS (SUMMARY PER MOVIE)
%% =========================================================

stackData = struct();

for v = 1:nVars
    stackData.(varNames{v}) = nan(nBins,nBins,nMovies);
end
stackData.cell_presence = false(nBins,nBins,nMovies);
stackData.valid_tissue = false(nBins,nBins,nMovies);

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

        % Spatial validity comes from tissue classification
        valid = d.tissue.validBinMask;

        % Store tissue mask
        stackData.valid_tissue(:,:,m) = ...
            stackData.valid_tissue(:,:,m) | valid;


        % Cell counts
        c = d.cells.count;
        c(~valid)=0;

        % Cell area
        a = d.cells.areaSum;
        a(~valid)=0;

        % Events
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

            % Track bins with cells
            if c(ii,jj)>0
                stackData.cell_presence(ii,jj,m)=true;
            end

            if ~isempty(d.cells.area{ii,jj})
                areaStack{ii,jj}=[areaStack{ii,jj}; ...
                    d.cells.area{ii,jj}(:)];
            end

            if ~isempty(d.cells.eccentricity{ii,jj})
                eccStack{ii,jj}=[eccStack{ii,jj}; ...
                    d.cells.eccentricity{ii,jj}(:)];
            end

            if ~isempty(d.cells.orientation{ii,jj})
                oriStack{ii,jj}=[oriStack{ii,jj}; ...
                    d.cells.orientation{ii,jj}(:)];
            end

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

sumExtr(~stackData.valid_tissue(:,:,m)) = NaN;
sumDiv(~stackData.valid_tissue(:,:,m))  = NaN;

stackData.extrusions(:,:,m)=sumExtr;
stackData.divisions(:,:,m)=sumDiv;

    stackData.mean_area(:,:,m)=meanArea;
    stackData.cv_area(:,:,m)=cvArea;
    stackData.mean_eccentricity(:,:,m)=meanEcc;
    stackData.cv_eccentricity(:,:,m)=cvEcc;
    stackData.orientation(:,:,m)=meanOri;
    stackData.cv_orientation(:,:,m)=cvOri;

    sumCells(~stackData.valid_tissue(:,:,m)) = NaN;
    stackData.cells(:,:,m)=sumCells;

end

%% =========================================================
% GLOBAL SUMMARY MAPS
%% =========================================================

totalMaps = struct();
medianMaps = struct();

% total events
totalMaps.extrusions = sum(stackData.extrusions,3,'omitnan');
totalMaps.divisions  = sum(stackData.divisions,3,'omitnan');

% median per movie
medianMaps.extrusions = median(stackData.extrusions,3,'omitnan');
medianMaps.divisions  = median(stackData.divisions,3,'omitnan');

medianMaps.cells = median(stackData.cells,3,'omitnan');
medianMaps.mean_area = median(stackData.mean_area,3,'omitnan');
medianMaps.cv_area = median(stackData.cv_area,3,'omitnan');
medianMaps.mean_eccentricity = median(stackData.mean_eccentricity,3,'omitnan');
medianMaps.cv_eccentricity = median(stackData.cv_eccentricity,3,'omitnan');
medianMaps.orientation = median(stackData.orientation,3,'omitnan');
medianMaps.cv_orientation = median(stackData.cv_orientation,3,'omitnan');

% Number of movies per bin
nMoviesMap = sum(stackData.valid_tissue,3);

invalid = nMoviesMap == 0;

totalMaps.extrusions(invalid) = NaN;
totalMaps.divisions(invalid)  = NaN;

medianMaps.extrusions(invalid) = NaN;
medianMaps.divisions(invalid)  = NaN;
medianMaps.cells(invalid)      = NaN;

clear binnedData %Create space to save then the figure


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
    'String',{ ...
    'Spearman R',...
    'Sample size N',...
    'Total extrusions',...
    'Median extrusions/movie',...
    'Total divisions',...
    'Median divisions/movie',...
    'Median cells/movie',...
    'Median mean area/movie',...
    'Median CV area/movie',...
    'Median eccentricity/movie',...
    'Median CV eccentricity/movie',...
    'Median orientation/movie',...
    'Median CV orientation/movie'},...
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

            validTissue = squeeze(stackData.valid_tissue(i,j,:));

            ok = isfinite(x) & isfinite(y) & validTissue;

            N(i,j) = sum(ok);

            if N(i,j) >= minN  % stricter threshold (important!)
                [R(i,j), P(i,j)] = corr(x(ok), y(ok), ...
                    'Type','Spearman', 'Rows','complete');
            end

        end

    end
    
    %% FDR correction
    validP = isfinite(P);
    Pvec = P(validP);
    P_FDR_vec = mafdr(Pvec,'BHFDR',true);
    P_FDR = nan(size(P));
    P_FDR(validP) = P_FDR_vec;

    mode = popupMode.Value;
    
switch mode 
    case 1
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

    case 2

        % =========================
        % SAMPLE SIZE
        % =========================
        hImg.CData = N;
        hImg.AlphaData = isfinite(N);
        delete(findall(ax,'Tag','SigBoundary'));

        colormap(ax, parula)
        caxis([0 max(N(:))])
        titleStr = 'Sample size (N)';
    case 3

    displayMap = totalMaps.extrusions;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([0 max(displayMap(:),[],'omitnan')])

    titleStr='Total extrusions';


case 4

    displayMap = medianMaps.extrusions;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([0 max(displayMap(:),[],'omitnan')])

    titleStr='Median extrusions/movie';


case 5

    displayMap = totalMaps.divisions;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([0 max(displayMap(:),[],'omitnan')])

    titleStr='Total divisions';


case 6

    displayMap = medianMaps.divisions;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([0 max(displayMap(:),[],'omitnan')])

    titleStr='Median divisions/movie';
case 7

    displayMap = medianMaps.cells;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([0 max(displayMap(:),[],'omitnan')])

    titleStr='Median cells/movie';


case 8

    displayMap = medianMaps.mean_area;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([0 max(displayMap(:),[],'omitnan')])

    titleStr='Median average area/movie';


case 9

    displayMap = medianMaps.cv_area;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([0 max(displayMap(:),[],'omitnan')])

    titleStr='Median CV area/movie';


case 10

    displayMap = medianMaps.mean_eccentricity;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([min(displayMap(:),[],'omitnan') max(displayMap(:),[],'omitnan')])

    titleStr='Median average eccentricity/movie';


case 11

    displayMap = medianMaps.cv_eccentricity;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([min(displayMap(:),[],'omitnan') max(displayMap(:),[],'omitnan')])

    titleStr='Median CV eccentricity/movie';


case 12

    displayMap = medianMaps.orientation;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([min(displayMap(:),[],'omitnan') ...
           max(displayMap(:),[],'omitnan')])

    titleStr='Median average orientation/movie';


case 13

    displayMap = medianMaps.cv_orientation;

    hImg.CData = displayMap;
    hImg.AlphaData = isfinite(displayMap);

    colormap(ax,parula)
    caxis([0 max(displayMap(:),[],'omitnan')])

    titleStr='Median CV orientation/movie';

end

if ~exist('displayMap','var')
    displayMap = nan(nBins);
end
%% =========================================================
% MOVIE COVERAGE BOUNDARIES
% Only for summary maps
%% =========================================================

delete(findall(ax,'Tag','CoverageBoundary'));


if mode >= 3

    coverageMask = nMoviesMap >= ceil(0.7*nMovies);


    hold(ax,'on')

    for i = 1:nBins
        for j = 1:nBins

            if coverageMask(i,j)

                rectangle(ax,...
                    'Position',[j-0.5 i-0.5 1 1],...
                    'EdgeColor','k',...
                    'LineWidth',2,...
                    'Tag','CoverageBoundary');

            end

        end
    end

    hold(ax,'off')

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
                case {3,4,5,6,7,8,9,10,11,12,13}

                    if isnan(displayMap(i,j))
                        hText(i,j).String='';
                    else

                        if ismember(mode,[3 5 7 8])
                            % eventos enteros
                            hText(i,j).String=sprintf('%.0f',displayMap(i,j));
                        elseif ismember(mode,[9 10 11])
                            hText(i,j).String=sprintf('%.2f',displayMap(i,j));
                        else
                            % parámetros continuos
                            hText(i,j).String=sprintf('%.1f',displayMap(i,j));
                        end

                    end

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
%% SAVE FIGURE BUTTON

saveButton = uicontrol(fig,...
    'Style','pushbutton',...
    'String','Save Figure',...
    'Units','normalized',...
    'Position',[0.85 0.4 0.13 0.05],...
    'Callback',@saveFigure);

%% INIT
update();

%% =========================================================
% SAVE CURRENT FIGURE
%% =========================================================

    function saveFigure(~,~)

        v1 = varNames{popup1.Value};
        v2 = varNames{popup2.Value};

        modeNames = popupMode.String;
        modeName = modeNames{popupMode.Value};

        % Clean filename
        modeName = strrep(modeName,' ','_');
        modeName = strrep(modeName,'/','_');

        filename = sprintf('%s_vs_%s_%s.png',...
            v1,...
            v2,...
            modeName);

        saveFolder = 'SavedFigures';

        if ~exist(saveFolder,'dir')
            mkdir(saveFolder)
        end

        filepath = fullfile(saveFolder,filename);

        %% Improve figure appearance before export

        % Increase figure size
        fig.Position = [100 100 1200 1000];

        % Axis tick labels
        ax.FontSize = 18;

        % Colorbar font size
        cb = colorbar(ax);
        cb.FontSize = 18;

        % Increase text inside bins
        for ii = 1:nBins
            for jj = 1:nBins
                hText(ii,jj).FontSize = 14;
                hText(ii,jj).FontWeight = 'bold';
            end
        end

        % Improve rendering
        set(fig,'Renderer','painters')

        exportgraphics(fig,filepath,...
            'Resolution',300);

        fprintf('Figure saved: %s\n',filepath)

    end

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