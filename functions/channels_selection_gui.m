function channels = channels_selection_gui(EEG, window_title)
    if nargin < 2
        window_title = "Channels selection"; % Default value
    end
    % This calls the App Class and waits for the result
    channels = channels_selection_gui_app.showGUI(EEG, window_title);
end
