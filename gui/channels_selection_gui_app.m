classdef channels_selection_gui_app < matlab.apps.AppBase
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        SelectchannelstoremoveLabel  matlab.ui.control.Label
        KiziumiziuButton             matlab.ui.control.Button
        ListBox                      matlab.ui.control.ListBox
        EEG              
        ChannelStatus
        StyleHandles    
        Output = []
        window_title = 'Select channels' % Default value
    end
    
    methods (Access = public, Static)
        function out = showGUI(eeg_data, window_title)
            if nargin < 2, window_title = 'Select channels'; end
            app = channels_selection_gui_app(eeg_data, window_title);
            uiwait(app.UIFigure);
            
            if isvalid(app)
                out = app.Output;
                delete(app.UIFigure);
                delete(app);
            else
                % Return empty if window was closed via 'X'
                out = []; 
            end
        end
    end

    methods (Access = public)
        function app = channels_selection_gui_app(varargin)
            createComponents(app)
            registerApp(app, app.UIFigure)
            if ~isempty(varargin)
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            end
        end
    end

    methods (Access = private)
        function startupFcn(app, eeg_input, window_title)
            app.EEG = eeg_input; 
            if nargin > 2
                app.window_title = window_title;
                % Update the UI labels immediately
                app.SelectchannelstoremoveLabel.Text = window_title;
                app.UIFigure.Name = window_title;
            end
            
            numChans = length(app.EEG.chanlocs);
            app.ListBox.Items = {app.EEG.chanlocs.labels};
            
            % Initialize status: false = clean/white
            app.ChannelStatus = false(1, numChans);
            app.StyleHandles = cell(1, numChans); 
        end

        function listbox1ValueChanged(app, event)
            % 1. Get the current selected value
            val = app.ListBox.Value;
        
            % GUARD: Exit if selection is empty
            if isempty(val)
                return; 
            end
            
            % 2. Find the index of the clicked item
            [found, idx] = ismember(val, app.ListBox.Items);
            if app.ChannelStatus(idx)
                % ACTION: Mark for removal (RED)
                app.ChannelStatus(idx) = false;
                
                % Create style and store it
                s = uistyle('BackgroundColor', [1 1 1]); 
                app.StyleHandles{idx} = s; 
                addStyle(app.ListBox, s, 'item', idx);
            else
                % ACTION: Re-include (WHITE)
                app.ChannelStatus(idx) = true;
                
                s = uistyle('BackgroundColor', [1 0.6 0.6]); 
                app.StyleHandles{idx} = s; 
                addStyle(app.ListBox, s, 'item', idx);
            end
            
            % 3. Clear selection highlight
            % IMPORTANT: This triggers the callback again, 
            % but the 'isempty(val)' at the top will stop it safely.
            app.ListBox.Value = {}; 
        end


        function OK_pushbuttonPushed(app, event)
            % Return indices of channels marked as 'false' (Red)
            app.Output = find(app.ChannelStatus);
            uiresume(app.UIFigure);
        end

        function UIFigureCloseRequest(app, event)
            uiresume(app.UIFigure);
        end

        function createComponents(app)
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.4235 0.9569 1];
            app.UIFigure.Position = [100 100 283 717];
            app.UIFigure.Name = 'Channel Selection';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            app.ListBox = uilistbox(app.UIFigure);
            app.ListBox.ValueChangedFcn = createCallbackFcn(app, @listbox1ValueChanged, true);
            app.ListBox.Position = [28 102 233 552];
            app.ListBox.Multiselect = 'off';

            app.KiziumiziuButton = uibutton(app.UIFigure, 'push');
            app.KiziumiziuButton.ButtonPushedFcn = createCallbackFcn(app, @OK_pushbuttonPushed, true);
            app.KiziumiziuButton.BackgroundColor = [0 1 0];
            app.KiziumiziuButton.Position = [29 22 232 56];
            app.KiziumiziuButton.Text = 'Kiziumiziu';
            app.KiziumiziuButton.FontWeight = 'bold';

            app.SelectchannelstoremoveLabel = uilabel(app.UIFigure);
            app.SelectchannelstoremoveLabel.HorizontalAlignment = 'center';
            app.SelectchannelstoremoveLabel.FontSize = 18;
            app.SelectchannelstoremoveLabel.Position = [2 653 282 47];
            app.SelectchannelstoremoveLabel.Text = app.window_title;

            app.UIFigure.Visible = 'on';
        end
    end
end