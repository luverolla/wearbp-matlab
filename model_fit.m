format long;
rng(42);
perc_train = 0.9;
%%
data = readtable('generated/features_vitaldb_1m.csv');
cols = string(data.Properties.VariableNames);
fts = cols(6:end);
%data = removevars(data, fts(contains(fts, 'DEMG') | contains(fts, 'MIX')) );
for i = 1:length(fts)
    colName = fts{i};
    % Remove outliers from the column
    [cleanedData, TF] = rmoutliers(data.(colName), 'movmean', 2);
    % Replace the original column with the cleaned data
    data(TF,:) = []; % You can choose to replace with NaN or remove rows entirely
end
%%
R = randperm(size(data, 1));
data = data(R, :);
R1 = randperm(size(data, 1));
data = data(R1,:);
%%
patients = unique(data.INFO_PATIENT);

train_pats = patients(1:floor(perc_train*numel(patients)));
test_pats = setdiff(patients, train_pats);

train_data = data(ismember(data.INFO_PATIENT, train_pats),:);
test_data = data(ismember(data.INFO_PATIENT, test_pats),:);
%%
X_train = train_data{:, 6:end};
X_test = test_data{:, 6:end};
y_train = train_data{:, 'GT_DBP'};
y_test = test_data{:, 'GT_DBP'};
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

%X_train_scaled = rmmissing(X_train_scaled);
%X_test_scaled = rmmissing(X_test_scaled);
%%
%[b,se,pval,finalmodel,stats] = stepwisefit(X_train_scaled, y_train, 'premove',0.005);
%[ixs, w] = relieff(X_train_scaled, y_train, 70);

finalmodel = 1:size(X_train, 2);
X_train_red = X_train_scaled(:, finalmodel);
X_test_red = X_test_scaled(:, finalmodel);
%% Models

hyperopts = struct('MaxObjectiveEvaluations',400, 'AcquisitionFunctionName','expected-improvement-plus', 'UseParallel',true);

% lasso linear regression
% best lambda for DBP 1.83065536254832e-08
%trnd_mod = fitrlinear(X_train_red, y_train, 'Learner','leastsquares', 'Regularization','lasso', 'OptimizeHyperparameters','Lambda', 'HyperparameterOptimizationOptions',hyperopts);

% ridge linear regression
% best lambda for DBP 
trnd_mod = fitrlinear(X_train_red, y_train, 'OptimizeHyperparameters','all', 'HyperparameterOptimizationOptions',hyperopts);

y_pred = predict(trnd_mod, X_test_red);

%%
abs_er = abs(y_test - y_pred);
rel_er = 100 .* abs_er ./ y_test;

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
%xlim([80 200])
%ylim([80 200])
scatter(y_test(:,:), y_pred);
xlabel("True values")
ylabel("Predicted values")
title("Best model for DBP")
fontsize(13, 'points')
%save_graphics(fig, "images/best_sbp")
%%
%mdl = discardSupportVectors(trnd_mod);
%Beta = mdl.Beta;
%ScfMin = scf_min;
%ScfMax = scf_max;
%Bias = mdl.Bias;
%save("images/svm_coefs_sbp_new.mat", 'Beta', 'ScfMin', 'ScfMax', 'Bias');
%%
function r2 = r2(y_pred, y_test)
    % Sum of squared residuals
    SSR = sum((y_pred - y_test).^2);
    % Total sum of squares
    TSS = sum(((y_test - mean(y_test)).^2));
    % R squared
    r2 = 1 - SSR/TSS;
end