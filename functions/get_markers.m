
function markers = get_markers(egg, windows)
% Returns indices of first closures found in the given windows of interest

    num = szdim(windows, 1); % number of windows
    markers = 1:num; % placeholder array
    for i = 1:num % loop through windows of interest
        idx = get_marker(egg(windows(i,1):windows(i,2)));
        plot(egg(windows(i,1):windows(i,2)));
        hold on
        xline(idx);
        pause;
        markers(i) = windows(i,1) + idx - 1; % index in full time series
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
    degg = smoo(degg, 1);
    
    % detect points where DEGG crosses threshold value
    auto = 1; % whether to use automatic threshold
    threshold = 0.5*std(egg); % manual threshold if needed
    [rims] = CRO(degg, [0 0 auto threshold]);
    
    % detection of position of the peaks . . . 
    % AMPOS function recomputes the DEGG from the EGG for some 
    % reason, which is a waste of CPU time, but we use it "as is" to
    % stay consistent with literature that has used peakdet2.)
    threshold = 0.5*std(egg);
    [Tgci,~,~,~] = AMPOS(egg, rims, 1, 1/48000, 1, threshold);
    marker = Tgci(1,1); % index of first closure in segment

end
