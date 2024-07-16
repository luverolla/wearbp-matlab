format long;
rng(42);
perc_train = 0.95;
target = 'SBP';
%%
data = readtable('generated/features_vitaldb_new.csv');
data.DEMG_SEX = strcmp(data.DEMG_SEX, 'F');
cols = string(data.Properties.VariableNames);
fts = cols(6:end);
%%
R = randperm(size(data, 1));
data = data(R, :);
%%
patients = unique(data.INFO_PATIENT);

train_pats = patients(1:floor(perc_train*numel(patients)));
test_pats = setdiff(patients, train_pats);

train_data = data(ismember(data.INFO_PATIENT, train_pats),:);
test_data = data(ismember(data.INFO_PATIENT, test_pats),:);
%%
X_train = train_data{:, fts};
X_test = test_data{:, fts};
y_train = train_data{:, strcat('GT_', target)};
y_test = test_data{:, strcat('GT_', target)};
%%
% scaling parameters
scf_min = min(X_train);
scf_max = max(X_train);

scf_mean = mean(X_train);
scf_std = std(X_train);

scf_sub = scf_mean;
scf_scale = scf_std;
%%
% Scale the features using min-max scaling
X_train_scaled = (X_train - scf_sub) ./ scf_scale;
X_test_scaled = (X_test - scf_sub) ./ scf_scale;
%%
[b,se,pval,finalmodel,stats] = stepwisefit(X_train_scaled, y_train, 'premove',0.0005);

%finalmodel = 1:size(X_train, 2);
rg = size(X_train, 2);
X_train_red = X_train_scaled(:, finalmodel);
X_test_red = X_test_scaled(:, finalmodel);
scf_sub = scf_sub(finalmodel);
scf_scale = scf_scale(finalmodel);
%% Models

hyperopts = struct('MaxObjectiveEvaluations',200, 'UseParallel',true, 'AcquisitionFunctionName','expected-improvement-plus');
%hyperopts = struct('MaxObjectiveEvaluations',100, 'UseParallel',true);

% lasso linear regression
% best lambda for DBP 1.83065536254832e-08
trnd_mod = fitrlinear(X_train_red, y_train, 'OptimizeHyperparameters','all', 'HyperparameterOptimizationOptions',hyperopts);
%trnd_mod = fitrsvm(X_train_red, y_train, 'KernelFunction','polynomial', 'OptimizeHyperparameters','auto');
y_pred = predict(trnd_mod, X_test_red);

% ridge linear regression
% best lambda for DBP 
%trnd_mod = fitrlinear(X_train_red, y_train, 'OptimizeHyperparameters','all', 'HyperparameterOptimizationOptions',hyperopts);

%y_pred = predict(trnd_mod, X_test_red);
%%
%{
X_test_red = (X_test-ModelOffset)./ModelScale;
y_pred = X_test_red*ModelBeta+ModelBias;
%}
%%
abs_er = abs(y_test - y_pred);
rel_er = 100 .* abs((y_test - y_pred)./y_test);

fprintf("R^2 = %.4f\n", r2(y_pred, y_test));

fprintf(...
    "Absolute error: min %.2f | mean %.2f | std %.2f | median %.2f | max %.2f\n", ...
    min(abs_er), mean(abs_er), std(abs_er), median(abs_er), max(abs_er) ...
    );

fprintf(...
    "Relative error: min %.2f%% | mean %.2f%% | std %.2f%% | median %.2f%% | max %.2f%%\n", ...
    min(rel_er), mean(rel_er), std(rel_er), median(rel_er), max(rel_er) ...
    );
%%
fig = figure;
hold on
grid on
plot(y_test, y_test, 'LineWidth',1, 'LineStyle','--', 'Color','red');
scatter(y_test(:,:), y_pred);
xlabel("True values")
ylabel("Predicted values")
title(strcat("Best model for ", target))
fontsize(13, 'points')
%save_graphics(fig, "images/best_sbp")
%%
ModelBeta = zeros(1, rg);
ModelBeta(finalmodel) = trnd_mod.Beta;

ModelBias = trnd_mod.Bias;

ModelOffset = zeros(1, rg);
ModelOffset(finalmodel) = scf_sub;

ModelScale = ones(1, rg);
ModelScale(finalmodel) = scf_scale;

save(sprintf('gendata/model_%s_3.mat', lower(target)),...
    'ModelScale', "ModelOffset", "ModelBias", "ModelBeta"...
);
var2hfile(sprintf('gendata/model_%s_3.h', lower(target)),...
    {ModelScale, ModelOffset, ModelBias, ModelBeta},...
    {sprintf('SVM_%s_SDIF', target), sprintf('SVM_%s_SMIN', target), sprintf('SVM_%s_BIAS', target), sprintf('SVM_%s_BETA', target)}...
);
%%
function r2 = r2(y_pred, y_test)
    % Sum of squared residuals
    SSR = sum((y_pred - y_test).^2);
    % Total sum of squares
    TSS = sum(((y_test - mean(y_test)).^2));
    % R squared
    r2 = 1 - SSR/TSS;
end