

sr=44100; % 默认采样率44100
timeLength=0.040;  % 采样时长，单位秒
samples=timeLength*sr;  % 计算采样点数
deviceReader = audioDeviceReader('SamplesPerFrame', samples,...
                                 'Device','Loopback Audio'  );
rectime = 10;
mySpeech=zeros(sr*rectime,1);  % 预分配录音时长
setup(deviceReader); % 开始录音

[audioIn,~] = deviceReader();                     % 第一次采样
figure('Name','实时频谱','MenuBar'...
    ,'none','ToolBar','none','NumberTitle','off');
xdata=(1:1:samples/2)/timeLength;          
axes1= subplot(1,3,1);
axes2= subplot(1,3,2);
pic= plot(axes1, 1:1:samples, audioIn);    % 初始化音频波形图
pic2= bar(axes2,xdata, xdata*0,'r');       % 初始化频谱图
set(axes1,'xlim', [0 samples], 'ylim', ...
    [-0.15 0.15],'XTick',[],'YTick',[] );
set(axes2,'xlim', [min(xdata) max(xdata)], 'ylim',[0 6] , ...
     'xscale','log','XTick',[1 10 100 1e3 1e4],'YTick',[] );
xlabel(axes2,'频率 (Hz)');
xlabel(axes1,'波形');
axes2.Position=[0.040 0.48 00.92 0.48]; % 左，下，宽度，高度
axes1.Position=[0.040 0.06 0.92 0.25];
drawnow;
db = mkblips(0,sr,sr*0.02);
tic
for i = 1:20/timeLength
    ti = toc;
    [audioIn,Overrun] = deviceReader();  % 采样 Overrun:数据溢出 
    mySpeech = circshift(mySpeech,-samples); % 循环左移
    mySpeech(end-samples+1:end,:) = []; % 删去最开始的录音
    mySpeech = vertcat(mySpeech,audioIn);% 拼接当前录音
 
    [t,xcr,D,onsetenv,sgsrate] = tempo(mySpeech,sr);
    
    if mod(i,5) == 0          % plot the mel-specgram
        tt = [1:length(onsetenv)]/sgsrate;
        imagesc(tt,[1 40],D); axis xy    
%         ydata_fft=fft(audioIn);             % 傅里叶变换
%         ydata_abs=abs(ydata_fft(1:samples/2));% 取绝对值
        set(pic, 'ydata',audioIn);          % 更新波形图数据
%         set(pic2, 'ydata',log(ydata_abs));  % 更新频谱图数据
        drawnow;                            % 刷新
    end
    to = toc;
    while ~(to-ti>=timeLength)
        to = toc;
    end
    
end
toc
close();
release(deviceReader);
audiowrite('mySpeech.wav',mySpeech,sr);
% soundsc(mySpeech,sr);

