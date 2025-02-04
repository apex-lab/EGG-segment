function [Fo,Oq,Oqval,DEOPA,goodperiods,OqS,OqvalS,DEOPAS,goodperiodsS,simppeak,SIG,AUD,dSIG,SdSIG] = ...
    FO(COEF,pathEGG,EGGfilename,time,method,propthresh,resampC,maxF)

% FO: detection of Fundamental frequency and Open quotient on the basis of the
% derivative of the electroglottographic signal.
% This is the script that calls the various functions for analysis of the
% electroglottographic signal.
% 
% The sequence of operations is as follows:
% - the function CRO detects the points where the DEGG signal crosses the threshold
% set for peak detection, and calls the function RIM which determines where peaks
% begin and end
%
% - the function AMPOS reinterpolates the signal within the peak regions (to
% obtain a more accurate measurement of peak height) and calls the function
% PEAKSHAPE to detect the number of summits and the ratio of the amplitude of
% the summits
%
% - the function DETECTMULT treats double peaks of another kind: double peaks
% that are almost completely distinct, and belong in different "peak bunches"
% (regions created by CRO), but which are too close for their Fo to make sense,
% and are thus considered as making up one double/multiple peak. 
% There are thus two vectors containing information on double peaks: verif, for
% peaks which are unique at threshold level and fork at a higher level; and
% doublepeaks for peaks which fork below threshold level.
%
% - the function SIMP calculates an approximative Fo value.


% retrieving user choice for smoothing step. Reminder: 0 means no smoothing; 1
% means smoothing 1 point to the left and right, i.e. over 3 data points; 2
% means smoothing 2 points to the left and right, i.e. over 5 data points, etc.
C_SMOO = COEF(2);

% retrieving user choice for amplitude threshold setting method
toggle = COEF(3);

% retrieving user choice for amplitude threshold 
AMP = COEF(4);


%%%%%%%%% loading relevant portion of EGG signal
% - <T>: vector containing time of beginning and end of interval.
% T is given in seconds. 
% - <pathEGG>: string containing path to folder containing EGG file
SIG = [];
% finding out the number of channels in signal
tmp = audioread([pathEGG EGGfilename]);
siz = size(tmp);
% if there is a single channel: no difficulty.
[SIG,FS] = audioread([pathEGG EGGfilename],[round(time(1) * COEF(1)) round(time(2) * COEF(1))]);
% if the signal contains two or more channels: choosing the second channel
% (right channel of stereo file) by convention.
if siz(2) > 1
    AUD = SIG(:,1);
    SIG = SIG(:,2);
end

% Placing the sampling rate in first slot of <COEF> vector
COEF(1) = FS;

% Sampling period: (T for: period, s for: sampling) 
Ts = 1 / COEF(1);

% check that the signal is Mono; if it is stereo: de-multiplexing it
[S,P] = size(SIG);
% In case there are two or more columns in the matrix: this means that there are
% two or more channels in the data, not simply one EGG channel. In the present
% state of the programme, the user is asked which channel to select; the answer
% can also be fixed, by the following lines:
% - to select the first column (EGG in left channel):
% SIG = SIG(:,1);
% - to select the second column (EGG in right channel):
% SIG = SIG(:,2);
if P > 1
    for z = 1:P
        figure
        plot(SIG(:,z))
        xlabel(['Signal in channel ',num2str(z)])
    end
    GoodChannel = input('Which is the channel containing the EGG signal? (number below figure) > ');
    SIG = SIG(:,GoodChannel);
end

%%%% calculating the derivative of the signal
% <dSIG> is the first derivative of <SIG>. No smoothing is done at this stage, as the
% detection of the closing peaks is best done using the unsmoothed signal. If a
% smoothing step has been specified, it is used later: in the detection of opening peaks.
dSIG = [];
for w = 1 : length(SIG) - 1
   dSIG (w) = SIG (w + 1) - SIG (w);
end

%%%% smoothing the derivative of the signal
% retrieving the smoothing step specified by the user
C_SMOO = COEF(2);
% smoothing
if C_SMOO > 0
    SdSIG = smoo(dSIG,C_SMOO);
else
    SdSIG = dSIG;
end


% detecting points where the DEGG signal crosses the threshold; this is done
% using the smoothed signal, otherwise the number of crossings may be very high
% due to a saw-like shape of the signal
[rims] = CRO(SdSIG,COEF);

% detection of the amplitude and position of the peaks (on the reinterpolated signal)
[Tgci,valid,validtime,numberofpeaks] = AMPOS(SIG,rims,resampC,Ts,method,propthresh);

% detection of double / multiple closing peaks ("peak clusters")
doublepeaks = detectmult(Tgci,maxF);

% choice of closing peaks, creating a matrix with only one maximum per cycle. 
[simppeak,BUND] = simp(Tgci,doublepeaks,method);

%%%%%%%%%%% Calculating Fo on the basis of the unique peaks
Fo = [];
for w = 1:length(simppeak(:,1)) - 1
    Fo(w) = 1 / (simppeak(w + 1,1) - simppeak(w,1));
end

% Retrieving opening peaks where possible on unsmoothed signal
[Oq,Oqval,DEOPA,goodperiods] = OP(simppeak,SIG,dSIG,valid,doublepeaks,COEF,resampC,Ts,method);

%%% Second call to the function OP, with smoothed signal
[OqS,OqvalS,DEOPAS,goodperiodsS] = OP(simppeak,SIG,SdSIG,valid,doublepeaks,COEF,resampC,Ts,method);