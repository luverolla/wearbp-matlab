res_sbp = readtable("res_dbp.csv");
res_sbp = res_sbp(res_sbp.PRED_EMB > 0,:);

figure
hold on
grid on
scatter(res_sbp.TRUTH, res_sbp.PRED_MLB, 'LineWidth',1, 'MarkerEdgeColor','blue');
scatter(res_sbp.TRUTH, res_sbp.PRED_EMB, 'LineWidth',1, 'MarkerEdgeColor','#ed8a09');
plot(35:180, 35:180, 'LineWidth',2, 'Color','#266601');
xlim([35 180])
ylim([35 180])
xlabel('Truth value')
ylabel('Predicted value')
legend('Matlab', 'Embedded')
title("DBP Truth vs Predicted")