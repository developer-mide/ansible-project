%close all

%% import data and shape into matrix
fileID = fopen("data.int32");
data = fread(fileID,'int32');
fclose(fileID);
% for no dt channels num_categories = 12
% for dt channels num_categories = 19
num_categories = 12; 
cols = floor(length(data)/num_categories);
data = reshape(data(1:cols*num_categories),[num_categories, cols]);

%% parse data
if num_categories == 12
    v_idx = 5;
else
    v_idx = 12;
end
% WFB info
UDP_seq_num = data(1,:);
curr_WFB_index = data(2,:);
local_WFB_index = data(3,:);
retrieval_microsec_raw = data(4,:);
% clean up time for plotting
retrieval_microsec = retrieval_microsec_raw - retrieval_microsec_raw(1);
retrieval_millisec = retrieval_microsec/1000;

% timers (can be disabled by setting num_categories = 12, enabled by
% num_categories = 19)
dt_create_UDP_packet = data(5,:);
dt_begin_SPI_transfer = data(6,:);
dt_end_SPI_transfer = data(7,:);
dt_end_wfb_processing = data(8,:);
dt_end_GPS = data(9,:);
dt_begin_UDP_transfer = data(10,:);
prev_end_begin_UDP = data(11,:);

% voltage channels
va = data(v_idx,:);
vb = data(v_idx + 1,:);
vc = data(v_idx + 2,:);
vx = data(v_idx + 3,:);

% currenct channels
ia = data(v_idx + 4,:);
ib = data(v_idx + 5,:);
ic = data(v_idx + 6,:);
in = data(v_idx + 7,:);


%% plotting
figure(1)
subplot(4,2,1)
plot(va(1:1024))
title("Voltage Channel A")
xlabel("Sample #")
ylabel("Digital Code")

subplot(4,2,3)
plot(vb(1:1024))
title("Voltage Channel B")
xlabel("Sample #")
ylabel("Digital Code")

subplot(4,2,5)
plot(vc(1:1024))
title("Voltage Channel C")
xlabel("Sample #")
ylabel("Digital Code")

subplot(4,2,7)
plot(vx(1:1024))
title("Vx")
xlabel("Sample #")
ylabel("Digital Code")

subplot(4,2,2)
plot(ia(1:1024))
title("Current Channel A")
xlabel("Sample #")
ylabel("Digital Code")

subplot(4,2,4)
plot(ib(1:1024))
title("Current Channel B")
xlabel("Sample #")
ylabel("Digital Code")

subplot(4,2,6)
plot(ic(1:1024))
title("Current Channel C")
xlabel("Sample #")
ylabel("Digital Code")

subplot(4,2,8)
plot(in(1:1024))
title("Current Neutral")
xlabel("Sample #")
ylabel("Digital Code")

figure(2)
subplot(3,1,1)
plot(UDP_seq_num(1:1024))
title("UDP sequence numbers")
ylabel("#")
xlabel("Sample #")

subplot(3,1,3)
hold on
stairs(retrieval_millisec(1:1024),local_WFB_index(1:1024))
stairs(retrieval_millisec(1:1024), curr_WFB_index(1:1024))
title("WFB index")
ylabel("WFB")
xlabel("ms")
legend(["Local WFB index","Current WFB index"])
hold off

subplot(3,1,2)
plot(retrieval_microsec(1:1024))
title("Retrieval Microseconds")
ylabel("microsec")
xlabel("Sample #")

%% timers
if num_categories == 19
    UDP_length = mean(prev_end_begin_UDP);
    UDP_max = max(prev_end_begin_UDP);
    SPI_length = mean(dt_end_SPI_transfer - dt_begin_SPI_transfer);
    SPI_max = max(dt_end_SPI_transfer - dt_begin_SPI_transfer);
    SPI_processing_length = mean(dt_end_wfb_processing - dt_end_SPI_transfer);
    SPI_processing_max = max(dt_end_wfb_processing - dt_end_SPI_transfer);
    disp("***************************************************************************************************")
    disp("Timer Information (us)")
    disp("------------------------")
    disp("Average time to send UDP packet: " + UDP_length/1000)
    disp("Max time to send UDP packet: " + UDP_max/1000)
    disp("Average time to read SPI: " + SPI_length/1000)
    disp("Max time to read SPI: " + SPI_max/1000)
    disp("Average time to process data from SPI: " + SPI_processing_length/1000)
    disp("Max time to process data from SPI: " + SPI_processing_max/1000)
end

%% statistics on individual channels - 
% analyze_waveform(Channel (data), Label for Channel Name (str))
%[avg_max,avg_min,median_max,median_min,sd_max,sd_min] = analyze_waveform(ia,"Ia");
%[avg_max,avg_min,median_max,median_min,sd_max,sd_min] = analyze_waveform(vb,"Vb");

function [avg_max,avg_min,median_max,median_min,sd_max,sd_min] = analyze_waveform(data,label)
    Fs = 32e3;
    nFFT = 2^13;
    local_max = findpeaks(data);
    local_min = -findpeaks(-data);
    avg_max = mean(local_max);
    avg_min = mean(local_min);
    median_max = median(local_max);
    median_min = median(local_min);
    sd_max = std(local_max);
    sd_min = std(local_min);

    % freq and amp measured
    Fnyq = Fs/2;
    nsamp  = length(data(1:nFFT));
    fts = fft(data(1:nFFT))/nsamp;
    Fv = linspace(0, 1, fix(nsamp/2)+1)*Fnyq;
    Iv = 1:length(Fv);
    amp_fts = abs(fts(Iv))*2;
    [amp,idx] = max(amp_fts(2:end));
    freq_meas = Fv(idx+1);

    % FFT calculations
    figure
    [SNDR,THD,SFDR,ENOB] = spectralanalyze(data(1:nFFT),Fs,freq_meas,label);
    disp("***************************************************************************************************")
    disp("Stats for Channel "+label)
    disp("----------------------")
    disp("Maximum: "+max(local_max))
    disp("Minimum: "+min(local_min))
    disp("Pk-Pk: "+amp*2)
    disp("Offset: "+mean(data))
    disp("Measured Frequency: "+freq_meas+" Hz")
    disp("Calculated SNDR: "+SNDR+" dB")
    disp("Calculated ENOB: "+ENOB+" bits")

    % error check
    if ((max(data) - amp)/amp > 0.05)
        [~,idx] = max(data);
        disp("Potential data error at IDX: "+idx)
        figure
        plot(data(idx - 100:idx + 100))
        title("Errors?")
        xlabel("Sample #")
        ylabel("Digital Out")
    elseif (abs(min(data) + amp)/amp > 0.05)
        [~,idx] = min(data);
        disp("Potential data error at IDX: "+idx)
        figure
        plot(data(idx - 100:idx + 100))
        title("Errors?")
        xlabel("Sample #")
        ylabel("Digital Out")
    end
end

function [SNDR,THD,SFDR,ENOB] = spectralanalyze(data,Fs,Fin,label) 
  nsamp = length(data); 
  % take FFT and calculate power
  if (isrow(data) == 1)
    data = data';
  end
  y = fft(data.*blackman(nsamp));
  Pyy = y.*conj(y)/nsamp; 
  % find fundamental bin
  %[~,sbin] = max(Pyy(2:end)); 
  sbin = round(Fin*nsamp/Fs);
  sbin = sbin + 1;
  % calculate SNDR
  Psig = sum(Pyy(sbin-2:sbin+2));
  Pnoi = sum(Pyy(4:nsamp/2+1))-Psig;
  %Psig = Pyy(sbin); 
  %Pnoi = sum(Pyy(2:nsamp/2))+Pyy(nsamp/2+1)/2-Psig; 
  SNDR = 10*log10(Psig/Pnoi); 
  % calculate ENOB
  ENOB = (SNDR - 1.76)/6.02; 
  % find harmonic locations
  har = Fin*[2:8]; 
  req_freq = zeros(1,length(har)); 
  for i=1:length(har)
      if mod(har(i),Fs) > Fs/2
          req_freq(i) = Fs - mod(har(i),Fs);
      else
          req_freq(i) = mod(har(i),Fs);
      end
  end
  % calculate THD
  bin = round(req_freq*nsamp/Fs)+1;
  Pthd_temp = Pyy(bin);
  Pthd = sum(Pthd_temp);
  THD = 10*log10(Pthd/Psig);
  % calculate SFDR
  Pyy_test = Pyy;
  Pyy_test(sbin-2:sbin+2) = 0;
  Pyy_test(1:3) = 0; 
  [spur,loc] = max(Pyy_test(4:nsamp/2)); 
  % spur = max(Pyy_test(2:nsamp/2));
  SFDR = 10*log10(Psig)-10*log10(spur); 
  % for plotting
  PyydBc = 10*log10(Pyy/Psig);
  freqs = (1:nsamp/2)*Fs/nsamp; 
  Pyy_plot = PyydBc(1:nsamp/2);
  %Pyy_plot(nsamp/2-1) = 10*log10(Pyy(nsamp/2)/2)-10*log10(Psig);
   plot(freqs,Pyy_plot); 
   %figure
   %plot(freqs,Pyy(1:nsamp/2-1))
   text(Fin,0,['\leftarrow Fundamental: ',num2str(Fin),'Hz'],'FontSize',10);
%   for i=1:length(har)
%       P = 10*log10(Pthd_temp(1,i)/Psig);
%       text(req_freq(1,i),P,['\leftarrow harmonic = ' num2str(i+1)],'FontSize',20);
%   end
   xlabel('Frequency (Hz)');
   xlim ([0 Fs/2]);
   ylabel('Power (dB)');
   title('Spectrum of Channel '+label);
   set(gca, 'FontSize', 10)
  grid 
end