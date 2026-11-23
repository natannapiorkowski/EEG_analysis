function idx = find_channel_by_label(EEG, label)
    idx = find(strcmp({EEG.chanlocs.labels}, label), 1);

    if isempty(idx)
        error('Label "%s" was not found.', label);
    end
end