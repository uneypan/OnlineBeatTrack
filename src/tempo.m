function [D,mm,onsetenv,sgsrate] = tempo(d,sr)
% [t,xcr,D,onsetenv,sgsrate] = tempo(d,sr,tmean,tsd,onsetenv,debug)
%    Estimate the overall tempo of a track for the MIREX McKinney contest.  
%    <d> is the input audio at sampling rate sr.  
%    <tmean> is the mode or BPM weighting (in bpm) and 
%    <tsd> is its spread (in octaves).
%    <onsetenv> is an already-calculated onset envelope (so d is ignored).  
%    <debug> causes a debugging plot.
%    Output <t(1)> is the lower BPM estimate, <t(2)> is the faster, t(3) is the relative 
%       weight for t(1) compared to t(2).
%    <xcr> is the windowed autocorrelation from which the BPM peaks were picked.
%    <D> is the mel-freq spectrogram
%    <onsetenv> is the "onset strength waveform", used for beat tracking
%    <sgsrate> is the sampling rate of onsetenv and D.
%
% 2006-08-25 dpwe@ee.columbia.edu
% uses: localmax, fft2melmx

%   Copyright (c) 2006 Columbia University.
% 
%   This file is part of LabROSA-coversongID
% 
%   LabROSA-coversongID is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License version 2 as
%   published by the Free Software Foundation.
% 
%   LabROSA-coversongID is distributed in the hope that it will be useful, but
%   WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%   General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with LabROSA-coversongID; if not, write to the Free Software
%   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
%   02110-1301 USA
% 
%   See the file "COPYING" for the text of the license.


sro = 8000;
% specgram: 80 bin/s @ 8kHz = 10 ms / 5 ms hop
swin = 80;
shop = 20;
% mel channels
nmel = 40;
% sample rate for specgram frames (granularity for rest of processing)
sgsrate = sro/shop;

  
% resample to 8 kHz 
if (sr ~= sro)
gg = gcd(sro,sr);
d = resample(d,sro/gg,sr/gg);
sr = sro;
end

D = specgram(d,swin,sr,swin,swin-shop);

% Construct db-magnitude-mel-spectrogram
mlmx = fft2melmx(swin,sr,nmel);
D = 20*log10( max(1e-10,mlmx( : , 1 : (swin/2+1))*abs(D) ) );

% Only look at the top 80 dB
D = max(D, max(max(D))-80);

% Average Filting
for i = 1:40
  D(:,i) = smooth(D(:,i),3);
end  

% The raw onset decision waveform
mm = (mean(max(0,diff(D(3:6,:)')')));

% dc-removed mm
onsetenv = filter([1 -1], [1 -.99],mm);

% Average Filting
mm = smooth(mm,3);
mm = mm';
  
% of onsetenv calc block

