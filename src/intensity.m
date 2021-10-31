clear
close();
sgsrate = 400;
% % Read Train Audio
Path = 'C:/Users/47370/Desktop/train/'; 
AudioList=[];
File = dir(fullfile(Path,'*.wav')); 
FileNames = {File.name}';            
L = size(FileNames,1);    
for k = 1 : L
    K_Trace = strcat(Path, FileNames(k));
    AudioList = [AudioList;K_Trace];
end

dfucs=cell(0);
AudioLengths=[];
L = size(AudioList,1);   
for   k = 1 : L
    AudioName = AudioList{k,1};
    [d,sr] = audioread(AudioName);
    Length = length(d)/sr;
    AudioLengths = [AudioLengths;Length];
    [~,~,~,~,df,~,~] = tempo(d,sr);
    df = [df,zeros(1,4)];
    dfucs = [dfucs;df];
end

% % Read Train Gound Truth
Path = 'C:/Users/47370/Desktop/train/'; 
DataList=[];
File = dir(fullfile(Path,'*.txt')); 
FileNames = {File.name}';            
L = size(FileNames,1);    
for k = 1 : L
    K_Trace = strcat(Path, FileNames(k));
    DataList = [DataList;K_Trace];
end

% % Read Train Gound Truth
blips = [];
BeatNoteIntensitys = [];
NonBeatNoteIntensitys = [];
L = size(DataList,1);
for k = 1 : L
    fileID = fopen(DataList{k},'r');
    raw = textscan(fileID,'%s',40,'Delimiter','\n'); raw = raw{1, 1};
    % blips were evaluated by 40 objectors .
    for objectorID = 1:size(raw)
        blips = [blips str2num(raw{objectorID,1})];    
    end
    df = dfucs{k,1};
    BeatNote = sort(blips); blips=[]; 
    BeatNotelocs = round(BeatNote*400);
    NonBeatNotelocs = (1:length(df)); 
    NonBeatNotelocs(BeatNotelocs) =[];
    BeatNoteIntensitys = [BeatNoteIntensitys,df(BeatNotelocs)];
    NonBeatNoteIntensitys = [NonBeatNoteIntensitys, df(NonBeatNotelocs)];
%     x = linspace(0,AudioLengths(k),length(dfucs{k}));
%     plot(x, dfucs{k}, ...
%         [BeatNote' BeatNote'],[0 15],'-g')
%     title(AudioList{k})
%     xlim([0 5])
%     drawnow
end


h1 = histogram(BeatNoteIntensitys);
hold on
h2 = histogram(NonBeatNoteIntensitys);
h1.BinWidth=0.25;
h2.BinWidth=0.25;
h1.Normalization='probability';
h2.Normalization='probability';    
xlim([0 8])

