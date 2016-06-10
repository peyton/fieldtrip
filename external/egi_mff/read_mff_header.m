%% read_mff_header.m
%  Matlab File
%  author Colin Davey
%  date 3/2/2012, 4/15/2014
%  Copyright 2012, 2014 EGI. All rights reserved.
% 
%  Takes the path to the data and returns the header in the structure
%  described at http://fieldtrip.fcdonders.nl/reference/ft_read_header.
%
%  filePath ? The path to the .mff file. 
%
%  Return a Field Trip header. Pulls most of the information from the
%  summary info returned by mff_getSummaryInfo. Stores the summary info in
%  the .orig field. Gets the sensor label info from the sensor layout
%  object. Gets the pib channel info from the pns set object. 
%%
function header = read_mff_header(filePath)
summaryInfo = mff_getSummaryInfo(filePath);
% Pull header info from the summary info. 
header.Fs = summaryInfo.sampRate;
header.nChans = summaryInfo.nChans;
header.nSamplesPre = 0;
if strcmp(summaryInfo.epochType, 'seg')
    header.nSamples = summaryInfo.epochNumSamps(1);
    header.nTrials = size(summaryInfo.epochBeginSamps,2);
    % if Time0 is the same for all segments...
    if size(unique(summaryInfo.epochTime0),2) == 1
        header.nSamplesPre = summaryInfo.epochTime0(1);
    end
else
    header.nSamples = sum(summaryInfo.epochNumSamps);
    header.nTrials = 1;
end

nChans = 0;
% Add the sensor info if it exists.
sensorLayoutObj = mff_getObject(com.egi.services.mff.api.MFFResourceType.kMFF_RT_SensorLayout, 'sensorLayout.xml', filePath);
if ~isempty(sensorLayoutObj)
    sensors = sensorLayoutObj.getSensors();
    for p = 1:sensors.size
        sensorObj = sensors.get(p-1); % sensors 0 based
        sensorType = sensorObj.getType;
        if sensorType == 0 || sensorType == 1
            tmpLabel = sensorObj.getName;
            if strcmp(tmpLabel,'')
                tmpLabel = sprintf('E%d', sensorObj.getNumber);
            else
                tmpLabel = char(tmpLabel);
            end
            header.label{p} = tmpLabel;
            header.chantype{p} = 'eeg'; % hard-coded for now. 
            header.chanunit{p} = 'uV'; % hard-coded for now. 
            nChans = nChans + 1;
        end
    end
end

% Add the pib channel info. 
if summaryInfo.pibNChans > 0
    pnsSetObj = mff_getObject(com.egi.services.mff.api.MFFResourceType.kMFF_RT_PNSSet, 'pnsSet.xml', filePath);
    pnsSensors = pnsSetObj.getPNSSensors;
    for p = 1:summaryInfo.pibNChans
        pnsSensorObj = pnsSensors.get(p - 1);
        label = pnsSensorObj.getName();
        header.label{nChans + p} = char(label);
        
        header.chantype{nChans + p} = char(pnsSensorObj.getName);
        header.chanunit{nChans + p} = char(pnsSensorObj.getUnit);
    end
end
header.nChans = header.nChans + summaryInfo.pibNChans;
header.orig = summaryInfo;
