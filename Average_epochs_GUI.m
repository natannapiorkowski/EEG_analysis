classdef Average_epochs_GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                matlab.ui.Figure
        ShowaverageButton       matlab.ui.control.StateButton
        ChannelsmapButton       matlab.ui.control.Button
        NocomponentButton       matlab.ui.control.Button
        PropagateButton_left    matlab.ui.control.Button
        PropagateButton_right   matlab.ui.control.Button
        FinishButton            matlab.ui.control.Button
        SaveimageButton         matlab.ui.control.Button % Added for new logic
        AddComponentButton      matlab.ui.control.Button % Added for new logic
        ChannelsListBox         matlab.ui.control.ListBox
        ComponentListBox        matlab.ui.control.ListBox % Added for new logic
        Slider                  matlab.ui.control.Slider
        UIAxes                  matlab.ui.control.UIAxes
        StatusBar               matlab.ui.control.UIAxes
        YlimEditField           matlab.ui.control.EditField

        EEG
        channel_labels = []
        curr_N_epochs = 1   % current number of epochs to be averaged
        curr_channel  = 1   % current channel to show
        grand_average       % Total average for all epochs

        % Multi-component properties
        ComponentNames = {'P1'} 
        ComponentColors = {[0.11, 0.82, 0.0]} % RGB double
        CurrentComponentIndex = 1

        % Adjustable Settings
        Settings = {}
        
        % General
        app_name = 'Peak Performance'

        % COLORS
        gray = '#808080'
        blue = "#0000ff"
        green = "#1dd100"

        % ERP DETECTION
        min_number_of_epochs = 50       % [Settings]
        ERP_search_window = 0.01 %in s  % [Settings]
        
        current_latency
        ERP_latencies = []    % Expanded to [chan x component x epoch]
        ERP_is_component = [] % 0: no component, 1: component present
        ERP_amplitudes = []

        % PLOTTING
        show_grand_average = false
        xaxis             % X-axis (time) for the plots % [Settings]
        xlim
        ylim = [-10, 10]        
        Output = []
        StatusBarPatch
        save_image_dirname = ''
        save_image_folderName = 'Peak_Performance_Images'

    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1138 662];
            app.UIFigure.Name = app.app_name;

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, '')
            xlabel(app.UIAxes, 'Time [s]')
            ylabel(app.UIAxes, 'Amplitude [uV]')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [1 109 1033 554];
            app.UIAxes.ButtonDownFcn = @(src,evt) axesClicked(app, src, evt);     
    

            % Create Slider
            app.Slider = uislider(app.UIFigure);
            app.Slider.Position = [12 89 1097 3];
            app.Slider.ValueChangedFcn = @(src,event) sliderValueChanged(app,src,event);
            app.UIFigure.WindowKeyPressFcn = @(src,event) figureKeyPressed(app, src, event);
            sliderPos = app.Slider.Position;

            % Create colorful statusbar (showich which epochs were already processed)
            app.StatusBar = uiaxes(app.UIFigure);
            app.StatusBar.Position = [sliderPos(1), 100, sliderPos(3), 15];
            app.StatusBar.XTick = [];
            app.StatusBar.YTick = [];
            app.StatusBar.Visible = 'off';
            app.StatusBar.XLim = app.Slider.Limits;
            app.StatusBar.YLim = [0.5 1.5]; % Keep the image vertically centered

            % Create ChannelsListBox
            app.ChannelsListBox = uilistbox(app.UIFigure);
            app.ChannelsListBox.Position = [1045 380 85 255]; % Adjusted for component list
            app.ChannelsListBox.ValueChangedFcn = @(src,event) ChannelsListBoxValueChanged(app, src, event);

            % Create ComponentListBox
            app.ComponentListBox = uilistbox(app.UIFigure);
            app.ComponentListBox.Position = [1045 160 85 190];
            app.ComponentListBox.Items = app.ComponentNames;
            app.ComponentListBox.ValueChangedFcn = @(src,event) ComponentListBoxValueChanged(app, src, event);

            % Create AddComponentButton
            app.AddComponentButton = uibutton(app.UIFigure, 'push');
            app.AddComponentButton.Position = [1045 133 85 23];
            app.AddComponentButton.Text = 'Add comp.';
            app.AddComponentButton.ButtonPushedFcn = @(src,event) AddComponentButtonPushed(app, src, event);

            % Create FinishButton
            app.FinishButton = uibutton(app.UIFigure, 'push');
            app.FinishButton.Position = [1021 20 100 23];
            app.FinishButton.Text = 'Finish';
            app.FinishButton.ButtonPushedFcn = @(src,event) FinishButtonPushed(app, src, event);

            % Create SaveimageButton
            app.SaveimageButton = uibutton(app.UIFigure, 'push');
            app.SaveimageButton.Position = [911 20 100 23];
            app.SaveimageButton.Text = 'Save image';
            app.SaveimageButton.ButtonPushedFcn = @(src,event) SaveimageButtonPushed(app, src, event);

            % Create PropagateButton_left
            app.PropagateButton_left = uibutton(app.UIFigure, 'push');
            app.PropagateButton_left.Position = [801 20 50 23];
            app.PropagateButton_left.Text = '<-';
            app.PropagateButton_left.ButtonPushedFcn = @(src,event) PropagateButtonPushed_left(app, src, event);

            % Create PropagateButton_right
            app.PropagateButton_right = uibutton(app.UIFigure, 'push');
            app.PropagateButton_right.Position = [851 20 50 23];
            app.PropagateButton_right.Text = '->';
            app.PropagateButton_right.ButtonPushedFcn = @(src,event) PropagateButtonPushed_right(app, src, event);

            % Create ChannelsmapButton
            app.ChannelsmapButton = uibutton(app.UIFigure, 'push');
            app.ChannelsmapButton.Position = [691 20 100 23];
            app.ChannelsmapButton.Text = 'Channels map';
            app.ChannelsmapButton.ButtonPushedFcn = @(src,event) ChannelsmapButtonPushed(app, src, event);

            % Create ShowaverageButton
            app.ShowaverageButton = uibutton(app.UIFigure, 'state');
            app.ShowaverageButton.Position = [581 20 100 23];
            app.ShowaverageButton.Text = 'Show average';
            app.ShowaverageButton.ValueChangedFcn = @(src,event) showAverageToggled(app, src, event);

            % Create NocomponentButton
            app.NocomponentButton = uibutton(app.UIFigure, 'push');
            app.NocomponentButton.Position = [471 20 100 23];
            app.NocomponentButton.Text = 'No component';
            app.NocomponentButton.ButtonPushedFcn = @(src,event) NocomponentButtonPushed(app, src, event);

            % Create YlimEditField
            app.YlimEditField = uieditfield(app.UIFigure, 'text');
            app.YlimEditField.Position = [361 20 100 23];
            app.YlimEditField.Value = num2str(app.ylim(2));
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
            limits = app.Slider.Limits;
            step = 1;
            switch event.Key
                case 'leftarrow'
                    newVal = app.Slider.Value - step;
                case 'rightarrow'
                    newVal = app.Slider.Value + step;
                otherwise
                    return
            end
            newVal = max(limits(1), min(limits(2), newVal));
            newVal = round(newVal);              
            if newVal ~= app.Slider.Value
                app.Slider.Value = newVal;       
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
            if isempty(channel), return; end
            app.curr_channel = find_channel_by_label(app, channel);
            refresh_plot(app)
        end

        function ComponentListBoxValueChanged(app, src, ~)
            app.CurrentComponentIndex = find(strcmp(app.ComponentNames, src.Value), 1);
            refresh_plot(app);
        end

        function AddComponentButtonPushed(app, ~, ~)
            d = uifigure('Name', 'Add Component', 'Position', [500 500 300 150], 'WindowStyle', 'modal');
            uilabel(d, 'Text', 'Name:', 'Position', [20 100 50 22]);
            editName = uieditfield(d, 'text', 'Position', [80 100 180 22], 'Value', '');
            pickedColor = [rand(), rand(), rand()]; 
            btnColor = uibutton(d, 'Position', [80 60 180 22], 'Text', 'Pick Color', 'BackgroundColor', pickedColor, 'ButtonPushedFcn', @(s,e) setColor());
            uibutton(d, 'Position', [100 20 80 22], 'Text', 'OK', 'ButtonPushedFcn', @(s,e) finalize());
            function setColor()
                c = uisetcolor(pickedColor);
                if length(c) == 3, pickedColor = c; btnColor.BackgroundColor = c; end
            end
            function finalize()
                name = editName.Value;
                app.ComponentNames{end+1} = name;
                app.ComponentColors{end+1} = pickedColor; 
                nComp = numel(app.ComponentNames);
                app.ERP_latencies(:, nComp, :) = nan;
                app.ERP_is_component(:, nComp, :) = nan;
                app.ERP_is_component(:, nComp, 1:app.min_number_of_epochs) = 0;
                app.ERP_amplitudes(:, nComp, :) = nan;
                app.ComponentListBox.Items = app.ComponentNames;
                app.ComponentListBox.Value = name;
                app.CurrentComponentIndex = nComp;
                close(d);
                refresh_plot(app);
            end
        end

        function ChannelsmapButtonPushed(app, src, ~)
            figure; topoplot([],app.EEG.chanlocs, 'style', 'blank', 'electrodes', 'labelpoint', 'chaninfo', app.EEG.chaninfo);
        end

        function SaveimageButtonPushed(app, ~, ~)
            to_save_path = fullfile(app.save_image_dirname, app.save_image_folderName, strrep(app.EEG.filename, '.set', ''));
            if ~exist(to_save_path, 'dir')
                mkdir(to_save_path); 
            end
            safeChan = strrep(char(app.ChannelsListBox.Value), ' ', '_');
            component = app.ComponentListBox.Value;
            fileName = fullfile(to_save_path, sprintf('ERP_%s_epochs_%d_%s.png', safeChan, app.curr_N_epochs, component));
            fprintf('Saving image to: %s', fileName)
            % Turn off layout updates
            app.UIFigure.AutoResizeChildren = 'off';
            exportgraphics(app.UIAxes, fileName);
            % Turn them back on
            app.UIFigure.AutoResizeChildren = 'on';
        end

        function PropagateButtonPushed_left(app, src, ~)
            propagate_peak_detection(app, src, 'left')
        end

        function PropagateButtonPushed_right(app, src, ~)
            propagate_peak_detection(app, src, 'right')
        end

        function propagate_peak_detection(app, src, direction)
            start_latency_sec = app.ERP_latencies(app.curr_channel, app.CurrentComponentIndex, app.curr_N_epochs);
            
            % Search from the current epoch to the end
            if isequal(direction, 'right')
                latency_sec = start_latency_sec;
                for epoch = app.curr_N_epochs : app.EEG.trials
                    if app.ERP_is_component(app.curr_channel, app.CurrentComponentIndex, epoch) == 0
                        continue
                    end
                    latency_sec = detectEpochLatency(app, src, epoch, latency_sec);
                    if isnan(latency_sec)
                       refresh_plot(app)
                       break    % exit loop but continue with code after the loop
                    end
                end
            end

            % Search from the current epoch to the beginning\
            if isequal(direction, 'left')
                latency_sec = start_latency_sec;
                for epoch = app.curr_N_epochs-1:-1: app.min_number_of_epochs
                    if app.ERP_is_component(app.curr_channel, app.CurrentComponentIndex, epoch) == 0
                        continue
                    end
                    latency_sec = detectEpochLatency(app, src, epoch, latency_sec);
                    if isnan(latency_sec)
                       refresh_plot(app)
                       break    % exit loop but continue with code after the loop
                    end                
                end
            end
            refresh_plot(app)
        end

        function latency_sec = detectEpochLatency(app, src, epoch, latency_sec)
            % If latency not yet detected (NaN) -> try detect
            if isnan(app.ERP_amplitudes(app.curr_channel, app.CurrentComponentIndex, epoch))
               [amplitude, detected_latency] = find_peak(app, epoch, latency_sec);
               if isempty(detected_latency)  
                   app.curr_N_epochs = epoch;
                   app.Slider.Value = epoch;
                   latency_sec = NaN;
                   return
               else
                    latency_sec = detected_latency;
                    app.ERP_latencies(app.curr_channel, app.CurrentComponentIndex, epoch) = latency_sec;
                    app.ERP_is_component(app.curr_channel, app.CurrentComponentIndex, epoch) = 1;
               end
            else
               latency_sec = app.ERP_latencies(app.curr_channel, app.CurrentComponentIndex, epoch);
            end
        end

        function NocomponentButtonPushed(app, src, ~)
            app.ERP_latencies(app.curr_channel, app.CurrentComponentIndex, app.curr_N_epochs) = nan;
            app.ERP_is_component(app.curr_channel, app.CurrentComponentIndex, app.curr_N_epochs) = 0;
            refresh_plot(app)
        end

        function FinishButtonPushed(app, ~, ~)
            % 1. Save the modified data into the Output property
            app.EEG.Cumulative_ERP_averaging = {};
            app.EEG.Cumulative_ERP_averaging.averaged_data = app.EEG.averaged_data;
            app.EEG.Cumulative_ERP_averaging.ERP_latencies = app.ERP_latencies;
            app.EEG.Cumulative_ERP_averaging.ERP_is_component = app.ERP_is_component;
            app.EEG.Cumulative_ERP_averaging.ComponentNames = app.ComponentNames;
            app.EEG.Cumulative_ERP_averaging.ComponentColors = app.ComponentColors;

            if isfield(app.EEG , 'averaged_data')
                app.EEG = rmfield(app.EEG, 'averaged_data');
            end
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
            average = app.EEG.averaged_data(app.curr_channel, :, app.curr_N_epochs);
            plot(app.UIAxes, app.xaxis, average, 'Color', app.blue)
            
            for iComp = 1:numel(app.ComponentNames)
                lat = app.ERP_latencies(app.curr_channel, iComp, app.curr_N_epochs);
                if ~isnan(lat)
                    compColor = app.ComponentColors{iComp};
                    
                    % Plot green area around the peak
                    mask = (app.xaxis >= lat - app.ERP_search_window) & (app.xaxis <= lat + app.ERP_search_window);
                    idx  = find(mask);   
                    plot(app.UIAxes, app.xaxis(idx), average(idx), 'Color', compColor, 'LineWidth', 2)
                    
                    % Plot the peak
                    [~, pIdx] = min(abs(app.xaxis - lat));
                    mSize = 10; edgeColor = 'red';
                    if iComp ~= app.CurrentComponentIndex, edgeColor = 'none'; mSize = 8; end
                    plot(app.UIAxes, app.xaxis(pIdx), average(pIdx), 'o', 'Color', compColor, 'MarkerEdgeColor', edgeColor, 'MarkerSize', mSize)
                end
            end
        end

        function plot_grid_lines(app, src, ~)
            yline(app.UIAxes, 0, '--', 'LineWidth', 0.5);
            xline(app.UIAxes, 0, '--', 'LineWidth', 0.5);
        end
        
        function refresh_statusbar(app)
            % 1. Get data and colors
            trials = app.EEG.trials;
            data = squeeze(app.ERP_is_component(app.curr_channel, app.CurrentComponentIndex, :));
            compColor = app.ComponentColors{app.CurrentComponentIndex};
            

            % 2. Prepare Colors Matrix (RGB)
            % Initialize all as Red [1 1 1]
            colors = repmat([1 0 0], trials, 1); %ones(trials, 3); 
            % Red for "No Component" (0)
            colors(data == 0, :) = repmat([1 0 0], sum(data == 0), 1);
            % Component Color for "OK" (1)
            colors(data == 1, :) = repmat(compColor, sum(data == 1), 1);

            % 3. Initialize or Update Patch
            if isempty(app.StatusBarPatch) || ~isvalid(app.StatusBarPatch)
                % Create geometry: 4 vertices per trial (rectangle)
                % X: [1 2 2 1; 2 3 3 2; ...]
                % Y: [0 0 1 1; 0 0 1 1; ...]
                x = [1:trials; 2:trials+1; 2:trials+1; 1:trials];
                y = repmat([0; 0; 1; 1], 1, trials);
                
                % Create the patch
                % IMPORTANT: 'FaceColor','flat' requires CData to be assigned correctly
                app.StatusBarPatch = patch(app.StatusBar, ...
                    'XData', x, 'YData', y, ...
                    'CData', reshape(colors, trials, 1, 3), ... % Reshape for flat coloring
                    'FaceColor', 'flat', ...
                    'EdgeColor', 'none');
                
                app.StatusBar.XLim = [1, trials+1];
                app.StatusBar.YLim = [0, 1];
                app.StatusBar.Visible = 'off';
                app.StatusBar.HitTest = 'off'; % Prevents bar from intercepting clicks
            else
                % Update logic: 
                % For 'flat' face coloring with RGB, MATLAB expects a 3D array: [Faces x 1 x 3]
                app.StatusBarPatch.CData = reshape(colors, trials, 1, 3);
            end
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

           % Refresh status bar
            refresh_statusbar(app);
            
            hold(app.UIAxes, 'off')
        end
        
        % === Component selection
        function axesClicked(app, src, ~)
            cp = src.CurrentPoint; 
            app.ERP_latencies(app.curr_channel, app.CurrentComponentIndex, app.curr_N_epochs) = cp(1,1);
            app.ERP_is_component(app.curr_channel, app.CurrentComponentIndex, app.curr_N_epochs) = 1;
            refresh_plot(app)
        end

        function [amplitude, latency] = find_peak(app, epoch, latency_sec)
            mask = (app.xaxis >= latency_sec-app.ERP_search_window) & (app.xaxis <= latency_sec + app.ERP_search_window);
            idx  = find(mask);   
            signal_fragment = app.EEG.averaged_data(app.curr_channel, idx, epoch);
            [amplitudes, latencies] = findpeaks(signal_fragment);
            if isempty(latencies)
                [amplitudes, latencies] = findpeaks(diff(signal_fragment));
            end
            latencies = sample_to_sec(app, latencies);
            latencies = latencies + latency_sec-app.ERP_search_window;
            [~, idx] = min(abs(latencies - latency_sec));
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
            if any(eqMask), channel_number = find(eqMask, 1, 'first'); return; end
        end

        function seconds = sample_to_sec(app, sample), seconds = sample / app.EEG.srate; end
        
        function samples = sec_to_sample(app, seconds), samples = round(seconds * app.EEG.srate); end

        function parse_settings(app, Settings)
            if isempty(Settings) || ~isstruct(Settings), return; end
            fields = fieldnames(Settings);
            for i = 1:numel(fields)
                fieldName = fields{i};
                if isprop(app, fieldName), app.(fieldName) = Settings.(fieldName);
                else, fprintf("Warning: '%s' is not a valid property of the app. Skipping.\n", fieldName); end
            end
        end

        % === tests and checks
        function test_EEG_struct(app)
            % check if the data is epoched
            if app.EEG.trials == 1
                h = errordlg("EEG data must be epoched!");
                uiwait(h);
                delete(app)
            end

        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Average_epochs_GUI(inputEEG, Settings) 
            parse_settings(app, Settings)
            createComponents(app)
            app.EEG = inputEEG; 
            test_EEG_struct(app)

            compute_EEG_averages(app)
            app.channel_labels = {app.EEG.chanlocs.labels};
            registerApp(app, app.UIFigure)
            
            if ~isempty(app.EEG)
                app.Slider.Limits = [1, app.EEG.trials]; 
                app.ChannelsListBox.Items = string({app.EEG.chanlocs.labels});
                nComp = numel(app.ComponentNames);
                app.ERP_latencies = nan(app.EEG.nbchan, nComp, app.EEG.trials);
                app.ERP_is_component  = nan(app.EEG.nbchan, nComp, app.EEG.trials);
                app.ERP_is_component(:, :, 1:app.min_number_of_epochs) = 0;
                app.ERP_amplitudes = nan(app.EEG.nbchan, nComp, app.EEG.trials);
            end

            if isfield(inputEEG, 'filename'), app.UIFigure.Name = strrep(app.EEG.filename, ".set", ""); end
            app.xaxis = linspace(app.EEG.xmin, app.EEG.xmax, app.EEG.pnts);
            if isempty(app.xlim), app.xlim = [app.EEG.xmin, app.EEG.xmax]; end
            app.UIAxes.XMinorTick = 'on'; app.UIAxes.XGrid = 'on';  
            app.UIAxes.XAxis.MinorTickValues = app.xlim(1) : 0.01 : app.xlim(2);
            app.UIFigure.WindowState = 'maximized';
            refresh_plot(app)
            if nargout == 0, clear app; end
        end

        function delete(app), delete(app.UIFigure); end
    end

    methods (Static)
        function outEEG = run_app(EEG_input, Settings)
            app = Average_epochs_GUI(EEG_input, Settings);
            uiwait(app.UIFigure);
            if isvalid(app), outEEG = app.Output; delete(app); else, warning('GUI closed without clicking Finish. Returning original EEG.'); outEEG = EEG_input; end
        end
    end
end