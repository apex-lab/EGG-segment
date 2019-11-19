% creates markers for the onset of voicing from an EGG time-series stored
% in an xdf file output by labstreaminglayer
% Tested with Matlab Version 9.6.0.1150989 (R2019a) Update 4

%% hard coded variables
filepath = '~/Documents/EGG/sub-P008/ses-S001/eeg/sub-P008_ses-S001_task-fastHum_run-001_eeg.xdf';
stream = 2; % which stream in the xdf file is EGG/audio
channel = 1; % which channel of EGG/audio is EGG

addpath('functions', 'peakdet2', 'xdf-Matlab')
    
%% extract EGG from xdf file
xdf = load_xdf(filepath, 'HandleJitterRemoval', false); 
egg = xdf{stream}.time_series(channel,:);
egg_t = xdf{stream}.time_stamps;

%% reverse filter to correct phase distortion from hardware filter
x = fliplr(egg); % we apply forward filter to reverse-time EGG
% single pole reverse filter 
y = highpass(x, 20, 48000); % our EGG amp lets you choose between 10 & 20hz
egg = fliplr(y);
egg = lowpass(egg, 1000, 48000);
% d = designfilt('bandstopiir','FilterOrder',2, ...
%                'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
%                'DesignMethod','butter','SampleRate',48000);
% egg = filtfilt(d,egg);
% d = designfilt('bandstopiir','FilterOrder',2, ...
%                'HalfPowerFrequency1',119,'HalfPowerFrequency2',121, ...
%                'DesignMethod','butter','SampleRate',48000);
%egg = filtfilt(d,egg);
clear x y %d

%% get time windows of interest for EGG analysis 
windows = get_windows(egg); % candidate windows to search for voicing onset
%windows(:,2) = windows(:,2) + 500;

%% get time stamps of first glottal closure in each window
indices = get_markers(egg, windows);
timestamps = egg_t(indices + 1);
timestamps = timestamps(timestamps ~= 0); % remove caught errors

%% add glottal closures to xdf object as marker stream and save as mat
s = length(xdf) + 1;
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