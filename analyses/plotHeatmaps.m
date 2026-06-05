function plotHeatmaps(summary)

figure;
imagesc(summary.totalCells);
axis image;
title('Cell count');
colorbar;

figure;
imagesc(summary.meanCellArea);
axis image;
title('Mean cell area');
colorbar;

figure;
imagesc(summary.cellDensity);
axis image;
title('Cell density (cells / tissue)');
colorbar;

figure;
imagesc(summary.totalExtrusions);
axis image;
title('Extrusion count');
colorbar;

figure;
imagesc(summary.extrusionDensity);
axis image;
title('Extrusion density (events / tissue)');
colorbar;

end