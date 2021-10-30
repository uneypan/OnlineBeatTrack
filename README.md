# Online Beat Tracking Based on  Kalman Filter（Matlab）基于卡尔曼滤波的在线节拍跟踪器(Matlab 实现)

## 概述

主文件为 beattrack.m , 运行之前需要设置音频I/O设备。目前搭建好卡尔曼滤波器，使用 AudioToolbox 可从文件或者设备读取音频流，放进 Buffer 内做重音(onset)检测和周期估计作为卡尔曼滤波器的输入，得到新的估计，拍位置的观测方法为简单的局部最大值规则选取(localmax)，但是测量不准确。

## 音频流 I/O 函数

使用matlab内置音频工具箱AudioToolbox的函数dsp.AudioFileReader | dsp.AudioFileWriter | audioDeviceReader | audioDeviceWriter 实现，具体参考官方手册: [Audio I/O: Buffering, Latency, and Throughput](https://ww2.mathworks.cn/help/audio/gs/audio-io-buffering-latency-and-throughput.html).

![streamprocessing3](/image/streamprocessing3.png "音频流处理过程")

需要设置的参数有一次采样率**sr**，读取的音频长度**readtime**，输入、输出**Device / Filename**，**Device**可以使用 [getAudioDevices( )](https://ww2.mathworks.cn/help/audio/ref/audioplayerrecorder.getaudiodevices.html)获取。

**注意**: 同时拾音和收音需要考虑音流重叠的问题，目前在MAC上可以用虚拟声卡软件Loopback提取音轨，Windows系统上还没找到比较好的解决方案。

## 添加一个处理的Buffer

由于“**音频读取--处理--估计--播放**”循环存在延迟，因此验证拍永远落后于实际音频播放的时间。设置一个处理Buffer，长度由历史缓存**bufferhistory**和预估缓存**bufferpredict**构成。历史缓存用于重音检测和自相关运算，预估缓存用于放置和播放预估得到的拍子。

Buffer随着歌曲进行向前推移，可与通过卡尔曼滤波或自相关运算获得的预估拍，再经localmax观测得到新的验证拍，如此递归运算。

## 可选择的播放位置

我们可以选择播放Buffer内任意位置的音频，通过一个延迟参数**playdelay**来实现，其含义为当前时间延迟**playdelay**秒。

如果**playdelay**设置为大于**2W**，则播放的为已验证的拍和音乐，如果 **playdelay**小于0, 则播放的是预估的拍子，但没有音乐，其中**2W**是验证窗口，长度为20%～30%的节拍周期。如果在**2W**验证窗口内播放，可能会同时听到估计拍和观测拍的声音。

![wave](/image/wave.jpg "实时波形图")

利用**playdelay**可以提前将预估拍子播放出来，抵消掉音频处理系统的“**音频读取--处理--估计--播放**”循环的延迟，实现在线节拍跟踪，提前的时间可能需要根据不同的处理系统具体测量，目前根据效果手动指定为0.2s。

## 对<tempo.m>的一些修改

<tempo.m> 是coversongs库给出的预处理函数。

原<tempo.m> 给出的**onsetenv**经过dc-remove滤波，去掉这个filter以后得到正常的重音检测函数 **df**，在Buffer内绘制出**df**,观测后发现主要是存在休止符和non-beat onset干扰的问题，导致卡尔曼滤波效果不稳定。

最后添加了整首歌曲在滤波前、后的节拍周期**obvdeltas**,**filtdeltas**, 也给出了Kalman滤波算法给出的和自相关运算得到的tempo曲线**filttmpos**,**xcrtmpos**的对比。

![df](/image/df.jpg "实时检测函数")

## 概率数据关联(PDA)

PDA算法用概率的方法同时讨论所有观测到的候选拍。理想情况下，PDA能拾取所有目标观测值，并丢弃随机噪声和干扰引起的其他测量值。

PDA算法分为两步：

1. 验证测量值：限制了测量值选取的范围，减少候选拍。

   由于参数复杂，手动限定一个观测区域即可。

   确定验证区域后，下一步是进行概率数据关联（或叫概率数据加权）。每一次采样时，都会计算一次测量验证空间，如果落入测量空间的候选测量值不止一个，那么就对所有候选测量值进行PDA。

2. 关联测量值：将候选的测量值与目标关联起来，获得一个更准确的测量值。
    2.1. 基础PDA-I：假定状态变量服从高斯分布，修改卡尔曼滤波算法，将新息修改为概率加权新息。对卡尔曼滤波算法修改如下:

    原始算法：

    ``` matlab
   % Predict
    xp = A * x;

    Pp = A * P * A' + Q;

    % Update
    K = Pp * M' / ( M * Pp * M' + R);

    x = xp + K * (y - M * xp);

    P = Pp - K * M * Pp;   
    ```

    引入多个观测候选值**y**和对应的权值**bta**，算法修改为：

    ``` matlab
    % Predict
    xp = A * x;

    Pp = A * P * A' + Q;
    
    % Update
    K = Pp * M' / ( M * Pp * M' + R);

    x = xp + K * sum((y - M * xp) .* bta);

    P0 = ( eye(2) - K * M ) * Pp;

    yh = y - M * xp;

    Ph = K * ( sum( bta * (yh * yh') ) - yh * yh' )  * K';

    P = ( 1 - sum(bta) ) * Pp + sum(bta) * P0 + Ph;  
    ```
