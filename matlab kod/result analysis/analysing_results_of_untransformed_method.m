%% analysing mean value
pc_stoch_ttc = get_data(3, 1, 1, [], 1, 80, 6);
pc_ttc =       get_data(3, 3, 1, [], 1, 80, 6);
pc_stoch_ttc_exp = get_data(3, 1, 2, 0.1, 1, 80, 6);

ci_stoch_ttc = compute_ci_meanest(pc_stoch_ttc, 500);
ci_ttc = compute_ci_meanest(pc_ttc, 500)
ci_stoch_ttc_exp = compute_ci_meanest(pc_stoch_ttc_exp, 500);



load 'pc_ea_2mill_r_0_3.mat'
p_true = pc_nea;

clf
a = plot(mean(pc_stoch_ttc), 'color' ,[0 .0 1]);
hold on
plot(ci_stoch_ttc,'LineStyle', ':', 'color' ,[0 .0 1])

b = plot(mean(pc_ttc), 'color' ,'red');
plot(ci_ttc,'LineStyle', ':', 'color' ,'red')

a = plot(mean(pc_stoch_ttc_exp), 'color' ,[0 .0 1]);
hold on
plot(ci_stoch_ttc_exp,'LineStyle', ':', 'color' ,[0 .0 1])

line([0,10], [p_true,p_true],'color','r')
title('mean value for different transformation parameters')
xlabel('threshold number')

%% analysing Mean-Square-Error
pc2 = get_data(3, 1, 1, [], 1, 80, 6);
load 'pc_ea_2mill_r_0_3.mat'
p_true = pc_nea;

rmse2 = sqrt(sum((pc2-p_true).^2)/500);

clf
plot(rmse2)
title('root-mean-square-error')
xlabel('threshold number')
%%
load 'pc_ea_2mill_r_0_3.mat'
p_true = pc_nea;

cut_off = .99;

pc_neg_stoch_ttc =      get_data(3, 1, 1, [], 1, 80, 6);
pc_neg_stoch_ttc_exp1 = get_data(3, 1, 2, 0.1, 1, 80, 6);
pc_neg_stoch_ttc_exp2 = get_data(3, 1, 2, 0.2, 1, 80, 6);
pc_neg_stoch_ttc_exp3 = get_data(3, 1, 2, 0.3, 1, 80, 6);
pc_neg_stoch_ttc_exp4 = get_data(3, 1, 2, 0.4, 1, 80, 6);
pc_neg_stoch_ttc_exp5 = get_data(3, 1, 2, 0.5, 1, 80, 6);
pc_neg_stoch_ttc_inv1 = get_data(3, 1, 3, [1, 3.5], 1, 80, 6);
pc_neg_ttc = get_data(3, 3, 1, [], 1, 80, 6);

accuracy_neg_stoch_ttc = accuracy_rate(pc_neg_stoch_ttc, p_true, cut_off);
accuracy_neg_stoch_ttc_exp1 = accuracy_rate(pc_neg_stoch_ttc_exp1, p_true, cut_off);
accuracy_neg_stoch_ttc_exp2 = accuracy_rate(pc_neg_stoch_ttc_exp2, p_true, cut_off);
accuracy_neg_stoch_ttc_exp3 = accuracy_rate(pc_neg_stoch_ttc_exp3, p_true, cut_off);
accuracy_neg_stoch_ttc_exp4 = accuracy_rate(pc_neg_stoch_ttc_exp4, p_true, cut_off);
accuracy_neg_stoch_ttc_exp5 = accuracy_rate(pc_neg_stoch_ttc_exp5, p_true, cut_off);
accuracy_neg_ttc = accuracy_rate(pc_neg_ttc, p_true, cut_off);


ci_neg_stoch_ttc = compute_ci_pest(accuracy_neg_stoch_ttc,500);
ci_neg_stoch_ttc_exp1 = compute_ci_pest(accuracy_neg_stoch_ttc_exp1,500);
ci_neg_stoch_ttc_exp2 = compute_ci_pest(accuracy_neg_stoch_ttc_exp2,500);
ci_neg_stoch_ttc_exp3 = compute_ci_pest(accuracy_neg_stoch_ttc_exp3,500);
ci_neg_stoch_ttc_exp4 = compute_ci_pest(accuracy_neg_stoch_ttc_exp4,500);
ci_neg_stoch_ttc_exp5 = compute_ci_pest(accuracy_neg_stoch_ttc_exp5,500);
ci_neg_ttc = compute_ci_pest(accuracy_neg_ttc,500);



clf
a=plot(100*accuracy_neg_stoch_ttc,'color', 'blue');
hold on
plot(100*ci_neg_stoch_ttc,':','color','black')

b=plot(100*accuracy_neg_ttc,'color', 'red');
plot(100*ci_neg_ttc,':','color','red')

c=plot(100*accuracy_neg_stoch_ttc_exp1,'o','color', [0 0 1]);
plot(100*accuracy_neg_stoch_ttc_exp1,'color', [0 0 1]);
plot(100*ci_neg_stoch_ttc_exp1,':','color',[0 0 1])

d=plot(100*accuracy_neg_stoch_ttc_exp2,'*','color',[0 .25 1]);
plot(100*accuracy_neg_stoch_ttc_exp2,'color',[0 .25 1]);
plot(100*ci_neg_stoch_ttc_exp2,':','color',[0 .25 1])

e=plot(100*accuracy_neg_stoch_ttc_exp3,'+','color', [0 .5 1]);
plot(100*accuracy_neg_stoch_ttc_exp3,'color', [0 .5 1])
plot(100*ci_neg_stoch_ttc_exp3,':','color',[0 .5 1])

f=plot(100*accuracy_neg_stoch_ttc_exp4,'x','color', [0 .75 1]);
plot(100*accuracy_neg_stoch_ttc_exp4,'color', [0 .75 1])
plot(100*ci_neg_stoch_ttc_exp4,':','color',[0 .75 1])

g=plot(100*accuracy_neg_stoch_ttc_exp5,'s','color', [0 1 1]);
plot(100*accuracy_neg_stoch_ttc_exp5,'color', [0 1 1])
plot(100*ci_neg_stoch_ttc_exp5,':','color',[0 1 1])

title('accuracy plots')
legend([a b c d e f g],'stoch. ttc', 'det. ttc','trans. stoch. ttc, 0.1','trans. stoch. ttc, 0.2','trans. stoch. ttc, 0.3','trans. stoch. ttc, 0.4','trans. stoch. ttc, 0.5')



