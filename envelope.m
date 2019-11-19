addpath ./Naplib/MATLAB/Preprocessing
stream = 1; % stream for eeg
C3 = xdf{stream}.time_series(36,:) - mean(xdf{stream}.time_series, 1);
t = xdf{stream}.time_stamps;
mark_t = xdf{3}.time_stamps;
m = 1:length(mark_t);
for i = 1:length(mark_t)
    m(i) = find(t > mark_t(i), 1);
end

%% filter EEG
d = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
               'DesignMethod','butter','SampleRate',48000);
C3 = filtfilt(d,C3);
d = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',119,'HalfPowerFrequency2',121, ...
               'DesignMethod','butter','SampleRate',48000);
C3 = filtfilt(d,C3);
d = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',179,'HalfPowerFrequency2',181, ...
               'DesignMethod','butter','SampleRate',48000);
C3 = filtfilt(d,C3);
d = designfilt('bandstopiir','FilterOrder',2, ...
               'HalfPowerFrequency1',239,'HalfPowerFrequency2',241, ...
               'DesignMethod','butter','SampleRate',48000);

%%
m = m(5:end-5);
M = zeros(length(m), 501);

%%

for i = 1:length(m)
    seg = C3(m(i) - 8*3500:m(i) + 8*3500);
    env1 = EcogExtractHighGamma(seg, 8000, 1000);
    %plot(-500:500,env(3500:4500));
    %M(i,:) = zscore(env(3500-500:3500));
    env1 = env1(3500 - 300:3500+200);
    p = 1:length(env1);
    for j = 1:length(env1)
        p(j) = sum(env1 < env1(j))/length(env1); % percentile rank each value
    end
    %q = quantile(env, 0.9);
    %range = max(env(:)) - min(env(:));
    %env = (env - min(env(:))) / range;
    M(i,:) = p; % env1/max(abs(env1));
    %pause;
end

%%
A = smooth2a(M, 1,1);
imagesc([-300 200], [1 length(m)], A)

%% plot FFT of EGG

Fs = 48000;            % Sampling frequency                    
T = 1/Fs;             % Sampling period       
L = length(egg);             % Length of signal
t = (0:L-1)*T;        % Time vector

Y = fft(egg);

P2 = abs(Y/L);
P1 = P2(1:L/2+1);   
P1(2:end-1) = 2*P1(2:end-1);

f = Fs*(0:(L/2))/L;
plot(f(1:30000),P1(1:30000)) 
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')


