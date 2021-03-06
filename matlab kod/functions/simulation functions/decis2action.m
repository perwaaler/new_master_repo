function action = decis2action(S,max_delta,driver_id,decision)
% function that maps decision (integer) to action 

if driver_id == 1
    
    if     decision == 1 % let other pass
        delta_theta = -deg2rad(8);
        delta_speed = -0.1;
        
    elseif decision == 2
        delta_theta = 0;
        delta_speed = 0;
        
    elseif decision == 3
        delta_theta = deg2rad(8);
        delta_speed = 0;
        
    elseif decision == 4
            delta_theta = -deg2rad(20);
            delta_speed = -1;
            
    elseif decision == 5
            delta_theta = +deg2rad(20);
            delta_speed = -1;
    end
    
elseif driver_id == 2
    if     decision == 1
        delta_theta = deg2rad(8);
        delta_speed = -0.1;
        
    elseif decision == 2
        delta_theta = 0;
        delta_speed = 0;
        
    elseif decision == 3
        delta_theta = -deg2rad(8);
        delta_speed = 0;
        
    elseif decision == 4
            delta_theta = +deg2rad(20);
            delta_speed = -1;
            
    elseif decision == 5
            delta_theta = -deg2rad(20);
            delta_speed = -1;
    end

end



action = [delta_speed, delta_theta];
end

