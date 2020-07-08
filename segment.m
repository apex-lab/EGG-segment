% creates markers for the onset of voicing from an EGG time-series stored
% in an xdf file output by labstreaminglayer
% Tested with Matlab Version 9.6.0.1150989 (R2019a) Update 4

%% hard coded variables
filepath = '~/Documents/EGG/sub-P010/ses-S001/eeg/sub-P010_ses-S001_task-slowHum_run-001_eeg.xdf';
channel = 1; % which channel of EGG/audio stream is EGG

addpath('functions', 'peakdet2', 'xdf-Matlab')
    
%% extract EGG from xdf file
xdf = load_xdf(filepath, 'HandleJitterRemoval', false); 
% find EGG/audio stream
for i = 1:length(xdf)
    if (xdf{i}.info.name == "AudioCaptureWin")
        stream = i;
    end
end
egg = xdf{stream}.time_series(channel,:);
egg_t = xdf{stream}.time_stamps;

%% reverse filter to offset phase distortion from hardware filter
x = fliplr(egg); % we apply forward filter to reverse-time EGG
% single pole reverse filter WITHOUT phase correction 
firf = designfilt('highpassfir', 'FilterOrder', 1, ...
    'CutoffFrequency', 20, 'SampleRate', 48000);
y = filter(firf, x); % our EGG amp lets you choose between 10 & 20 hz hpf
egg = fliplr(y);
% remove high frequency noise WITH phase correction
egg = lowpass(egg, 1000, 48000);
clear x y firf

%% get time windows of interest for EGG analysis 
windows = get_windows(egg); % candidate windows to search for voicing onset
%windows(:,2) = windows(:,2) + 500;

%% get time stamps of first glottal closure in each window
indices = get_markers(egg, windows);
timestamps = egg_t(indices + 1);

%% now view epochs of interest to make sure they trials aren't overlapping
epoch = [-800 200]; % epoch boundaries relative to GCI in milliseconds
epoch = epoch/1000*48000; % convert to samples
for i = 1:length(indices) 
    plot((epoch(1):epoch(2))/48, egg(indices(i)+epoch(1):indices(i)+epoch(2))); 
    hold on; 
    xline(0); 
    %sound(egg(indices(i)-10000:indices(i)+epoch(2)),48000); 
    hold off; 
    prompt = 'Press (y) if trial is good, (n) if bad.';
    status = input(prompt, 's');
    if (status == 'n')
        timestamps(i) = 0;
    end
end
timestamps = timestamps(timestamps ~= 0); % remove caught errors

%% add glottal closures to xdf object as marker stream and save as mat
s = 3; %length(xdf) + 1;
xdf{s}.info.type = 'Markers';
xdf{s}.info.name = 'glottis_closure_instants';
xdf{s}.time_stamps = timestamps;
num = length(timestamps);
xdf{s}.time_series = repmat("TGCI", [1 num]); 
% tage name means "time of glottis-closure instant"

% save
tmp = char(filepath);
savepath = strcat(tmp(1:end-4), '.mat');
save(savepath, 'xdf'); % overwrites file "savepath" if already there