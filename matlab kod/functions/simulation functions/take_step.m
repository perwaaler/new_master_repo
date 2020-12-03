function new_state = take_step(state, desired_speed, desired_angle, max_change)
% Takes a step given current state and desired state.
% position A0, speed, direction (angle0), 
max_delta_speed = max_change(1);
max_delta_theta = max_change(2);
max_delta_dtheta = deg2rad(4);
angle_diff = desired_angle - state.theta;

%angle_acc  = angle_diff - dtheta0;
speed_diff = desired_speed - state.speed;

angle_diff_diff =  sign(angle_diff)*min(max_delta_dtheta, abs(angle_diff - state.dtheta));


angle_diff = state.dtheta + angle_diff_diff;

% compute new angle and speed, and take next step
theta1 = state.theta + sign(angle_diff)*min(max_delta_theta, abs(angle_diff));
speed1 = state.speed + sign(speed_diff)*min(max_delta_speed, abs(speed_diff));
A1 = state.pos + speed1*exp(1i*theta1);
dtheta1 = theta1 - state.theta;

[state.pos, state.theta, state.speed, state.dtheta] = deal(A1,theta1,speed1,dtheta1);

new_state = state;
end