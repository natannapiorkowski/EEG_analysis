function [EEG, isOK]= removeSpikes(EEG, varargin)
% This function removes spikes accuring due to tactile stimulation.
% parameters:
% 
% lookForSpikeRange       - time range afet trigger to search for the spikes in ms
% lookForSpikeRange_shift - start looking for the spikes a bit before the trigger (just in case)
% SD_crit                 - signal with amplitude exceeding value mean+SD_crit*SD will be considered spike
% spikeWidth              - [ms] Width of the signal  (spike) to be interpolated 
% interpolationTimeRage   - the spike is interpolated based on the time range (given by interpolationTimeRagesignal) before and after the spike. 


    p = inputParser;
    p.addParamValue('lookForSpikeRange', 10);
    p.addParamValue('lookForSpikeRange_shift', 5);
    p.addParamValue('SD_crit', 1.5);
    p.addParamValue('spikeWidth', 7);
    p.addParamValue('interpolationTimeRage', 20);
    p.addParamValue('showResults', 1);
    p.parse(varargin{:})
    
    % repeat spike removal until data looks ok
    isOK = 1;
    
    % 
    if p.Results.showResults
        EEGorig = EEG;
    end
    
    epoched = 0;
    if length(size(EEG.data)) == 3
        epoched = 1;
        EEG.data=reshape(EEG.data, size(EEG.data, 1), size(EEG.data, 2)*size(EEG.data, 3));
    end
    
    % prepare the data and latencies of the triggers
    eventLatencies = cell2mat({EEG.event.latency});
    eventLatencies = round(eventLatencies);

    %convert to ms to samples
    lookForSpikeRange = round(EEG.srate*p.Results.lookForSpikeRange/1000); 
    lookForSpikeRange_shift = round(EEG.srate*p.Results.lookForSpikeRange_shift/1000);
    spikeWidth = round(EEG.srate*p.Results.spikeWidth/1000);
    interpolationTimeRage = round(EEG.srate*p.Results.interpolationTimeRage/1000);

    %% Interpolate spikes
    for channel = 1:EEG.nbchan
        foundSpikes = 0;
        colorprint([1 0 0], sprintf('Channel: %s ', EEG.chanlocs(channel).labels))
        for i=1:length(eventLatencies)
            %[spikeHeights,spikeLatencies] = findpeaks(dataAroundEvents(indx(i,:)),EEG.srate, 'Threshold', mean(dataAroundEvents(indx(i,:))) + SD_crit*std(dataAroundEvents(indx(i,:))));
            indx =[eventLatencies(i):eventLatencies(i)+lookForSpikeRange]-lookForSpikeRange_shift; 

            dataAroundEvents = EEG.data(channel, indx);
            [spikeHeight,spikeLatency] = max(abs(detrend(dataAroundEvents-mean(dataAroundEvents))));
            spikeHeight = dataAroundEvents(spikeLatency);
            
            
            % select spikes that have high enough amplitude
            threshold = mean(dataAroundEvents) + p.Results.SD_crit * [-std(dataAroundEvents),std(dataAroundEvents)];            
            if spikeHeight < threshold(1) || spikeHeight >=threshold(2)
                foundSpikes=foundSpikes+1;
                % select position of the given spike       
                spike = spikeLatency + min(indx);

                % select data around the spike. 
                dataForInterpolation = EEG.data(channel, spike-spikeWidth-interpolationTimeRage+1:spike+spikeWidth+interpolationTimeRage);
                dataForInterpolationIndx = spike-spikeWidth-interpolationTimeRage+1:spike+spikeWidth+interpolationTimeRage;

                % recalculate the spike position to match the selected data 
                spike = spikeWidth + interpolationTimeRage;

                % change spike to nans 
                dataForInterpolation(spike-spikeWidth:spike+spikeWidth) = nan;

                % interpolate the missing signal: use samples preceding and following
                % the spike to interpolate the spike
                interploated = interp1(find(~isnan(dataForInterpolation)), ...
                                       dataForInterpolation(~isnan(dataForInterpolation)), ...
                                       find(isnan(dataForInterpolation)),'pchip');

                dataForInterpolation(isnan(dataForInterpolation)) = interploated;

                EEG.data(channel, dataForInterpolationIndx) = dataForInterpolation;
            else
                continue
%                 figure()
%                 hold on                
%                 plot(dataAroundEvents)
%                 plot(spikeLatency, spikeHeight, 'r.')
%                 keyboard
            end
        end
        colorprint([1 0 0], sprintf('  Found spikes: %g  \n', foundSpikes))
    end

    if epoched
        EEG.data=reshape(EEG.data, size(EEG.data, 1), EEG.pnts, EEG.trials);
    end

     
%% show results - ERPs with interpolated spikes
    if p.Results.showResults
        if epoched
            ERPinterp = EEG;
            ERPinterp.bindata = mean(ERPinterp.data,3);
            ERPorig = EEGorig;
            ERPorig.bindata = mean(ERPorig.data,3);
            plotERPfigures(ERPinterp, ERPorig, EEG, EEGorig);
        else
            [ERPinterp, ERPorig]  =  calculateERPs(EEG, EEGorig);
            plotERPfigures(ERPinterp, ERPorig, EEG, EEGorig);
        end
        uiwait(gcf)                     
        isOK = input('Is data ok? Yes [1], No [0]');
                    
    end
    
end

function [ERPinterp, ERPorig] = calculateERPs(EEG, EEGorig)
    
    % average interpolated data
    EEG2 = EEG;
    eventlistFile = fullfile(pwd,'Eventlists/eventlist_Tactile.txt');
                    EEG2 = pop_editeventlist( ...
                        EEG2, ...
                        'AlphanumericCleaning', 'on', ...
                        'BoundaryNumeric', { -99}, ...
                        'BoundaryString', { 'boundary' }, ...
                        'List',eventlistFile, ...
                        'SendEL2', 'EEG', ...
                        'UpdateEEG', 'binlabel', ...
                        'Warning', 'off' ); 
                    EEG2 = pop_epochbin(EEG2 , [-abs(300) 300],'pre','warning', 'off');    

    ERPinterp = pop_averager( EEG2 , 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on' );


    % average original data
    EEG2 = EEGorig;
    eventlistFile = fullfile(pwd,'Eventlists/eventlist_Tactile.txt');
                    EEG2 = pop_editeventlist( ...
                        EEG2, ...
                        'AlphanumericCleaning', 'on', ...
                        'BoundaryNumeric', { -99}, ...
                        'BoundaryString', { 'boundary' }, ...
                        'List',eventlistFile, ...
                        'SendEL2', 'EEG', ...
                        'UpdateEEG', 'binlabel', ...
                        'Warning', 'off' ); 
                    EEG2 = pop_epochbin(EEG2 , [-abs(300) 300],'pre','warning', 'off');    

    ERPorig = pop_averager( EEG2 , 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on' );

end


function plotERPfigures(ERPinterp, ERPorig, EEG, EEGorig)
    close all    
    channel = 1;
    
    eventLatencies = cell2mat({EEG.event.latency});
    eventLatencies = round(eventLatencies);

    
    fig = figure();
    set(gcf, 'Color',[1,1,1]) ;
    updatePlot([], [])
    
        % add popup menu with channels   
    c = uicontrol('Style', 'popup',...
                  'BackgroundColor', [0.9 0.9 0.9],...
                  'Units', 'normalized', ...
                  'String', {ERPinterp.chanlocs.labels},...
                  'Position', [0.91 0.1 0.08 0.85],...
                  'Value', channel, ...
                  'Callback', @updatePlot); 
              
function updatePlot(hObj, event)
    if ~isempty(hObj)
        channel = get(hObj, 'Value');
    end
%     cla    
    s1=subplot(221);
    set(s1,'Position', [0.05 0.5 0.44 0.42]);
%     hold on
    plot(ERPinterp.times,ERPinterp.bindata(channel,:), 'LineWidth', 3)
    ylim([-10, 20])
    line([0,0], get(gca, 'Ylim'),'LineStyle', '--',  'Color', 'r', 'LineWidth', 1)
    title('INTERPOLATED', 'FontSize', 20)
    
    s2=subplot(222);
    set(s2,'Position', [0.528 0.5 0.44 0.42]);
%     hold on
    plot(ERPorig.times,ERPorig.bindata(channel,:), 'LineWidth', 3)
    ylim([-10, 20])
    line([0,0], get(gca, 'Ylim'),'LineStyle', '--',  'Color', 'r', 'LineWidth', 1)    
    title('ORIGINAL', 'FontSize', 20)
 
    s3 = subplot(2,2,3:4);
    set(s3,'Position', [0.05 0.1 0.92 0.341163]);
    cla
    hold on
    try
    plot(EEGorig.times, EEGorig.data(channel,:),'r', 'LineWidth', 3)
    plot(    EEG.times,     EEG.data(channel,:),'k', 'LineWidth', 1)
    plot(eventLatencies/EEG.srate*1000, zeros(size(eventLatencies)),'.', 'MarkerSize', 6,'LineWidth', 4, 'color', 'g')
    legend({'Original signal', 'Removed spikes', 'Triggers'})
    end;

     
%         , 
        
end
end

















