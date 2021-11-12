clear 
clear KalmanFilter
tic
% % Initialization

ifOut = 1;
ifPlay = 0;
ifDraw = 0;

sr = 44100;
readtime = 0.1; % read audio stream duration at one time.
readLength = sr*readtime;

fileReader = dsp.AudioFileReader( ...
    'Filename','../../train/train13.wav', ...
    'SamplesPerFrame',readLength);

fileWriter = dsp.AudioFileWriter(...
    'Filename','../../beat_train/beat.wav',...
    'FileFormat','WAV',...
    'SampleRate',sr);

deviceReader = audioDeviceReader(...
    'SamplesPerFrame', readLength,...
    'Device','MacBook Air麦克风',...
    'NumChannels',1 );

deviceWriter = audioDeviceWriter( ...
    'SampleRate',sr,...
    'Device','外置耳机');

cnt = 0;
sro = 8000;  % specgram: 80 bin @ 40kHz = 2 ms
swin = 80;
shop = 20;
nmel = 40; % mel channels
sgsrate = sro/shop; % sample rate for specgram frames
sampleLength = readtime * sgsrate;
bufferhistory = 3;  % allocate time for Onset Dectection & Autocorrelation
bufferpredict = 1;  % allocate time for Kalman Filting
playdelay = 1;
bufferLength = round((bufferhistory+bufferpredict) * sr);
buffersgsLength = round((bufferhistory+bufferpredict) * sgsrate);
buffb = [];
df = zeros(bufferhistory * sgsrate ,1);
dfs = [];
buffsignal = zeros(bufferhistory * sr ,1);
buffblipsound = zeros(bufferLength ,1);
tmean = 90;
tsd = 1.4;

obvtao = 0;
pdlast = tmean;
obvtaos = zeros(1);
obvdeltas = [];
obvtmpos = [];
filttaos = [];
filtdeltas = [];
filttmpos=[];
xcrtmpos = [];

b = [0 60/90]';
P = eye(2);
A = [ 1 1 ;
      0 1 ];
M = [ 1 0 ]; 


% % main audio stream loop
while ~isDone(fileReader)

    cnt = cnt+1;
    nowtime = cnt * readtime;
    starttime = bufferhistory - playdelay;
    playtime = nowtime - playdelay;

    signal = fileReader();
    if length(signal(1,:)) == 2
        signal = (signal(:,1)+signal(:,2))/2; % stero to monosignal
    end
    buffsignal(1:readLength) = [];
    buffsignal = [buffsignal ; signal];
    
    % Period Estimate
    [D,df,~,~] = tempo(buffsignal,sr);
    pas = 1;
    df = (max(df,pas)-pas)*max(df)/max(max(df,pas)-pas);
    dfs = [dfs ; df( end-sampleLength : end )'];
    % % Kalman Filter
    pretao = sum(b);
    predelta = b(2);
    w = 0.25 * predelta;
    if pretao < nowtime - w / 2
    % Valify Measurements
    pretaoloc = round((pretao - nowtime + bufferhistory) * sgsrate);
    pdf = normpdf(linspace(-0.1,0.1,length(df)), 0, sqrt(P(1,1)));
    pdff = normpdf(linspace(-w/2,w/2,length(df)), 0, w/6);
    
    obvtaoloc = localmax2(df.*pdff,pretaoloc,w*sgsrate);
    obvtao = nowtime - bufferhistory + obvtaoloc/sgsrate;
    if obvtao > 0
        [b,P] = KalmanFilter(obvtao);
        if b(2) < 60/240
            b(2) = 60/240;     
        elseif b(2) > 60/60
            b(2) = 60/60;
        end
        if sum(signal) == 0 
            b(2) = 60/120;
        end
        disp(60/b(2))
        % record observed & filted(valided) taos,deltas,tempos
        obvdeltas = [ obvdeltas ; obvtao-obvtaos(end)]; %#ok<*AGROW> 
        obvtmpos = [obvtmpos 60/obvdeltas(end)];
        obvtaos = [obvtaos ; obvtao];
        filttaos = [filttaos ; b(1)];
        filtdeltas = [filtdeltas ; b(2)];
        filttmpos =  [filttmpos ; 60/b(2)];
        if ifDraw
        % Plot onset detection function
        subplot(313)
        timespan = linspace(nowtime-bufferhistory,nowtime+bufferpredict,buffersgsLength)';
        p = plot(timespan,[df,zeros(1,length(timespan)-length(df))],'-b', ...
            [nowtime nowtime], [0 10], '-b',...
            [pretao+w/2 pretao+w/2],[0 10],'-black',...
            [pretao-w/2 pretao-w/2],[0 10],'-black',...
            [playtime playtime],[0 10],'-r',...
            [obvtao obvtao],[0 10],'-g');
        title("Onset Detection Function")
        for i =2:6; p(i).LineWidth = 2; end
        xlim([min(timespan) max(timespan)])
        ylim([0 10])
        end
    end
    end
    
        buffb = [ obvtaos ; pretao] - (nowtime - bufferhistory);
        [i,~]=find(buffb < 0);
        buffb(i)=[];
        if buffb ~= 0
        buffblipsound = mkblips(buffb',sr,bufferLength); 
        end
        buffout = [buffsignal;zeros(sr*bufferpredict,1)] + buffblipsound;
        out = buffout(round((starttime*sr-readLength+1:starttime*sr)));
        
    if ifOut   
        fileWriter(out);
    end
    
    if ifPlay
        deviceWriter(out);
    end
    
    if ifDraw
        % plot Time-Domin wave in the buffer
        subplot(311)
        timespan = linspace(nowtime-bufferhistory,nowtime+bufferpredict,bufferLength)';
        p = plot(timespan,buffout,'-b',...
             [playtime playtime],[-1 1],'-r',...         
             [pretao pretao],[-1 1],'-g',...
             [nowtime nowtime],[-1 1],'-b');
        p(2).LineWidth = 2;
        p(3).LineWidth = 2;
        title("Wave")
        ylim([-1 1])
        xlim([min(timespan) max(timespan)])

        % Visualize MFCCs
        subplot(312)
        t = linspace(nowtime-bufferhistory, nowtime, bufferhistory*sgsrate-3);       
        ff = 1:length(D(:,1));
        imagesc(t,ff,D);
        title("MFCCs")
        axis xy; 
        xlim([min(timespan) max(timespan)])
        drawnow;
    end
end
obvtaos(1) = [];
dfs(1)=[];
release(deviceReader)   
release(fileReader)
release(deviceWriter)    
release(fileWriter)
toc

% plot observed and filted deltas
subplot(211)
plot(obvtaos,obvtmpos, filttaos,filttmpos);
xlim([0 nowtime])
ylim([0 240])
title("Raw & Kalman Filted Tempos (BPM)")
drawnow


% Plot onset detection function
subplot(212)
timespan2 = linspace(0.1,nowtime,length(dfs))';
p = plot(timespan2,dfs,'-b', ...
    [obvtaos obvtaos],[0 10],'-g');
p(1).LineWidth = 0.1;
p(2).LineWidth = 0.1;
ylim([0 10])
xlim([2 3])
title("Onset Detection Function")
drawnow 
