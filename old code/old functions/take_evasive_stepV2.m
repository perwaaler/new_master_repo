function out = take_evasive_stepV2(A0,B0, stepsize, theta, driver_prop, decision_state)
% predict future positions


% stepsize0 = driver_prop{1};
% var_step = driver_prop{2};
% var_theta = driver_prop{3};
% stability_fac = driver_prop{4};
min_stepsize = driver_prop{5};
% theta_mod_par = driver_prop{6};
% speed_mod_par = driver_prop{7};

% d1   = theta_mod_par(1);
% p1   = theta_mod_par(2);
% amp1 = theta_mod_par(3);
% d2   = speed_mod_par(1);
% p2   = speed_mod_par(2);
% amp2 = speed_mod_par(3);

%delta_theta = amp1*s_function(real(A0),d1,p1) ^ (amp2*s_function(theta(1), d2,p2));
%expected_theta = s_function(real(A0),d1,p1,amp1);
%expected_speed = stepsize0(1) - amp2*exp(-p2*(theta(1)-d2)^2)*(s_function(1,-0.6,2)+1);

% pred_thetaA = theta(1) - stability_fac*(theta(1) - expected_theta);
% pred_thetaB = theta(2);

Ap = A0 + stepsize(1)*exp(1i*theta(1)); % prediction of the A's future position
Bp = B0 - stepsize(1)*exp(1i*theta(2)); % prediction of the B's future position

v_delta0 = stepsize(1)*exp(1i*theta(1)) + stepsize(2)* exp(1i*theta(2));
s_delta0 = A0-B0;
norm_v_delta0 = norm(v_delta0);
t_min = -real(s_delta0*conj(v_delta0))/norm_v_delta0;    % time to point of minimum distance
d_min = norm(s_delta0 + t_min*v_delta0 );                % distance at point of minimum distance

x_diff = abs(real(Ap-Bp));
y_diff = imag(Ap - Bp);

rudeness_driverA = 0.5; % increasing this factor will increase preference of A to "go for it", i.e. cut across the other driver
line_y = imag(B0) + rudeness_driverA*stepsize(1)/stepsize(2)^0.9*(real(A0) - real(B0));
decision_dist = imag(A0) - line_y;
% if decision_dist 
rotation_sign = sign(decision_dist);


%rotation_sign = sign(y_diff + 2*stepsize(1)*x_dist);

if rotation_sign < 0 && decision_state == 0
    mod_thetaA = s_function(imag(A0),-3.5,1)*min(pi/15, 0.1*exp(-0.7*(t_min-10))*exp(-3*(d_min-4)) );
    mod_thetaB = s_function(abs(y_diff/x_diff),2.5,4)*s_function(imag(B0),2,3)*min(pi/25,          0.0007*exp(-0.5*(t_min-9))*exp(-1.5*(d_min-3)) );
    mod_theta = [mod_thetaA mod_thetaB];
    mod_step = [1 0]*stepsize(1)*min(0.08, 0.15*exp(-0.9*(t_min-5))*exp(-4*(d_min-2.8)) );
else % driver B goes for it, and B slows down
    mod_thetaA = min(pi/30, 0.01*exp(-0.3*(t_min-5))*exp(-2.5*(d_min-2)) );
    mod_thetaB = min(pi/30, 0.01*exp(-0.3*(t_min-5))*exp(-2.8*(d_min-2)) );
    mod_theta = [mod_thetaA mod_thetaB];
    mod_step =  [0,stepsize(2)*min(0.07, 0.2*exp(-0.3*(t_min-7))*exp(-2.5*(d_min-4)) )];
    decision_state = 1;
end

var_theta = driver_prop{3};


step = take_NEA_step(A0,B0, stepsize, theta, driver_prop);
theta_mod = normrnd(rotation_sign*mod_theta, var_theta);
stepsize = step{2};
theta = step{3};
theta = theta + theta_mod;
%theta = sign(theta).*max(abs(theta), pi/15)
stepsize = max(0.08*min_stepsize, stepsize - mod_step);
A1 = A0 + stepsize(1)*exp(1i*theta(1));
B1 = B0 - stepsize(2)*exp(1i*theta(2));
step{1} = [A1,B1];
step{2} = stepsize;
step{3} = theta;
out = {step, decision_state, rotation_sign};

end