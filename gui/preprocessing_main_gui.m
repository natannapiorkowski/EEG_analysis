classdef preprocessing_main_gui < matlab.apps.AppBase
    % Port of GUIDE MAIN_GUI core behaviors to App Designer style.
    % Key features replicated:
    % - output struct as the contract (incrementally updated)
    % - load files (bdf/set), load first EEG, cache properties
    % - step selection drives which controls are enabled
    % - listbox shows context (filenames/channels/srate) and supports channel picking
    %   for rereference + removeICA with toggle selection and persistent markers
    % - resample exports output.newFS

    %% Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        SelectprocessingstepButtonGroup  matlab.ui.container.ButtonGroup
        If128electrodesuseinterpolationmethodDropDown  matlab.ui.control.DropDown
        If128electrodesuseinterpolationmethodDropDownLabel  matlab.ui.control.Label
        UsenoactivitythresholdButton    matlab.ui.control.Button
        UsesampletosamplethresholdButton  matlab.ui.control.Button
        UseamplitudethresholdButton     matlab.ui.control.Button
        uVLabel_2                       matlab.ui.control.Label
        flatlinethreshold               matlab.ui.control.NumericEditField
        uVLabel                         matlab.ui.control.Label
        sampletosamplethreshold         matlab.ui.control.NumericEditField
        Label_2                         matlab.ui.control.Label
        maxtimewindow                   matlab.ui.control.NumericEditField
        mintimewindow                   matlab.ui.control.NumericEditField
        TimewindowLabel                 matlab.ui.control.Label
        Label                           matlab.ui.control.Label
        AmplitudethresholdLabel         matlab.ui.control.Label
        maxAmp                          matlab.ui.control.NumericEditField
        minAmp                          matlab.ui.control.NumericEditField
        PoststimdurEditField            matlab.ui.control.NumericEditField
        PoststimdurEditFieldLabel       matlab.ui.control.Label
        PrestimdurEditField             matlab.ui.control.NumericEditField
        PrestimdurEditFieldLabel        matlab.ui.control.Label
        ChannelstohighlightEditField    matlab.ui.control.EditField
        ChannelstohighlightEditFieldLabel  matlab.ui.control.Label
        AmplitudeEditField              matlab.ui.control.NumericEditField
        AmplitudeEditFieldLabel         matlab.ui.control.Label
        TimerangeEditField              matlab.ui.control.NumericEditField
        TimerangeEditFieldLabel         matlab.ui.control.Label
        HighpassfilterButton_2          matlab.ui.control.RadioButton
        BoundryEditField_2              matlab.ui.control.NumericEditField
        BoundryEditField_2Label         matlab.ui.control.Label
        BoundryEditField                matlab.ui.control.NumericEditField
        BoundryEditFieldLabel           matlab.ui.control.Label
        NewsamplingrateEditField        matlab.ui.control.NumericEditField
        NewsamplingrateEditFieldLabel   matlab.ui.control.Label
        ReferencechannelsTextArea       matlab.ui.control.TextArea
        ReferencechannelsTextAreaLabel  matlab.ui.control.Label
        AverageepochsButton             matlab.ui.control.RadioButton
        ChangechannelslabelsButton      matlab.ui.control.RadioButton
        AutomaticartifactsrejectionButton  matlab.ui.control.RadioButton
        EpocheddatainspectionButton     matlab.ui.control.RadioButton
        EpochdataButton                 matlab.ui.control.RadioButton
        RemoveICAcomponentsButton       matlab.ui.control.RadioButton
        RunICAButton                    matlab.ui.control.RadioButton
        ContinuousdatainspectionButton  matlab.ui.control.RadioButton
        LowpassfilterButton             matlab.ui.control.RadioButton
        ResampleButton                  matlab.ui.control.RadioButton
        RereferenceButton               matlab.ui.control.RadioButton
        RUNButton                       matlab.ui.control.Button
        ListBox                         matlab.ui.control.ListBox
        LoadfilesButton                 matlab.ui.control.Button
    end

    %% Data properties (GUIDE handles equivalent)
    properties (Access = public)
        EEG struct = struct()
        files cell = {}
        pathname char = ''
        EEG_srate double = NaN
        EEG_channelLabels cell = {}
        output struct = struct()
    end

    %% Internal state
    properties (Access = private)
        % ListBox selection delta tracking (robust toggle)
        prevListBoxValue cell = {}

        % What the listbox currently shows: 'files' | 'channels' | 'srate'
        listboxMode char = 'files'

        % Groups of controls to enable per step (GUIDE-like)
        group_importChansLocs cell = {}
        group_rereference cell = {}
        group_resample cell = {}
        group_highpass cell = {}
        group_lowpass cell = {}
        group_inspection cell = {}
        group_runICA cell = {}
        group_removeICA cell = {}
        group_epoch cell = {}
        group_artifacts cell = {}
        group_changeLabels cell = {}
        group_average cell = {}
    end

    %% UI construction
    methods (Access = private)

        % Create UIFigure and components (your existing layout)
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 883 800];
            app.UIFigure.Name = 'Preprocessing App';
            app.UIFigure.Color = [0 0 0];

            % Create LoadfilesButton
            app.LoadfilesButton = uibutton(app.UIFigure, 'push');
            app.LoadfilesButton.BackgroundColor = [0 1 1];
            app.LoadfilesButton.FontWeight = 'bold';
            app.LoadfilesButton.Position = [15 23 135 34];
            app.LoadfilesButton.Text = 'Load files';

            % Create ListBox
            app.ListBox = uilistbox(app.UIFigure);
            app.ListBox.Position = [607 63 260 720];

            % Create RUNButton
            app.RUNButton = uibutton(app.UIFigure, 'push');
            app.RUNButton.BackgroundColor = [0 1 0];
            app.RUNButton.FontSize = 18;
            app.RUNButton.FontWeight = 'bold';
            app.RUNButton.Position = [607 23 259 41];
            app.RUNButton.Text = 'RUN!';

            % Create SelectprocessingstepButtonGroup
            app.SelectprocessingstepButtonGroup = uibuttongroup(app.UIFigure);
            app.SelectprocessingstepButtonGroup.Title = 'Select processing step';
            app.SelectprocessingstepButtonGroup.Position = [14 63 565 720];

            % Create RereferenceButton
            app.RereferenceButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.RereferenceButton.Text = 'Rereference';
            app.RereferenceButton.FontSize = 18;
            app.RereferenceButton.Position = [9 670 121 22];
            app.RereferenceButton.Value = true; % will be cleared in constructor

            % Create ResampleButton
            app.ResampleButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.ResampleButton.Text = 'Resample';
            app.ResampleButton.FontSize = 18;
            app.ResampleButton.Position = [9 623 103 22];

            % Create LowpassfilterButton
            app.LowpassfilterButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.LowpassfilterButton.Text = 'Low pass filter';
            app.LowpassfilterButton.FontSize = 18;
            app.LowpassfilterButton.Position = [9 576 137 22];

            % Create ContinuousdatainspectionButton
            app.ContinuousdatainspectionButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.ContinuousdatainspectionButton.Text = 'Continuous data inspection';
            app.ContinuousdatainspectionButton.FontSize = 18;
            app.ContinuousdatainspectionButton.Position = [9 482 241 22];

            % Create RunICAButton
            app.RunICAButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.RunICAButton.Text = 'Run ICA';
            app.RunICAButton.FontSize = 18;
            app.RunICAButton.Position = [9 435 90 22];

            % Create RemoveICAcomponentsButton
            app.RemoveICAcomponentsButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.RemoveICAcomponentsButton.Text = 'Remove ICA components';
            app.RemoveICAcomponentsButton.FontSize = 18;
            app.RemoveICAcomponentsButton.Position = [9 388 228 22];

            % Create EpochdataButton
            app.EpochdataButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.EpochdataButton.Text = 'Epoch data';
            app.EpochdataButton.FontSize = 18;
            app.EpochdataButton.Position = [9 341 113 22];

            % Create EpocheddatainspectionButton
            app.EpocheddatainspectionButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.EpocheddatainspectionButton.Text = 'Epoched data inspection';
            app.EpocheddatainspectionButton.FontSize = 18;
            app.EpocheddatainspectionButton.Position = [9 294 220 22];

            % Create AutomaticartifactsrejectionButton
            app.AutomaticartifactsrejectionButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.AutomaticartifactsrejectionButton.Text = 'Automatic artifacts rejection';
            app.AutomaticartifactsrejectionButton.FontSize = 18;
            app.AutomaticartifactsrejectionButton.Position = [9 247 245 22];

            % Create ChangechannelslabelsButton
            app.ChangechannelslabelsButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.ChangechannelslabelsButton.Text = 'Change channels labels';
            app.ChangechannelslabelsButton.FontSize = 18;
            app.ChangechannelslabelsButton.Position = [9 84 215 22];

            % Create AverageepochsButton
            app.AverageepochsButton = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.AverageepochsButton.Text = 'Average epochs';
            app.AverageepochsButton.FontSize = 18;
            app.AverageepochsButton.Position = [9 46 152 22];

            % Create ReferencechannelsTextAreaLabel
            app.ReferencechannelsTextAreaLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.ReferencechannelsTextAreaLabel.HorizontalAlignment = 'right';
            app.ReferencechannelsTextAreaLabel.Position = [216 666 115 22];
            app.ReferencechannelsTextAreaLabel.Text = 'Reference channels:';

            % Create ReferencechannelsTextArea
            app.ReferencechannelsTextArea = uitextarea(app.SelectprocessingstepButtonGroup);
            app.ReferencechannelsTextArea.Position = [340 667 204 20];

            % Create NewsamplingrateEditFieldLabel
            app.NewsamplingrateEditFieldLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.NewsamplingrateEditFieldLabel.HorizontalAlignment = 'right';
            app.NewsamplingrateEditFieldLabel.Position = [216 623 104 22];
            app.NewsamplingrateEditFieldLabel.Text = 'New sampling rate';

            % Create NewsamplingrateEditField
            app.NewsamplingrateEditField = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.NewsamplingrateEditField.Position = [338 623 206 22];

            % Create BoundryEditFieldLabel
            app.BoundryEditFieldLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.BoundryEditFieldLabel.Position = [216 576 50 22];
            app.BoundryEditFieldLabel.Text = 'Boundry';

            % Create BoundryEditField
            app.BoundryEditField = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.BoundryEditField.Position = [291 576 49 22];

            % Create BoundryEditField_2Label
            app.BoundryEditField_2Label = uilabel(app.SelectprocessingstepButtonGroup);
            app.BoundryEditField_2Label.Position = [216 537 50 22];
            app.BoundryEditField_2Label.Text = 'Boundry';

            % Create BoundryEditField_2
            app.BoundryEditField_2 = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.BoundryEditField_2.Position = [291 537 49 22];

            % Create HighpassfilterButton_2
            app.HighpassfilterButton_2 = uiradiobutton(app.SelectprocessingstepButtonGroup);
            app.HighpassfilterButton_2.Text = 'High pass filter';
            app.HighpassfilterButton_2.FontSize = 18;
            app.HighpassfilterButton_2.Position = [9 529 141 22];

            % Create TimerangeEditFieldLabel
            app.TimerangeEditFieldLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.TimerangeEditFieldLabel.HorizontalAlignment = 'right';
            app.TimerangeEditFieldLabel.Position = [253 482 69 22];
            app.TimerangeEditFieldLabel.Text = 'Time range:';

            % Create TimerangeEditField
            app.TimerangeEditField = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.TimerangeEditField.Position = [322 482 63 22];

            % Create AmplitudeEditFieldLabel
            app.AmplitudeEditFieldLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.AmplitudeEditFieldLabel.HorizontalAlignment = 'right';
            app.AmplitudeEditFieldLabel.Position = [428 482 58 22];
            app.AmplitudeEditFieldLabel.Text = 'Amplitude';

            % Create AmplitudeEditField
            app.AmplitudeEditField = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.AmplitudeEditField.Position = [493 482 51 22];

            % Create ChannelstohighlightEditFieldLabel
            app.ChannelstohighlightEditFieldLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.ChannelstohighlightEditFieldLabel.HorizontalAlignment = 'right';
            app.ChannelstohighlightEditFieldLabel.Position = [241 388 120 22];
            app.ChannelstohighlightEditFieldLabel.Text = 'Channels to highlight:';

            % Create ChannelstohighlightEditField
            app.ChannelstohighlightEditField = uieditfield(app.SelectprocessingstepButtonGroup, 'text');
            app.ChannelstohighlightEditField.Position = [368 388 176 22];

            % Create PrestimdurEditFieldLabel
            app.PrestimdurEditFieldLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.PrestimdurEditFieldLabel.HorizontalAlignment = 'right';
            app.PrestimdurEditFieldLabel.Position = [174 341 74 22];
            app.PrestimdurEditFieldLabel.Text = 'Pre-stim dur:';

            % Create PrestimdurEditField
            app.PrestimdurEditField = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.PrestimdurEditField.Position = [263 341 78 22];

            % Create PoststimdurEditFieldLabel
            app.PoststimdurEditFieldLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.PoststimdurEditFieldLabel.HorizontalAlignment = 'right';
            app.PoststimdurEditFieldLabel.Position = [373 341 79 22];
            app.PoststimdurEditFieldLabel.Text = 'Post-stim dur:';

            % Create PoststimdurEditField
            app.PoststimdurEditField = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.PoststimdurEditField.Position = [467 341 77 22];

            % Create minAmp
            app.minAmp = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.minAmp.FontSize = 10;
            app.minAmp.Position = [304 193 35 22];
            app.minAmp.Value = -100;

            % Create maxAmp
            app.maxAmp = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.maxAmp.FontSize = 10;
            app.maxAmp.Position = [350 193 35 22];
            app.maxAmp.Value = 100;

            % Create AmplitudethresholdLabel
            app.AmplitudethresholdLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.AmplitudethresholdLabel.FontSize = 10;
            app.AmplitudethresholdLabel.Position = [209 193 96 22];
            app.AmplitudethresholdLabel.Text = 'Amplitude threshold:';

            % Create Label
            app.Label = uilabel(app.SelectprocessingstepButtonGroup);
            app.Label.FontSize = 10;
            app.Label.Position = [343 193 25 22];
            app.Label.Text = '-';

            % Create TimewindowLabel
            app.TimewindowLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.TimewindowLabel.FontSize = 10;
            app.TimewindowLabel.Position = [391 193 67 22];
            app.TimewindowLabel.Text = 'Time window:';

            % Create mintimewindow
            app.mintimewindow = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.mintimewindow.FontSize = 10;
            app.mintimewindow.Position = [457 193 40 22];
            app.mintimewindow.Value = -500;

            % Create maxtimewindow
            app.maxtimewindow = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.maxtimewindow.FontSize = 10;
            app.maxtimewindow.Position = [508 193 36 22];
            app.maxtimewindow.Value = 1000;

            % Create Label_2
            app.Label_2 = uilabel(app.SelectprocessingstepButtonGroup);
            app.Label_2.FontSize = 10;
            app.Label_2.Position = [497 193 12 22];
            app.Label_2.Text = '-';

            % Create sampletosamplethreshold
            app.sampletosamplethreshold = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.sampletosamplethreshold.FontSize = 10;
            app.sampletosamplethreshold.Position = [304 166 81 22];
            app.sampletosamplethreshold.Value = 30;

            % Create uVLabel
            app.uVLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.uVLabel.FontSize = 10;
            app.uVLabel.Position = [391 166 25 22];
            app.uVLabel.Text = 'uV';

            % Create flatlinethreshold
            app.flatlinethreshold = uieditfield(app.SelectprocessingstepButtonGroup, 'numeric');
            app.flatlinethreshold.FontSize = 10;
            app.flatlinethreshold.Position = [304 138 81 22];
            app.flatlinethreshold.Value = 2;

            % Create uVLabel_2
            app.uVLabel_2 = uilabel(app.SelectprocessingstepButtonGroup);
            app.uVLabel_2.FontSize = 10;
            app.uVLabel_2.Position = [391 138 25 22];
            app.uVLabel_2.Text = 'uV';

            % Create UseamplitudethresholdButton
            app.UseamplitudethresholdButton = uibutton(app.SelectprocessingstepButtonGroup, 'push');
            app.UseamplitudethresholdButton.Position = [20 193 188 23];
            app.UseamplitudethresholdButton.Text = 'Use amplitude threshold';

            % Create UsesampletosamplethresholdButton
            app.UsesampletosamplethresholdButton = uibutton(app.SelectprocessingstepButtonGroup, 'push');
            app.UsesampletosamplethresholdButton.Position = [20 165 188 23];
            app.UsesampletosamplethresholdButton.Text = 'Use sample-to-sample threshold';

            % Create UsenoactivitythresholdButton
            app.UsenoactivitythresholdButton = uibutton(app.SelectprocessingstepButtonGroup, 'push');
            app.UsenoactivitythresholdButton.Position = [20 137 188 23];
            app.UsenoactivitythresholdButton.Text = 'Use no activity threshold';

            % Create If128electrodesuseinterpolationmethodDropDownLabel
            app.If128electrodesuseinterpolationmethodDropDownLabel = uilabel(app.SelectprocessingstepButtonGroup);
            app.If128electrodesuseinterpolationmethodDropDownLabel.HorizontalAlignment = 'right';
            app.If128electrodesuseinterpolationmethodDropDownLabel.FontSize = 10;
            app.If128electrodesuseinterpolationmethodDropDownLabel.Position = [241 84 193 22];
            app.If128electrodesuseinterpolationmethodDropDownLabel.Text = 'If 128 electrodes use interpolation method:';

            % Create If128electrodesuseinterpolationmethodDropDown
            app.If128electrodesuseinterpolationmethodDropDown = uidropdown(app.SelectprocessingstepButtonGroup);
            app.If128electrodesuseinterpolationmethodDropDown.Items = {'invdist', 'spherical'};
            app.If128electrodesuseinterpolationmethodDropDown.FontSize = 10;
            app.If128electrodesuseinterpolationmethodDropDown.Position = [452 84 95 22];
            app.If128electrodesuseinterpolationmethodDropDown.Value = 'invdist';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end

        %% GUIDE-equivalent init: output schema
        function initializeOutput(app)
            app.output = struct();
        
            % --- GUIDE-like contract fields
            app.output.analysisStep = '';                 % e.g. 'rereference', 'resample', ...
            app.output.interpolationMethod = 'invdist';   % dropdown
        
            % Files
            app.output.filenames = {};
            app.output.pathname  = '';
            app.output.firstFileLoaded = '';
        
            % EEG properties
            app.output.EEG = struct();
            app.output.EEG.srate = NaN;
            app.output.EEG.channelLabels = {};
            app.output.EEG.struct = struct();
        
            % Step outputs
            app.output.newReference = {};  % rereference selection (cellstr)
            app.output.newFS        = NaN; % resample
            app.output.ICAchans     = {};  % remove ICA selection (cellstr)
        
            % Misc settings (directly on output)
            app.output.referenceChannels = "";   % mirrors ReferencechannelsTextArea.Value
            app.output.newSamplingRate   = NaN;  % mirrors NewsamplingrateEditField.Value
        
            app.output.lowpassBoundary   = NaN;  % BoundryEditField
            app.output.highpassBoundary  = NaN;  % BoundryEditField_2
        
            app.output.timeRangeToDisplay = NaN; % TimerangeEditField
            app.output.amplitudeToDisplay = NaN; % AmplitudeEditField
        
            app.output.prestimDur  = NaN;        % PrestimdurEditField
            app.output.poststimDur = NaN;        % PoststimdurEditField
        
            app.output.lowAmplitudeThreshold  = NaN; % minAmp
            app.output.highAmplitudeThreshold = NaN; % maxAmp
            app.output.sampleToSample         = NaN; % sampletosamplethreshold
            app.output.minTimeWindowArtifacts = NaN; % mintimewindow
            app.output.maxTimeWindowArtifacts = NaN; % maxtimewindow
            app.output.noActivity             = NaN; % flatlinethreshold
        end

        %% Build control groups (GUIDE style)
        function buildGroups(app)
            app.group_importChansLocs = {app.If128electrodesuseinterpolationmethodDropDown, app.If128electrodesuseinterpolationmethodDropDownLabel};

            app.group_rereference = {app.ReferencechannelsTextArea, app.ReferencechannelsTextAreaLabel};

            app.group_resample = {app.NewsamplingrateEditField, app.NewsamplingrateEditFieldLabel};

            app.group_lowpass = {app.BoundryEditField, app.BoundryEditFieldLabel};
            app.group_highpass = {app.BoundryEditField_2, app.BoundryEditField_2Label};

            app.group_inspection = { ...
                app.TimerangeEditField, app.TimerangeEditFieldLabel, ...
                app.AmplitudeEditField, app.AmplitudeEditFieldLabel ...
                };

            app.group_runICA = {}; % no dedicated controls in current UI

            app.group_removeICA = {app.ChannelstohighlightEditField, app.ChannelstohighlightEditFieldLabel};

            app.group_epoch = { ...
                app.PrestimdurEditField, app.PrestimdurEditFieldLabel, ...
                app.PoststimdurEditField, app.PoststimdurEditFieldLabel ...
                };

            app.group_artifacts = { ...
                app.UseamplitudethresholdButton, ...
                app.UsesampletosamplethresholdButton, ...
                app.UsenoactivitythresholdButton, ...
                app.minAmp, app.maxAmp, app.AmplitudethresholdLabel, app.Label, ...
                app.mintimewindow, app.maxtimewindow, app.TimewindowLabel, app.Label_2, ...
                app.sampletosamplethreshold, app.uVLabel, ...
                app.flatlinethreshold, app.uVLabel_2 ...
                };

            app.group_changeLabels = app.group_importChansLocs; % mapping: change labels -> interpolation method

            app.group_average = {}; % no controls
        end

        %% Enable/disable helpers (GUIDE-like)
        function setComponentEnabled(app, comp, tf)
            if ~isvalid(comp); return; end

            if isa(comp, 'matlab.ui.control.Label')
                if tf
                    comp.FontColor = [0 0 0];
                else
                    comp.FontColor = [0.8 0.8 0.8];
                end
                return;
            end

            if isprop(comp, 'Enable')
                comp.Enable = matlab.lang.OnOffSwitchState(tf);
            end
        end

        function setFieldsEnabled(app, comps)
            for i = 1:numel(comps)
                app.setComponentEnabled(comps{i}, true);
            end
        end

        function setAllFieldsDisabled(app)
            % Disable all groups' controls (not radio buttons themselves)
            groupNames = { ...
                'group_importChansLocs','group_rereference','group_resample','group_highpass','group_lowpass', ...
                'group_inspection','group_runICA','group_removeICA','group_epoch','group_artifacts','group_changeLabels','group_average' ...
                };
            for g = 1:numel(groupNames)
                comps = app.(groupNames{g});
                for i = 1:numel(comps)
                    app.setComponentEnabled(comps{i}, false);
                end
            end
        end

        function setUIEnabledAfterLoad(app, isLoaded)
            % Load button always enabled
            app.LoadfilesButton.Enable = 'on';

            % Disable the whole processing panel before load (like GUIDE hid panel)
            if isLoaded
                app.SelectprocessingstepButtonGroup.Enable = 'on';
                app.RUNButton.Enable = 'on';
                app.ListBox.Enable = 'on';
            else
                app.SelectprocessingstepButtonGroup.Enable = 'off';
                app.RUNButton.Enable = 'off';
                app.ListBox.Enable = 'off';
            end
        end

        function resetProcessingStepSelection(app)
            app.RereferenceButton.Value = false;
            app.ResampleButton.Value = false;
            app.LowpassfilterButton.Value = false;
            app.HighpassfilterButton_2.Value = false;
            app.ContinuousdatainspectionButton.Value = false;
            app.RunICAButton.Value = false;
            app.RemoveICAcomponentsButton.Value = false;
            app.EpochdataButton.Value = false;
            app.EpocheddatainspectionButton.Value = false;
            app.AutomaticartifactsrejectionButton.Value = false;
            app.ChangechannelslabelsButton.Value = false;
            app.AverageepochsButton.Value = false;
        end

        %% File loading + EEG property extraction (GUIDE-compatible)
        function LoadfilesButtonPushed(app, ~)
            [filenames, pathname] = uigetfile('*', 'Select Files', 'MultiSelect', 'on');
            if isequal(filenames, 0)
                return;
            end
            if ischar(filenames)
                filenames = {filenames};
            end
        
            files = {};
            for i = 1:numel(filenames)
                if ~isempty(strfind(filenames{i}, 'bdf')) || ~isempty(strfind(filenames{i}, 'set')) %#ok<STREMP>
                    files{end+1} = filenames{i}; %#ok<AGROW>
                end
            end
        
            if isempty(files)
                app.ListBox.Items = {'No .bdf or .set files selected.'};
                app.ListBox.ItemsData = {};
                app.ListBox.Value = {};
                return;
            end
        
            % Store file selection
            app.files = files;
            app.pathname = pathname;
        
            app.output.filenames = files;   % filtered list (what GUIDE effectively used)
            app.output.pathname  = pathname;
        
            % Load first EEG file
            app.EEG = app.loadOneEEGFile();
            app.output.firstFileLoaded = files{1};
        
            % Cache properties
            app.getEEGProperties();
            app.output.EEG.srate         = app.EEG_srate;
            app.output.EEG.channelLabels = app.EEG_channelLabels;
            app.output.EEG.struct        = app.EEG;
        
            % Enable UI now that data loaded
            app.setUIEnabledAfterLoad(true);
        
            % Disable all step-specific fields initially
            app.setAllFieldsDisabled();
        
            % Clear selection state
            app.output.newReference = {};
            app.output.ICAchans = {};
            app.ReferencechannelsTextArea.Value = "";
            app.ChannelstohighlightEditField.Value = "";
            app.prevListBoxValue = {};
        
            % --- REQUIRED NEW BEHAVIOR ---
            % Select "Rereference" step and show channels immediately
            app.RereferenceButton.Value = true;
            app.output.analysisStep = 'rereference';
        
            % Enable rereference controls
            app.setFieldsEnabled(app.group_rereference);
        
            % Populate listbox with channels (marker-aware)
            app.updateListBox('channels');
            app.updateChannelListBoxSelection(app.output.newReference);
        
            % Keep a snapshot (optional)
            app.syncOutputFromUI();
        end

        function EEG = loadOneEEGFile(app)
            fileToLoad = app.files{1};

            if ~isempty(strfind(fileToLoad, 'bdf')) %#ok<STREMP>
                EEG = pop_biosig(fullfile(app.pathname, fileToLoad));
            elseif ~isempty(strfind(fileToLoad, 'set')) %#ok<STREMP>
                EEG = pop_loadset('filename', fileToLoad, 'filepath', app.pathname);
            else
                error('Unsupported file type: %s', fileToLoad);
            end
        end

        function getEEGProperties(app)
            if isfield(app.EEG, 'srate') && ~isempty(app.EEG.srate)
                app.EEG_srate = double(app.EEG.srate);
            else
                app.EEG_srate = NaN;
            end

            app.EEG_channelLabels = {};
            if isfield(app.EEG, 'chanlocs') && ~isempty(app.EEG.chanlocs) && isfield(app.EEG.chanlocs, 'labels')
                labels = {app.EEG.chanlocs.labels};
                labels = labels(:)';
                labels = labels(~cellfun(@isempty, labels));
                for k = 1:numel(labels)
                    if isstring(labels{k})
                        labels{k} = char(labels{k});
                    end
                end
                app.EEG_channelLabels = labels;
            end
        end

        %% ListBox display (GUIDE getPropertyFromEEGFile equivalent)
        function updateListBox(app, mode)
            if nargin < 2 || isempty(mode)
                mode = 'files';
            end
            app.listboxMode = mode;

            switch lower(mode)
                case 'files'
                    if isempty(app.files)
                        app.ListBox.Items = {'No files loaded.'};
                        app.ListBox.ItemsData = {};
                        app.ListBox.Value = {};
                    else
                        app.ListBox.Items = app.files;
                        app.ListBox.ItemsData = app.files;
                        app.ListBox.Value = {};
                    end

                case 'channels'
                    if isempty(app.EEG_channelLabels)
                        app.ListBox.Items = {'No channel info.'};
                        app.ListBox.ItemsData = {};
                        app.ListBox.Value = {};
                    else
                        % Show with markers depending on current step selections
                        if strcmp(app.output.analysisStep, 'rereference')
                            app.updateChannelListBoxSelection(app.output.newReference);
                        elseif strcmp(app.output.analysisStep, 'removeICA')
                            app.updateChannelListBoxSelection(app.output.ICAchans);
                        else
                            % plain list (no markers)
                            app.ListBox.Items = app.EEG_channelLabels;
                            app.ListBox.ItemsData = app.EEG_channelLabels;
                            app.ListBox.Value = {};
                        end
                    end

                case 'srate'
                    if isnan(app.EEG_srate)
                        app.ListBox.Items = {'NaN'};
                    else
                        app.ListBox.Items = {num2str(app.EEG_srate)};
                    end
                    app.ListBox.ItemsData = {};
                    app.ListBox.Value = {};

                otherwise
                    error('updateListBox:InvalidMode', 'Unknown mode: %s', mode);
            end

            % Reset delta tracking baseline after mode change
            app.prevListBoxValue = app.ListBox.Value;
        end

        function updateChannelListBoxSelection(app, selectedLabels)
            baseLabels = app.EEG_channelLabels;

            if isempty(baseLabels)
                app.ListBox.Items = {'No channel info.'};
                app.ListBox.ItemsData = {};
                app.ListBox.Value = {};
                return;
            end

            % Normalize
            if nargin < 2 || isempty(selectedLabels)
                selectedLabels = {};
            end
            if ischar(selectedLabels); selectedLabels = {selectedLabels}; end
            if isstring(selectedLabels); selectedLabels = cellstr(selectedLabels); end

            isSel = ismember(baseLabels, selectedLabels);

            displayItems = baseLabels;
            for i = 1:numel(baseLabels)
                if isSel(i)
                    displayItems{i} = ['[*] ' baseLabels{i}];
                else
                    displayItems{i} = ['    ' baseLabels{i}];
                end
            end

            app.ListBox.Items = displayItems;
            app.ListBox.ItemsData = baseLabels;
            app.ListBox.Value = selectedLabels;

            app.prevListBoxValue = app.ListBox.Value;
        end

        %% Step selection (GUIDE uipanel SelectionChangeFcn equivalent)
        function ProcessingStepChanged(app, ~)
            sel = app.SelectprocessingstepButtonGroup.SelectedObject;
            if isempty(sel) || ~isvalid(sel)
                app.output.analysisStep = '';
                return;
            end
        
            % Disable all step-specific fields
            app.setAllFieldsDisabled();
        
            if app.RereferenceButton.Value
                app.output.analysisStep = 'rereference';
                app.setFieldsEnabled(app.group_rereference);
                app.updateListBox('channels');
                app.updateChannelListBoxSelection(app.output.newReference);
        
            elseif app.ResampleButton.Value
                app.output.analysisStep = 'resample';
                app.setFieldsEnabled(app.group_resample);
                app.updateListBox('srate');
                app.output.newFS = app.NewsamplingrateEditField.Value;
        
            elseif app.HighpassfilterButton_2.Value
                app.output.analysisStep = 'highPassFilter';
                app.setFieldsEnabled(app.group_highpass);
        
            elseif app.LowpassfilterButton.Value
                app.output.analysisStep = 'lowPassFilter';
                app.setFieldsEnabled(app.group_lowpass);
        
            elseif app.ContinuousdatainspectionButton.Value
                app.output.analysisStep = 'dataInspection';
                app.setFieldsEnabled(app.group_inspection);
        
            elseif app.RunICAButton.Value
                app.output.analysisStep = 'runICA';
                app.setFieldsEnabled(app.group_runICA);
        
            elseif app.RemoveICAcomponentsButton.Value
                app.output.analysisStep = 'removeICA';
                app.setFieldsEnabled(app.group_removeICA);
                app.updateListBox('channels');
                app.updateChannelListBoxSelection(app.output.ICAchans);
        
            elseif app.EpochdataButton.Value
                app.output.analysisStep = 'epoch';
                app.setFieldsEnabled(app.group_epoch);
        
            elseif app.EpocheddatainspectionButton.Value
                app.output.analysisStep = 'epochedDataInspection';
                app.setFieldsEnabled(app.group_epoch);
        
            elseif app.AutomaticartifactsrejectionButton.Value
                app.output.analysisStep = 'artifactsRejection';
                app.setFieldsEnabled(app.group_artifacts);
        
            elseif app.ChangechannelslabelsButton.Value
                app.output.analysisStep = 'changeLabels';
                app.setFieldsEnabled(app.group_changeLabels);
        
            elseif app.AverageepochsButton.Value
                app.output.analysisStep = 'average';
                app.setFieldsEnabled(app.group_average);
        
            else
                app.output.analysisStep = '';
            end
        
            app.syncOutputFromUI();
        end

        %% ListBox interaction (GUIDE listbox_Callback equivalent)
        function ListBoxValueChanged(app, ~)
            % Only active for rereference/removeICA when listbox shows channels
            if ~strcmp(app.listboxMode, 'channels')
                app.prevListBoxValue = app.ListBox.Value;
                return;
            end
            if ~strcmp(app.output.analysisStep, 'rereference') && ~strcmp(app.output.analysisStep, 'removeICA')
                app.prevListBoxValue = app.ListBox.Value;
                return;
            end

            cur = app.ListBox.Value;
            if isempty(cur); cur = {}; end
            if ischar(cur); cur = {cur}; end
            if isstring(cur); cur = cellstr(cur); end

            prev = app.prevListBoxValue;
            if isempty(prev); prev = {}; end
            if ischar(prev); prev = {prev}; end
            if isstring(prev); prev = cellstr(prev); end

            added   = setdiff(cur,  prev, 'stable');
            removed = setdiff(prev, cur,  'stable');

            if ~isempty(added)
                clickedLabel = added{end};
            elseif ~isempty(removed)
                clickedLabel = removed{end};
            else
                % nothing changed
                app.prevListBoxValue = cur;
                return;
            end

            switch app.output.analysisStep
                case 'rereference'
                    selected = app.output.newReference;
                    if isempty(selected); selected = {}; end

                    idx = find(strcmp(selected, clickedLabel), 1);
                    if isempty(idx)
                        selected{end+1} = clickedLabel; %#ok<AGROW>
                    else
                        selected(idx) = [];
                    end
                    app.output.newReference = selected;

                    % Comma-separated in text area
                    if isempty(selected)
                        app.ReferencechannelsTextArea.Value = "";
                    else
                        app.ReferencechannelsTextArea.Value = strjoin(selected, ',');
                    end

                    app.updateChannelListBoxSelection(selected);

                case 'removeICA'
                    selected = app.output.ICAchans;
                    if isempty(selected); selected = {}; end

                    idx = find(strcmp(selected, clickedLabel), 1);
                    if isempty(idx)
                        selected{end+1} = clickedLabel; %#ok<AGROW>
                    else
                        selected(idx) = [];
                    end
                    app.output.ICAchans = selected;

                    if isempty(selected)
                        app.ChannelstohighlightEditField.Value = "";
                    else
                        app.ChannelstohighlightEditField.Value = strjoin(selected, ',');
                    end

                    app.updateChannelListBoxSelection(selected);
            end

            app.prevListBoxValue = app.ListBox.Value;
        end

        %% Field callbacks (GUIDE edit_Callback equivalents)
        function ReferencechannelsTextAreaValueChanged(app, ~)
            txt = app.ReferencechannelsTextArea.Value;
            if iscell(txt)
                txt = strjoin(txt, ' ');
            end
            txt = char(txt);

            if isempty(strtrim(txt))
                app.output.newReference = {};
            else
                parts = regexp(txt, '\s*,\s*', 'split'); % comma-separated
                parts = parts(~cellfun(@isempty, parts));
                app.output.newReference = parts;
            end

            if strcmp(app.output.analysisStep, 'rereference') && strcmp(app.listboxMode, 'channels')
                app.updateChannelListBoxSelection(app.output.newReference);
            end
        end

        function NewsamplingrateEditFieldValueChanged(app, ~)
            if strcmp(app.output.analysisStep, 'resample')
                app.output.newFS = app.NewsamplingrateEditField.Value;
            end
        end

        function InterpolationDropDownValueChanged(app, ~)
            app.output.interpolationMethod = app.If128electrodesuseinterpolationmethodDropDown.Value;
        end

        function EpochFieldsValueChanged(app, ~)
            app.output.prestimDur  = app.PrestimdurEditField.Value;
            app.output.poststimDur = app.PoststimdurEditField.Value;
        end

        function InspectionFieldsValueChanged(app, ~)
            app.output.timeRangeToDisplay = app.TimerangeEditField.Value;
            app.output.amplitudeToDisplay = app.AmplitudeEditField.Value;
        end

        function ArtifactFieldsValueChanged(app, ~)
            app.output.lowAmplitudeThreshold  = app.minAmp.Value;
            app.output.highAmplitudeThreshold = app.maxAmp.Value;
            app.output.sampleToSample         = app.sampletosamplethreshold.Value;
            app.output.minTimeWindowArtifacts = app.mintimewindow.Value;
            app.output.maxTimeWindowArtifacts = app.maxtimewindow.Value;
            app.output.noActivity             = app.flatlinethreshold.Value;
        end

        %% Sync snapshot (optional convenience)
        function syncOutputFromUI(app)
            % Store all UI-derived values directly in app.output (no output.settings).
            % Safe if UI components are missing/deleted.
        
            function val = safeGet(h, prop, defaultVal)
                val = defaultVal;
                try
                    if ~isempty(h) && isvalid(h) && isprop(h, prop)
                        val = h.(prop);
                    end
                catch
                    % keep default
                end
            end
        
            % Rereference
            app.output.referenceChannels = safeGet(app.ReferencechannelsTextArea, 'Value', "");
            % Keep newReference already managed by listbox/text callback; no overwrite here.
        
            % Resample
            app.output.newSamplingRate = safeGet(app.NewsamplingrateEditField, 'Value', NaN);
            if strcmp(app.output.analysisStep, 'resample')
                app.output.newFS = app.output.newSamplingRate;
            end
        
            % Filters
            app.output.lowpassBoundary  = safeGet(app.BoundryEditField,   'Value', NaN);
            app.output.highpassBoundary = safeGet(app.BoundryEditField_2, 'Value', NaN);
        
            % Continuous inspection
            app.output.timeRangeToDisplay = safeGet(app.TimerangeEditField, 'Value', NaN);
            app.output.amplitudeToDisplay = safeGet(app.AmplitudeEditField, 'Value', NaN);
        
            % Epoching
            app.output.prestimDur  = safeGet(app.PrestimdurEditField,  'Value', NaN);
            app.output.poststimDur = safeGet(app.PoststimdurEditField, 'Value', NaN);
        
            % Interpolation method
            app.output.interpolationMethod = safeGet(app.If128electrodesuseinterpolationmethodDropDown, 'Value', "invdist");
        
            % Artifact rejection thresholds
            app.output.lowAmplitudeThreshold  = safeGet(app.minAmp, 'Value', NaN);
            app.output.highAmplitudeThreshold = safeGet(app.maxAmp, 'Value', NaN);
            app.output.sampleToSample         = safeGet(app.sampletosamplethreshold, 'Value', NaN);
            app.output.minTimeWindowArtifacts = safeGet(app.mintimewindow, 'Value', NaN);
            app.output.maxTimeWindowArtifacts = safeGet(app.maxtimewindow, 'Value', NaN);
            app.output.noActivity             = safeGet(app.flatlinethreshold, 'Value', NaN);
        end


        %% RUN button (GUIDE OK_pushbutton analogue)
        function RUNButtonPushed(app, ~)
            % Final snapshot while UI still exists
            app.syncOutputFromUI();
        
            % Unblock constructor
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                uiresume(app.UIFigure);
        
                % IMPORTANT: do NOT delete UIFigure here.
                % Deleting the UIFigure can delete the app object, breaking .getOutput().
                app.UIFigure.Visible = 'off';
            end
        end

        function CloseRequest(app, src, evt) %#ok<INUSD>
            % Closing the window should behave like pressing RUN:
            % store output, unblock uiwait, but do NOT delete the UIFigure (to keep app valid
            % for the chained .getOutput() call).
        
            try
                app.syncOutputFromUI();
            catch
                % ignore
            end
        
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                uiresume(app.UIFigure);
                app.UIFigure.Visible = 'off';
            else
                % Fallback
                delete(src);
            end
        end

    end

    %% Public API (constructor, getOutput, delete)
    methods (Access = public)
        function app = preprocessing_main_gui(EEG)
            if nargin < 1
                EEG = struct();
            end
            if ~isstruct(EEG)
                error('preprocessing_main_gui:InvalidInput', 'EEG must be a struct.');
            end
            app.EEG = EEG;
        
            createComponents(app);
        
            % UI text
            app.LoadfilesButton.Text = 'Load data';
        
            % Initialize output schema and groups
            app.initializeOutput();
            app.buildGroups();
        
            % Wire callbacks
            app.LoadfilesButton.ButtonPushedFcn = @(~,~) app.LoadfilesButtonPushed();
            app.RUNButton.ButtonPushedFcn       = @(~,~) app.RUNButtonPushed();
        
            app.SelectprocessingstepButtonGroup.SelectionChangedFcn = @(~,~) app.ProcessingStepChanged();
        
            app.ListBox.Multiselect     = 'on';
            app.ListBox.ValueChangedFcn = @(~,~) app.ListBoxValueChanged();
        
            app.NewsamplingrateEditField.ValueChangedFcn = @(~,~) app.NewsamplingrateEditFieldValueChanged();
            app.If128electrodesuseinterpolationmethodDropDown.ValueChangedFcn = @(~,~) app.InterpolationDropDownValueChanged();
        
            app.ReferencechannelsTextArea.ValueChangedFcn = @(~,~) app.ReferencechannelsTextAreaValueChanged();
        
            app.PrestimdurEditField.ValueChangedFcn  = @(~,~) app.EpochFieldsValueChanged();
            app.PoststimdurEditField.ValueChangedFcn = @(~,~) app.EpochFieldsValueChanged();
        
            app.TimerangeEditField.ValueChangedFcn = @(~,~) app.InspectionFieldsValueChanged();
            app.AmplitudeEditField.ValueChangedFcn = @(~,~) app.InspectionFieldsValueChanged();
        
            app.minAmp.ValueChangedFcn = @(~,~) app.ArtifactFieldsValueChanged();
            app.maxAmp.ValueChangedFcn = @(~,~) app.ArtifactFieldsValueChanged();
            app.sampletosamplethreshold.ValueChangedFcn = @(~,~) app.ArtifactFieldsValueChanged();
            app.mintimewindow.ValueChangedFcn = @(~,~) app.ArtifactFieldsValueChanged();
            app.maxtimewindow.ValueChangedFcn = @(~,~) app.ArtifactFieldsValueChanged();
            app.flatlinethreshold.ValueChangedFcn = @(~,~) app.ArtifactFieldsValueChanged();
        
            % IMPORTANT: close handler must also unblock uiwait
            app.UIFigure.CloseRequestFcn = @(src,evt) app.CloseRequest(src, evt);
        
            % Startup state: disable everything except load
            app.setUIEnabledAfterLoad(false);
            app.setAllFieldsDisabled();
            app.resetProcessingStepSelection();
            app.updateListBox('files');
        
            registerApp(app, app.UIFigure);
        
            % GUIDE-like behavior: block until RUN or window close
            uiwait(app.UIFigure);
        
            % Do NOT clear app here (breaks chaining).
        end

        function out = getOutput(app)
            try
                app.syncOutputFromUI();
            catch
                % ignore (UI may be gone)
            end
            out = app.output;
        end

        function delete(app)
            if isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end
end
