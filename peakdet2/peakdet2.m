% Complete version, October 2004, with minor changes in July 2005 and July
% 2007. Written by Alexis Michaud.
%
% Edition by Sergi Abadal, for Daniel Recasens on April-July 2009.
%
% Software for the semi-automatic analysis of the electroglottographic
% signal for a set of continuously voiced items: for example, vowels,
% syllable rhymes, or sustained voiced sounds containing up to <MaxPerN>
% glottal cycles. The value of <MaxPerN> is set at 100 by default.
%
% Takes as input 
% - an EGG signal: either a MONO wav file, or in the right channel of a
% STEREO wav file. Any sampling rate is possible. Recommended: 44,100 Hz or
% higher sampling frequency.
% - a file containing the information concerning the beginning and end of
% each item. Originally designed for reading a .txt file containing a list
% of Regions created with the software SoundForge, as below: 
% Name                                  In           Out      Duration
% -------------------------- ------------- ------------- -------------
% 1                        00:00:03,273  00:00:03,363  00:00:00,090
% 2                        00:00:03,388  00:00:03,490  00:00:00,102
% where "1" and "2" are labels chosen by the user, and the times are given
% as: hours:minutes:seconds,milliseconds.
% 
% Have a look at the comments inside the script <peakdet.m> for finding out
% about parameters that you can modify. For instance, the
% electroglottographic signal is reinterpolated at the closing and opening
% peaks for accurate peak detection; the coefficient for reinterpolation is
% set at 100 by default; this can be modified by the user, to define it as
% a function of the sampling frequency of the original signal, or in
% relation to the fundamental frequency of the sample under analysis.

function peakdet2(varargin)

% % clearing workspace
% clear

% times that user has chosen to save
savings = 0;

% setting resampling coefficient
resampC = 100;

% initializing matrix; assumption: there will be no more than 100 periods in each
% analyzed token; this value, which is sufficient for single syllables, 
% can be changed below, in order to treat longer intervals of voicing at one go:
MaxPerN = 100;
data(MaxPerN,10,1) = 0; 

% setting coefficient for recognition of "double peaks": for closings, is 0.5,
% following Henrich N., d'Alessandro C., Castellengo M. et Doval B., 2004, "On
% the use of the derivative of electroglottographic signals for characterization 
% of non-pathological voice phonation", Journal of the Acoustical Society of America, 
% 115(3), pp. 1321-1332.
propthresh = 0.5;

if nargin>0
    action = upper(varargin{1});
else
    action = 'PRINCIPAL';
end

switch action
    
    case 'PRINCIPAL'
        % indicating path to EGG file
        % disp('Please paste complete path to EGG file here (e.g. D:\EGGsession1\sig.wav)')
        % pathEGG = input(' > ','s');
        [EGGfilename,pathEGG] = uigetfile('*.*','Please choose the EGG file to be downloaded');

        % finding out the characteristics of the sound file
        [Y,FS] = audioread([pathEGG EGGfilename]);
        player = audioplayer(Y(:,1),FS);


        %%% loading file that contains beginning and endpoint of relevant
        %%% portions of the signal, and the number of the item
        % If there exists a text file with the same name as the file of the
        % recordings, in the same folder, this file is loaded; otherwise the user
        % indicates the path to the text file.
        if exist([pathEGG EGGfilename(1:(length(EGGfilename) - 4)) '.txt'])
            textpathfile = pathEGG;
            textfile = [EGGfilename(1:(length(EGGfilename) - 4)) '.txt'];
        else
            [textfile,textpathfile] = uigetfile([pathEGG '*.*'],'Please choose the text file that contains the time boundaries of signal portions to be analyzed',pathEGG);
        end

        % Reading the text file, and retrieving the beginning and end of relevant
        % intervals
        [LENG,numb] = beginend([textpathfile textfile]);
        % LENG = load([textpathfile textfile]);
        % retrieving number of lines and columns in LENG:
        [NumL,NumC] = size(LENG);

        % computing total number of syllables
        maxnb = NumL;

        disp(' ')
        aaa = sprintf('***** Enter the item which you want to begin from (1 to %d)',maxnb);
        disp(aaa)
        beginning = input('Your choice: > ');

        % loop for syllables
        for i = beginning:maxnb
            % loop allowing the user to modify the parameters in view of the results.
            % Uses a variable <SATI>, for SATIsfactory. It is set at 0 to begin with.
            SATI = 0;
            err = 0;

            % initialization of an extra variable used to know whether changes
            % must be made in the Oq values. Set at 0 to begin with.
            OqCHAN = 0;

            % assigning default values to <COEF> vector, used in FO: sampling frequency of the
            % electroglottographic recording;
            % smoothing step specified by user; 1, to indicate that the amplitude threshold
            % for peak detection will be set automatically; the fourth value is the threshold value
            % set manually; left at 0 to begin with, as the value will be set automatically
            % and not manually
            COEF = [FS 0 1 0];

            % setting the value for threshold for peak detection: by default, half
            % the size of the maximum peak
            propthresh = 0.5;

            while SATI == 0
                % retrieving time of beginning and end, 
                % and converting from milliseconds to seconds
                time = [LENG(i,1)/1000 LENG(i,2)/1000];
                TIME = LENG(i,2)-LENG(i,1);

                % clearing previous results
                clear datafile

                % In case a number had been given to the item in the text file: displaying it 
                if ~isempty(numb)
                    disp(' ')
                    disp(' ')
                    disp(['Currently treating item that carries label ' num2str(numb(i)) '.'])
                else
                    disp(' ')
                    disp(' ')
                    disp(['Currently treating item on line ' num2str(i) ' of input text file.'])
                end



            [SIGbis,FS] = audioread([pathEGG EGGfilename],[round(time(1) * COEF(1)) round(time(2) * COEF(1))]);
            h1 = figure(1);
            clf
            title_mod = sprintf('EGG preview of item %d',i);
            set(h1,'Name',title_mod);
            Xaxis = linspace(0,TIME,size(SIGbis,1));
            plot(Xaxis,SIGbis(:,2));


        % choice of method chosen to handle double closing peaks in Fo calculation:
        % if <method == 0>: selecting highest of the peaks
        % if <method == 1>: selecting first peak
        % if <method == 2>: selecting last peak
        % if <method == 3>: using barycentre method
        % if <method == 4>: exclude all double peaks
        disp(' ')
        disp('***** In case of multiple closing peaks, the value selected in peak detection, can correspond to')
        disp('The highest peak (enter 0)')
        disp('The first peak (enter 1)')
        disp('The last peak (enter 2)')
        disp('A value in-between (barycentre method; enter 3)')
        disp('None of them (exclude from calculation; enter 4)')
        method = input('Your choice: > ');

        % choosing maximum possible Fo
        disp(' ')
        disp('****** The detection of double peaks requires an F0 ceiling')
        disp('Which value do you propose for this ceiling?')
        disp('(i.e. a value slightly above the maximum plausible F0 that could be produced by the speaker)')
        disp('Recommended value: 500 Hz.')
        maxF = input('Your choice (in Hz): > ');

        % choosing the smoothing step
        disp(' ')
        disp('***** Number of points for DEGG smoothing ')
        disp('(0: no smoothing, 1: 1 point to the right and left, etc.)')
        disp('Recommended value: 1; for noisy signals: up to 3')
        COEF(2) = input('Your choice: > ');

        % choosing to show 
        disp(' ')
        disp('***** Put markers')
        disp('Only in the first and last valid peaks (enter 0)')
        disp('In all valid peaks (enter 1)')
        pics = input('Your choice: > ');
        disp(' ')
        disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
        disp(' ')


                %%%%%%%%%%%%%% running main analysis programme
                [Fo,Oq,Oqval,DEOPA,goodperiods,OqS,OqvalS,DEOPAS,goodperiodsS,simppeak,SIG,...
                    AUD,dSIG,SdSIG] = FO(COEF,pathEGG,EGGfilename,time,method,propthresh,resampC,maxF);	


                %%% Placing main results in a single matrix
                % Structure of matrix: 
                % - beginning and end of period : in 1st and 2nd columns
                % - Fo : 3rd column
                % - DECPA : 4th column
                % - Oq determined from raw maximum, and DEOPA : 5th and 6th columns
                % - Oq determined from maximum after smoothing : 7th column
                % - Oq determined from peak detection : 8th and 9th colums without smoothing
                % and with smoothing, respectively.
                datafile = [];
                if isempty(Fo)
                    disp('No single F0 value calculated for this item. Press any key to continue.')
                    pause
                    err = 1;
                    SATI = 1;
                else
                    for k = 1:length(Fo)
                        datafile(k,1) = simppeak(k,1);
                        datafile(k,2) = simppeak(k + 1,1);
                        datafile(k,3) = Fo(k);
                        datafile(k,4) = simppeak(k,2);
                        datafile(k,5) = Oq(k);
                        datafile(k,6) = DEOPAS(k);
                        datafile(k,7) = OqS(k);
                        datafile(k,8) = Oqval(k);
                        datafile(k,9) = OqvalS(k);
                    end

                    set(0, 'DefaultAxesFontName', 'Tahoma')
                    set(0, 'DefaultAxesFontSize', 8)

                    %%%%%%%%%%%%%%%%%%%%%%% visual check of results, and manual corrections
                    h1 = figure(1);
                    clf
                    title_mod = sprintf('Item %d',i);
                    set(h1,'Name',title_mod);
                    plot(OqS,'-pb')
                    hold on
                    plot(Oq,'*g')
                    plot(Oqval,'or')
                    plot(OqvalS,'sk')
                    % plotting Fo
                    plot(Fo,'-pb')
                    xlabel('Results of analysis. Fundamental frequency, and Oq calculated in 4 ways.')
                    ylabel('Fo in Hz; Oq in %')
                    hold off
                    %%% plotting signals (EGG and dEGG), so the user can check visually the shape
                    %%% of the peaks. New feature, added in August 2007: the limits
                    %%% of the voiced portion as detected by the script are
                    %%% indicated on the figures showing the EGG and dEGG signals.
                    h2 = figure(2);
                    N = 64;
                    zoom off
                    clf

                    title_mod = sprintf('PeakdetMOD Figure for EGG file "%s", item %d [%5.2f to %5.2f (ms)]',EGGfilename,i,time(1)*1000,time(2)*1000);
                    screen = get(0, 'ScreenSize');
                    set(h2,'KeyPressFcn',@printfig,'Name',title_mod,'MenuBar','none','OuterPosition',[0.1*screen(3) 0.1*screen(4) 0.85*screen(3) 0.85*screen(4)])
                    load('MyColormaps','mycmap')

                    axiSPEC = subplot('Position',[0.05 0.6 0.9 0.38]);
                        hspec = myspecgram(AUD,64,FS,blackman(64));
                        set(figure(2),'Colormap',mycmap);
                        ylabel('Spectrogram (64)')
                        hold(axiSPEC,'on');
                        Hmarker(1,1) = plot(axiSPEC,[TIME/3 TIME/3],[0 FS/2],'-g','ButtonDownFcn','peakdet2(''DOWN'',1)');
                        Hmarker(1,2) = plot(axiSPEC,[2*TIME/3 2*TIME/3],[0 FS/2],'-g','ButtonDownFcn','peakdet2(''DOWN'',2)');
                        hold(axiSPEC,'off');

                    Xaxis = linspace(0,TIME,size(SdSIG,2));
                    ax(1) = subplot('Position',[0.05 0.07 0.9 0.155]);
                    zoom off
                    plot(Xaxis,SdSIG);
                    xlabel('Time (ms)')
                    ylabel('DEGG')
                    xlim([0 TIME]);
                    hold on
                    % showing where the first and last closures have been detected
                    firstclo = datafile(1,1) * 1000;
                    ylim = get(ax(1),'ylim');
                    minmark = 0.6*ylim(1);
                    maxmark = 0.6*ylim(2);
                    plot([firstclo firstclo],[minmark maxmark],'-r')
                    lastclo = datafile(length(nonzeros(datafile(:,2))),2) * 1000;
                    clo =0;
                    if pics==1
                        for k = 1:length(Fo)
                            clo = simppeak(k,1)* 1000;
                            plot([clo clo],[minmark maxmark],'-r')
                        end
                    end
                    plot([lastclo lastclo],[minmark maxmark],'-r')
                    Hmarker(2,1) = plot(ax(1),[TIME/3 TIME/3],ylim,'-g','ButtonDownFcn','peakdet2(''DOWN'',1)');
                    Hmarker(2,2) = plot(ax(1),[2*TIME/3 2*TIME/3],ylim,'-g','ButtonDownFcn','peakdet2(''DOWN'',2)');
                    hold off

                    ax(2) = subplot('Position',[0.05 0.24 0.9 0.155]);
                    xlim([0 TIME]);
                    Xaxis = linspace(0,TIME,size(SIG,1));
                    hegg = plot(Xaxis,SIG);
                    hold on
                    set(gca,'xtick',[])
                    ylabel('EGG')
                    % showing where the first and last closures have been detected
                    ylim = get(ax(2),'ylim');
                    minmark = 0.6*ylim(1);
                    maxmark = 0.6*ylim(2);
                    plot([firstclo firstclo],[minmark maxmark],'-r')
                    if pics==1
                        for k = 1:length(Fo)
                            clo = simppeak(k,1)* 1000;
                            plot([clo clo],[minmark maxmark],'-r')
                        end
                    end
                    plot([lastclo lastclo],[minmark maxmark],'-r')
                    Hmarker(3,1) = plot(ax(2),[TIME/3 TIME/3],ylim,'-g','ButtonDownFcn','peakdet2(''DOWN'',1)');
                    Hmarker(3,2) = plot(ax(2),[2*TIME/3 2*TIME/3],ylim,'-g','ButtonDownFcn','peakdet2(''DOWN'',2)');
                    hold off

                    ax(3) = subplot('Position',[0.05 0.41 0.9 0.155]);
                    Xaxis = linspace(0,TIME,size(AUD,1));
                    xlim([0 TIME]);
                    plot(Xaxis,AUD);
                    set(ax(3),'xtick',[])
                    ylabel('Audio')
                    ylim = get(ax(3),'ylim');
                    hold on
                    Hmarker(4,1) = plot(ax(3),[TIME/3 TIME/3],ylim,'-g','ButtonDownFcn','peakdet2(''DOWN'',1)');
                    Hmarker(4,2) = plot(ax(3),[2*TIME/3 2*TIME/3],ylim,'-g','ButtonDownFcn','peakdet2(''DOWN'',2)');
                    hold off
                    
                    linkaxes(ax,'x');
%                     cc1 = CreateCursor;
%                     cc2 = CreateCursor;

                   txt1 = sprintf('x1 = %5.2f',TIME/3);
                   txt2 = sprintf('x2 = %5.2f',2*TIME/3);
                   txt3 = sprintf('/\\x = %5.2f',TIME/3);

                    men = uimenu('Label','Play');
                    uimenu(men,'Label','Play Entire Original WAV','Callback','peakdet2(''PLAY'',1)');
                    uimenu(men,'Label','Play Current Cut','Callback','peakdet2(''PLAY'',2)');
                    uimenu(men,'Label','Play Selection','Callback','peakdet2(''PLAY'',3)');

                    men2 = uimenu('Label','Zoom');
                    uimenu(men2,'Label','Zoom In','Callback','peakdet2(''ZOOM'',1)');
                    uimenu(men2,'Label','Zoom Out','Callback','peakdet2(''ZOOM'',2)');

                    men3 = uimenu('Label','Spectrogram');
                    s(6) = uimenu(men3,'Label','OFF','Callback','peakdet2(''SPEC'',0)');
                    s(1) = uimenu(men3,'Label','32','Callback','peakdet2(''SPEC'',1)');
                    s(2) = uimenu(men3,'Label','64','Checked','On','Callback','peakdet2(''SPEC'',2)');
                    s(3) = uimenu(men3,'Label','128','Callback','peakdet2(''SPEC'',3)');
                    s(4) = uimenu(men3,'Label','256','Callback','peakdet2(''SPEC'',4)');
                    s(5) = uimenu(men3,'Label','512','Callback','peakdet2(''SPEC'',5)');

                    if pics==1
                        redmarktxt = sprintf('First to Last: %5.2f',lastclo-firstclo);
                    else
                        redmarktxt = sprintf('Red Marks Distance: %5.2f',lastclo-firstclo);
                    end

                    redmarktext = uicontrol('Style','text','Units','normalized','position',[0.05 0.01 0.3 0.03],'String',redmarktxt);

                    text(1) = uicontrol('Style','text','Units','normalized','position',[0.55 0.01 0.08 0.03],'String',txt1);
                    text(2) = uicontrol('Style','text','Units','normalized','position',[0.65 0.01 0.08 0.03],'String',txt2);
                    text(3) = uicontrol('Style','text','Units','normalized','position',[0.75 0.01 0.08 0.03],'String',txt3);


                 x(1) = TIME/3;
                 x(2) = 2*TIME/3;

                 state = struct('AX', ax, ...
                         'AXISPEC', axiSPEC, ...
                         'HSPEC', hspec, ...
                         'HEGG', hegg, ...
                         'HMARKER', Hmarker, ...
                         'XPOS', x, ...
                         'TEXT', text, ...
                         'TIMES', time, ...
                         'TIME', TIME, ...
                         'AUD', AUD, ...
                         'MYCMAP', mycmap, ...
                         'S', s, ...
                         'PLAYER', player);

                       
                       
                set(h2,'userdata',state);





              mode = input('Do you wish to proceed to modify the results? (y/n) > ','s');

              if strcmp(mode,'y') | strcmp(mode,'yes')

                    cornb = 4;
                    while ~ismember(cornb,[0 1 2 3])
                        % manual correction of Fo
                        disp('Fundamental frequency values: ')
                        disp(rot90(datafile(:,3)))
                        disp('If all the Fo values are correct, type 0 (zero).')
                        disp(' ')
                        disp('The red lines on figures 2 and 3 indicate the first and last detected periods.')
                        disp('If some of the periods went undetected, or extra periods were erroneously detected, enter 1 (one).')
                        disp('You will then be asked to change the values of some of the settings.')
                        disp(' ')
                        disp('If you wish to correct some of the F0 values, enter 2.')
                        % It may happen that the portion of the EGG signal that was selected
                        % when placing the time boundaries includes a preceding glottal closure
                        % that should not in fact count as part of the voiced portion under
                        % investigation. In that case, it is useful for the user to be able to
                        % exclude this extra closing, which results in an extra period at
                        % beginning of syllable giving a wrong notion as to the duration of the
                        % syllable and the initial Fo and Oq values.
                        cornb = input('If the coefficient is correct but the initial/final period(s) must be suppressed, enter 3. > ');
                    end
                    if cornb == 0
                        % setting coefloop at 0, to exit the second "while" loop
                        coefloop = 0;
                        % setting <SATI> at 1, to exit the first "while" loop
                        SATI = 1;
                        corr = 0;
                        % setting variable <OqCHAN> so that Oq values can be checked
                        % manually:
                        OqCHAN = 1;
                    elseif cornb == 1
                        coefloop = 0;
                        while coefloop == 0
                            disp(' ')
                            disp(' ')
                            disp('If too many periods were detected, you may change the threshold for maximum F0.')
                            disp(['The present threshold is: ',num2str(maxF)]) 
                            maxF = input('New value for the threshold (in Hz): > ');
                            coefloop = 1;
                            disp(' ')
                            disp(' ')
                            disp('If too few periods were detected, you may change the threshold for peak detection.')
                            if COEF(3) == 1
                                tre1 =  - min(SdSIG);
                                tre2 = max(SdSIG) / 4;
                                if tre1<tre2
                                    msg = sprintf('The present threshold is: %.4f (highest negative -opening- peak)',tre1);
                                else
                                    msg = sprintf('The present threshold is: %.4f (25% of highest positive -closing- peak)',tre2);
                                end
                                disp(msg);
                            else
                                disp(['The present threshold is: ',num2str(COEF(4))]) 
                            end
                            disp(' - Enter a new value (absolute value; refer to figure to choose) for the threshold; or')
                            disp(' - press RETURN to leave threshold unchanged; ')
                            disp(' - type 0 in case the syllable needs to be analyzed as several distinct portions, i.e. ')
                            disp('if the discrepancy in peak amplitude is such that no setting gives satisfactory result')
                            coefchange = input('for the entire syllable. > ');
                            if coefchange ~= 0
                                COEF(3) = 0;
                                if and (coefchange > COEF(4),COEF(4) > 0)
                                    disp('Warning: the new value is higher than the value previously set, ')
                                    confir = input(['which was ' num2str(COEF(4)) '. Are you sure? y/n > '],'s');
                                    if confir == 'y'
                                        COEF(4) = coefchange;
                                        propthresh = coefchange / max(SdSIG);
                                    else
                                        coefchange = input ('Set new value > ');
                                        COEF(4) = coefchange;
                                        propthresh = coefchange / max(SdSIG);
                                    end
                                else
                                    COEF(4) = coefchange;
                                    propthresh = coefchange / max(SdSIG);
                                end
                                corr = 0;
                                coefloop = 1;
                            elseif coefchange == 0
                                disp('Enter the limit between the two portions to analyze (in samples; refer to')
                                bound = input('the axis of the figure showing the DEGG and EGG signals) > ');
                                coefchange1 = input('Amplitude for first part of syllable: ');
                                coefchange2 = input('Amplitude for second part of syllable: ');
                                COEF(3) = 0;

                                % clearing previous results
                                clear datafile

                                %%%%%%%%%%%%%% running main analysis programme
                                [Fo,Oq,Oqval,DEOPA,goodperiods,OqS,OqvalS,DEOPAS,goodperiodsS,simppeak,SIG,AUD,dSIG,SdSIG] = FO(COEF,pathEGG,EGGfilename,time,method,propthresh,resampC,maxF)                    
                                % setting a counter for number of periods placed in results
                                % matrix <datafile>
                                chosen = 0;
                                for ii = 1:length(Fo)
                                    if simppeak(ii,1) < bound/FS
                                        chosen = chosen + 1;
                                        datafile(chosen,1) = simppeak(ii,1);
                                        datafile(chosen,2) = simppeak(ii + 1,1);
                                        datafile(chosen,3) = Fo(ii);
                                        datafile(chosen,4) = simppeak(ii,2);
                                        datafile(chosen,5) = Oq(ii);
                                        datafile(chosen,6) = DEOPAS(ii);
                                        datafile(chosen,7) = OqS(ii);
                                        datafile(chosen,8) = Oqval(ii);
                                        datafile(chosen,9) = OqvalS(ii);
                                    end
                                end
                                % changing threshold
                                COEF(4) = coefchange2;

                                %%%%%%%%%%%%%% running main analysis programme
                                [Fo,Oq,Oqval,DEOPA,goodperiods,OqS,OqvalS,DEOPAS,goodperiodsS,simppeak,SIG,AUD,dSIG,SdSIG] = FO(COEF,pathEGG,EGGfilename,time,method,propthresh,resampC,maxF)                    
                                % assigning complementary results in file
                                for ii = 1:length(Fo)
                                    if simppeak(ii,1) > (bound/FS)
                                        chosen = chosen + 1;
                                        datafile(chosen,1) = simppeak(ii,1);
                                        datafile(chosen,2) = simppeak(ii + 1,1);
                                        datafile(chosen,3) = Fo(ii);
                                        datafile(chosen,4) = simppeak(ii,2);
                                        datafile(chosen,5) = Oq(ii);
                                        datafile(chosen,6) = DEOPAS(ii);
                                        datafile(chosen,7) = OqS(ii);
                                        datafile(chosen,8) = Oqval(ii);
                                        datafile(chosen,9) = OqvalS(ii);
                                    end
                                end
                                % plotting the results
                                figure(1)
                                clf
                                plot(datafile(:,7),'-pb')
                                hold on
                                plot(datafile(:,5),'*g')
                                plot(datafile(:,8),'or')
                                plot(datafile(:,9),'sk')
                                % plotting Fo
                                plot(datafile(:,3),'-pb')

                                % setting the <corr> variable so the user can check the results
                                corr = 1;
                                coefloop = input('Were the coefficients adequate? Enter 1 if yes, 0 if no. > ')
                            end
                        end
                    elseif cornb == 2
                        corr = 1;
                    elseif cornb == 3
                        lopoff = 0;
                        while lopoff == 0
                            disp('  ')
                            disp('To suppress first period, enter 1. To suppress last period, enter 9.');
                            PERN = input('If no period suppression is needed, enter 0. > ');
                            % if the first line must be suppressed:
                            if PERN == 1
                                TRANS = [];
                                TRANS = datafile(2:length(datafile(:,1)),:);
                                datafile = [];
                                datafile = TRANS;
                            elseif PERN == 9
                            % if the last line must be suppressed:
                                TRANS = [];
                                TRANS = datafile(1:length(datafile(:,1)) - 1,:);
                                datafile = [];
                                datafile = TRANS;
                            else
                                lopoff = 1;
                            end
                            % plotting the results
                            figure(1)
                            clf
                            plot(datafile(:,7),'-pb')
                            hold on
                            plot(datafile(:,5),'*g')
                            plot(datafile(:,8),'or')
                            plot(datafile(:,9),'sk')
                            % plotting Fo
                            plot(datafile(:,3),'-pb')
                        end
                        corr = 1;
                    end

                    % Manual corrections if desired
                    while corr == 1
                        % showing the Fo values
                        % (after 90� rotation so the indices will be displayed)
                        if ~isempty(numb)
                            disp(['Item that carries label ' num2str(numb(i)) '.'])
                        else
                            disp(['Item on line ' num2str(i) ' of input text file.'])
                        end
                        disp('Fundamental frequency values: ')
                        disp(rot90(datafile(:,3)))
                        cornb = input('If an Fo value needs to be corrected manually, enter its index in vector. Otherwise enter 0. > ');
                        if cornb > 0
                            disp(['The Fo value was ',num2str(datafile(cornb,3)),'.'])
                            newvalue = input('Set new Fo value : ');
                            datafile(cornb,3) = newvalue;
                            figure(4)
                            clf
                            plot(nonzeros(datafile(:,1)),nonzeros(datafile(:,3)),'pb')
                            if ~isempty(numb)
                                disp(['Item that carries label ' num2str(numb(i)) '.'])
                            else
                                disp(['Item on line ' num2str(i) ' of input text file.'])
                            end
                            disp('Fundamental frequency values: ')
                            disp(rot90(datafile(:,3)))
                        else
                            corr = 0;
                        end
                        % signalling that the programme does not need to be run again
                        SATI = 1;
                        % using an extra variable passed on below to know whether changes
                        % must be made in the Oq values
                        OqCHAN = 1;
                    end

                    if OqCHAN == 1
                        choiceOq = 10;
                        while ~ismember(choiceOq,[0:4])
                            disp(['Item : ',num2str(i)])
                            disp('To choose Oq values calculated by maxima on unsmoothed signal (in green), enter 0.')
                            disp('To choose Oq values calculated by maxima on smoothed signal (in blue), enter 1.')
                            disp('To choose Oq values calculated by peak detection (in red), enter 2.')
                            disp('To choose Oq values calculated by peak detection on smoothed signal (in black), enter 3.')
                            disp('To exclude all Oq values for this item, enter 4.')
                            choiceOq = input('Your choice : ');
                        end

                        % placing chosen Oq values in 10th column of matrix.
                        if choiceOq == 0
                            for k = 1:length(datafile(:,1))
                                 datafile(k,10) = datafile(k,5);
                            end
                        elseif choiceOq == 1
                            for k = 1:length(datafile(:,1))
                                 datafile(k,10) = datafile(k,7);
                            end
                        elseif choiceOq == 2
                            for k = 1:length(datafile(:,1))
                                 datafile(k,10) = datafile(k,8);
                            end
                        elseif choiceOq == 3
                            for k = 1:length(datafile(:,1))
                                 datafile(k,10) = datafile(k,9);
                            end
                        elseif choiceOq == 4
                            for k = 1:length(datafile(:,1))
                                 datafile(k,10) = 0;
                            end
                        end

                        % manual correction of open quotient values
                        corr = 1;
                        if choiceOq ~= 4
                            while corr == 1
                                % If not all values have been excluded: listing the Oq values
                                % obtained by the method chosen
                                % (after 90� rotation so the indices will be displayed)
                                disp('Open quotient values : ')
                                disp(rot90(datafile(:,10)))
                                disp('If values need to be suppressed, enter their index in vector:')
                                disp('for instance, 2 for 2nd value, 5:15 for values from 5 to 15.')
                                cornb = input('If all the values are correct now, type 0. Your choice : ');
                                % looking at whether the user specified one value or several
                                LE = size(cornb);
                                % in case one single value is specified, and this value is zero: stop
                                % corrections.
                                if LE(2) == 1
                                    if cornb == 0
                                        corr = 0;
                                    end
                                end
                                % if one or more non-zero values were given: make
                                % correction.
                                if corr == 1          
                                    if LE(2) == 1
                                        disp(['The specified value was ',num2str(datafile(cornb,10)),'.'])
                                        disp('It is now set at zero, and will be excluded from the calculations.')
                                    else
                                        disp('The specified values were:')
                                        disp(datafile(cornb,10))
                                        disp('They are now set at zero, and will be excluded from the calculations.')
                                    end
                                    disp('Refer to the figure to see modified curve.')
                                    datafile(cornb,10) = 0;
                                    figure(1)
                                    clf
                                    plot(datafile(:,1),datafile(:,10),'pb')
                                end
                            end
                        end
                    end
              end

              disp(' ')
              disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
              disp(' ')
              disp('The parameters used were:')
              disp(' ')
              disp('** Multiple Closing Peaks Selection:')
              switch method
                  case 0
                    disp('   Highest peak (0)')
                  case 1
                    disp('   First peak (1)')
                  case 2
                    disp('   Last peak (2)')
                  case 3
                    disp('   Baricentre method (3)')
                  case 4
                    disp('   Exclude multiple closings (4)')
              end
              disp(' ')
              disp('** F0 Ceiling:')
              disp(maxF)
              disp('** Smoothing value:')
              disp(COEF(2))
              repeat = input('Do you wish to repeat the experiment, for this item? (y/n) > ','s');


              if strcmp(repeat,'y') | strcmp(repeat,'yes')
                SATI = 0;
              else
                  SATI = 1;
              end


                    %%%%%%%%%%%%%% placing results in matrices

                      % checking that there is no doubling of the last line (this occasional
                      % problem results in a bug that I have not identified, which causes
                      % the last line to be written twice into the <datafile> matrix)
                      ld = length(datafile(:,1));
                      if ld > 1
                          if datafile(ld,:) == datafile(ld - 1,:)
                              datafile = datafile(1:ld - 1,:);
                          end
                      end

                      % calculating the number of periods (= nb of lines)
                      period_nb = size(datafile,1);

                      % calculating the number of columns
                      nbcol = length(datafile(1,:));
                      % assigning values in data matrix
                              for q = 1:nbcol
                                for r = 1:period_nb
                                    data(r,q,i) = datafile(r,q);
                                end
                              end
                % end of the condition on non-emptiness of Fo variable              
                end
            % end of the WHILE loop
            end

            % saving the results in a temporary data file; can be recovered in case MatLab
            % suddenly closes (due to error, computer crash, power supply problem...)
            save tempdata data


            disp(' ')
              disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
              disp(' ')
            saving = input('Do you wish to save the results, for this item? (y/n) > ','s');
            if strcmp(saving,'y') | strcmp(saving,'yes')
                savings = savings + 1;

                % If it's the first time to save, filename will be demanded.
                if savings==1
                    [resname, pathname] = uiputfile({'*.mat';'*.txt';'*.*'},...
                        'Save results as :');
                    pospunt = findstr('.',resname);
                    resfile_ext = resname(pospunt+1:length(resname));
                    resfile_name = resname(1:pospunt-1);
                % If not, will follow the first filename
                else
                    resname = sprintf('%s%d.%s',resfile_name,i,resfile_ext);
                end

                % Saving it... differently depending on the file type.
                if strcmp(resfile_ext,'mat')
                         save([pathname resname],'datafile','goodperiods')
                    else
                        fid = fopen([pathname resname],'wt');
                        % Info headers
                        fprintf(fid,'EGG = %s\n',EGGfilename);
                        fprintf(fid,'ITEM = %d\n',i);
                        fprintf(fid,'BEGINNING = %5.2f ms\n',time(1)*1000);
                        fprintf(fid,'END = %5.2f ms\n',time(2)*1000);
                        fprintf(fid,'MULTIPLE CLOSING PEAKS SELECTION = ');
                        switch method
                              case 0
                                fprintf(fid,'Highest peak\n')
                              case 1
                                fprintf(fid,'First peak\n')
                              case 2
                                fprintf(fid,'Last peak\n')
                              case 3
                                fprintf(fid,'Baricentre method\n')
                              case 4
                                fprintf(fid,'Exclude multiple closings\n')
                        end
                        fprintf(fid,'CEILING FREQUENCY USED = %5.2f\n',maxF);
                        fprintf(fid,'PEAK DETECTION THRESHOLD = %5.2f\n',propthresh);
                        if(COEF(2)==0)
                            fprintf(fid,'SMOOTHING = NONE');
                        else
                            fprintf(fid,'SMOOTHING = %d\n\n',COEF(2));
                        end
                        % Datafile
                        fprintf(fid,'DATAFILE\n\n');
                        fprintf(fid,'#\tSimpPeak1\tSimPeak2\tF0\tSimpPeak3\tOq\tDEOPAS\tOqS\tOqval\tOqvalS\n');
                        k=1;
                        for i=1:size(datafile,1)
                            fprintf(fid,'%d\t',k);
                            for j=1:size(datafile,2)
                                fprintf(fid,'%5.4f\t',datafile(i,j));
                            end
                            fprintf(fid,'\n');
                            k = k+1;
                        end

                        % Explanation
                        fprintf(fid,'\n\n');
                        fprintf(fid,'SimPeak1 is the closing-peak time (in seconds)\n');
                        fprintf(fid,'SimPeak2 is the closing-peak time (in seconds) of the next closure\n');
                        fprintf(fid,'F0 is the fundamental frequency calculated for each closure \n');
                        fprintf(fid,'SimPeak3 is the closing-peak amplitude  \n');
                        fprintf(fid,'Oq is the open quotient, using detection by maxima on UNSMOOTHED DEGG signal \n');
                        fprintf(fid,'DEOPAS is the amplitude of the minimum (opening-peak) in each closure\n');
                        fprintf(fid,'OqS is the open quotient, using detection by maxima on SMOOTHED DEGG signal \n');
                        fprintf(fid,'Oqval is the open quotient, using the method listed above on unsmoothed DEGG signal  \n');
                        fprintf(fid,'OqvalS is the open quotient, using the method method listed above on smoothed DEGG signal \n');

                      %  fprintf(fid,'\n\n');
                      %  fprintf(fid,'GOODPERIODS\n\n')
                      %  fprintf(fid,'Beginning\tEnd\n');
                      %  for i=1:size(goodperiods,1)
                      %      for j=1:size(goodperiods,2)
                      %          fprintf(fid,'%5.4f\t',goodperiods(i,j));
                      %      end
                      %      fprintf(fid,'\n');
                      %  end
                end
            end
            disp(' ')
              disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
              disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
              disp(' ')    
        % end of syllable loop
        end

        if (err==0)
            if strcmp(mode,'y') | strcmp(mode,'yes')

            % Calculating the proportion of Oq values that have been excluded manually
            NbOq = length(nonzeros(data(:,5,:)));
            NbExclOq = length(nonzeros(data(:,5,:))) - length(nonzeros(data(:,10,:)));
            RatioExclOq = 100 * (NbExclOq / NbOq);
            disp(['Number of Oq values that have been manually excluded: ' num2str(NbExclOq)])
            disp(['out of a total of ' num2str(NbOq)])
            disp(['i.e. a ratio of ' num2str(RatioExclOq) '%.'])

            end

        %%%%%%% saving the results
        % clearing unnecessary variables
        clear SIG
        clear dSIG
        clear SdSIG
        % disp('Saving the results: ')
        % disp('Please type results file name and complete path (e.g. D:\EGGsession1\results1)')
        % resname = input(' > ','s');


        end

        disp(' ')
        disp(' ')
        disp('Goodbye.')
        disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
        disp(' ')
        
%-----------------------------------------------------------------------------
%	DOWN: to do when the user clicks
    
    case 'DOWN'
        
        % Retrieving the userdata, for later use
        state = get(gcbf, 'userdata');
        xyz = get(gca, 'currentPoint');
        x = xyz(1,1); y = xyz(1,2);
        
        % Putting all markers where the user has clicked (current point)
        for i=1:4
            set(state.HMARKER(i,varargin{2}),'XData',[x x]);
        end
        state.XPOS(varargin{2}) = x; % Updating 'userdata'
        set(gcbf,'userdata',state);
        
        % Refreshing text and palate for the new marker position
        refresh_text;

        % Setting the motion and up mouse functions
        switch varargin{2}
            case 1
                set(gcbf,'windowButtonMotionFcn', 'peakdet2(''MOVE'',1)','windowButtonUpFcn', 'peakdet2(''UP'',1)');   
            case 2
                set(gcbf,'windowButtonMotionFcn', 'peakdet2(''MOVE'',2)','windowButtonUpFcn', 'peakdet2(''UP'',2)');
        end
          
%-----------------------------------------------------------------------------
%	MOVE: to do when the user moves the mouse while clicked.
        
    case 'MOVE'
        
        % Retrieving the userdata, for later use
        state = get(gcbf, 'userdata');
        xyz = get(gca, 'currentPoint');
        lim = get(gca, 'Xlim');
        x = xyz(1,1); y = xyz(1,2);
        
        % Putting all markers where the user points (if it's on sight)
        if(x>lim(1) && x<lim(2))
            for i=1:4
                set(state.HMARKER(i,varargin{2}),'XData',[x x]);
            end
            % Refreshing text and palate for the new marker position
        end
        
        state.XPOS(varargin{2}) = x; % Updating 'userdata'
        set(gcbf,'userdata',state);
        refresh_text;
        
%-----------------------------------------------------------------------------
%	UP: to do when the user ceases to click
                
    case 'UP'
        
        % Return motion and up functions to normal
        set(gcbf, 'windowButtonMotionFcn', '', ...
			'windowButtonUpFcn', '');
        
        % Updating position for the last time
        state = get(gcbf,'userdata');
        xyz = get(gca, 'currentPoint');
        state.XPOS(varargin{2}) = xyz(1,1);
        set(gcbf,'userdata',state);

%-----------------------------------------------------------------------------
%	PLAY: functions to play the WAV selected at the beginning

    case 'PLAY'
        
        % Retrieving the player from 'userdata'
        state = get(gcbf,'userdata');
        fs = get(state.PLAYER,'SampleRate');
        switch varargin{2}
            case 1 % Playing the whole file
                play(state.PLAYER);
            case 2 % Playing the current cut
                play(state.PLAYER,[round(state.TIMES(1) * fs) round(state.TIMES(2) * fs)])
            case 3 % Playing the selection
                if(state.XPOS(2) > state.XPOS(1)) 
                    play(state.PLAYER,[round((state.TIMES(1)+state.XPOS(1)/1000)*fs) round((state.TIMES(1)+state.XPOS(2)/1000)*fs)]); 
                elseif(state.XPOS(1) > state.XPOS(2)) 
                    play(state.PLAYER,[round((state.TIMES(1)+state.XPOS(2)/1000)*fs) round((state.TIMES(1)+state.XPOS(1)/1000)*fs)]); 
                end
        end
        
%-----------------------------------------------------------------------------
%	ZOOM: zoom functions
        
    case 'ZOOM'
        
        state = get(gcbf,'userdata');
        switch varargin{2}
            case 1 % ZOOM IN
                if(state.XPOS(2) > state.XPOS(1)) 
                    set(state.AX(1),'Xlim',[state.XPOS(1) state.XPOS(2)]);
                else
                    set(state.AX(1),'Xlim',[state.XPOS(2) state.XPOS(1)]);
                end; 
            case 2 % ZOOM OUT
                set(state.AX(1),'Xlim',[0 state.TIME]);

        end
       
%-----------------------------------------------------------------------------
%	SPEC: spectrogram menu functions
        
    case 'SPEC'
        
        state = get(gcbf,'userdata');
        
        if varargin{2}>0
           
            FS = get(state.PLAYER,'SampleRate');
            set(state.AX(1),'Position',[0.05 0.07 0.9 0.155]);
            set(state.AX(2),'Position',[0.05 0.24 0.9 0.155]);
            set(state.AX(3),'Position',[0.05 0.41 0.9 0.155]);
            
            N = 16 * 2^varargin{2};

            for i=1:6
                if i==varargin{2}
                    set(state.S(i),'Checked','On');
                else
                    set(state.S(i),'Checked','Off');
                end
            end  
            
            state.AXISPEC = subplot('Position',[0.05 0.6 0.9 0.38]); 
            set(state.AXISPEC,'Visible','On');
            state.HSPEC = myspecgram(state.AUD,N,FS,blackman(N)); 
            msg = sprintf('Spectrogram (%d)',N);
            ylabel(msg); 
            hold(state.AXISPEC,'on');
                state.HMARKER(1,1) = plot(state.AXISPEC,[state.XPOS(1) state.XPOS(1)],[0 FS/2],'-g','ButtonDownFcn','peakdet2(''DOWN'',1)');
                state.HMARKER(1,2) = plot(state.AXISPEC,[state.XPOS(2) state.XPOS(2)],[0 FS/2],'-g','ButtonDownFcn','peakdet2(''DOWN'',2)');
            hold(state.AXISPEC,'off');
            set(gcbf,'Colormap',state.MYCMAP);
            
        else
            
            set(state.S(6),'Checked','On');
            for i=1:5
                set(state.S(i),'Checked','Off');
            end
            set(state.AXISPEC,'Visible','Off');
            set(state.HSPEC,'Visible','Off');
            set(state.HMARKER(1,1),'Visible','Off');
            set(state.HMARKER(1,2),'Visible','Off');
            set(state.AX(1),'Position',[0.05 0.09 0.9 0.28]);
            set(state.AX(2),'Position',[0.05 0.4 0.9 0.28]);
            set(state.AX(3),'Position',[0.05 0.71 0.9 0.28]);
            
        end
           

        set(gcbf,'userdata',state);
        
    end
    
end

function refresh_text
    
    state = get(gcbf,'userdata');

    txt1 = sprintf('x1 = %5.2f',state.XPOS(1));
    txt2 = sprintf('x2 = %5.2f',state.XPOS(2));
    txt3 = sprintf('/\\x = %5.2f',abs(state.XPOS(1)-state.XPOS(2)));
    
    % Setting the panel with the right text
    set(state.TEXT(1),'String',txt1);
    set(state.TEXT(2),'String',txt2);
    set(state.TEXT(3),'String',txt3);
        

end

function printfig(src,evnt)
      
      state = get(gcbf,'userdata');
      x = state.XPOS;
      
      try
          if strcmp(evnt.Modifier{:},'control')
                  k=1;
          elseif strcmp(evnt.Modifier{:},'shift')
                  k=2;
          end
          
          switch evnt.Key
              case 'leftarrow' % Go back 1 sample
                    state.XPOS(k) = x(k)-5;
              case 'rightarrow' % Go forth 1 sample
                    state.XPOS(k) = x(k)+5;
              case 'uparrow' % Go forth 5 samples
                    state.XPOS(k) = x(k)+25;
              case 'downarrow' % Go back 5 samples
                    state.XPOS(k) = x(k)-25;
          end

          % Updating the markers
          for i=1:4
              set(state.HMARKER(i,k),'XData',[state.XPOS(k) state.XPOS(k)]);
          end

          % Refreshing the 'userdata', text, and palate
          set(gcbf,'userdata',state);
          refresh_text;
          
      catch ME1
          helpdlg('Use CTRL to move the left marker and SHIFT to move the right marker');
      end
      
     

end       