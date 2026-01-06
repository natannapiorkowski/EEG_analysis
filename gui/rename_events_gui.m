classdef rename_events_gui < matlab.apps.AppBase

    % Properties that correspond to app componentsRenameButton_right
    properties (Access = public)
        UIFigure         matlab.ui.Figure
        TimeSlider       matlab.ui.control.Slider
        TimeSliderLabel  matlab.ui.control.Label
        OkButton         matlab.ui.control.Button
        RenameButton_right     matlab.ui.control.Button
        RenameButton_left     matlab.ui.control.Button
        Button_right     matlab.ui.control.Button
        LargestgapbetweeneventsEditField  matlab.ui.control.NumericEditField
        LargestgapbetweeneventsEditFieldLabel  matlab.ui.control.Label
        UIAxes           matlab.ui.control.UIAxes
        OutputEEG

    end
    
    % Custom properties to store the data
    properties (Access = private)
        EEG % Holds the EEG structure passed at startup
        EventTypes    % Cell array of strings
        EventTimes    % Array of latencies in seconds
        EventTimesDiff
        totalEEGDuration_sec 
        WindowSize
        centerLinePos = -1
        EventNameSuffix
    end

    methods (Static)
        function outEEG = run_app(EEG_input)
            % 1. Create the app instance
            app = rename_events_gui(EEG_input);
            
            % 2. Wait for the user to click Ok or X
            if isvalid(app) && isvalid(app.UIFigure)
                uiwait(app.UIFigure);
            end
            
            % 3. Once uiresume is called, check validity and grab data
            if isvalid(app)
                outEEG = app.EEG;
                delete(app); % Clean up the app
            else
                outEEG = EEG_input; % Return original if closed unexpectedly
            end
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, EEG)
            if nargin > 1 && isstruct(EEG)
                app.EEG = EEG;
                app.EEG.epochs_renamed = 0;
                app.OutputEEG = EEG;
            else
                errordlg('Please use correct EEG struct')
                return
            end
            % SETTINGS
            app.WindowSize = 120; %seconds
            app.EventNameSuffix = 2;

            % Process EEG Data
            app.extractEEGData(EEG);
            
            configureSlider(app)

            refreshPlot(app)

            % Redirect the 'X' button to just resume, NOT delete
            app.UIFigure.CloseRequestFcn = @(src, event) uiresume(app.UIFigure);
        end
    
        %% --- Logic Functions ---
        function extractEEGData(app, EEG)          
            % Extract types and latencies using your logic
            app.EventTypes = cellfun(@(x) num2str(x), {EEG.event.type}, 'UniformOutput', false);
            latencies = cellfun(@(x) x(1), {EEG.event.latency});
            app.EventTimes = latencies / EEG.srate;
            app.EventTimesDiff = [0, diff(app.EventTimes)];
            app.totalEEGDuration_sec = app.EEG.pnts / app.EEG.srate;
        end

        function configureSlider(app)           
            % Set slider limits and starting value
            app.TimeSlider.Limits = [0, app.totalEEGDuration_sec];
            app.TimeSlider.Value = 0;
            
            % Assign the callback for when the slider moves
            app.TimeSlider.ValueChangedFcn = createCallbackFcn(app, @TimeSliderValueChanged, true);
        end

        function refreshPlot(app)
            cla(app.UIAxes);
            hold(app.UIAxes, 'on');
            
            % Get current window
            startT = app.TimeSlider.Value;
            endT = min(app.totalEEGDuration_sec, startT + app.WindowSize);
            
            
            % Add a red line
            if app.centerLinePos > 0
                xline(app.UIAxes, app.centerLinePos, 'r', 'LineWidth', 3, 'HitTest', 'off'); 
            end
            
            % Plot Event Markers
            isVisible = (app.EventTimes >= startT) & (app.EventTimes <= endT);
            if any(isVisible)
                hLines = xline(app.UIAxes, app.EventTimes(isVisible), '--r', app.EventTypes(isVisible), ...
                    'LabelOrientation', 'aligned', 'FontSize', 8);
                
                % Make lines transparent to clicks so the axes handles it, 
                % or assign the callback to them as well:
                set(hLines, 'ButtonDownFcn', @(src, event)app.AxesClicked(event));
            end
            
            % Assign Click Callback to the Axes itself
            app.UIAxes.ButtonDownFcn = @(src, event)app.AxesClicked(event);
            
            xlim(app.UIAxes, [startT, endT]);
            hold(app.UIAxes, 'off');
        end

        function AxesClicked(app, event)
            % Extract the X-coordinate (Time) where the user clicked
            clickedX = event.IntersectionPoint(1);
            
            % Update the centerLinePos property
            app.centerLinePos = clickedX;

            % Refresh the plot to show the red line in the new spot
            app.refreshPlot();
        end

        function rename_eeg_events(app, direction)
            % Set default direction if not provided (handles calls from buttons)
            if nargin < 2
                direction = 'right'; 
            end
        
            % 1. Identify indices based on direction
            if strcmpi(direction, 'right')
                targetIdx = find(app.EventTimes > app.centerLinePos);
            elseif strcmpi(direction, 'left')
                targetIdx = find(app.EventTimes < app.centerLinePos);
            else
                return; % Invalid direction
            end
            
            if isempty(targetIdx)
                return;
            end
            
            % Apply the Global Suffix
            suffixStr = ['_', num2str(app.EventNameSuffix)];

            % 2. Loop through and increment or add suffix
            for i = targetIdx
                currentName = app.EventTypes{i};
                
                % Clean the name: remove any existing _n suffix before adding the new global one
                % This prevents names like S10_2_3_4
                baseName = regexprep(currentName, '_[0-9]+$', '');
                newName = [baseName, suffixStr];
                
                % Update storage
                app.EventTypes{i} = newName;
                app.EEG.event(i).type = newName;
            end
            % Note the epochs name change
            app.EEG.epochs_renamed = 1;

            % Increment the global suffix for the NEXT batch of renames
            app.EventNameSuffix = app.EventNameSuffix + 1;
            % Refresh the visual plot
            app.refreshPlot();
        end

        function [maxGap, gapStartTime] = find_largest_event_gap(app)
            % 1. Get unique event types to iterate through
            uniqueTypes = unique(app.EventTypes);
            
            maxGap = 0;
            gapType = '';
            gapStartTime = 0;
        
            for i = 1:length(uniqueTypes)
                thisType = uniqueTypes{i};
                
                % 2. Find times for ONLY this specific event type
                thisTypeTimes = app.EventTimes(strcmp(app.EventTypes, thisType));
                
                if length(thisTypeTimes) > 1
                    % 3. Calculate gaps between consecutive occurrences of this type
                    gaps = diff(thisTypeTimes);
                    [currentMax, idx] = max(gaps);
                    
                    % 4. Check if this is the largest gap found across all types
                    if currentMax > maxGap
                        maxGap = currentMax;
                        gapType = thisType;
                        gapStartTime = thisTypeTimes(idx);
                    end
                end
            end
        end
       
        function display_max_gap(app)
            [maxGap, gapStartTime] = find_largest_event_gap(app);
            app.LargestgapbetweeneventsEditField.Value = maxGap;
            app.TimeSlider.Value = max(0, gapStartTime - app.WindowSize/2 + 2);
            refreshPlot(app)
        end

        %% --- Callbacks ---
        function TimeSliderValueChanged(app, event)
            % Simply call the refresh logic
            app.refreshPlot();
        end

        function OkButtonPushed(app, event)
            % 1. Copy the current state of EEG to the Output property
            app.OutputEEG = app.EEG;
            
            % 2. Resume execution so the constructor can finish
            uiresume(app.UIFigure);
        end
    end
    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1134 377];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'EEG events')
            xlabel(app.UIAxes, 'Time [s]')
            ylabel(app.UIAxes, '')
            zlabel(app.UIAxes, '')
            app.UIAxes.Position = [1 101 1134 277];

            % Create OkButton
            app.OkButton = uibutton(app.UIFigure, 'push');
            app.OkButton.BackgroundColor = [0.2314 0.6667 0.1961];
            app.OkButton.FontWeight = 'bold';
            app.OkButton.Position = [1041 18 81 36];
            app.OkButton.Text = 'Ok';
            app.OkButton.ButtonPushedFcn = createCallbackFcn(app, @(src,event)OkButtonPushed(app), true);
            

            % Create LargestgapbetweeneventsEditFieldLabel
            app.LargestgapbetweeneventsEditFieldLabel = uilabel(app.UIFigure);
            app.LargestgapbetweeneventsEditFieldLabel.HorizontalAlignment = 'right';
            app.LargestgapbetweeneventsEditFieldLabel.Position = [375 65 159 22];
            app.LargestgapbetweeneventsEditFieldLabel.Text = 'Largest gap between events [sec]:';

            % Create LargestgapbetweeneventsEditField
            app.LargestgapbetweeneventsEditField = uieditfield(app.UIFigure, 'numeric');
            app.LargestgapbetweeneventsEditField.ValueChangedFcn = createCallbackFcn(app, @LargestgapbetweeneventsEditFieldValueChanged, true);
            app.LargestgapbetweeneventsEditField.Position = [554 65 136 22];

            % Create RenameButton_right
            app.RenameButton_right = uibutton(app.UIFigure, 'push');
            app.RenameButton_right.BackgroundColor = [0 1 1];
            app.RenameButton_right.FontWeight = 'bold';
            app.RenameButton_right.Position = [239 64 100 23];
            app.RenameButton_right.Text = 'Rename >>';
            app.RenameButton_right.ButtonPushedFcn = createCallbackFcn(app, @(src,event)rename_eeg_events(app, 'right'), true);
            %app.RenameButton_right.ButtonPushedFcn = createCallbackFcn(app, @(src,event)test(app), true);

            % Create RenameButton_left
            app.RenameButton_left = uibutton(app.UIFigure, 'push');
            app.RenameButton_left.BackgroundColor = [0 1 1];
            app.RenameButton_left.FontWeight = 'bold';
            app.RenameButton_left.Position = [130 64 100 23];
            app.RenameButton_left.Text = '<< Rename';
            app.RenameButton_left.ButtonPushedFcn = createCallbackFcn(app, @(src,event)rename_eeg_events(app, 'left'), true);
            %app.RenameButton_right.ButtonPushedFcn = createCallbackFcn(app, @(src,event)test(app), true);

            % Create Button_right
            app.Button_right = uibutton(app.UIFigure, 'push');
            app.Button_right.BackgroundColor = [0.8 0.8 0.8];
            app.Button_right.FontWeight = 'bold';
            app.Button_right.Position = [729 64 100 23];
            app.Button_right.Text = '>>>';
            app.Button_right.ButtonPushedFcn = createCallbackFcn(app, @(src,event)display_max_gap(app), true);

            % Create TimeSlider
            app.TimeSlider = uislider(app.UIFigure);
            app.TimeSlider.Position = [46 37 975 3];
            app.TimeSlider.ValueChangedFcn = createCallbackFcn(app, @TimeSliderValueChanged, true);

            % Create TimeSliderLabel
            app.TimeSliderLabel = uilabel(app.UIFigure);
            app.TimeSliderLabel.HorizontalAlignment = 'right';
            app.TimeSliderLabel.Position = [1 16 31 22];
            app.TimeSliderLabel.Text = 'Time';

            

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = rename_events_gui(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            % Note: No uiwait here! The static method handles it.
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
end