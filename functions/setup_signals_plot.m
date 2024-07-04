function [] = setup_signals_plot(ax, sigs, fs, names, colors, options)
%SETUP_SIGNAL_PLOT Setup given axes to plot generic time-variant signals
%   All signals must be sampled at same frequency fs, the signal length
%   considered is the one of the longest signal
arguments
   ax (1,1) matlab.graphics.axis.Axes
   sigs (:,:) double
   % signals must be sampled at common rate
   fs (1, 1) double
   % if not empty, a legend will be shown whose position can be changed
   % setting the option "LegendLocation" with values as cardinal points
   % written in lowercase and without spaces, dashes, or other separators
   % example: setup_signals_plot(..., "LegendLocation", "northeast", ...)
   names (1, :) string = []
   colors (1, :) string = repelem("b", size(sigs, 1))
   options.YLabel (1, 1) string = "Value [NU]"
   options.LineStyle (1,1) string = "-" 
   options.LineWidth (1,1) {mustBeNumeric} = 1
   options.LegendLocation (1,1) string = "northeast"
end

numsigs = size(sigs, 1);
siglen = max(size(sigs, 2));
t = 0:1/fs:(siglen-1)/fs;
plotOptions = rmfield(options, ["YLabel", "LegendLocation"]);

hold on
grid on

xlabel(ax, "Time [s]")
ylabel(ax, options.YLabel)

for i = 1:numsigs
    plot(t, sigs(i, :), 'Color', colors(i), plotOptions)
end

if size(names, 1) > 0
    legend(names, "FontSize", 11, "Location", options.LegendLocation)
end
end

