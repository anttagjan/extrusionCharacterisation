
%%Dessin de chaque Heatmaps
function plotHeatmaps(summary, sex_icon, filepath)

fprintf("Making features...")

global f_summary
saveFolder = fullfile(filepath,'figures_program');

if ~exist(saveFolder,'dir') %Si le dossier existe pas, le créer
    mkdir(saveFolder)
    fprintf("Création par plotHeatmaps")
end


% Dessin différence entre Males et femelles
if sex_icon == 'F'
    f_summary = summary;
else
    if ~isempty(f_summary)
        name = fieldnames(f_summary);

        for i = 1:length(name) % calcul une différence entre M et F
            one_name = name{i};
            diff.(one_name) = f_summary.(one_name) - summary.(one_name); %Add abs() ? %Rajoute données par données, à f_summary
        end
        averageMF(:,:,1) = summary.cellAverage;
        averageMF(:,:,2) = f_summary.cellAverage; %Création matrice en 3D
        meanMF = mean(averageMF,3); %Moyenne entre M et F
        coefVarMF = (std(averageMF,0,3)) ./ meanMF;
        

        %diff = abs(f_summary - summary); 
        figure;
        imagesc(diff.totalCells);
        axis image;
        title('difference Total Cell between F - M ');
        colorbar;
        exportgraphics(gcf, fullfile(saveFolder, 'difference_totalCell_MF.png')) %Export de la derniere figure (gcf)

        % Add all figure if you want with "diff.(name of what do you want to see)"


        figure;
        imagesc(coefVarMF);
        axis image;
        title('Coef Var between M et F');
        colorbar;
        exportgraphics(gcf, fullfile(saveFolder, 'coefVar_MF.png')) %Export de la derniere figure (gcf)
        
    end
end


figure;
imagesc(summary.coefVar);
axis image;
title(['coef variability ' sex_icon]);
colorbar;

exportgraphics(gcf, fullfile(saveFolder, ['coef_variability_' sex_icon '.png'])) %Export de la derniere figure (gcf)


figure;
imagesc(summary.totalCells);
axis image;
title(['Cell count ' sex_icon]);
colorbar;

exportgraphics(gcf, fullfile(saveFolder, ['CellCount_' sex_icon '.png'])) %Export de la derniere figure (gcf)


figure;
imagesc(summary.meanArea);
axis image;
title(['Mean cell area' sex_icon]);
colorbar;


exportgraphics(gcf, fullfile(saveFolder, ['Mean cell area_' sex_icon '.png'])) %Export de la derniere figure (gcf)


figure;
imagesc(summary.cellDensity);
axis image;
title(['Cell density (cells divide by tissue)_' sex_icon]);
colorbar;


exportgraphics(gcf, fullfile(saveFolder, ['Cell density (cells divide by tissue)_' sex_icon '.png'])) %Export de la derniere figure (gcf)


figure;
imagesc(summary.totalExtr);
axis image;
title(['Extrusion count_' sex_icon]);
colorbar;


exportgraphics(gcf, fullfile(saveFolder, ['Extrusion count_' sex_icon '.png'])) %Export de la derniere figure (gcf)


%%FIugre pour division
figure;
imagesc(summary.totalDiv);
axis image;
title(['Division count_' sex_icon]);
colorbar;


exportgraphics(gcf, fullfile(saveFolder, ['Division count_' sex_icon '.png'])) %Export de la derniere figure (gcf)


figure;
imagesc(summary.extrusionRate);
axis image;
title(['Extrusion rate (events divide by tissue)_' sex_icon]);
colorbar;

exportgraphics(gcf, fullfile(saveFolder, ['Extrusion rate (events divide by tissue)_' sex_icon '.png'])) %Export de la derniere figure (gcf)



% =========================
% MORPHOLOGY FEATURES
% =========================

figure;
imagesc(summary.meanEccentricity);
axis image; set(gca,'YDir','normal');
title(['Mean eccentricity_' sex_icon]); colorbar; colormap(jet);


exportgraphics(gcf, fullfile(saveFolder, ['Mean eccentricity_' sex_icon '.png'])) %Export de la derniere figure (gcf)


% figure;
% imagesc(summary.meanAspectRatio);
% axis image; set(gca,'YDir','normal');
% title('Mean aspect ratio'); colorbar; colormap(jet);

figure;
imagesc(summary.meanOrientation);
axis image; set(gca,'YDir','normal');
title(['Mean orientation (degrees)_' sex_icon]); colorbar;
colormap(hsv); % better for angles

exportgraphics(gcf, fullfile(saveFolder, ['Mean orientation (degrees)_' sex_icon '.png'])) %Export de la derniere figure (gcf)



end