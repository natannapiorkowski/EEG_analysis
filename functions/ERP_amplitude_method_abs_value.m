function EEG = ERP_amplitude_method_abs_value(EEG, amplitude_window_sample, METHOD)
   % ERP_amplitude_method_abs_value Compute absolute-value peak amplitudes for ERP data
    %
    % EEG = ERP_amplitude_method_abs_value(EEG, amplitude_window_sample, METHOD)
    %
    % Description
    %   Compute peak amplitudes for annotated ERP components by averaging
    %   samples in a symmetric window around each peak latency. Results are
    %   stored in EEG.Cumulative_ERP_averaging.ERP_amplitudes.
    %
    % Inputs
    %   EEG                    EEG struct containing ERP averaging results. Must
    %                          include field `Cumulative_ERP_averaging` with
    %                          fields `ComponentNames`, `averaged_data`, and
    %                          `ERP_latencies`.
    %   amplitude_window_sample  scalar nonnegative integer specifying the half-
    %                          width of the sample window around each peak to
    %                          average (in samples).
    %   METHOD                 string or char describing the amplitude method;
    %                          stored to EEG.Cumulative_ERP_averaging.ERP_amplitude_method.
    %
    % Outputs
    %   EEG                    The input EEG struct augmented with
    %                          EEG.Cumulative_ERP_averaging.ERP_amplitudes, a
    %                          matrix of size [nbchan x nComponents x trials]
    %                          containing the mean amplitude within the window
    %                          around each annotated peak. Also sets
    %                          EEG.Cumulative_ERP_averaging.ERP_amplitude_method = METHOD.
    %
    % Behavior and details
    %   - Requires `ComponentNames` to include at least "P1" and "N1". If
    %     required fields or components are missing, the function prints an
    %     error message and returns EEG = {}.
    %   - Peak latencies are read from
    %     EEG.Cumulative_ERP_averaging.ERP_latencies (in seconds). Sample
    %     indices are computed as (abs(EEG.xmin) + latency_sec) * EEG.srate.
    %   - For each non-NaN latency, amplitude is computed as the mean of
    %     samples in the range
    %     [peak_sample - amplitude_window_sample : peak_sample + amplitude_window_sample].
    %   - Entries with NaN latency remain NaN in ERP_amplitudes.
    %
    % Example
    %   EEG = ERP_amplitude_method_abs_value(EEG, 3, 'abs_mean_window');
    %
    % Errors
    %   - Returns EEG = {} and prints a message when required fields or
    %     components are missing.


    % Checks and tests
    if ~isfield(EEG, 'Cumulative_ERP_averaging')
        fprintf('!!! EEG struct must contain a field Cumulative_ERP_averaging! (run script "Cumulative_ERP_averaging") !!!\n')
        EEG = {};
        return
    end
    
    for field =  ["ComponentNames", "averaged_data", "ERP_latencies"]
        if ~isfield(EEG.Cumulative_ERP_averaging, field)
            fprintf('!!! EEG.Cumulative_ERP_averaging struct must contain a field %s! (run script "Cumulative_ERP_averaging")) !!!\n', field)
            EEG = {};
            return
        end
    end
    
    for comp = ["P1", "N1"]
        if ~ismember(comp, EEG.Cumulative_ERP_averaging.ComponentNames)
            fprintf('!!! EEG.Cumulative_ERP_averaging.ComponentNames struct must contain component %s! !!!\n', comp)
            EEG = {};
            return
        end
    end



    % Initialize empty array to store component amplitudes
    EEG.Cumulative_ERP_averaging.ERP_amplitudes = NaN(EEG.nbchan, length(EEG.Cumulative_ERP_averaging.ComponentNames), EEG.trials);
    EEG.Cumulative_ERP_averaging.ERP_amplitude_method = METHOD;

    % Find indices of the latency array which contains non_NaN vales
    %latencies = EEG.Cumulative_ERP_averaging.ERP_latencies;
    %[chan_index,component_index,trial_index] = ind2sub(size(latencies), find(~isnan(latencies)));

    % For all annotated peaks calculate amplitude
    for channel = 1:EEG.nbchan %unique(chan_index)'
        for component = 1:length(EEG.Cumulative_ERP_averaging.ComponentNames) %unique(component_index)'
            for trial = 1:EEG.trials %unique(trial_index)'
                % get EEG signal
                signal = EEG.Cumulative_ERP_averaging.averaged_data(channel, :, trial);
    
                % method 1: absolute mean peak value within window
                component_latency_sec = EEG.Cumulative_ERP_averaging.ERP_latencies(channel, component, trial);
                % calculate amplitudes only for these components that were annotated
                if ~isnan(component_latency_sec)
                    component_latency_sample = (abs(EEG.xmin) + component_latency_sec) * EEG.srate;
                    component_amplitude = mean(signal(component_latency_sample-amplitude_window_sample : component_latency_sample+amplitude_window_sample));
                    EEG.Cumulative_ERP_averaging.ERP_amplitudes(channel, component, trial) = component_amplitude;
                end
            end
        end
    end
    
end