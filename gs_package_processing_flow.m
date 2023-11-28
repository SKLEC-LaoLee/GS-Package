function gs_package_processing_flow(userSettings)
%----------------------------------------------------------------------------------------------------
% @file name:   gs_package_processing_flow.m
% @description: Main processing flow of GS-Package
% @author:      Li Weihua, whli@sklec.ecnu.edu.cn
% @version:     Ver1.1, 2023.10.22
%----------------------------------------------------------------------------------------------------
userSettings.instrumentId=1;
sampleSettings=readSampleSettings(userSettings);
rawData=readCoulterLsData(userSettings,sampleSettings);

if isempty(rawData)
    userSettings.instrumentId=11;
    sampleSettings=readSampleSettings(userSettings);
    rawData=readCamSizerData(userSettings,sampleSettings);
end

if isempty(rawData)
    userSettings.instrumentId=21;
    sampleSettings=readSampleSettings(userSettings);
    rawData=readMalvernData(userSettings,sampleSettings);
end

if isempty(rawData)
    userSettings.instrumentId=31;
    rawData=readLISSTData(userSettings,[]);
end

if (isempty(sampleSettings))&&(~isempty(rawData))
    warndlg("Warning: This is the first time the raw data has been processed and the sample setting information file has not been edited.");
end
if ~isempty(rawData)
    statisticalParams=calcStatisticalParams(rawData,userSettings);
    exportDataReport(statisticalParams,userSettings);
    exportForAnalySize(statisticalParams,userSettings);
    if userSettings.exportClassificationScheme
        plotClassificationScheme(statisticalParams,userSettings);
    end
else
    warndlg("No valid Coulter-data file in the specified path.");
end
