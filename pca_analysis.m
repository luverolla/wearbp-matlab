rng(42);

data = readtable('generated/features_new.csv');
data = rmmissing(data);
cols = string(data.Properties.VariableNames);
feats = cols(5:end);
perc_train = 0.8;
%%
gt_class = zeros(height(data),1);
gt_sbp = data.GT_SBP;
gt_dbp = data.GT_DBP;

gt_class(gt_sbp < 130 & gt_dbp < 80) = 1;
gt_class((gt_sbp >= 130 & gt_sbp < 140) | (gt_dbp >= 80 & gt_dbp < 90)) = 2;
gt_class(gt_sbp >= 140 | gt_dbp >= 90) = 3;

data.GT_CLASS = gt_class;
n_classes = numel(unique(gt_class));
%%
class_names = {'normal (<130,<80)', 'hypertension1 (130-140,80-90)', 'hypertension2 (>140,>90)'};
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

train_mat = train_data{:, 4:end-1};
test_mat = test_data{:, 4:end-1};

train_mat = train_mat(all(~isnan(train_mat) & ~isinf(train_mat), 2),:);
test_mat = test_mat(all(~isnan(test_mat) & ~isinf(test_mat), 2),:);
%%
X_train = train_mat(:, 2:end-1);
X_test = test_mat(:, 2:end-1);
y_train = train_mat(:, 2);
y_test = test_mat(:, 2);
y_train_class = train_mat(:, end);
y_test_class = test_mat(:, end);
%%
% scaling parameters
scf_mean = mean(X_train);
scf_std = std(X_train);
%%
% Scale the features using min-max scaling
X_train_scaled = (X_train - scf_mean) ./ scf_std;
X_test_scaled = (X_test - scf_mean) ./ scf_std;
%% PCA
[coeff,score,latent,tsquared,explained,mu] = pca(X_train_scaled);
colors = {'#46c755', '#f59402', '#f54702'};

cumulative_explained = cumsum(explained);

% Plot the elbow graph
figure;
plot(1:length(cumulative_explained), cumulative_explained, '-o', 'LineWidth', 2);
xlabel('Number of Principal Components');
ylabel('Cumulative Explained Variance (%)');
title('Elbow Graph for PCA - DBP');
grid on;

% Optionally, highlight the elbow point
% You can choose a threshold to find the elbow point if necessary
threshold = 95; % Example threshold for 95% variance
elbow_point = find(cumulative_explained >= threshold, 1);
hold on;
plot(elbow_point, cumulative_explained(elbow_point), 'ro', 'MarkerSize', 10, 'LineWidth', 2);
hold off;

legend('Cumulative Explained Variance', strcat('95% exp.var. (', string(elbow_point), ' components)'));
fontsize(13, 'points');
set(gca,'LooseInset',get(gca,'TightInset'));
saveas(gcf,'images/pca-elbow-dbp.svg');

figure
hold on
for class = 1:n_classes
    scatter( ...
        score(y_train_class == class, 1), ...
        score(y_train_class == class, 2), ...
        36, 'MarkerEdgeColor', colors{class}, 'MarkerFaceColor', ...
        'none'...
    );
end
axis equal
xlabel('1st Principal Component')
ylabel('2nd Principal Component')
legend(class_names)
title("1st vs 3rd principal component")
fontsize(13, 'points');
hold off
%%
num_components = find(cumulative_explained >= threshold, 1);
selected_coeff = coeff(:, 1:num_components);
transformed_data = score(:, 1:num_components);
%%
tot_feats = {};
for i = 1:3
    % Get the coefficients for the i-th principal component
    componentLoadings = coeff(:, i);

    % Get the absolute values of the loadings
    absLoadings = abs(componentLoadings);

    % Sort the loadings in descending order
    [sortedLoadings, sortedIdx] = sort(absLoadings, 'descend');

    % 3rd quartile of loadings
    q3 = prctile(sortedLoadings, 75);

    sel_idx = [];

    % selection
    for k=1:numel(sortedIdx)
        if sortedLoadings(k) >= q3
            sel_idx = [sel_idx sortedIdx(k)];
        end
    end

    tot_feats = [tot_feats feats{sel_idx}];
end

disp(unique(tot_feats));