% creates markers for the onset of voicing from an EGG time-series stored
% in an xdf file output by labstreaminglayer
% Tested with Matlab Version 9.6.0.1150989 (R2019a) Update 4

%% hard coded variables
filepath = "/home/john/Documents/EGG_pilot/sub-marisa/ses-S001/eeg/sub-marisa_ses-S001_task-8_acq-eeg-egg_run-001_eeg.xdf";
stream = 2; % which stream in the xdf file is EGG/audio
channel = 1; % which channel of EGG/audio is EGG

addpath("functions", "peakdet2", "xdf-Matlab")
    
%% extract EGG from xdf file
xdf = load_xdf(filepath, "HandleJitterRemoval", false); 
egg = xdf{stream}.time_series(channel,:);
egg_t = xdf{stream}.time_stamps;

%% reverse filter to correct phase distortion from hardware filter
x = fliplr(egg); % we apply forward filter to reverse-time EGG
% single pole reverse filter 
y = highpass(x, 40, 48000);
egg = fliplr(y);
clear x y

%% get time windows of interest for EGG analysis 
windows = get_windows(egg); % candidate windows to search for voicing onset

%% get time stamps of first glottal closure in each window
indices = get_markers(egg, windows);
timestamps = egg_t(indices);
timestamps = unique(timestamps); % remove duplicates, if any

%% add glottal closures to xdf object as marker stream and save as mat
s = length(xdf) + 1;
xdf{s}.info.type = 'Markers';
xdf{s}.info.type = 'glottis_closure_instants';
xdf{s}.time_stamps = timestamps;
num = length(timestamps);
xdf{s}.time_series = repmat("TGCI", [1 num]); 
% tage name means "time of glottis-closure instant"

% save
tmp = char(filepath);
savepath = strcat(tmp(1:end-3), "_tags.mat");
save(savepath, 'xdf'); % overwrites file "savepath" if already there