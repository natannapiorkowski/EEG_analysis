function colorprint(rgb, txt)
% printColoredText Display text in a figure using the specified RGB color.
%   printColoredText([r g b], 'Some text') shows 'Some text' centered in a
%   new figure (or reuses current figure) with color [r g b], where each
%   component is in the range [0,1].
%
%   Example:
%       printColoredText([1 0 0], 'Hello, red world!')

    % Input validation
    validateattributes(rgb, {'numeric'}, {'vector','numel',3,'>=',0,'<=',1}, mfilename, 'rgb', 1);
    validateattributes(txt, {'char','string'}, {'scalartext'}, mfilename, 'txt', 2);

    % Ensure there is a figure and an axes
    fig = gcf;
    clf(fig);                 % clear figure so text is clearly visible
    ax = axes('Parent', fig);
    set(ax, 'Visible', 'off');    % hide axes ticks/box

    % Display centered text
    text(0.5, 0.5, char(txt), ...
        'Parent', ax, ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', 18, ...
        'Color', rgb);

    % Make figure background white for contrast
    set(fig, 'Color', 'w');
end
