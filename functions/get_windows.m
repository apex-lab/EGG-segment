function windows = get_windows(egg)
% finds candidate windows where voicing has started to occur 

    % get all peaks that exceed certain threshold (1 sd of sig)
    sd = std(egg);
    [~,locs_Rwave] = findpeaks(egg, 'MinPeakHeight', sd);

    % remove all peaks but first of each cluster/sound
    sz = size(locs_Rwave);
    locs = 1:sz;
    locs(1) = locs_Rwave(1);
    for i = 2:sz(2)
        if locs_Rwave(i) - locs_Rwave(i - 1) < 1000 % should be big enough
            locs(i) = 0;                      % to encompass 2 consecutive
        else                                  % peaks of any speaker's f0
            locs(i) = locs_Rwave(i);
        end
    end
    locs = locs(locs ~= 0);

    % now we take intervals before each remaining peak and slide back in 
    % time until the variance of the values in the window is near zero
    var_length = 150;
    start = locs - var_length; % start of each window
    for i = 1:length(start)
        while var((egg(start(i):start(i)+var_length))) > 1e-4
            start(i) = start(i) - 1;
        end
    end
    
    % now we select our windows for further analysis as those 
    % beginning at "start" and ending at the peaks remaining in "locs"
    windows = transpose([start; locs]);
    [~,idx,~] = unique(windows(:,1));
    windows = windows(idx,:);

end