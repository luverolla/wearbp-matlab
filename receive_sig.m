dev = serialport("COM8", 115200);
nsamp = 1;
acqs = SignalHandle([]);
%%
figure
hold on
grid on
datacursormode on
al = animatedline("LineWidth",1.25, "Color",'blue');
count = 1;
fnh = @(src,evt) updatePlot(src,evt,al,nsamp,acqs);
configureCallback(dev,"byte",nsamp*4,fnh);
%%
function [] = updatePlot(src,~,a,nsamp,acqs)
    raw = read(src, nsamp, "single");

    [x,~] = getpoints(a);
    start = numel(x);
    %acqs.Data = [acqs.Data raw];
    addpoints(a, start+1:start+nsamp, raw);
    drawnow
end