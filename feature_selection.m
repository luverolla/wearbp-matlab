rng(42);

data = readtable('generated/features_new.csv');
data = rmmissing(data);
cols = string(data.Properties.VariableNames);
perc_train = 0.8;
%%
chks = split(data.INFO_RECORD, '-');
data.INFO_PATIENT = chks(:, 1);
%%
R = randperm(size(data, 1));
data = data(R, :);
%%
patients = unique(data.INFO_PATIENT);
train_pats = patients(1:floor(perc_train*numel(patients)));
test_pats = setdiff(patients, train_pats);

train_data = data(ismember(data.INFO_PATIENT, train_pats),:);
test_data = data(ismember(data.INFO_PATIENT, test_pats),:);

train_mat = train_data{:, 3:end-1};
test_mat = test_data{:, 3:end-1};

train_mat = train_mat(all(~isnan(train_mat) & ~isinf(train_mat), 2),:);
test_mat = test_mat(all(~isnan(test_mat) & ~isinf(test_mat), 2),:);
%%
X_train = train_mat(:, 3:end);
X_test = test_mat(:, 3:end);
y_train = train_mat(:, 2);
y_test = test_mat(:, 2);
%%
% scaling parameters
scf_min = min(X_train);
scf_max = max(X_train);
%%
% Scale the features using min-max scaling
X_train_scaled = (X_train - scf_min) ./ (scf_max - scf_min);
X_test_scaled = (X_test - scf_min) ./ (scf_max - scf_min);
%% Relieff algorithm
[ft_idx, ft_weights] = relieff(X_train_scaled, y_train, 10);
%%
fprintf("=== Relieff ranks ===\n")
for idx=ft_idx
    fprintf("%s: %.6f\n", cols{4+idx}, ft_weights(idx));
end
%% select features over 3rd quartile
q3 = prctile(ft_weights, 75);
fprintf("=== Relieff selected DBP ===\n")
ft_sel = {};
for idx=ft_idx
    if ft_weights(idx) > q3
        ft_sel = [ft_sel cols{4+idx}];
        fprintf("%s: %.6f\n", cols{4+idx}, ft_weights(idx));
    end
end