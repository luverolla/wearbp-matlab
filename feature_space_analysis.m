data = readtable('generated/features_vitaldb.csv');
cols = data.Properties.VariableNames;
R = randperm(size(data, 1));
data = data(R, :);
%%
gt_class = zeros(height(data),1);
gt_sbp = data.GT_SBP;
gt_dbp = data.GT_DBP;

gt_class(gt_sbp < 120 & gt_dbp < 80) = 1;
gt_class(gt_sbp >= 120 & gt_sbp < 130 & gt_dbp < 80) = 2;
gt_class(gt_class == 0) = 3;

data.GT_CLASS = gt_class;
n_classes = numel(unique(gt_class));
%% generate plots
colors = {'#46c755', '#f59402', '#f54702', '#6E260E'};
f1 = 'DEMG_BMI';
f2 = 'DEMG_BMI';
%%
fig = figure('Position', get(0, 'Screensize'));
hold on;
grid on;

for class = 1:n_classes
    scatter( ...
        data{data.GT_CLASS == class, f1}, ...
        data{data.GT_CLASS == class, f2}, ...
        36, 'MarkerEdgeColor', colors{class}, 'MarkerFaceColor', 'none',...
        'LineWidth',1.5 ...
    );
end

legend('Normal (<120, <80)', 'High (120-140, <80)', 'Hypertension (>=140, >=90)', 'Location', 'northeast');
xlabel(f1, 'Interpreter','none');
ylabel(f2, 'Interpreter','none');
fontsize(13, "points")
hold off;
