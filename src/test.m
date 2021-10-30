% t = tempo2(d,sr[,tmean,tsd]) - Estimates the tempo of the audio waveform in 
%     d (at sampling rate sr) and returns two tempo estimates in BPM as t(1) (slower)
%     and t(2) (faster), with the relative strength of t(1) given by t(3) 
%     (i.e. t(1) is the preferred tempo if t(3) > 0.5).
%     Optional tmean and tsd specify the mean (in BPM) and spread (in octave£©
%     of the tempo bias window; default is (110, 0.9).
% b = beat2(d,sr[,startbpm,tightness]) - Extract the beat times in the audio waveform 
%     d (at sampling rate sr). It operates by first calling tempo2() (above), then using
%     dynamic programming to find the sequence of beat times that both approximately follow
%     the estimated tempo, and lie on or close to maxima of the "onset strength waveform". 
%     Optional parameter startbpm either prespecifies the tempo, or, if a two-element vector,
%     is used as tmean and tsd for the call to tempo2(). 
%     Optional parameter tightness controls the relative weighting of tempo conformity 
%     and onset envelope; larger numbers result in more rigid tempos (default 400).
% F = chrombeatftrs(d,sr) - Returns the beat-synchronous chroma feature
%     matrix for the audio waveform d (sampled at sr). First the beat 
%     positions are tracked, then a 12-dimensional chroma feature is 
%     averaged across each beat interval.
%     qlist = calclistftrs(querylistfilename) - Calculates beat-synchronous
%     chroma feature matrices for all the wav or mp3 files listed, one per 
%     line, in the named file, returning a list of calculated feature files, then...
% R = coverTestLists(qlist) - Compares each feature file named in the 
%     qlist against every item and returns R as a square matrix of distances
%     between each pair.

 filename= '../mymusic/test30.wav';
 savename='../mymusic/beat.wav';
 % Load a song
 [d,sr] = audioread(filename)
 % Calculate the beat times
 [b,onsetenv,D,cumscore] = beat(d,sr,0,0,true);
 % Resynthesize a blip-track of the same length
 db = mkblips(b,sr,length(d));
 % Listen to them mixed together
 soundsc(d+0.1*db,sr);
 audiowrite(savename,d+db,sr);
 