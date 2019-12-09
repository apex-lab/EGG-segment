function fund = get_fundamental(egg)
% measures funamental frequency as peak of spectral distribution over a
% given strech of EGG 

    Fs = 48000;            % Sampling frequency                    
    L = length(egg);       % Length of signal

    Y = fft(egg);

    P2 = abs(Y/L);
    P1 = P2(1:L/2+1);   
    P1(2:end-1) = 2*P1(2:end-1);

    f = Fs*(0:(L/2))/L;
    [~,idx] = max(P1);
    fund = f(idx);
    
end