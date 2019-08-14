% creates markers for the onset of voicing from an EGG time-series stored
% in an xdf file output by labstreaminglayer

%%% hard coded variables
filename = "/home/john/Documents/EGG_pilot/sub-michelle/ses-S001/eeg/sub-michelle_ses-S001_task-egg_pilot_run-003_eeg.xdf";
stream = 2; % which stream in the xdf file is EGG/audio
channel = 1; % which channel of EGG/audio is EGG


%%% extract EGG from xdf file
xdf = load_xdf(filename); 
egg = xdf{stream}.time_series(channel,:);

%%% get markers from EGG
windows = get_windows(egg); % candidate windows to search for voicing onset
markers = get_markers(egg, windows); % exact timestamps of voicing onset


%%% save as mat object that can be uploaded to EEGLab
tags = to_eeglab(markers):
tmp = char(filename);
saveName = strcat(tmp(1:end-3), "_tags.mat");
save(savename, tags); % overwrites file "savename" if already there