%% plot probabilities 
clf
pc_neg_stoch_ttc_exp2 = get_data(3, 1, 2, 0.2, 1, 80, 6);
pc_neg_stoch_ttc_inv30 = get_data(3, 1, 3, [3 3.5], 1, 80, 6);

load 'pc_ea_2mill_r_0_3.mat'
p_true = pc_nea;
plot(pc_neg_stoch_ttc_inv30(:,1)/p_true,'.')

hold on
plot(ones(1,500)*0.1)
plot(ones(1,500)*1.9)
%% analysing mean value
pc_stochttc = get_data(3, 1, 1, [], 1, 80, 6);
pc_ttc =       get_data(3, 3, 1, [], 1, 80, 6);
pc_stoch_ttc_exp = get_data(3, 1, 2, 0.1, 1, 80, 6);

ci_stoch_ttc = compute_ci_meanest(pc_stochttc, 500);
ci_ttc = compute_ci_meanest(pc_ttc, 500)
ci_stoch_ttc_exp = compute_ci_meanest(pc_stoch_ttc_exp, 500);



load 'pc_nea_2mill_r_0_3.mat'
p_true = pc_nea;

clf
a = plot(mean(pc_stochttc), 'color' ,[0 .0 1]);
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
pc_stochttc = get_data(3, 1, 3, [3 3.5], 1, 80, 6);
load 'pc_ea_2mill_r_0_3.mat'
p_true = pc_nea;

rmse2 = sqrt(sum((pc_stochttc-p_true).^2)/500);

clf
plot(rmse2)
title('root-mean-square-error')
xlabel('threshold number')
%%
load 'pc_nea_2mill_r_0_3.mat'
p_true = pc_nea;

sev_measure = cell(3,1);
sev_measure{1} = 'stoch. TTC';
sev_measure{2} = 'TTC';
sev_measure{3} = 'min. dist.';

trans_string = cell(3,1);
trans_string{1} = [];
trans_string{2} = 'exponential';
trans_string{3} = 'inverse';

cut_off = .5;
data_type = 1;
sev_meas = 1;
tran = 2;

clf
a = plot_acc_w_ci(6, 1, [], p_true, cut_off, 'r', data_markers{1});
b = plot_acc_w_ci(1, 1, [], p_true, cut_off, 'b', data_markers{2});
b = plot_acc_w_ci(3, 1, [], p_true, cut_off, 'g', data_markers{3});
title('estimate of p(coll, NEA) for different severity measures')

%% comparing accuracy plots
load 'pc_nea_2mill_r_0_3.mat'
p_true = pc_nea;

sev_measure = cell(3,1);
sev_measure{1} = 'stoch. TTC';
sev_measure{2} = 'TTC';
sev_measure{3} = 'min. dist.';

trans_string = cell(3,1);
trans_string{1} = [];
trans_string{2} = 'exponential';
trans_string{3} = 'inverse';

cut_off = .5;
data_type = 1;
sev_meas = 1;
tran = 2;
par_range = [.1 .15 .2 .25 .3 .4 .5];
%par_range = [.02 .04 .06 .1 .2 .3 .4 ];
%par_range = [1 1.5 2 2.5 3 3.5 4 4.5];
n_ex = length(par_range);
data_markers = cell(1,n_ex);
data_markers{1} = 'o';
data_markers{2} = '*';
data_markers{3} = '+';
data_markers{4} = 'x';
data_markers{5} = 'p';
data_markers{6} = 'd';
data_markers{7} = 's';
data_markers{8} = 'h';
data_markers{9} = '^';
data_markers{9} = 'v';


pc_stochttc_exp = cell(1,n_ex);
accuracy_stoch_ttc_exp = cell(1,n_ex);
ci_stoch_ttc_exp = cell(1,n_ex);
legend_labels = cell(n_ex, 1);
color_spec = linspace(0,1,n_ex);
plot_vec = zeros(1, n_ex);

clf
hold on
for i=1:n_ex
    
    pc_stochttc_exp{i} = get_data(3, data_type, tran, par_range(i), 1, 80, 6);
    accuracy_stoch_ttc_exp{i} = accuracy_rate(pc_stochttc_exp{i}, p_true, cut_off);
    ci_stoch_ttc_exp{i} = compute_ci_pest(accuracy_stoch_ttc_exp{i},500);


    plot_vec(i)=plot(100*accuracy_stoch_ttc_exp{i}, data_markers{i},'color', [0 color_spec(i) 1]);
    plot(100*accuracy_stoch_ttc_exp{i},'color', [0 color_spec(i) 1]);
    plot(100*ci_stoch_ttc_exp{i},':','color',[0 color_spec(i) 1])

    legend_labels{i,1} = sprintf('%s, p = %s',sev_measure{sev_meas}, num2str(par_range(i)));
end

a = plot_acc_w_ci(6, 1, [], p_true, cut_off, 'r', data_markers{8});
%plot_acc_w_ci(data_type, transform, trans_par, p_true, cut_off, color, data_mark)
%b = plot_acc_w_ci(3, 1, [], p_true, cut_off, 'r', data_markers{9});
%c = plot_acc_w_ci(1, 3, [4.5 3.5], p_true, cut_off, 'r', data_markers{9});


legend_labels{end + 1} = sev_measure{3};
% labels{9} = 'ttc';

title(sprintf('accuracy plots for %s, %s transform, cut-off = 0.%d',sev_measure{sev_meas},trans_string{tran} , cut_off*10))
xlabel('threshold index')
legend([plot_vec a], legend_labels)%labels)
%% accuracy inv transform
%
load 'pc_nea_2mill_r_0_3.mat'
p_true = pc_nea;
sev_measure = cell(3,1);
sev_measure{1} = 'stoch. TTC';
sev_measure{2} = 'TTC';
sev_measure{3} = 'min. dist.';

trans_string = cell(3,1);
trans_string{1} = [];
trans_string{2} = 'exponential';
trans_string{3} = 'inverse';

sev_meas = 3;
cut_off = .8;
data_type = 6;
par_range = [.1 .2 .3 .4 .5 .6 .8 1 1.5 2];
par_range = [1 1.5 2 2.5 3 3.5 4 4.5];
n_ex = length(par_range);
data_markers = cell(1,n_ex);
data_markers{1} = 'o';
data_markers{2} = '*';
data_markers{3} = '+';
data_markers{4} = 'x';
data_markers{5} = 'p';
data_markers{6} = 'd';
data_markers{7} = 's';
data_markers{8} = 'h';
data_markers{9} = '^';
data_markers{10} = 'v';


pc_stochttc_exp = cell(1,n_ex);
accuracy_stoch_ttc_exp = cell(1,n_ex);
ci_stoch_ttc_exp = cell(1,n_ex);
legend_labels = cell(n_ex, 1);
color_spec = linspace(0,1,n_ex);
plot_vec = zeros(1, n_ex);

clf
hold on
for i=1:n_ex

    pc_stochttc_exp{i} = get_data(3, data_type, 3, [par_range(i),3.5], 1, 80, 6);
    accuracy_stoch_ttc_exp{i} = accuracy_rate(pc_stochttc_exp{i}, p_true, cut_off);
    ci_stoch_ttc_exp{i} = compute_ci_pest(accuracy_stoch_ttc_exp{i},500);


    plot_vec(i)=plot(100*accuracy_stoch_ttc_exp{i}, data_markers{i},'color', [0 color_spec(i) 1]);
    plot(100*accuracy_stoch_ttc_exp{i},'color', [0 color_spec(i) 1]);
    plot(100*ci_stoch_ttc_exp{i},':','color',[0 color_spec(i) 1])

    legend_labels{i,1} = sprintf('%s, p = %s',sev_measure{sev_meas}, num2str(par_range(i)));
end

a = plot_acc_w_ci(6, 1, [], p_true, cut_off, 'r', data_markers{end-1});



legend_labels{n_ex+1} = 'min dist';


title(sprintf('accuracy plots for %s, inverse transform, cut-off = %s', sev_measure{sev_meas}, num2str(cut_off)) );

legend([plot_vec a], legend_labels)

%% comparison of peak performance between exponential and inverse transform
load 'pc_nea_2mill_r_0_3.mat'
p_true = pc_nea;

cut_off = .5;
clf
%plot_acc_w_ci(data_type, transform, trans_par, p_true, cut_off, color, data_mark)
hold on
a = plot_acc_w_ci(1, 2, 0.25, p_true, cut_off, 'r', 's');
b = plot_acc_w_ci(1, 3, [4 3.5], p_true, cut_off, 'b', 's');
legend([a b], 'stoch. ttc, inv. trans., p = 4.0', 'stoch. ttc, exp, p = 0.25)')
title('comparison between best performing transformations')

%% analysing mean value of inverse transform

load 'pc_nea_2mill_r_0_3.mat'
p_true = pc_nea;

par_range = [1 1.5 2 2.5 3 3.5 4 4.5];
n_ex = length(par_range);
data_markers = cell(1,n_ex);
data_markers{1} = 'o';
data_markers{2} = '*';
data_markers{3} = '+';
data_markers{4} = 'x';
data_markers{5} = 'p';
data_markers{6} = 'd';
data_markers{7} = 's';
data_markers{8} = 'h';
data_markers{9} = '^';
data_markers{9} = 'v';

pc_stochttc_exp = cell(1,n_ex);
ci_stoch_ttc_exp = cell(1,n_ex);
legend_labels = cell(n_ex, 1);
color_spec = linspace(0,1,n_ex);
plot_vec = zeros(1, n_ex);

clf
hold on
for i=1:n_ex

    pc_stochttc_exp{i} = get_data(3, 1, 3, [par_range(i),3.5], 1, 80, 6);
    accuracy_stoch_ttc_exp{i} = mean(pc_stochttc_exp{i});
    ci_stoch_ttc_exp{i} = compute_ci_meanest(pc_stochttc_exp{i},500);


    plot_vec(i)=plot(accuracy_stoch_ttc_exp{i}, data_markers{i},'color', [0 color_spec(i) 1]);
    plot(accuracy_stoch_ttc_exp{i},'color', [0 color_spec(i) 1]);
    plot(ci_stoch_ttc_exp{i},':','color',[0 color_spec(i) 1])

    legend_labels{i,1} = sprintf('stoch ttc, %d.%d',floor(par_range(i)), decpart(par_range(i)));
end
a = plot(ones(1,10)*p_true,'r');

legend_labels{n_ex+1} = 'pc_{nea} true';

title('Expected value for inverse transform')

legend([plot_vec a], legend_labels)

%% analysing mean value of exp transform




load 'pc_nea_2mill_r_0_3.mat'
p_true = pc_nea;

par_range = [.1 .15 .2 .25 .3 .4 .5];
n_ex = length(par_range);
data_markers = cell(1,n_ex);
data_markers{1} = 'o';
data_markers{2} = '*';
data_markers{3} = '+';
data_markers{4} = 'x';
data_markers{5} = 'p';
data_markers{6} = 'd';
data_markers{7} = 's';
data_markers{8} = 'h';
data_markers{9} = '^';
data_markers{9} = 'v';

pc_stochttc_exp = cell(1,n_ex);
ci_stoch_ttc_exp = cell(1,n_ex);
legend_labels = cell(n_ex, 1);
color_spec = linspace(0,1,n_ex);
plot_vec = zeros(1, n_ex);

clf
hold on
for i=1:n_ex

    pc_stochttc_exp{i} = get_data(3, 1, 2, par_range(i), 1, 80, 6);
    accuracy_stoch_ttc_exp{i} = mean(pc_stochttc_exp{i});
    ci_stoch_ttc_exp{i} = compute_ci_meanest(pc_stochttc_exp{i},500);


    plot_vec(i)=plot(accuracy_stoch_ttc_exp{i}, data_markers{i},'color', [0 color_spec(i) 1]);
    plot(accuracy_stoch_ttc_exp{i},'color', [0 color_spec(i) 1]);
    plot(ci_stoch_ttc_exp{i},':','color',[0 color_spec(i) 1])

    legend_labels{i,1} = sprintf('stoch ttc, p = %d.%d',floor(par_range(i)), decpart(par_range(i)));
end
ylim([0 2e-3])
a = plot(ones(1,10)*p_true,'r');

legend_labels{n_ex+1} = 'pc_{nea} true';

title('Expected value for exponential transform')

legend([plot_vec a], legend_labels)
% we can see that there is clearly increase in bias as trans-par increases.
% specifically, the tendency to overestimate increases. In order to
% compensate for this increased bias, we have to use higher thresholds.


