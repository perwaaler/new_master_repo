n_est_sets = 1;                        % number of encounter-samples desired
N_enc = 300;                           % number of encounters
all_data = cell(n_est_sets, 12);       % collects data from each encounter-sample
NTTC = 30;                             % Number of TTC to sample at first evasive action for each encounter
est_ttc = 0;                           % tells the algorithm whether or not you want to estimate ttc distribution for each encounter
compute_X = 0;

% plot settings
plots.enc        = 1;
plots.predpath   = 0;
plots.overlap    = 1;
plots.pause      = 2^-5;
plots.pred_pause = 2^-5;
plots.radius     = 0.3;
plots.xinit      = 6;
plots.EAmode     = 0;
plots.dec_cols   = ["black", "green", "cyan", "red", "yellow", "magenta"];

disable_crash = 1;                       % disable collision and EA mode to record free movement patterns
use_history = 0;
use_dp_model = 0;                        % set to 1 if you want to use estimated reaction model


for kk = 1:n_est_sets
kk %#ok<NOPTS>
    
% variables that collects severity meausures and data for each encounter
% FEA
fea.dist = inf*ones(N_enc,1);              % saves separation distance at time of first evasive action
fea.ttc = inf*ones(N_enc,1);               % saves TTC at FEA
fea.stoch_ttc = nan*ones(N_enc, NTTC);     % saves estimates of TTC distributions; each row contains NTTC simulated ttc values

% encounter minimum
ea.mindist = inf*ones(N_enc,1000);         % saves min sep. dist. over EA part
ea.minttc = inf*ones(N_enc,1000);          % saves min TTC over EA part
enc.mindist = inf*ones(1,N_enc);           % saves min sep. dist.
enc.minttc = inf*ones(1,N_enc);            % saves min TTC
% + --> no EA, - --> EA); 1 --> no collision, 2 --> collision

% cell structure that saves the encounters
save_enc.states = cell(N_enc,1);
save_enc.type   = zeros(N_enc,1);
save_enc.decisions = cell(N_enc,1);

for i=1:N_enc
i
plots.col        = ["black","black"];
%%%% initiate encounter %%%%
% determines average and initial speed of each vehicle
speed0 = max(0.01, gam_rnd(0.20, 0.05, 2)); speed  = speed0;
theta  = normrnd([0,pi], deg2rad(7));
dtheta = [0,0];
dspeed = [0,0];
% determine initial x values
init_x = plots.xinit;
A_real = -init_x;
B_real = init_x;
A_im = normrnd(-2.3,0.5);
B_im = normrnd(0,   0.5);
A0 = A_real + 1i*A_im;
B0 = B_real + 1i*B_im;
% set initial decision states
decision = [0,0];

% choose how similar a trajectory has to be in order to be "similar"
tolerance = 0.4*[0.16*0.1, 0.03, 0.08]; 


% set regression parameters for probability to engage in Evasive Action(EA)
beta_EA.int   = -2.8;
beta_EA.dist  = .8;
beta_EA.speed = -1;

%%%% set driver properties %%%%
% radius of Road Users
RUprop.r         = 0.3;
% determine how jerky the RU are in their movements
RUprop.Etheta_std      = beta_rnd(deg2rad(3),deg2rad(.5),2); 
RUprop.Espeed_std      = beta_rnd(0.05, 0.01,2);
RUprop.d2theta_std     = beta_rnd(deg2rad(7),deg2rad(2),2);
% set how accurately the drivers can predict future positions
RUprop.pred_speed_err = gam_rnd(0.001, 0.0001,2);
RUprop.pred_theta_err = gam_rnd(deg2rad(.5),deg2rad(.05),2);
% set minimum speed
RUprop.speed_min = 0.01;
RUprop.avg_speed = speed0;
% determine how much A brakes during left turn
RUprop.turn_brake = beta_rnd(0.03,0.003);
RUprop.start_brake = beta_rnd(0.03,0.003);
% weight determines momentum of drivers
RUprop.weight    = gam_rnd(1.0,0.09,2);
% where does A start and end turn
RUprop.turnstart = normrnd(-5.2,0.5);
RUprop.turnend   =  RUprop.turnstart + gam_rnd(5,0.5);
% determine how alert each driver is
RUprop.alert = beta_rnd(.8,.08,2);
% determine how often RU assesses success of decision
RUprop.decision_freq = [2,2];
RUprop.aggression = beta_rnd(0.5,0.02,2);
RUprop.id = [1,2];

%%%% set laws of movement / laws of momentum %%%%
max_delta(1).dspeed = beta_rnd(0.01*RUprop.weight(1)^-1, 1e-4);
max_delta(2).dspeed = beta_rnd(0.01*RUprop.weight(2)^-1, 1e-4);
max_delta(1).dtheta = beta_rnd(0.3*RUprop.weight(1)^-1, 8e-4);
max_delta(2).dtheta = beta_rnd(0.3*RUprop.weight(2)^-1, 8e-4);
max_delta(1).d2theta = deg2rad(15);
max_delta(2).d2theta = deg2rad(15);
% for convenience set laws of physics as a driver property
RUprop.max_delta = max_delta;


%%%% set state of each Road User (RU) %%%%
[S(1).pos,    S(2).pos]          = deal(A0,B0);
[S(1).theta,  S(2).theta]        = deal(theta(1),theta(2));
[S(1).speed,  S(2).speed]        = deal(speed0(1), speed0(2));
[S(1).dtheta, S(2).dtheta]       = deal(dtheta(1),dtheta(2));
[S(1).dspeed, S(2).dspeed]       = deal(dspeed(1),dspeed(2));
[S(1).EA,     S(2).EA]           = deal(0,0);
[S(1).decision, S(2).decision]   = deal(0,0);
[S(1).RUprop, S(2).RUprop]       = deal(RUprop,RUprop);
[S(1).id,     S(2).id     ]      = deal(1,2);

% enc is a field that saves information for the encounter as a whole
enc.states = cell(150,1); 
enc.states{1} = S;
enc.time_diff = cell(150,1);
enc.decisions = zeros(2,150);
enc.decisions(:,1) = [0;0]; % decisions==0 --> no interaction yet

%%%% variables that track status %%%%
% track frame
stat.frame     = 1;
% starts ticking once EA has been engaged
stat.EAframe   = [1,1]; 
% used to determine how often RUs makes decisions
stat.decision_count = [0,0];
% Has there been a first interaction?
stat.first_int = 0;
% is atleast one of them interacting?
stat.int       = 0;
% have they been commanded to stop interacting?
stat.stop_int  = 0;
% decision status
stat.decision  = [0,0];
% tracks time advantage over the last couple of frames
stat.Tadv      = [0,0];
% tracks Time-To-Potential-Collision
stat.TTPC      = 0;
% track the number of consecutive failed attempts at conflict resolution
stat.CR_fails  = 0;
stat.type      = 1; 

time_diff    = []; 
D_enc_i      = inf*ones(1,500);           
D_enc_i(1)   = norm(A0-B0)-2*RUprop.r;
ttc_enc_i    = inf*ones(1,500);           % saves danger index associated with each timestep
ttc_enc_i(1) = calc_ttc(S,RUprop.r);

    while continue_simulation(S,init_x)==1
        
        % compute probability of A or B reacting
        pea = p_interact(S,beta_EA,RUprop);
  
        if min(S.EA)==0 % if one of them has not engaged EA
            
            % roll to decide if EA gets engaged
            pea = p_interact(S,beta_EA,RUprop);
            
            % update EA status and interaction status
            S(1).EA = max(rand(1)<pea(1)*RUprop.alert(1), S(1).EA);
            S(2).EA = max(rand(1)<pea(2)*RUprop.alert(2), S(2).EA);
            stat.int = max(S(1).EA,S(2).EA);
        end
        
        if disable_crash==1 
            pea=0; 
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % if  "drivers are in interaction mode" OR "interaction is engaged by pea roll"
        % and  "they have not yet passed each other"
        if  max(S.EA)==1 && disable_crash==0 && stat.stop_int==0
            
            % estimate stochastic TTC at First Evasive Action
            if stat.first_int == 0
                
                if use_history==1
                    [row, col] = find_sim_sit(A0, speed(1),theta(1), historyA, tolerance);
                else
                    row=0;
                end
                
                if est_ttc == 1
                    for k=1:NTTC 

                        if k>length(row) || use_history==0 %number of observed walks satisfying init. cond.
                            ttc = ttc_simulator_double_momentumV2(S, r, driver_prop, plot_pred_path);
                            fea.stoch_ttc(i,k) = ttc;
                        else
                            ttc = ttc_simulator_history(A0,B0,speed,theta,r,driver_prop,historyA{1},row,col,k,plot_pred_path);
                            fea.stoch_ttc(i,k) = ttc;
                        end
                    end
                    fea.ttc(i) = calc_ttc(S,RUprop.r);
                    fea.dist(i) = D;
                    ea.mindist(i,stat.EAframe) = D;
                    ea.minttc(i, stat.EAframe) = fea.ttc(i);
                end
                
            end
            
            % update status of encounter
            stat.EAframe = stat.EAframe + 1;
            stat.type = -1;
            plots.EAmode = 1;

            %%%% determine where they would want to move if not interacting
            E_speedA = normrnd(E_speed_A(S, RUprop), RUprop.Espeed_std(1));
            E_thetaA = normrnd(E_theta_A(S, RUprop), RUprop.Etheta_std(1));
            E_speedB = normrnd(RUprop.avg_speed(2),  RUprop.Espeed_std(2));
            E_thetaB = normrnd(pi,                   RUprop.Etheta_std(2));
            
%             time_diff = temporal_sep(enc,RUprop,stat,plots);
            Tsep = spline_pred_path(stateA,stateB,k,sparse_ind,genInfo)
            
            % positive Tadv means that RU A has a time advantage
            T2        = time_diff.T2;   % Time To Path Overlap
            Tadv      = time_diff.Tadv; % Time advantage
            TTPC      = time_diff.TTPC; % Time To Potential Collision
            
            % update previous and current time advantage vector
            stat.Tadv(1) = stat.Tadv(2);
            stat.Tadv(2) = Tadv;
            stat.TTPC    = TTPC;
                        
            % take step and update states            
            
            if S(1).EA==1 % if RU1 has engaged EA
                stat.decision_count(1) = mod(stat.decision_count(1) + 1,RUprop.decision_freq(1));
%                 plots.pred_path = boolean(stat.decision_count(1)==1);
                
                if stat.decision_count(1) == 1
                    % update decision and action
                    decision(1) = make_decision(time_diff,RUprop,1);
                    actionA = decis2action(S,max_delta,1,decision(1));
                end
                
%                 plots.col(1) = decision2color(decision(1));
                S(1) = take_step(S(1), S(1).speed + actionA(1), S(1).theta+actionA(2), max_delta(1));
            else
                S(1) = take_step(S(1), E_speedA, E_thetaA, max_delta(1));
            end
            
            if S(2).EA==1 % if RU1 has engaged EA
                stat.decision_count(2) = mod(stat.decision_count(2) + 1,2);

                if stat.decision_count(2) == 1
                    decision(2) = make_decision(time_diff, RUprop, 2);
                    actionB = decis2action(S,max_delta,2, decision(2));
                end
                
%                 plots.col(2) = decision2color(decision(2));
                S(2) = take_step(S(2), S(2).speed + actionB(1), S(2).theta + actionB(2), max_delta(2));
            else
                S(2) = take_step(S(2), E_speedB, E_thetaB, max_delta(2));
            end
            
            stat.first_int = 1; % set to 1 so that above loop only runs on first interaction
            plots.EAmode = 0;
            % plot drivers
            plot_pos(S, plots, time_diff, [decision(1),decision(2)])
%             if (decision(1)==4 || decision(1)==5)&& (decision(2)==4 || decision(2)==5)
%                 decision(1)
%                 decision(2)
%             pause(3)
%             end
            
            % check to see if it is safe to end interaction
            stat.stop_int = end_interaction(S,max_delta,plots);
            
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% NO DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        else
            % saving information in vectors, and updating status
            % find desired angle and speed of each driver
            % (add small value to argument to make driver A slow down before
            % he starts to make turn)
            E_speedA = normrnd(E_speed_A(S, RUprop), RUprop.Espeed_std(1));
            E_thetaA = normrnd(E_theta_A(S, RUprop), RUprop.Etheta_std(1));
            E_speedB = normrnd(RUprop.avg_speed(2),  RUprop.Espeed_std(2));
            E_thetaB = normrnd(pi,                   RUprop.Etheta_std(2));
                        
            % take step and update states
            S(1) = take_step(S(1), E_speedA, E_thetaA, max_delta(1)); 
            S(2) = take_step(S(2), E_speedB, E_thetaB, max_delta(2));
            
            % plot drivers
            plot_pos(S, plots, time_diff,[0,0])
            
        end
        
        % update frame
        stat.frame = stat.frame + 1;
        
        % update positions
        A0 = S(1).pos;
        B0 = S(2).pos;
        
        % save data from frame stat.frame of encounter kk
        D                           = norm(A0-B0) - 2*RUprop.r;
        D_enc_i(stat.frame)         = D;
        ttc_enc_i(stat.frame)       = calc_ttc(S,RUprop.r);
        enc.decisions(:,stat.frame) = [decision(1);decision(2)]*(1-stat.stop_int);
        enc.time_diff{stat.frame}   = time_diff;
        
        % save state
        enc.states{stat.frame} = S;
        
        if D<0 % collision has occurred!
            if stat.type==-1
                % set to crash type EA
                stat.type = -2;
            else
                % set to crash type no EA
                stat.type = +2;
            end
            % end encounter
            break
        end
        
    end
    
    save_enc.time_diff{i} = enc.time_diff;
    save_enc.states{i}    = enc.states;
    save_enc.type(i)      = stat.type;
    save_enc.decisions{i} = enc.decisions;

    enc.mindist(i) = min(D_enc_i);
    enc.minttc(i) = min(ttc_enc_i);

end

if disable_crash == 1
    historyA{1} = enc.posA;
    historyA{2} = enc.speedA;
    historyA{3} = enc.thetaA;
end
end


%%
%plot_encounter(enc.posA, enc.posB,enc.int_stateA, enc.int_stateB, find(stat.type==-2), .15, xinit, RUprop.r)






%%%% process data

sum(stat.type==-2)
sum(stat.type==2)
% remove all elements/rows corresponding to encounters with no EA
fea.dist(stat.type==1,:) =[];
X = fea.stoch_ttc;
fea.stoch_ttc(stat.type==1,:) = [];
ea.mindist(stat.type>0,:) = [];
ea.mindist = min(ea.mindist,[],2);
ea.minttc( stat.type > 0 ,:) = [];
ea.minttc = min(ea.minttc,[],2);
dist_min_nea = dist_min_nea( stat.type > 0 );


% save data from estimation set kk


avg_cond_ttc = mean(fea.stoch_ttc,2,'omitnan');
p_hypo_coll = sum(1-isnan(fea.stoch_ttc'))'/NTTC;
weighted_ttc_fea = avg_cond_ttc.*(1+exp(-3*p_hypo_coll));
% ttc and stochastic-ttc measurements
all_data{kk,1} = fea.stoch_ttc;
all_data{kk,2} = weighted_ttc_fea;
all_data{kk,3} = fea.ttc;
all_data{kk,4} = enc.minttc';
all_data{kk,5} = ea.minttc;

% minim D measurements
all_data{kk,6} = fea.dist;
all_data{kk,7} = ea.mindist;
all_data{kk,8} = enc.mindist';

% other information
all_data{kk,9} = sum(stat.type==2);                                               % saves p_nea_coll
all_data{kk,10} = sum(stat.type==-2);                                             % saves p_ea_coll
all_data{kk,11} = (sum(stat.type==-1) + sum(stat.type==-2) + sum(stat.type==2))/N_enc;  % saves p_interactive
all_data{kk,12} = (sum(stat.type==-1)+sum(stat.type==-2))/N_enc;                       % saves p_ea


