%% Feature space analysis
% This script draws a scatter plot with a pair of features, and colours
% the sample points based on their BP values, partitioning them in ranges
%% Load data
data = readtable('generated/features_vitaldb.csv');
cols = data.Properties.VariableNames;
R = randperm(size(data, 1));
data = data(R, :);
%% Partition in ranges
gt_class = zeros(height(data),1);
gt_sbp = data.GT_SBP;
gt_dbp = data.GT_DBP;

gt_class(gt_sbp < 120 & gt_dbp < 80) = 1;
gt_class(gt_sbp >= 120 & gt_sbp < 130 & gt_dbp < 80) = 2;
gt_class(gt_class == 0) = 3;

data.GT_CLASS = gt_class;
n_classes = numel(unique(gt_class));
%% Set features to show
f1 = 'DEMG_BMI';
f2 = 'DEMG_BMI';
%% Draw scatter plot
colors = {'#46c755', '#f59402', '#f54702', '#6E260E'};
fig = figure('Position', get(0, 'Screensize'));
hold on;
grid on;

for class = 1:n_classes
    scatter( ...
        data{data.GT_CLASS == class, f1}, ...
        data{data.GT_CLASS == class, f2}, ...
        36, 'MarkerEdgeColor', colors{class}, ...
        'MarkerFaceColor', 'none',...
        'LineWidth',1.5 ...
    );
end

legend( ...
    'Normal (<120, <80)', ...
    'High (120-140, <80)', ...
    'Hypertension (>=140, >=90)', ...
    ...
    'Location', 'northeast' ...
);
xlabel(f1, 'Interpreter','none');
ylabel(f2, 'Interpreter','none');
fontsize(13, "points")
hold off;
