% function EEG = removeEpochs_singleChannel(EEG, varargin)
function EEG = removeEpochs_singleChannel(EEG, varargin)
% TODO
% dodać opcje zmiany skali amplitudy sygnalu  - amplitudeScale

% PARSE ARGUMENTS AND CREATE DEFAULT VALUES
p = inputParser;
p.addRequired('EEG');
p.addParameter('channelsToPlot', {EEG.chanlocs.labels});
p.addParameter('channelsOfInterest','0');
p.addParameter('howManyEpochsToDisplay',10);
p.addParameter('colorOfChannelsInterest',[0, 1, 0]);
p.addParameter('defaultColor',[0, 0, 0]);
p.addParameter('whatToPlot','data');
p.addParameter('amplitudeScale',1);
p.addParameter('fft_freq_range',[1 30]);
p.addParameter('plotEvents', false);
p.addParameter('line_colors_and_styles', {});
p.addParameter('resaple_rate', 32);
p.parse(EEG, varargin{:});

channelsToPlot             = 1:length(p.Results.channelsToPlot);
channelsLabels             = p.Results.channelsToPlot;
channelsOfInterest         = p.Results.channelsOfInterest;
colorOfInterest            = p.Results.colorOfChannelsInterest;
defaultColor               = p.Results.defaultColor;
howManyEpochsToDisplay     = p.Results.howManyEpochsToDisplay;
amplitudeScale             = p.Results.amplitudeScale;
plotEvents                 = p.Results.plotEvents;
line_colors_and_styles     = p.Results.line_colors_and_styles;
resaple_rate               = p.Results.resaple_rate;

% Check if EEG.data is epoched
if ndims(EEG.data) ~= 3 
    errordlg('Input EEG data must be epoched!')
    return
end 

% Define defaults
blue_color = "#01BABA";
green_color = "#01ba03";
rejection_mode = 'IndividualMode';
channel_offset = 50;

% Resample EEG data for faster plotting
if resaple_rate > 0
    EEG_toplot = pop_resample(EEG, resaple_rate); 
else
    EEG_toplot = EEG;
end
% Get the data to plot (EEG or FFT)
if isequal(p.Results.whatToPlot, 'data')
    dataToPlot = EEG_toplot.(p.Results.whatToPlot)*-1;
elseif isequal(p.Results.whatToPlot, 'fft')
    dataToPlot = abs(EEG_toplot.fft.fft_absolutePower_all)*-1;
    freqs1 = EEG_toplot.fft.fft_freqs >= p.Results.fft_freq_range(1);
    freqs2 = EEG_toplot.fft.fft_freqs < p.Results.fft_freq_range(2);
    dataToPlot = dataToPlot(:, find(freqs1 .* freqs2), :);
end


% Initialize objects
xtickPositions      = [];
xLabels             = {};
selectedEpoch       = [];
selectedChannel     = [];
rejectedCells       = nan(EEG_toplot.nbchan, EEG_toplot.trials);
epochLength         = size(dataToPlot, 2);
curEpochs           = [1, howManyEpochsToDisplay];
EEG_event_types     = {EEG_toplot.event.type};
EEG_event_latency   = {EEG_toplot.event.latency};
xLim                = [1, howManyEpochsToDisplay*epochLength]; 


%% CREATE THE FIGURE
signalFigure = createFigureToPlotSignal();
set(signalFigure, 'WindowButtonDownFcn', @ButtonDownFcnCallback)

refresh_figure()

%% Add buttons to the figure
uiwait(signalFigure)


function signalFigure = createFigureToPlotSignal()  
        signalFigure = figure('WindowState', 'maximized');

        h1=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', '2',...
           'String', 'REMOVE','Units', 'normalized',...
           'Position', [0.35 0 0.3 0.07],'BackgroundColor', [0.5, 0.5, 0.5],...
           'Callback', {@REMOVE});  
        h2=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', 'scrollLeft',...
           'String', '<<','Units', 'normalized',...
           'Position', [0.248 0 0.1 0.07],'BackgroundColor', [0.3, 0.3, 0.3],...
           'Callback', {@SCROLL_PLOT});  

        h3=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', 'scrollRight',...
           'String', '>>','Units', 'normalized',...
           'Position', [0.652 0 0.1 0.07],'BackgroundColor', [0.3, 0.3, 0.3],...
           'Callback', {@SCROLL_PLOT}); 
        
        % Buttons defining rejection type (Whole poch, whole channel,
        % single epoch/channel)
        h4=uicontrol('Style', 'pushbutton' , 'Max', 0, 'Tag', 'EpochMode',...
           'String', 'Epoch','Units', 'normalized',...
           'Position', [0.01 0.02 0.05 0.03],...
           'BackgroundColor', blue_color,...
           'Callback', {@set_rejection_mode}); 
        h5=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', 'ChanMode',...
           'String', 'Channel','Units', 'normalized',...
           'Position', [0.07 0.02 0.05 0.03],...
           'BackgroundColor', blue_color,...
           'Callback', {@set_rejection_mode}); 
        h6=uicontrol('Style', 'pushbutton' , 'Max', 0,'Tag', 'IndividualMode',...
           'String', 'Single','Units', 'normalized',...
           'Position', [0.13 0.02 0.05 0.03],...
           'BackgroundColor', green_color,...
           'Callback', {@set_rejection_mode});         

        axes('position',[0.03 0.1 0.96 0.9]) % [left, bottom, width, height]
                
        % setting up channels labels and ticks positions
        ytickPositions = channel_offset* (1:length(channelsToPlot)); 
        ylim([ytickPositions(1)-channel_offset, ytickPositions(end)+channel_offset]);

        set(gca,'yTick', ytickPositions, 'yTickLabel', channelsLabels);
        set(gca, 'FontWeight', 'bold', 'FontSize', 12)
        set( gca, 'YDir', 'reverse' )
end

function refresh_figure()
    cla

    plot_signal()
   
    display_vertical_lines() 
    %display_events()

end

function display_vertical_lines()    
    % Display vertical lines marking epochs edges
    xtickPositions = 1 : epochLength/2 : howManyEpochsToDisplay*epochLength;
    xLabels = repmat({''}, 1, size(xtickPositions, 2));
    epochs = curEpochs(1) : curEpochs(2);
    for i=1 : howManyEpochsToDisplay
        xLabels{i*2} = num2str(epochs(i));
%       xLabels{i*2-1} = EEG_event_types{ceil(xLim(1) / epochLength):xLim(2) / epochLength};       
    end  
    set(gca,'xTick', xtickPositions, 'xTickLabel', xLabels);

    % display vertical lines on the plot:
    for j= 1 : 2: size(xtickPositions, 2)
        line([xtickPositions(j) xtickPositions(j)], get(gca, 'YLim'), 'LineStyle', '--', 'Color', [0 0 0])
    end
    
end

function display_events()
    % Display events
    if plotEvents
        ylim = get(gca, 'YLim');
        for e = 1:length(EEG_event_types)
            if (EEG_event_latency{e} >= xLim(1)) && (EEG_event_latency{e} <= xLim(2))
                event_line_xpos = EEG_event_latency{e} - xLim(1);
                if isfield(line_colors_and_styles, EEG_event_types{e})
                    linestyle = line_colors_and_styles.(EEG_event_types{e}).linestyle;
                    color = line_colors_and_styles.(EEG_event_types{e}).color;
                else
                    linestyle = '-';
                    color = [0 0 0];
                end
                line([event_line_xpos event_line_xpos], ylim, 'LineStyle', linestyle, 'Color', color)
                text(event_line_xpos, ylim(2)*0.1, EEG_event_types{e});
            end
        end
    end
end

function plot_signal()       
    cla; 
    visibleEpochs = curEpochs(1):curEpochs(2);
    for i = 1:length(channelsToPlot)
        chanIdx = channelsToPlot(i);
        hold on;
        yOffset = i * channel_offset;

        % 1. Get the original signal for the visible range
        % Size: [1, epochLength * numVisible]
        sig_segment = reshape(dataToPlot(chanIdx, :, visibleEpochs), 1, []);
        
        % 2. Create the "Rejection Mask" for the visible range
        if any(rejectedCells(chanIdx, visibleEpochs) == 1)
            mask_row = double(rejectedCells(chanIdx, visibleEpochs)); 
            
            % This line expands [1, NaN, 1] into [ones(1,3072), nans(1,3072), ones(1,3072)]
            expanded_mask = repelem(mask_row, 1, epochLength);
            
            % 3. Calculate the red line data
            % This will result in the signal value where rejected, and NaN where clean
            red_line_data = sig_segment .* expanded_mask;
    
            % 4. Plot the Red Overlay
            plot(red_line_data * amplitudeScale + yOffset, 'color', [1 0 0], 'LineWidth', 2);
        end
        % 5. Plot the Base Signal
        color = defaultColor;
        width = 1;
        if ismember(chanIdx, channelsOfInterest)
            color = colorOfInterest;
            width = 2;
        end
        plot(ones(1, length(sig_segment))* amplitudeScale + yOffset, 'color', [0.7, 0.7, 0.7], 'LineWidth', 0.2);
        plot(sig_segment * amplitudeScale + yOffset, 'color', color, 'LineWidth', width);

    end        
end

function set_rejection_mode(hObj, event)
    tag=get(hObj, 'Tag');   
    rejection_mode = tag;

    for t = ["EpochMode", "ChanMode", "IndividualMode"]
        btn = findobj('Tag', t);
        if isequal(t, tag)
            set(btn, 'BackgroundColor', green_color);
        else
            set(btn, 'BackgroundColor', blue_color);
        end
    end
end

function SCROLL_PLOT(hObj, event)
        tag=get(hObj, 'Tag');    
       
        % Scroll left
        if isequal(tag, 'scrollLeft')
            curEpochs(1) = max(1, curEpochs(1) - howManyEpochsToDisplay);
            curEpochs(2) = curEpochs(1) + howManyEpochsToDisplay-1;

        % Scroll right    
        elseif isequal(tag, 'scrollRight')
            curEpochs(2) = min(curEpochs(2) + howManyEpochsToDisplay, EEG_toplot.trials);
            curEpochs(1) = curEpochs(2) - howManyEpochsToDisplay+1;
        end

        refresh_figure()
end

function REMOVE(hObj, event)
        rejectedCells(isnan(rejectedCells)) = 0;

        for chan = 1:EEG_toplot.nbchan            
           EEG.data(chan, :,  find(rejectedCells(chan, :))) = NaN;
           if isfield(EEG, 'fft')
                EEG.fft.fft_absolutePower_all(chan, :,  find(rejectedCells(chan, :))) = NaN;
           end
        end        
        
        EEG = addHistory(EEG, "individualCellsRejection", rejectedCells);

        close(signalFigure)
        
end

function ButtonDownFcnCallback(x, ~)
    C = get(gca, 'CurrentPoint');
    x = C(1,1);
    y = C(1,2);
    
    % get clicked trial and channel
    sec = round(x);    
    selectedEpoch = ceil(sec / epochLength)+ ceil(xLim(1) / epochLength)-1;
    selectedEpoch = selectedEpoch + curEpochs(1) -1;
    selectedChannel = ceil((y-25)/channel_offset);

    if isequal(rejection_mode, 'EpochMode')
        selectedChannel = 1:EEG_toplot.nbchan;
    elseif isequal(rejection_mode, 'ChanMode')
        selectedEpoch = curEpochs(1) : curEpochs(2);
    end
    % update array defining which trials should be excluded
    if isnan(rejectedCells(selectedChannel, selectedEpoch))
        rejectedCells(selectedChannel, selectedEpoch) = 1;
    else
        rejectedCells(selectedChannel, selectedEpoch) = NaN;
    end
    refresh_figure()
end



end

