function overlap_ind_RU1 = find_overlap_RU1(k,pathA,pathB,RU1,...
                                overlapRU2_ind,ind_first_touch,RUprop,sr)
% function that finds the index for the overlapping balls of RU1.
% sr indicates the number of balls in pathRU1 to set as potential
% overlap-candidates.

r = RUprop.r;

if isempty(sr)
    sr=3;
end

if RU1==1
    pathRU1 = pathA;
    pathRU2 = pathB;
else
    pathRU1 = pathB;
    pathRU2 = pathA;
end

% indicator variables that determines if index goes out of bounds
left_bound_reached  = 0;
right_bound_reached = 0;

% get index for the ball in pathRU1 that got hit first by RU2
centerP = ind_first_touch(1);
% set search range to look for overlapping balls in pathRU1
overlap_cand_ind = centerP - sr:centerP + sr;
% make sure not to include points that go out of bounds
overlap_cand_ind = overlap_cand_ind(overlap_cand_ind<=k);
overlap_cand_ind = overlap_cand_ind(1<=overlap_cand_ind);
% select candidate for overlap of RU1
overlapRU1_cand  = pathRU1(overlap_cand_ind);
% select overlap of RU2
overlapRU2 = pathRU2(overlapRU2_ind);

% find distances between candidate points and overlap of RU2
dist_matrix = abs(overlapRU1_cand.' - overlapRU2);
overlap_matrix = dist_matrix < 2*r;

% cut consecutive zeros:
overlap_indicator = sum(overlap_matrix,2)>0;
overlap_cand_ind = overlap_cand_ind(overlap_indicator);

l_is_overlap = 1;
r_is_overlap = 1;

%       one of the endpoints overlap  AND  both are not out of bounds 
while (l_is_overlap==1 && left_bound_reached==0) || ...
      (r_is_overlap==1 && right_bound_reached==0)

if l_is_overlap==1 && left_bound_reached==0
    % add an earlier ball to the overlap of RU1
    ind_left_ext = overlap_cand_ind(1) - 1;
    
    % check if index goes out of bounds
    if ind_left_ext < 1
        left_bound_reached = 1;
    end
    
    if left_bound_reached==0
        % append new index to beginning of overlap-index-vector
        overlap_cand_ind = [ind_left_ext, overlap_cand_ind]; %#ok<*AGROW>
        % compute distances for new left-candidate-ball
        l_is_overlap = sum(abs(pathRU1(ind_left_ext) - overlapRU2) < 2*r)>0;
        
    end
        
end

if r_is_overlap==1 && right_bound_reached==0
    % add a later ball to the overlap of RU1
    ind_right_ext = overlap_cand_ind(end) + 1;
    
    % check if index goes out of bounds
    if ind_right_ext > k
        right_bound_reached = 1;
    end
    
    if right_bound_reached==0
        % append new index to beginning of overlap-index-vector
        overlap_cand_ind = [overlap_cand_ind,ind_right_ext];
        % compute distances for new left-candidate-ball
        r_is_overlap = sum(abs(pathRU1(ind_right_ext) - overlapRU2) < 2*r)>0;

    end
    
end
end


% overlapRU1_cand  = pathRU1(overlap_cand_ind);
% % select overlap of RU2
% overlapRU2 = pathRU2(overlap_RU2);

% find distances between candidate points and overlap of RU2
% dist_matrix = abs(overlapRU1_cand.' - overlapRU2);
% overlap_matrix = dist_matrix < 2*r;
overlap_ind_RU1 = overlap_cand_ind(1 + (1-left_bound_reached):...
                                 end - (1-right_bound_reached));

end

    
    
    
    