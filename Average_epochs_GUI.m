classdef Average_epochs_GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        ShowaverageButton  matlab.ui.control.StateButton
        ChannelsmapButton  matlab.ui.control.Button
        NocomponentButton  matlab.ui.control.Button
        PropagateButton    matlab.ui.control.Button
        FinishButton       matlab.ui.control.Button
        ChannelsListBox    matlab.ui.control.ListBox
        Slider             matlab.ui.control.Slider
        UIAxes             matlab.ui.control.UIAxes
        StatusBar          matlab.ui.control.UIAxes
        YlimEditField      matlab.ui.control.EditField

        EEG
        channel_labels = []
        curr_N_epochs = 1   % current number of epochs to be averaged
        curr_channel  = 1   % current channel to show
        grand_average       % Total average for all epochs

        % Adjustable Settings
        Settings = {}
        

        % COLORS
        gray = '#808080'
        blue = "#0000ff"
        green = "#1dd100"

        % ERP DETECTION
        min_number_of_epochs = 50       % [Settings]
        ERP_search_window = 0.01 %in s  % [Settings]
        
        current_latency
        ERP_latencies = []
        ERP_is_component = []  % 0: no component, 1: component present
        ERP_amplitudes = []

        % PLOTTING
        show_grand_average = false
        xaxis             % X-axis (time) for the plots % [Settings]
        xlim
        ylim = [-10, 10]        
        Output = []
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1138 662];
            app.UIFigure.Name = 'ERP Epoch Averaging Tool';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, '')
            xlabel(app.UIAxes, 'Time [s]')
            ylabel(app.UIAxes, 'Amplitude [uV]')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [1 109 1033 554];
            app.UIAxes.ButtonDownFcn = @(src,evt) axesClicked(app, src, evt);     
    
            % Create colorful statusbar (showich which epochs were already
            % processed)
            app.StatusBar = uiaxes(app.UIFigure);
            app.StatusBar.Position = [5 100 1115 5];
            %app.StatusBar.XLim = [1, app.EEG.trials];
            app.StatusBar.XTick = [];
            app.StatusBar.YTick = [];
            app.StatusBar.Visible = 'off';

            % Create Slider
            app.Slider = uislider(app.UIFigure);
            app.Slider.Position = [12 89 1097 3];
            app.Slider.ValueChangedFcn = @(src,event) sliderValueChanged(app,src,event);
            app.UIFigure.WindowKeyPressFcn = @(src,event) figureKeyPressed(app, src, event);

            % Create ChannelsListBox
            app.ChannelsListBox = uilistbox(app.UIFigure);
            app.ChannelsListBox.Position = [1045 133 85 516];
            app.ChannelsListBox.ValueChangedFcn = @(src,event) ChannelsListBoxValueChanged(app, src, event);

            % Create FinishButton
            app.FinishButton = uibutton(app.UIFigure, 'push');
            app.FinishButton.Position = [1021 20 100 23];
            app.FinishButton.Text = 'Finish';
            app.FinishButton.ButtonPushedFcn = @(src,event) FinishButtonPushed(app, src, event);

            % Create PropagateButton
            app.PropagateButton = uibutton(app.UIFigure, 'push');
            app.PropagateButton.Position = [901 20 100 23];
            app.PropagateButton.Text = 'Propagate';
            app.PropagateButton.ButtonPushedFcn = @(src,event) PropagateButtonPushed(app, src, event);

            % Create ChannelsmapButton
            app.ChannelsmapButton = uibutton(app.UIFigure, 'push');
            app.ChannelsmapButton.Position = [781 20 100 23];
            app.ChannelsmapButton.Text = 'Channels map';
            app.ChannelsmapButton.ButtonPushedFcn = @(src,event) ChannelsmapButtonPushed(app, src, event);


            % Create ShowaverageButton
            app.ShowaverageButton = uibutton(app.UIFigure, 'state');
            app.ShowaverageButton.Position = [661 20 100 23];
            app.ShowaverageButton.Text = 'Show average';
            app.ShowaverageButton.ValueChangedFcn = @(src,event) showAverageToggled(app, src, event);

            % Create NocomponentButton
            app.NocomponentButton = uibutton(app.UIFigure, 'push');
            app.NocomponentButton.Position = [541 20 100 23];
            app.NocomponentButton.Text = 'No component';
            app.NocomponentButton.ButtonPushedFcn = @(src,event) NocomponentButtonPushed(app, src, event);

            % Create YlimEditField
            app.YlimEditField = uieditfield(app.UIFigure, 'text');
            app.YlimEditField.Position = [421 20 100 23];    % adjust coords/size
            app.YlimEditField.Value = num2str(app.ylim(2)) ;                % initial value
            app.YlimEditField.ValueChangedFcn = @(src,event) editFieldValueChanged(app, src, event);

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end

        % === EEG structure handling
        function compute_EEG_averages(app, src, ~)
            h = waitbar(0,'Averaging epochs.....');
            averaged_data = nan(size(app.EEG.data));
            for epoch = 1:app.EEG.trials
                averaged_data(:, :, epoch) = mean(app.EEG.data(:, :, 1:epoch), 3, 'omitnan');
                waitbar(epoch/app.EEG.trials,h);
            end
            app.EEG.averaged_data = averaged_data;
            close(h);
        end

        % === Callbacks
        function sliderValueChanged(app, src, ~)
            app.curr_N_epochs = round(src.Value);
            refresh_plot(app)
        end

        function figureKeyPressed(app, ~, event)
            % Respond to left/right arrow keys to move slider by one step
            if isempty(app.Slider) || isempty(app.Slider.Limits)
                return
            end
    
            % Determine step: for epoch index sliders use step = 1; otherwise choose a fraction
            limits = app.Slider.Limits;
            % If slider values are integer epoch indices:
            step = 1;
    
            switch event.Key
                case 'leftarrow'
                    newVal = app.Slider.Value - step;
                case 'rightarrow'
                    newVal = app.Slider.Value + step;
                otherwise
                    return
            end
    
            % Clamp and round if discrete steps expected
            newVal = max(limits(1), min(limits(2), newVal));
            newVal = round(newVal);              % keep integer epoch indices
    
            % Only assign and trigger change if different
            if newVal ~= app.Slider.Value
                app.Slider.Value = newVal;       % this will invoke ValueChangedFcn if defined
                % If you use ValueChangingFcn instead, call your update manually:
                sliderValueChanged(app, app.Slider, []);
            end

            
        end

        function editFieldValueChanged(app, src, ~)
            val = str2double(src.Value);            
            app.ylim = [-abs(val), abs(val)];
            refresh_plot(app)
        end

        function ChannelsListBoxValueChanged(app, src, ~)
            channel = src.Value;
            if isempty(channel)
                return
            end
            app.curr_channel = find_channel_by_label(app, channel);
            refresh_plot(app)

        end

        function ChannelsmapButtonPushed(app, src, ~)
            figure; topoplot([],app.EEG.chanlocs, ...
                'style', 'blank', ...
                'electrodes', 'labelpoint', ...
                'chaninfo', app.EEG.chaninfo);
        end

        function PropagateButtonPushed(app, src, ~)
            start_latency_sec = app.ERP_latencies(app.curr_channel, 1, app.curr_N_epochs);

            % Search from the current epoch to the end
            latency_sec = start_latency_sec;
            for epoch = app.curr_N_epochs : app.EEG.trials
                if app.ERP_is_component(app.curr_channel, 1, epoch) == 0
                    continue
                end

                latency_sec = detectEpochLatency(app, src, epoch, latency_sec);
                if isnan(latency_sec)
                   refresh_plot(app)
                   break    % exit loop but continue with code after the loop
                end
            end

            % Search from the current epoch to the beginning
            latency_sec = start_latency_sec;
            for epoch = app.curr_N_epochs-1:-1: app.min_number_of_epochs
                if app.ERP_is_component(app.curr_channel, 1, epoch) == 0
                    continue
                end

                latency_sec = detectEpochLatency(app, src, epoch, latency_sec);
                if isnan(latency_sec)
                   refresh_plot(app)
                   break    % exit loop but continue with code after the loop
                end                
            end

            refresh_plot(app)
        end

        function latency_sec = detectEpochLatency(app, src, epoch, latency_sec)
            % Update or detect latency for given channel/epoch and return a numeric value.
            % If detection fails, keep latency_sec unchanged and mark ERP_latencies as NaN.


            % If latency not yet detected (NaN) -> try detect
            if isnan(app.ERP_amplitudes(app.curr_channel, 1, epoch))
               % Search for peaks
               [amplitude, detected_latency] = find_peak(app, epoch, latency_sec);
               
               % if the peak detection failed, find the peak manually
               if isempty(detected_latency)  
                   app.curr_N_epochs = epoch;
                   app.Slider.Value = epoch;
                   latency_sec = NaN;
                   return
               else
                    % Successful detection -> update latency and stored table
                    latency_sec = detected_latency;
                    app.ERP_latencies(app.curr_channel, 1, epoch) = latency_sec;
                    app.ERP_is_component(app.curr_channel, 1, epoch) = 1;
               end
            else
                % Already detected: read stored value
               latency_sec = app.ERP_latencies(app.curr_channel, 1, epoch);
            end
        end

        function NocomponentButtonPushed(app, src, ~)
            app.ERP_latencies(app.curr_channel, 1, app.curr_N_epochs) = nan;
            app.ERP_is_component(app.curr_channel, 1, app.curr_N_epochs) = 0;
            refresh_plot(app)
        end

        function FinishButtonPushed(app, ~, ~)
            % 1. Save the modified data into the Output property
            app.EEG.Cumulative_ERP_averaging = {};
            app.EEG.Cumulative_ERP_averaging.averaged_data = app.EEG.averaged_data;
            app.EEG.Cumulative_ERP_averaging.ERP_latencies = app.ERP_latencies;
            app.EEG.Cumulative_ERP_averaging.ERP_is_component = app.ERP_is_component;

            app.EEG = rmfield(app.EEG, 'averaged_data');
            
            app.Output = app.EEG;
            
            % 2. Resume execution (this "unblocks" the uiwait in run_app)
            uiresume(app.UIFigure);
        end


        % === Plotting
        function showAverageToggled(app, src, ~)
            app.show_grand_average = src.Value == 1;
            refresh_plot(app)
        end

        function plot_current_average(app, src, ~)
            %average = mean(app.EEG.data(app.curr_channel, :, 1:app.curr_N_epochs), 3, 'omitnan');
            average = app.EEG.averaged_data(app.curr_channel, :, app.curr_N_epochs);
            plot(app.UIAxes, app.xaxis, average, 'Color', app.blue)
            
            current_marked_peak_latency = app.ERP_latencies(app.curr_channel, 1, app.curr_N_epochs);
            if ~isnan(current_marked_peak_latency)

                % Plot green area around the peak
                mask = (app.xaxis >= current_marked_peak_latency - app.ERP_search_window) & (app.xaxis <= current_marked_peak_latency + app.ERP_search_window);
                idx  = find(mask);   
                plot(app.UIAxes, app.xaxis(idx), average(idx), ...
                    'Color', app.green, ...
                    'LineWidth', 1.5)
                
                % Plot the peak
                [c, idx] = min(abs(app.xaxis - current_marked_peak_latency));
                plot(app.UIAxes, app.xaxis(idx), average(idx), ...
                    'o',...
                    'Color', app.green, ...
                    'MarkerEdgeColor','red',...
                    'MarkerSize',10)
            end
        end

        function plot_grid_lines(app, src, ~)
            yline(app.UIAxes, 0, '--', 'LineWidth', 0.5);
            xline(app.UIAxes, 0, '--', 'LineWidth', 0.5);
        end

        function refresh_plot(app, src, ~)
            cla(app.UIAxes)

            hold(app.UIAxes, 'on')
            xlim(app.UIAxes, app.xlim)
            ylim(app.UIAxes, app.ylim)

            % Plot horizontal and vertical lines
            plot_grid_lines(app)

            % Plot grand average
            if app.show_grand_average
                get_grand_average(app)
                plot(app.UIAxes, app.xaxis, app.grand_average, 'LineWidth', 0.5, 'Color', app.gray )
            end

            % Plot current average
            plot_current_average(app)

            % Add a small textbox to the figure 
            if app.ERP_is_component(app.curr_channel, 1, app.curr_N_epochs) == 0
                s = sprintf('Epochs: %g \n Component: MISSING', app.curr_N_epochs);
            elseif app.ERP_is_component(app.curr_channel, 1, app.curr_N_epochs) == 1
                s = sprintf('Epochs: %g \n Component: OK', app.curr_N_epochs);
            else
                s = sprintf('Epochs: %g \n Component: ...', app.curr_N_epochs);
            end
            text(app.UIAxes, 0.9, 0.9, s, ...
                'Units', 'normalized', ...  
                'BackgroundColor', 'white', ...
                'EdgeColor', 'black');

            % Plot a status bar
            C = squeeze(app.ERP_is_component(app.curr_channel, :, :))';
            C(isnan(C)) = -1;

            h = image(app.StatusBar, ...
                      1:app.EEG.trials, 1,...
                      C ...
                      ); 
            h.CDataMapping = 'scaled'; 
            colormap(app.StatusBar, [1 1 1; 1 0 0; 0 1 0]); 
            app.StatusBar.CLim = [-1 1]; 
            

            hold(app.UIAxes, 'off')

        end
        
        % === Component selection
        function axesClicked(app, src, ~)
            % src is the axes; get mouse position in axes coordinates
            cp = src.CurrentPoint;    % 2x3 matrix: [x y z; ...]
            latency_sec= cp(1,1);
            app.ERP_latencies(app.curr_channel, 1, app.curr_N_epochs) = latency_sec;
            app.ERP_is_component(app.curr_channel, 1, app.curr_N_epochs) = 1;
            refresh_plot(app)
        end

        function [amplitude, latency] = find_peak(app, epoch, latency_sec)
            % Select signal fragment
            mask = (app.xaxis >= latency_sec-app.ERP_search_window) & (app.xaxis <= latency_sec + app.ERP_search_window);
            idx  = find(mask);   
            signal_fragment = app.EEG.averaged_data(app.curr_channel, idx, epoch);

            % Peak detection
            [amplitudes, latencies] = findpeaks(signal_fragment);
            if isempty(latencies)
                [amplitudes, latencies] = findpeaks(diff(signal_fragment));
            end
            latencies = sample_to_sec(app, latencies);

            % convert to global indices (time)
            latencies = latencies + latency_sec-app.ERP_search_window;

            % Select peak closest to the center of search window
            [c, idx] = min(abs(latencies - latency_sec));
            latency = latencies(idx);
            amplitude = amplitudes(idx);
        end

        % === Utils
        function get_grand_average(app)
            app.grand_average = mean(app.EEG.data(app.curr_channel, :, :), 3, 'omitnan');
        end

        function channel_number = find_channel_by_label(app, label)
            labelsStr = string(app.channel_labels);
            target = string(label);

            eqMask = strcmpi(labelsStr, target);
            if any(eqMask)
                channel_number = find(eqMask, 1, 'first');
                return
            end
        end

        function seconds = sample_to_sec(app, sample)
            seconds = sample / app.EEG.srate;
        end

        function samples = sec_to_sample(app, seconds)
            samples = round(seconds * app.EEG.srate);
        end

        function parse_settings(app, Settings)
            if isempty(Settings) || ~isstruct(Settings)
                return;
            end
        
            % Get all field names provided in the Settings struct
            fields = fieldnames(Settings);
        
            for i = 1:numel(fields)
                fieldName = fields{i};
                
                % Check if the property exists in the app class
                if isprop(app, fieldName)
                    app.(fieldName) = Settings.(fieldName);
                else
                    % Optional: Warn if a setting was passed that the app doesn't use
                    fprintf("Warning: '%s' is not a valid property of the app. Skipping.\n", fieldName);
                end
            end
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Average_epochs_GUI(inputEEG, Settings) 
            % Parse settings (use default values if not present in
            % Settings)
            parse_settings(app, Settings)

            % Create UIFigure and components
            createComponents(app)
            
            % Prepare EEG struct
            app.EEG = inputEEG; 
            compute_EEG_averages(app)
            app.channel_labels = {app.EEG.chanlocs.labels};
                     

            % Register the app with App Designer
            registerApp(app, app.UIFigure)
            
            % Initialize components (e.g., set slider limits based on EEG data)
            if ~isempty(app.EEG)
                app.Slider.Limits = [1, app.EEG.trials]; 
                app.ChannelsListBox.Items = string({app.EEG.chanlocs.labels});
                app.ERP_latencies = nan(app.EEG.nbchan, 1, app.EEG.trials);
                app.ERP_is_component  = nan(app.EEG.nbchan, 1, app.EEG.trials);
                app.ERP_is_component(:, :, 1:app.min_number_of_epochs) = 0;
                app.ERP_amplitudes = nan(app.EEG.nbchan, 1, app.EEG.trials);
            end

            % Rename the window app
            if isfield(inputEEG, 'filename')
                app.UIFigure.Name = strrep(app.EEG.filename, ".set", "");
            end

            % Calculate some variables required for plotting (such as plot
            % X-axis)            
            app.xaxis = linspace(app.EEG.xmin, app.EEG.xmax, app.EEG.pnts);
            if isempty(app.xlim)
                app.xlim = [app.EEG.xmin, app.EEG.xmax];
            end
            app.UIAxes.XMinorTick = 'on';
            app.UIAxes.XGrid = 'on';  
            app.UIAxes.XAxis.MinorTickValues = app.xlim(1) : 0.01 : app.xlim(2);
            app.UIFigure.WindowState = 'maximized';

            % Initialize plot
            refresh_plot(app)


            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end

    methods (Static)
        function outEEG = run_app(EEG_input, Settings)
            % 1. Create the app instance
            app = Average_epochs_GUI(EEG_input, Settings);
            
            % 2. Wait here until uiresume is called (or figure is closed)
            uiwait(app.UIFigure);
            
            % 3. Check if the app still exists (user didn't just X-out)
            if isvalid(app)
                outEEG = app.Output;
                delete(app); % Now it's safe to delete
            else
                % If the user closed the window via 'X', return original data
                warning('GUI closed without clicking Finish. Returning original EEG.');
                outEEG = EEG_input; 
            end
        end
    end
end