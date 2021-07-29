function [] = XR_psf_analysis_plot(frameFullname, figureFullname, RW_info_Fullname, ch_ind, source_descrip, xypixsize, zpixsize, NAdet, index, exc_lambda, det_lambda, PSFsubpix, gamma)
% perform psf analysis and plot the figures
% 
% Author: Xiongtao Ruan (07/28/2021)


if exist(figureFullname, 'file')
    return;
end

a = load(RW_info_Fullname);
RW_info = a.RW_info;
xz_exp_PSF_RW = RW_info{ch_ind}{1};
xz_exp_OTF_RW = RW_info{ch_ind}{2};
xOTF_linecut_RW = RW_info{ch_ind}{3};
zOTF_linecut_RW = RW_info{ch_ind}{4};
zOTF_bowtie_linecut_RW = RW_info{ch_ind}{5};

% psf analysis for data
[xz_exp_PSF, xz_exp_OTF, xOTF_linecut, zOTF_linecut, zOTF_bowtie_linecut] = ...
    Load_and_Plot_Exp_Overall_xzPSF_xzOTF_update(frameFullname, source_descrip, ...
    xypixsize, zpixsize, NAdet, index, exc_lambda, det_lambda, PSFsubpix, gamma);

% plot line cut with RW line cuts as reference
f0 = gcf();
[~, fsname] = fileparts(frameFullname);
result_dir = fileparts(figureFullname);
print(f0, '-painters','-dpng', '-loose',[result_dir filesep 'comp_' fsname '.png']);
close all

figure('Renderer', 'painters', 'Position', [10 10 600 600]);
% figure;
A = size(xz_exp_OTF);
D = size(zOTF_linecut);
plot(log10(zOTF_linecut), 'r', 'LineWidth', 2);hold on
plot(log10(xOTF_linecut), 'b', 'LineWidth', 2);
plot(log10(zOTF_bowtie_linecut), 'g', 'LineWidth', 2);
axis([1 D(2) -3 0]);
axis square;
grid on;
set(gca, 'XTick', [1:(D(2)-1)./10:D(2)]);
set(gca, 'XTickLabel', [-1:0.2:1]);
xlabel(['k / (4\pi/\lambda)'], 'FontSize', 14);
set(gca, 'YTick', [-3:1:0]);
set(gca, 'YTickLabel', 10.^[-3:1:0]);
ylabel(['OTF Strength'], 'FontSize', 14);
% text(-0.1 .*A(2), 0.15, ['Overall OTF linecuts From ', source_descrip], 'FontSize', 14);
text(0.6.*A(2), -0.15, 'OTF along ky', 'Color', [0 0 1], 'FontSize', 14);
text(0.6.*A(2), -0.3, 'OTF along kz', 'Color', [1 0 0], 'FontSize', 14);
text(0.6.*A(2), -0.45, 'Bowtie OTF along kz', 'Color', [0 0.75 0], 'FontSize', 14);

hold on

D = size(zOTF_linecut_RW);
plot(log10(zOTF_linecut_RW), '--r', 'LineWidth', 2);hold on
plot(log10(xOTF_linecut_RW), '--b', 'LineWidth', 2);
plot(log10(zOTF_bowtie_linecut_RW), '--g', 'LineWidth', 2);
axis([1 D(2) -3 0]);
axis square;
grid on;
set(gca, 'XTick', [1:(D(2)-1)./10:D(2)]);
set(gca, 'XTickLabel', [-1:0.2:1]);
xlabel(['k / (4\pi/\lambda)'], 'FontSize', 14);
set(gca, 'YTick', [-3:1:0]);
set(gca, 'YTickLabel', 10.^[-3:1:0]);
ylabel(['OTF Strength'], 'FontSize', 14);
title( ['Overall OTF linecuts From ', source_descrip], 'FontSize', 14);
legend([{'OTF along kz','OTF along ky','Bowtie OTF along kz', 'RW OTF along kz',  'RW OTF along ky', 'RW Bowtie OTF along kz'}]);

f0 = gcf();
print(f0, '-painters','-dpng', '-loose', figureFullname);

end

