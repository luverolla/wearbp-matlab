function [] = save_graphics(fig, path)
%SAVE_GRAPHICS Summary of this function goes here
%   Detailed explanation goes here
set(fig,'PaperOrientation','landscape');
set(fig,'PaperUnits','normalized');
set(fig,'PaperPosition', [0 0 1 1]);
set(gca,'LooseInset',get(gca,'TightInset'));

% PDF, for LaTeX
print(fig, "-dpdf", "-vector", path);
% SVG for PowerPoint
print(fig, "-dsvg", "-vector", path);
end

