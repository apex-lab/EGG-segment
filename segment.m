% creates markers for the onset of voicing from an EGG time-series stored
% in an xdf file output by labstreaminglayer
% Tested with Matlab Version 9.6.0.1150989 (R2019a) Update 4

%% hard coded variables
filepath = "/home/john/Documents/EGG_pilot/sub-marisa/ses-S001/eeg/sub-marisa_ses-S001_task-2_acq-eeg-egg_run-001_eeg.xdf";
stream = 2; % which stream in the xdf file is EGG/audio
channel = 1; % which channel of EGG/audio is EGG

addpath("functions", "peakdet2", "xdf-Matlab")
    
%% extract EGG from xdf file
xdf = load_xdf(filepath); 
egg = xdf{stream}.time_series(channel,:);

%% get segments for EGG analysis and save as text file for peakdet2
windows = get_windows(egg); % candidate windows to search for voicing onset

%%
% convert from samples to milliseconds
windows = windows*1000/48000;
% save as text file
tmp = char(filepath);
savepath = strcat(tmp(1:end-3), "_windows.txt");
dlmwrite(savepath, windows, 'delimiter', '\t');
% save wav file for peakdet2 to load
savepath = strcat(tmp(1:end-3), "_egg.wav");
audiowrite(savepath, transpose(xdf{stream}.time_series), 48000);

% open peakdet2 and graphically verify its results, making sure to save
peakdet2

%% convert peakdet2 output into markers for EEG 
markers = get_markers(egg, windows); % exact timestamps of voicing onset

%% save as mat object that can be uploaded to EEGLab
tags = to_eeglab(matlab);
tmp = char(filepath);
savepath = strcat(tmp(1:end-3), "_tags.mat");
save(savepath, tags); % overwrites file "savepath" if already there