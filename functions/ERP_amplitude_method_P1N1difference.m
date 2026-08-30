function EEG = ERP_amplitude_method_P1N1difference(EEG, amplitude_window_sample, METHOD)
    % ERP_amplitude_method_P1N1difference Compute P1–N1 amplitude difference for ERP data
    %
    % EEG = ERP_amplitude_method_P1N1difference(EEG, amplitude_window_sample, METHOD)
    %
    % Description
    %   Compute the absolute amplitude difference between the P1 and N1 peaks
    %   for each channel and trial using averaged ERP waveforms stored in
    %   EEG.Cumulative_ERP_averaging. The function expects annotated peak
    %   latencies for P1 and N1 and extracts amplitudes by averaging samples
    %   within a symmetric window around each peak, then stores the result in
    %   EEG.Cumulative_ERP_averaging.ERP_amplitudes.
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
    %                          matrix of size [nbchan x 1 x trials] containing
    %                          the absolute P1–N1 amplitude differences for
    %                          channels/trials where both P1 and N1 latencies
    %                          are available. Also sets
    %                          EEG.Cumulative_ERP_averaging.ERP_amplitude_method = METHOD.
    %
    % Notes and behavior
    %   - The function requires `ComponentNames` to contain the entries "P1"
    %     and "N1". If fields or components are missing, the function prints an
    %     error message and returns EEG = {}.
    %   - Peak latencies are read from
    %     EEG.Cumulative_ERP_averaging.ERP_latencies (seconds). Sample indices
    %     are computed as (abs(EEG.xmin) + latency_sec) * EEG.srate.
    %   - Amplitude for a peak is computed as the mean of samples in the range
    %     [peak_sample - amplitude_window_sample : peak_sample + amplitude_window_sample].
    %   - The stored amplitude is abs(P1_amplitude - N1_amplitude).
    %   - If either latency is NaN for a channel/trial, that entry remains NaN.
    %
    % Example
    %   EEG = ERP_amplitude_method_P1N1difference(EEG, 3, 'P1-N1_mean_window');
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
    EEG.Cumulative_ERP_averaging.ERP_amplitudes = NaN(EEG.nbchan, 1, EEG.trials);
    EEG.Cumulative_ERP_averaging.ERP_amplitude_method = METHOD;
    
    p1_index = find(EEG.Cumulative_ERP_averaging.ComponentNames == "P1");
    n1_index = find(EEG.Cumulative_ERP_averaging.ComponentNames == "N1");
    
    % For all annotated peaks calculate amplitude
    for channel = 1:EEG.nbchan %unique(chan_index)'
        for trial = 1:EEG.trials %unique(trial_index)'
            component_latency_sec = EEG.Cumulative_ERP_averaging.ERP_latencies(channel, :, trial);
    
            if sum(~isnan(component_latency_sec)) == 2
                signal = EEG.Cumulative_ERP_averaging.averaged_data(channel, :, trial);
    
                component_latency_sample = (abs(EEG.xmin) + component_latency_sec) * EEG.srate;
                p1_amplitude = mean(signal(component_latency_sample(p1_index)-amplitude_window_sample : component_latency_sample(p1_index)+amplitude_window_sample));
                n1_amplitude = mean(signal(component_latency_sample(n1_index)-amplitude_window_sample : component_latency_sample(n1_index)+amplitude_window_sample));
                
                % calculate component amplitude as an absolute difference
                % between P1 and N1
                component_amplitude = abs(p1_amplitude - n1_amplitude);

                % Store a component amplitude in a struct
                EEG.Cumulative_ERP_averaging.ERP_amplitudes(channel, 1, trial) = component_amplitude;
            end
        end
    end

end