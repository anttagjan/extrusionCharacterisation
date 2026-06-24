
%%Dessin de chaque Heatmaps
function plotHeatmaps(summary)

figure;
imagesc(summary.totalCells);
axis image;
title('Cell count');
colorbar;

figure;
imagesc(summary.meanArea);
axis image;
title('Mean cell area');
colorbar;

figure;
imagesc(summary.cellDensity);
axis image;
title('Cell density (cells / tissue)');
colorbar;

figure;
imagesc(summary.totalExtr);
axis image;
title('Extrusion count');
colorbar;

%%FIugre pour division
figure;
imagesc(summary.totalDiv);
axis image;
title('Division count');
colorbar;

figure;
imagesc(summary.extrusionRate);
axis image;
title('Extrusion rate (events / tissue)');
colorbar;

% =========================
% MORPHOLOGY FEATURES
% =========================

figure;
imagesc(summary.meanEccentricity);
axis image; set(gca,'YDir','normal');
title('Mean eccentricity'); colorbar; colormap(jet);

% figure;
% imagesc(summary.meanAspectRatio);
% axis image; set(gca,'YDir','normal');
% title('Mean aspect ratio'); colorbar; colormap(jet);

figure;
imagesc(summary.meanOrientation);
axis image; set(gca,'YDir','normal');
title('Mean orientation (degrees)'); colorbar;

colormap(hsv); % better for angles
end