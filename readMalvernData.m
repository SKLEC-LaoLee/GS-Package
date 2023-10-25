function rawData=readMalvernData(dataPath,simpleProcessFlag,userSettingFileName,userDefinedValidSizeLim,forceReadRawDataFlag,MIN_CHANNEL_SIZE_MM,MAX_CHANNEL_SIZE_MM)
%----------------------------------------------------------------------------------------------------
% @file name:   readMalvernData.m
% @description: Read text reports exported by Malvern MasterSizer 2000/3000 software.
% @author:      Li Weihua, whli@sklec.ecnu.edu.cn
% @version:     Ver1.1, 10/21/2023
%----------------------------------------------------------------------------------------------------
% dataPath, full path of the data files
% simpleProcessFlag, simple processing mode (no configuration file information is read)
%            = true  enable "userDefinedValidSizeLim", sample auto-numbering with the same groupId
%            = false disable "userDefinedValidSizeLim", get settings from "userSettingFileName"
% userSettingFileName, file of user settings (full path)
% userDefinedValidSizeLim, valid range of particle size [min_mm,max_mm]
% forceReadRawDataFlag,
%            = true  allways read data from "*.mal" file
%            = false load the rawData.mat if exists in the dataPath; otherwise, read data from "*.mal" file
% MIN_CHANNEL_SIZE_MM, lower limit of instrument detection (mm), should be greater than 0, default is 0.1um
% MAX_CHANNEL_SIZE_MM, upper limit of instrument detection (mm), default is 20mm
%
% @return: 
% rawData.
%           dataPath: full path of the data file
%           fileName: file name of the xle/xld file
%       instrumentId: instrument code, here is 21
%                     = 1, coulter LS 13320
%                     =11, camsizer X2
%                     =21, malvern
%                     =99, unknown
%          groupName: sample group
%            groupId: unique numeric id of the group
%         sampleName: sample name
%           sampleId: unique numeric id of the sample
%  exportToAnalySize: export the sample data to AnalySize. =0, disable; =1, enable
%         configInfo: configuration file name of the instrument (xxx.cfg)
%               type: Rules for particle size statistics(string), here is 'x_area'
%                     ='xc_min', perpendicular to sieving methods
%                     ='x_area', perpendicular to laser diffraction methods
%                     ='xFemin', perpendicular to the width of the vernier methods
%                     ='xFemax', perpendicular to the length of the vernier methods
%                     ='xMamin', martin diameter
%       analysisTime: Time to start on-board measurements(datetime)
%       validSizeLim: user defined valid range of grainsize [minLim(um),maxLim(um)]
%     analysisPeriod: measurement period(s)
%        obscuration: obscuration(%), only for laser diffraction method
%          pumpSpeed: pump speed, only for laser diffraction method
%                SSa: specific surface area, only for laser diffraction method
%  waterRefractivity: water refractivity, only for laser diffraction method
%particleRefractivity: particle refractivity, only for laser diffraction method
%particleAbsorptivity: particle absorptivity, only for laser diffraction method
%    channelDownSize: lower limit size of the channel(um)
%      channelUpSize: upper limit size of the channel(um)
%     channelMidSize: logarithmic midpoint size of the channel(um)
%                 p3: raw differential volume(%)
%                 q3: raw cumulative volume(%)
%           adjustP3: differential volume percentage after removal of invalid components (%)
%           adjustQ3: cumulative volume percentage after removal of invalid components (%)
%      haveShapeData: , here is 0
%                = 0, no particle shape information
%                = 1, particle shape information only indexed by particle size
%                = 2, particle shape information both indexed by particle size and normalized shape factor
%              spht3: sphericity, =4*pi*area/(round^2)
%              symm3: Symmetry
%               b_l3: Aspect ratio = Xc_min (particle width: sieve size)/XFe_Max (particle length)
%            B_LRec3: Minimum aspect ratio = min(Xc/XFe)
%            sigmav3: Standard deviation of ?
%              conv3: Convexity = sqrt(real area / convex particle area)
%             rdnsc3: Roundness, ratio of the averaged radius of curvature of all convex regions to the circumscribed cricle of the particle
%                pdv: volume-based number of particle detections
%    channelMeanSize: mean value of the particle size
%channelSize_xFe_avg: average feret diameter
%channelSize_xMa_avg: average martin diameter
% channelSize_xc_avg: average chord diameter
%channelSize_xFe_min: minimum feret diameter, particle width
%channelSize_xMa_min: minimum martin diameter, paticle thickness
% channelSize_xc_min: minimum chord diameter, sieve size
%channelSize_xFe_max: maxmum feret diameter, paticle length
%channelSize_xMa_max: maxmum martin diameter
% channelSize_xc_max: maxmum chord diameter
%   channelDownShape: lower limit of normalized shape index(0~1), only when haveShapeData==2
%     channelUpShape: upper limit of normalized shape index(0~1), only when haveShapeData==2
%    channelMidShape: logarithmic midpoint of normalized shape index(0~1), only when haveShapeData==2
%             q3Spht: cumulative volume percentage of sphericity, only when haveShapeData==2
%             q3Symm: cumulative volume percentage of symmetry, only when haveShapeData==2
%             q3_b_l: cumulative volume percentage of aspect ratio, only when haveShapeData==2
%           q3B_LRec: cumulative volume percentage of minimum aspect ratio, only when haveShapeData==2
%           q3Sigmav: cumulative volume percentage of Sigmav, only when haveShapeData==2
%             q3Conv: cumulative volume percentage of convexity, only when haveShapeData==2
%            q3Rdnsc: cumulative volume percentage of roundness, only when haveShapeData==2
%             q0Spht: cumulative number percentage of sphericity, only when haveShapeData==2
%             q0Symm: cumulative number percentage of symmetry, only when haveShapeData==2
%             q0_b_l: cumulative number percentage of aspect ratio, only when haveShapeData==2
%           q0B_LRec: cumulative number percentage of minimum aspect ratio, only when haveShapeData==2
%           q0Sigmav: cumulative number percentage of Sigmav, only when haveShapeData==2
%             q0Conv: cumulative number percentage of convexity, only when haveShapeData==2
%            q0Rdnsc: cumulative number percentage of roundness, only when haveShapeData==2
%            sfCorey: Corey shape factor=channelSize_xMa_min/sqrt(channelSize_xFe_min*channelSize_xFe_max)
% @references:
% NONE
% @others:
% How to export text data in Mastersizer 2000/3000 software?
% (1) Edit menu>>User grainsize>>Edit grainsize: Load grainsize, select malvernGrainsize.siz
% (2) Copy malvernExportDataForGSPackage.edf to the following directory:
%     C:\Users\Public\Documents\Malvern Instruments\Mastersizer 2000\Export Templates
% (3) shift+left click of mouse button to select the data file >> File menu >> Export Data:
%     .Use Data Templates = malvernExportDataForGSPackage
%     .Format Options = Use tabs as separators, exclude header rows.
%     .Export data to file, select text file (*.txt)
%     .Check to overwrite files
%     .Output filename suffixes only allowed as *.mal
%----------------------------------------------------------------------------------------------------
rawData={};
if ~exist('simpleProcessFlag','var')
    simpleProcessFlag = true;
    userSettingFileName='';
end

if ~exist('userDefinedValidSizeLim','var')
    userDefinedValidSizeLim = [-inf,inf];
end
if ~exist('forceReadRawDataFlag','var')
    forceReadRawDataFlag = true;
end

if ~exist('MIN_CHANNEL_SIZE_MM','var')
    MIN_CHANNEL_SIZE_MM = 0.0001;
end
MIN_CHANNEL_SIZE_UM=MIN_CHANNEL_SIZE_MM*1000;

if ~exist('MAX_CHANNEL_SIZE_MM','var')
    MAX_CHANNEL_SIZE_MM = 20;
end
MAX_CHANNEL_SIZE_UM=MAX_CHANNEL_SIZE_MM*1000;

if ~exist('forceReadRawDataFlag','var')
    forceReadRawDataFlag = false;
end

if dataPath(end)~='\'
    dataPath(end+1)='\';
end

hidWait=waitbar(0,'Reading Malvern data, please wait...');
if exist([dataPath,'rawData.mat'],'file')&&(forceReadRawDataFlag==false)
    load([dataPath,'rawData.mat'],'-mat','rawData');
    close(hidWait);
    return;
end

suffix='.mal';
tempVar=dir([dataPath,'*',suffix]);
allFile=char(tempVar.name);
fileNum=size(allFile,1);
instrumentDataTable=[];
validSampleNum=0;

channelSize=load('malvernGrainsize.siz','-ascii');
channelSize=channelSize(2:end);

for iFile=1:fileNum
    thisDataFileName=allFile(iFile,:);
    instrumentDataTable=[instrumentDataTable;readtable(strcat(dataPath,thisDataFileName),'FileType','text')];
end
[sampleNum,varNum]=size(instrumentDataTable);
if sampleNum<1
    error('No valid data in the selected file.');
    return;
end
if varNum~=110
    error('Data export template error, only support malvernExportDataForGSPackage.edf and malvernGrainsize.siz.');
    return;
end

backslashId=strfind(dataPath,'\');
if length(backslashId)<=1
    lastLevelDataPath=dataPath;  % root dir, for example: "c:\"
else
    lastLevelDataPath=dataPath(backslashId(end-1)+1:backslashId(end)-1);
end

userDefinedValidSizeLim=userDefinedValidSizeLim*1000;
%read user defined infomation.
if simpleProcessFlag==false
    userSettings=readUserSettings(userSettingFileName);
end
%
for iSample=1:sampleNum
    thisSampleName=instrumentDataTable.Var1{iSample};
    thisDiscardFlag=false;
    thisSampleId=nan;
    validSizeLim=userDefinedValidSizeLim;
    thisGroupName='undefined';
    thisGroupId=-999;
    exportToAnalySize=1;

    thisSampleData=zeros(500,2);
    diamChannelNum=0;
    hightChannelNum=0;

    %read user defined infomation.
    if simpleProcessFlag==false
        userSetRecordNum=length(userSettings.name);
        for iSet=1:userSetRecordNum
            % sample search principle: file name and directory are the same
            if (strcmpi(strrep(thisSampleName,' ',''),strrep(userSettings.name{iSet},' ',''))==true)&&(strcmpi(lastLevelDataPath,userSettings.dataPath{iSet})==true)
                if userSettings.discard(iSet)==1
                    thisDiscardFlag=true;
                end
                thisSampleName=userSettings.name{iSet};
                validSizeLim=[userSettings.minValidSize(iSet),userSettings.maxValidSize(iSet)];
                thisGroupName=userSettings.groupName{iSet};
                thisGroupId=userSettings.groupId(iSet);
                thisSampleId=userSettings.sampleId(iSet);
                exportToAnalySize=userSettings.exportToAnalySize(iSet);
                break;
            end
        end
    end
    if thisDiscardFlag==true
        continue;
    end

    validSampleNum=validSampleNum+1;
    rawData(validSampleNum).instrumentId=21;
    rawData(validSampleNum).sampleName=thisSampleName;
    if isnan(thisSampleId)
        thisSampleId=-validSampleNum;
    end
    rawData(validSampleNum).sampleId=thisSampleId;
    rawData(validSampleNum).groupName=thisGroupName;
    rawData(validSampleNum).groupId=thisGroupId;
    rawData(validSampleNum).dataPath=dataPath;
    rawData(validSampleNum).fileName=thisDataFileName;
    rawData(validSampleNum).exportToAnalySize=exportToAnalySize;
    rawData(validSampleNum).configInfo=instrumentDataTable.Var3{iSample};
    rawData(validSampleNum).type='x_area';
    rawData(validSampleNum).analysisTime=instrumentDataTable.Var2(iSample); %datetime类型
    rawData(validSampleNum).validSizeLim=validSizeLim;
    rawData(validSampleNum).analysisPeriod=0;
    rawData(validSampleNum).pumpSpeed=instrumentDataTable.Var4(iSample);
    rawData(validSampleNum).SSa=instrumentDataTable.Var5(iSample);
    rawData(validSampleNum).waterRefractivity=instrumentDataTable.Var6(iSample);
    rawData(validSampleNum).particleRefractivity=instrumentDataTable.Var7(iSample);
    rawData(validSampleNum).particleAbsorptivity=instrumentDataTable.Var8(iSample);
    rawData(validSampleNum).obscuration=instrumentDataTable.Var9(iSample);

    rawData(validSampleNum).channelDownSize=channelSize(1:end-1,1);
    rawData(validSampleNum).channelUpSize=channelSize(2:end,1);
    thisSampleLogMidSize=(log2(rawData(validSampleNum).channelDownSize)+log2(rawData(validSampleNum).channelUpSize))./2;
    rawData(validSampleNum).channelMidSize=2.^(thisSampleLogMidSize);
    q3=table2array(instrumentDataTable(iSample,10:end))';
    rawData(validSampleNum).p3=diff(q3);
    % reject the invalid components according to the user-defined "validSizeLim"
    inValidId=(rawData(validSampleNum).channelUpSize<rawData(validSampleNum).validSizeLim(1)*1000)|(rawData(validSampleNum).channelDownSize>rawData(validSampleNum).validSizeLim(2)*1000);
    newP3=rawData(validSampleNum).p3;
    newP3(inValidId)=0;
    newP3=newP3./sum(newP3).*100;

    nChannel=length(newP3);
    q3=newP3.*0;
    newQ3=newP3.*0;
    for iChannel=1:nChannel
        q3(iChannel,1)=sum(rawData(validSampleNum).p3(1:iChannel,1));
        newQ3(iChannel,1)=sum(newP3(1:iChannel,1));
    end
    rawData(validSampleNum).q3=q3;
    rawData(validSampleNum).adjustP3=newP3;
    rawData(validSampleNum).adjustQ3=newQ3;
    rawData(validSampleNum).haveShapeData=false;
    waitbar(iSample./sampleNum,hidWait);
end
close(hidWait);
if validSampleNum<1
    rawData=[];
else
    save([dataPath,'rawData.mat'],'rawData');
end