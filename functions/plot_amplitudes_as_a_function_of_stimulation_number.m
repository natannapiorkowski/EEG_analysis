function plot_amplitudes_as_a_function_of_stimulation_number(EEG, components_to_plot, method, to_save_path)

    %% Preparations

    % Prepare subject name
    subject_name = strrep(EEG.filename, '.set', '');
    subject_name = strrep(subject_name, ',', '_');


    
    % Get indices of components to plot (from Settings)
    % Ensure both are string arrays for robust matching
    targets = string(components_to_plot);
    namesStr = string(EEG.Cumulative_ERP_averaging.ComponentNames);
    [tf, loc] = ismember(targets, namesStr);  
    components_to_plot = loc(tf);


    % Get channels labels
    chan_labels = {EEG.chanlocs.labels};

    
    for channel = 1:EEG.nbchan 
        chan_data = squeeze(EEG.data(channel, :, :));
        [~, trials_with_nans ] = ind2sub(size(chan_data), find(isnan(chan_data)));
        trials_with_nans = unique(trials_with_nans);
        
        [~, trials_without_nans ] = ind2sub(size(chan_data), find(~isnan(chan_data)));
        trials_without_nans = unique(trials_without_nans);
        
        for component = components_to_plot
            if sum(~isnan(EEG.Cumulative_ERP_averaging.ERP_amplitudes(channel, component, :))) == 0
                
                continue
            end
            
            hold on
            plot(trials_without_nans, squeeze(EEG.Cumulative_ERP_averaging.ERP_amplitudes(channel, component, trials_without_nans)), ...
                'o', 'MarkerSize',8, ...
                'MarkerFaceColor',EEG.Cumulative_ERP_averaging.ComponentColors{component}, ...
                "Color",EEG.Cumulative_ERP_averaging.ComponentColors{component} ...
                )
    
            plot(trials_with_nans, squeeze(EEG.Cumulative_ERP_averaging.ERP_amplitudes(channel, component, trials_with_nans)), ...
                'o','MarkerSize',8, ...
                "Color",EEG.Cumulative_ERP_averaging.ComponentColors{component}, ...
                'LineWidth',0.5)
    
            xlabel('Number of averaged epochs')
            ylabel(sprintf('%s component amplitude', EEG.Cumulative_ERP_averaging.ComponentNames{component}))
            title(sprintf('Amplitude of %s component as a function of stimulations number. Method: %s \n Channel: %s ', ...
                EEG.Cumulative_ERP_averaging.ComponentNames{component}, ...
                method,...
                chan_labels{channel}), ...
                'Interpreter', 'none')
            
            exportgraphics(gca, ...
                fullfile(to_save_path, sprintf("Amplitude_detection__%s", method), sprintf('Amplitude_%s_%s_%d.png', subject_name, chan_labels{channel}, component)) ...
                )
            close(gcf, 'force');
    
        end
    end
end