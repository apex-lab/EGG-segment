
function markers = get_markers(egg, windows)
% Returns indices of first closures found in the given windows of interest

    sz = size(windows); 
    num = sz(1); % number of windows
    markers = 1:num; % placeholder array
    for i = 1:num % loop through windows of interest
        try
            idx = get_marker(egg(windows(i,1):windows(i,2)));
            markers(i) = windows(i,1) + idx - 1;
        catch % if it doesn't find a peak
            hold off;
            plot(egg(windows(i,1):windows(i,2)));
            pause;
            markers(i) = 0;
        end
    end
    
end

function marker = get_marker(egg)
% Returns index of first glottal closure in segment of EGG time series.
% Uses peakdet2 toolbox. 

    % calculate derviative of EGG signal (DEGG)
    degg = 1 :(length(egg) - 1); % placeholder array
    for w = 1 :(length(egg) - 1)
        degg(w) = egg(w + 1) - egg(w);
    end
    
    % smooth DEGG as in peakdet2
    degg = smoo(degg, 10);
    
    % detect points where DEGG crosses threshold value
    auto = 1; % whether to use automatic threshold
    threshold = 0.7*std(degg); % manual threshold if needed
    [rims] = CRO(degg, [0 0 auto threshold]);
    
    % detection of position of the peaks . . . 
    % AMPOS function recomputes the DEGG from the EGG for some 
    % reason, which is a waste of CPU time, but we use it "as is" to
    % stay consistent with literature that has used peakdet2.)
    [Tgci,~,~,~] = AMPOS(egg, rims, 1, 1/48000, 1, threshold);
    idx = Tgci(1,1); % index of first closure in segment
    % plot marker for user to accept or reject
    hold off
    plot(egg);
    hold on
    plot(10*degg);
    hold on
    xline(idx);
    prompt = 'Press (y) if marker is good, (n) if bad.';
    status = input(prompt, 's');
    if (status == 'n')
        [idx,~,~] = ginput(1);
    end
    hold off
    marker = idx;

end
