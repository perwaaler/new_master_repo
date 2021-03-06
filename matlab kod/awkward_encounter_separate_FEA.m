% simulation of encounters between two vehicles.

n = 1;                                 % number of encounter-samples desired
N = 500;                               % number of encounters
all_data = cell(n, 12);                % collects data from each encounter-sample
r = 0.3;                               % collision radius of each person
NTTC = 30;                              % Number of TTC to sample at first evasive action for each encounter
est_ttc = 1;                             % tells the algorithm whether or not you want to estimate ttc distribution for each encounter
compute_X = 0;
plot_enc = 1;                            % set to one if plots of encounters are wanted
plot_pred_path =0;                      % enable to simulate each predicted path
disable_crash = 0;                       % disable collision and EA mode to record free movement patterns
pause_length = 2^-10;
use_history = 0;
use_dp_model = 0;                        % set to 1 if you want to use estimated reaction model

for kk = 1:n
kk %#ok<NOPTS>
% parameters for distribution of stepsize. EX = a*b, VX = a*b^2
step_par = [0.30*2 0.2/2];

% parameters for the gamma distribution for the INITIAL steps
step_mean_init = 0.16;
step_var_init = 0.0015;
theta_var_init = 0.015;                      % variance of initial theta

% gamma parametes for initial step as fcn of mean and variance
a_init = step_mean_init^2/step_var_init;
b_init = step_var_init/step_mean_init;
xinit = 6;                                  % determines how far apart they are at the start
sigma_var0 = 0.3;                           % variance of initial starting position


% variance of the step-size and step-angle
var_step0 = 0.001;
var_theta0 = 0.03;                           % determins the amount of random variability of the step-angle at each iteration.

% EA behaviour modification parameters
thetamod_k = 0.4;              % determines how quickly the person can change direction after detecting the other driver.
thetamod_s = 1.6;              % makes modification of behaviour more dramatic for very small ydiff, but less dramatic for large ydiff
thetamod_p = 3;                % amplifies difference in reaction between small and large ydiff


% variables that collects data about encounters
dist_fea = inf*ones(N,1);               % saves danger index at time of first evasive action
ttc_fea = inf*ones(N,1);                % saves TTC at FEA
stoch_ttc_fea = nan*ones(N, NTTC);      % saves estimates of TTC distributions; each row contains NTTC simulated ttc values
dist_min_ea = inf*ones(N,1000);         % saves min sep. dist. over EA frames
ttc_min_ea = inf*ones(N,1000);          % saves min TTC over EA frames
dist_min_nea = inf*ones(1,N);           % saves min sep. dist. for encounters of type NEA
dist_min = inf*ones(1,N);               % saves min sep. dist. for all encounters
ttc_min = inf*ones(1,N);                % saves min TTC for all encounters
enc_status = ones(0);                   % saves interaction status of each timeframe
min_ttcvec = ones(0);                   
min_distvec = ones(0);
distvec = ones(0);

enc_type = zeros(1,N);                  % vector describing type of each encounter
min_stepsize = 0.01;                    % minimum stepsize/speed
stability_fac = 0.06;                   % parameter that determines how strongly course gets corrected once disrupted

react_A_save = ones(N,500)*Inf;
react_B_save = ones(N,500)*Inf;
A_save = ones(N,500)*Inf;
B_save = ones(N,500)*Inf;
A_theta_save = ones(N,500)*Inf;
B_theta_save = ones(N,500)*Inf;
A_stepsize_save = ones(N,1);
B_stepsize_save = ones(N,1);

if disable_crash==1
    save_pos_A = inf*ones(N,500);
    save_step_A = inf*ones(N,500);
    save_theta_A = inf*ones(N,500);
    save_pos_B = inf*ones(N,500);
    save_step_B = inf*ones(N,500);
    save_theta_B = inf*ones(N,500);
end

aa =1;
bb =1;

for i=1:N
decision_state = 0;
i %#ok<NOPTS>
%%%%%%%%%%%%% initiation of encounter %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nn = 0;
EA_index = 1;                                                  % tracks number of EA frame
first_detec = 0;                                           % 0 --> have not detected yet
stepsize = min_stepsize*[1 1] + gamrnd(a_init*[1 1],b_init);   % determines average speed of each vehicle
stepsize0 = stepsize;
theta = normrnd([0,0], theta_var_init);

% detection parameters
farsight = 40;      % determines how far drivers extrapolate into future to determine if EA is necessary
shift_d = 2*0.3*2.5;% determines the inflection point of the dist. factor
pow_d = 4;          % determines how quickly dist. factor goes to 1 as min. dist. goes to 0
shift_t = 15;       % determines the inflectopn point of the ttc factor
pow_t = 2;          % determines how quickly ttc factor goes to 1 as ttc goes to 0
detec_amp = 0.45;
detec_par = [shift_d, pow_d, shift_t, pow_t, detec_amp];

tolerance = 0.4*[0.16*0.1, 0.03, 0.08];

%%%% driver properties %%%%
% determine inertia of each driver; how twitchy can they be in their
% movements?
var_theta = var_theta0*gamrnd(1^2/0.04, 0.04/1); 
var_step = var_step0*gamrnd(1^2/0.02, 0.02/1);
d1_theta = +0.5-4.0*gamrnd(1^2/0.1, 0.1/1);           % determines where driver A starts turning
p1_theta = -1.0*gamrnd(1^2/0.1, 0.1/1);               % determines how quickly driver A makes the turn
amp1_theta = pi/2;                                    % determins the angle driver A expects to have after the turn
d1_step = pi/4*0.6*gamrnd(1^2/0.02, 0.02/1);          % angle for which maximum deccelaration occurs
p1_step = 15*gamrnd(1^2/0.2, 0.2/1);              
amp1_step = 0.06*gamrnd(1^2/0.15, 0.15/1);            % determines maximum amount of deceleration during turn

alertness = betarnd(40,3,[1,2]);                      % determines how likely each driver is to notice threat

theta_mod_par = [d1_theta, p1_theta, amp1_theta];      % parameters of s-function that computes exp_theta(A0)
speed_mod_par = [d1_step, p1_step, amp1_step];         % parameters of exp-function that computes exp_step(A0,theta)

% collect properties characterizing each driver
driver_prop = {stepsize0, var_step, var_theta, ...
               stability_fac, min_stepsize, theta_mod_par, speed_mod_par};

%%% initial positions
A_real = -xinit;
B_real = xinit;
A_im = normrnd(-2.5,sigma_var0);
B_im = normrnd(0,sigma_var0);
A0 = A_real + 1i*A_im;
B0 = B_real + 1i*B_im;



%%% data collection variables
detec_stat_A = 0;   
detec_stat_B = 0;
encounter_classifier = 1; % tracks status: sign indicates interaction status 
                          % + --> no interaction, - --> interaction); 1 --> no collision, 2 --> collision
danger_enc_i = [];        % saves danger index associated with each timestep
ttc_enc_i = [];           % saves danger index associated with each timestep
counter = 0;              % keeps track of the current frame


% if disable_crash==1
%   engage_EA = double(imag(A0)<4 || real(B0)>-xinit); 
% else
%   engage_EA = double(real(A0) < xinit   && imag(A0)<4 && real(B0) > -xinit && imag(A0)<imag(B0)+1.5 && real(A0)<real(B0)+1.5);
% end

%     while  imag(A0)<4 || real(B0)>-xinit 
    while continue_simulation(A0,B0,xinit,disable_crash)==1
        counter = counter + 1;
        nn = nn + 1;
        D = norm(A0-B0);
        
        if disable_crash==1
            save_pos_A(i,nn) = A0;
            save_step_A(i,nn) = stepsize(1);
            save_theta_A(i,nn) = theta(1);
            save_pos_B(i,nn) = B0;
            save_step_B(i,nn) = stepsize(2);
            save_theta_B(i,nn) = theta(2);
        end
        
%       dp = p_engage_EA(A0,B0,stepsize,theta, detec_par);
        if detec_stat_A==0 || detec_stat_B==0
            [dp,t_min,d_min] = pd_separate_reaction(A0,B0,stepsize0,theta, driver_prop, detec_par,farsight);
            
            if use_dp_model == 1
                predictor = [1,t_min,d_min];
                dp = 1./(1 + exp(-predictor*b));
            end
            
            detec_stat_A = max(double(rand(1)<dp*alertness(1)),detec_stat_A);
            detec_stat_B = max(double(rand(1)<dp*alertness(2)),detec_stat_B);
            enc_status(end+1) = max(detec_stat_A,detec_stat_B);
            min_ttcvec(end+1) = t_min;
            min_distvec(end+1) = d_min;
            detec_stat = max(detec_stat_A,detec_stat_B);
            distvec(end+1) = D;
        end
        
        %enc_status(i,nn) = react;
        %dp = 0.98*exp(-0.4*norm(A0-B0));
        if disable_crash == 1 
            dp=0; 
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% detection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % if          "drivers are in EA mode"    OR     "EA is engaged by dp roll"
        % and         "they have not yet passed each other"
        if  detec_stat==1 && real(A0) < real(B0) && imag(A0)<imag(B0)+0.5
            % saving information in vectors, and updating status
            
            if first_detec == 0 && est_ttc == 1 % a loop that collects information at first moment of evasive action
                
                if use_history==1
                    [row, col] = find_sim_sit(A0, stepsize(1),theta(1), historyA, tolerance);
                else
                    row=0;
                end
                
                for k=1:NTTC 
                    %pred_paths = inf*ones(NTTC,500);
                    if k>length(row) || use_history==0 %number of observed walks satisfying init. cond.
                        ttc = ttc_simulator_double_momentumV2(A0,B0, stepsize, theta, r, driver_prop, plot_pred_path);
                        stoch_ttc_fea(i,k) = ttc;
%                         ttc
%                         pause(.1)
                    else
                        ttc = ttc_simulator_history(A0,B0,stepsize,theta,r,driver_prop,historyA{1},row,col,k,plot_pred_path);
                        stoch_ttc_fea(i,k) = ttc;
%                         ttc;
%                         pause(1)
                        %                     ttc = ttc_simulator_double_momentumV2(A0,B0, stepsize, theta, r, driver_prop, plot_setting);
                    end
                end
                ttc_fea(i) = compute_ttc(A0,B0,stepsize,theta,r);
                dist_fea(i) = norm(A0-B0) - 2*r;
                dist_min_EA(i,EA_index) = norm(A0-B0) - 2*r;
                ttc_min_ea(i,EA_index) = compute_ttc(A0,B0,stepsize,theta,r);
                EA_index = EA_index + 1;
                
            end
            
            first_detec = 1; % set to 1 so that above loop only runs on first moment of detection
            detec_stat_A = 1;
            encounter_classifier = -1;
            danger_index = D - 2*r;
            danger_enc_i(length(danger_enc_i) + 1) = danger_index;
            ttc_enc_i(length(ttc_enc_i) + 1) = compute_ttc(A0,B0,stepsize,theta,r);
            
            % take next step
            if detec_stat_A==1 && detec_stat_B==1
                newstep = take_evasive_stepV2(A0,B0, stepsize, theta, driver_prop, decision_state);
                decision_state = newstep{2};
                A1 = newstep{1}{1}(1);    
                B1 = newstep{1}{1}(2);
                stepsize = newstep{1}{2};
                theta = newstep{1}{3};

            elseif detec_stat_A==1 && detec_stat_B==0
                newstepA = take_evasive_stepV2(A0,B0, stepsize, theta, driver_prop, decision_state);
                newstepB = take_NEA_step(A0,B0, stepsize, theta, driver_prop);
                A1 = newstepA{1}{1}(1);    
                B1 = newstepB{1}(2); 
                stepsize = [newstepA{1}{2}(1), newstepB{2}(2)];
                theta =    [newstepA{1}{3}(1), newstepB{3}(2)];
                
            elseif detec_stat_A==0 && detec_stat_B==1
                newstepB = take_evasive_stepV2(A0,B0, stepsize, theta, driver_prop, decision_state);
                newstepA = take_NEA_step(A0,B0, stepsize, theta, driver_prop);
                A1 = newstepA{1}(1);    
                B1 = newstepB{1}{1}(2); 
                stepsize = [newstepA{2}(1), newstepB{1}{2}(2)];
                theta =    [newstepA{3}(1), newstepB{1}{3}(2)];
            end
                
            dist_min_EA(i,EA_index) = norm(A1-B1) - 2*r;
            ttc_min_ea(i,EA_index) = compute_ttc(A1,B1,stepsize,theta,r);
            EA_index = EA_index + 1;

            plot_pos(A1, B1, pause_length, xinit, r, plot_enc,detec_stat_A, detec_stat_B) 
            
            if norm(A1-B1) < 2*r && disable_crash==0 % if satisfied, then colliosion with evasive action has ocurred
                hold on
                title(sprintf(" decision_state = %d", decision_state))
                hold off
                danger_index = norm(A1-B1) - 2*r;
                dist_min(i) = danger_index;
                ttc_min(i) = compute_ttc(A1,B1,stepsize,theta,r);
                danger_enc_i(length(danger_enc_i) + 1) = danger_index;
                ttc_enc_i(length(ttc_enc_i) + 1) = compute_ttc(A1,B1,stepsize,theta,r);
                encounter_classifier = -2;             % set encounter to type crash with attempted evasive action
                break
            end
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% no detection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        else
            % saving information in vectors, and updating status

            danger_index = D - 2*r;
            danger_enc_i(length(danger_enc_i) + 1) = danger_index;
            ttc_enc_i(length(ttc_enc_i) + 1) = compute_ttc(A0,B0,stepsize,theta,r);
 
            
            newstep = take_NEA_step(A0,B0, stepsize, theta, driver_prop);
            A1 = newstep{1}(1);    
            B1 = newstep{1}(2); 
            stepsize = newstep{2};
            theta = newstep{3};
            D = norm(A1-B1);
            ttc = compute_ttc(A1,B1,stepsize,theta,r);
            
            plot_pos(A1, B1, pause_length, xinit, r, plot_enc, detec_stat_A, detec_stat_B)
            
            if D < 2*r && disable_crash==0% if satisfied, collision has occured before evasive action is taken
                hold on; title("collision"); hold off
                danger_index = D - 2*r;

                %%% compute ttc (which will now be negative) and danger_FEA
                ttc = ttc_simulator_double_momentum_improved(A1,B1,stepsize,theta,min_stepsize,var_step,r, var_theta, stability_fac);

                dist_fea(i) = danger_index;
                ttc_fea(i) = ttc;
                stoch_ttc_fea(i,:) = ttc*ones(1,NTTC);
                danger_enc_i(length(danger_enc_i) + 1) = danger_index; %#ok<*SAGROW>
                ttc_enc_i(length(ttc_enc_i) + 1) = compute_ttc(A1,B1,stepsize,theta,r);
                dist_min(i) = danger_index;
                ttc_min(i) = compute_ttc(A1,B1,stepsize,theta,r);
                encounter_classifier = 2;                                  % indicates a collision with no evasive action attempted
                break
            end
        end
        react_A_save(i,nn) = detec_stat_A;
        react_B_save(i,nn) = detec_stat_B;
        A_save(i,nn) = A1;
        B_save(i,nn) = B1;
        A_theta_save(i,nn) = theta(1);
        B_theta_save(i,nn) = theta(2);

        A0 = A1;
        B0 = B1;
    end
    
    A_stepsize_save(i) = stepsize(1);
    B_stepsize_save(i) = stepsize(2);

    enc_type(i) = encounter_classifier;
    dist_min(i) = min(danger_enc_i);
    ttc_min(i) = min(ttc_enc_i);

    if encounter_classifier == 1  % no evasive action and no collision has occured
        dist_min_nea(i) = min(danger_enc_i);
    end
    sum(enc_type==2);

end

if disable_crash == 1
    historyA{1} = save_pos_A;
    historyA{2} = save_step_A;
    historyA{3} = save_theta_A;
end


%plot_encounter(A_save, B_save,react_A_save, react_B_save, find(enc_type==-2), .25, xinit, r)





























sum(enc_type==-2)
sum(enc_type==2)
% remove all elements/rows corresponding to encounters with no EA
dist_fea(enc_type==1,:) =[];
X = stoch_ttc_fea;
stoch_ttc_fea(enc_type==1,:) = [];
dist_min_EA(enc_type>0,:) = [];
dist_min_EA = min(dist_min_EA,[],2);
ttc_min_ea( enc_type > 0 ,:) = [];
ttc_min_ea = min(ttc_min_ea,[],2);
dist_min_nea = dist_min_nea( enc_type > 0 );

%%%%%%% Compute minimum ttc for all encounters where there was no evasive action
if est_ttc == 1 && compute_X ==1

N_enc_type1 = sum(enc_type==1);
A_NEA = A_save(enc_type==1,:);
B_NEA = B_save(enc_type==1,:);
diff_NEA = A_NEA - B_NEA;
real_diff_NEA = real(diff_NEA);
norm_diff_NEA = sqrt(conj(diff_NEA).*diff_NEA);
ttc_dist_save = ones(N_enc_type1, NTTC)*Inf;

for i=1:N_enc_type1
    %i
    ttc_dist = ones(500, NTTC)*Inf;
    ttc_minimum = Inf;
    min_ttc_index = 1;
%     if min(norm_diff_NEA(i,:))>2
%         continue
%     end

    for j=1:100
        t = norm_diff_NEA(i,j)/(A_stepsize_save(i) + B_stepsize_save(i));
        if real_diff_NEA(i,j)<0   &   t < 6    &     min(norm_diff_NEA(i,:)) < 4
                A0 = A_NEA(i,j);
                B0 = B_NEA(i,j);
                theta = [A_theta_save(i,j), B_theta_save(i,j)];
                stepsize = [A_stepsize_save(i), B_stepsize_save(i)];

                for k=1:NTTC
                    ttc = ttc_simulator_double_momentum_improved(A0,B0,stepsize,theta,min_stepsize,var_step*aa,r, var_theta*bb, stability_fac,plot_sim_walks);
                    if ttc< Inf
                        pause(0.0)
                    end
                    if ttc < ttc_minimum
                        ttc_minum=ttc;
                        min_ttc_index = j;    % keeps track of which moment is most dangerous
                    end
                    ttc_dist(j,k) = ttc;
                    if ttc<0
                        TTC = 0;
                        AA = A0;
                        BB = B0;
                        step0 = stepsize;
                        theta0 = theta;
                    end

                end



    end
    ttc_dist_save(i,:) = ttc_dist(min_ttc_index,:); % find ttc-distribution from moment with lowest minimum ttc.
    end
end

X(enc_type==1,:) = ttc_dist_save;   % vector that contains ttc-data from all encounters.
end

avg_cond_ttc = mean(stoch_ttc_fea,2,'omitnan');
p_hypo_coll = sum(1-isnan(stoch_ttc_fea'))'/NTTC;
weighted_ttc_fea = avg_cond_ttc.*(1+exp(-3*p_hypo_coll));
% ttc and stochastic-ttc measurements
all_data{kk,1} = stoch_ttc_fea;
all_data{kk,2} = weighted_ttc_fea;
all_data{kk,3} = ttc_fea;
all_data{kk,4} = ttc_min';
all_data{kk,5} = ttc_min_ea;

% minim distance measurements
all_data{kk,6} = dist_fea;
all_data{kk,7} = dist_min_EA;
all_data{kk,8} = dist_min';

% other information
all_data{kk,9} = sum(enc_type==2);                                               % saves p_nea_coll
all_data{kk,10} = sum(enc_type==-2);                                             % saves p_ea_coll
all_data{kk,11} = (sum(enc_type==-1) + sum(enc_type==-2) + sum(enc_type==2))/N;  % saves p_interactive
all_data{kk,12} = (sum(enc_type==-1)+sum(enc_type==-2))/N;                       % saves p_ea


end
