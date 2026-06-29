function runTemporalPlots(results, outputPath)

n = length(results);

x_peaks = arrayfun(@(r) r.x_peak, results);
shift_ref = max(x_peaks);

cm = jet(n);

%% FITS OF ALL DATASETS

plotsPerFigure = 28;      % 7 rows × 4 columns
nCols = 4;
nRows = 7;

nFigures = ceil(n / plotsPerFigure);

for f = 1:nFigures

    figure;
    set(gcf,'Position',[50 50 1200 1800]);

    firstIdx = (f-1)*plotsPerFigure + 1;
    lastIdx  = min(f*plotsPerFigure, n);

    for k = firstIdx:lastIdx

        subplot(nRows,nCols,k-firstIdx+1);
        hold on;
        box on;

        plot(results(k).t,results(k).raw,...
            'Color',[0.75 0.75 0.75],'LineWidth',1.2);

        plot(results(k).t,results(k).smooth,...
            'k','LineWidth',1.8);

        fitInt = results(k).interval;
        fitModel = results(k).fit;

        plot(fitInt(1):fitInt(2),...
             fitModel(fitInt(1):fitInt(2)),...
             'r','LineWidth',2.5);

        title(results(k).name,'Interpreter','none','FontSize',8);

        xlabel('Time');
        ylabel('Signal');

    end

    sgtitle(sprintf('Fits (%d-%d)',firstIdx,lastIdx));

    saveas(gcf, fullfile(outputPath,...
        sprintf('fits_%02d.png',f)));

    close(gcf);

end

%% SHIFT
tmat = nan(max(arrayfun(@(r) length(r.smooth), results)), n);

for i = 1:n
    tmat(1:length(results(i).smooth),i) = (1:length(results(i).smooth));
end

shifts = shift_ref - x_peaks;
tshift = tmat + shifts;

%% PLOT BEFORE/AFTER
figure(1); clf;

subplot(1,2,1); hold on; box on;
for i=1:n
    plot(results(i).t, results(i).smooth,'Color',cm(i,:));
end
title('Before alignment');

subplot(1,2,2); hold on; box on;

normMat = nan(size(tshift));

for i=1:n
    y = results(i).smooth;
    tt = tshift(:,i);

    yy = nan(length(tt),1);
    yy(1:length(y)) = y;

    normMat(:,i) = yy / results(i).y_peak;

    plot(tt,yy,'Color',cm(i,:));
end

title('After alignment');

saveas(gcf, fullfile(outputPath,'alignment.png'));

%% MEAN CURVE
all_t = tshift(:);
t_unique = unique(all_t(~isnan(all_t)));

aligned = nan(length(t_unique),n);

for i=1:n
    [~,loc] = ismember(tshift(:,i), t_unique);
    valid = loc > 0 & ~isnan(loc);
    aligned(loc(valid),i) = normMat(valid,i);
end

m = mean(aligned,2,'omitnan');
s = std(aligned,0,2,'omitnan');

figure; hold on;

plot(t_unique,m,'k','LineWidth',2);

patch([t_unique; flip(t_unique)], ...
      [m-s; flip(m+s)], ...
      'k','FaceAlpha',0.2,'EdgeColor','none');

title('Mean aligned curve');

saveas(gcf, fullfile(outputPath,'mean.png'));

%% SAVE SHIFT TABLE
T = table({results.name}', shifts', ...
    'VariableNames',{'Name','Shift'});

writetable(T, fullfile(outputPath,'shifts.xlsx'));

%% NORMALIZED INDIVIDUAL CURVES + MEAN

figure;
set(gcf,'Position',[300 1500 900 400]);

subplot(1,2,1);
hold on;
box on;

for i = 1:n
    plot(t_unique,...
         aligned(:,i),...
         'Color',cm(i,:),...
         'LineWidth',1.5);
end

title('Individual Curves');
xlabel('Shifted Time');
ylabel('Normalized Signal');

subplot(1,2,2);
hold on;
box on;

plot(t_unique,...
     m,...
     'k',...
     'LineWidth',2);

patch([t_unique; flipud(t_unique)],...
      [m-s; flipud(m+s)],...
      'k',...
      'FaceAlpha',0.2,...
      'EdgeColor','none');

title('Average');
xlabel('Shifted Time');
ylabel('Normalized Signal');

saveas(gcf, fullfile(outputPath,'normalized.png'));
end