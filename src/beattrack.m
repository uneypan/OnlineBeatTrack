clear 
clear KalmanFilter
load Ib.csv
load In.csv
tic
% % Initialization
sr = 44100;
readtime = 0.05; % read audio stream length at one time.
readLength = sr*readtime;

fileReader = dsp.AudioFileReader( ...
    'Filename','../mymusic/level5.mp3', ...
    'SamplesPerFrame',readLength);

fileWriter = dsp.AudioFileWriter(...
    'Filename','../mymusic/beat.wav',...
    'FileFormat','WAV',...
    'SampleRate',sr);

deviceReader = audioDeviceReader(...
    'SamplesPerFrame', readLength,...
    'Device','Default',...
    'NumChannels',2 );

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
playdelay = 2;
bufferLength = round((bufferhistory+bufferpredict) * sr);
buffersgsLength = round((bufferhistory+bufferpredict) * sgsrate);
buffb = [];
df = zeros(bufferhistory * sgsrate ,1);
dfs = [];
buffsignal = zeros(bufferhistory * sr ,1);
buffblipsound = zeros(bufferLength ,1);
tmean = 120;
tsd = 1.4;

obvtao = 0;
pdlast = tmean;
obvtaos = zeros(1);
obvdeltas = [];
filttaos = [];
filtdeltas = [];
filttmpos=[];
xcrtmpos = [];

b = [0 60/120]';
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
    [pd,pd2,xcr,D,df,~,~] = tempo(buffsignal,sr,tmean,tsd);
    dfs = [dfs ; df( end-sampleLength : end )'];
    % % Kalman Filter
    pretao = sum(b);
    predelta = b(2);
    w = 0.3 * predelta;
    if pretao < nowtime - w / 2

        % Valify Measurements
        
        pretaoloc = round((pretao - nowtime + bufferhistory) * sgsrate);
%         halfw = round(w * sgsrate / 2);
%         sreachrigion = intersect((1:length(df)),(pretaoloc-halfw:pretaoloc+halfw));
%         intens = df(sreachrigion); 

        obvtaoloc = localmax2(df,pretaoloc,w*sgsrate);
        obvtao = nowtime - bufferhistory + obvtaoloc/sgsrate;
        if obvtao > 0
            b = KalmanFilter(obvtao);
            if b(2) < 60/240
                b(2) = 60/120;     
            elseif b(2) > 60/60
                b(2) = 60/60;
            end
            if sum(signal) == 0 
                b(2) = 60/120;
            end
            disp(60/b(2))
            % record observed & filted(valided) taos,deltas,tempos
            obvdeltas = [ obvdeltas ; obvtao-obvtaos(end)];
            obvtaos = [obvtaos ; obvtao];
            filttaos = [filttaos ; b(1)];
            filtdeltas = [filtdeltas ; b(2)];
            filttmpos =  [filttmpos ; 60/b(2)];
            xcrtmpos = [xcrtmpos; pd2];

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
    deviceWriter(out);
    fileWriter(out);
    


    ifDraw = false;
    if ifDraw
    % plot Time-Domin wave in the buffer
    subplot(311)
    timespan = linspace(nowtime-bufferhistory,nowtime+bufferpredict,bufferLength)';
    p = plot(timespan,buffout,'-b',...
         [playtime playtime],[-1 1],'-r',...         
         [pretao pretao],[0 0.3],'-g',...
         [nowtime nowtime],[-1 1],'-b');
    p(2).LineWidth = 1.4;
    p(3).LineWidth = 2;
    p(3).Marker = '^';
    ylim([-1 1])
    xlim([min(timespan) max(timespan)])
    
    % Visualize MFCCs
    subplot(312)
    t = linspace(nowtime-bufferhistory, nowtime, bufferhistory*sgsrate-3);       
    ff = 1:length(D(:,1));
    imagesc(t,ff,D);
    axis xy; 
    xlim([min(timespan) max(timespan)])

    % Plot onset detection function
    subplot(313)
    timespan = linspace(nowtime-bufferhistory,nowtime+bufferpredict,buffersgsLength)';
    p = plot(timespan,[df,zeros(1,length(timespan)-length(df))],'-b', ...
        [nowtime nowtime], [0 10], '-b',...
        [pretao+w/2 pretao+w/2],[0 10],'-black',...
        [pretao-w/2 pretao-w/2],[0 10],'-black',...
        [pretao pretao], [0 3], '-gd',...
        [playtime playtime],[0 10],'-r',...
        [obvtao obvtao],[0 3],'-gd');
    for i =2:7; p(i).LineWidth = 2; end
    xlim([min(timespan) max(timespan)])
    ylim([0 10])
    drawnow;
    end
end

release(deviceReader)   
release(fileReader)
release(deviceWriter)    
release(fileWriter)
toc

% plot observed and filtered deltas
obvtaos(1)=[];
plot(obvtaos,obvdeltas,filttaos,filtdeltas);
xlim([0 filttaos(end)]);
ylim([0 1])
drawnow 

% plot tempo estimated by xcr and filter
x = 1:length(filttmpos);
plot(x,[filttmpos,xcrtmpos])
xlim([0 filttaos(end)])
drawnow 

% Plot onset detection function
dfs(1)=[];
timespan2 = linspace(0,nowtime,length(dfs))';
p = plot(timespan2,dfs,'-b', ...
    [obvtaos obvtaos],[0 10],'-g');
p(1).LineWidth = 0.2;
p(2).LineWidth = 2;
xlim([nowtime-5  nowtime]);
ylim([0 10])
drawnow 