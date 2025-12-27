classdef preprocessing_main_gui_gui < matlab.apps.AppBase

    % Properties that correspond to app components
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

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 883 800];
            app.UIFigure.Name = 'MATLAB App';

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
            app.RereferenceButton.Value = true;

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
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = preprocessing_main_gui

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

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