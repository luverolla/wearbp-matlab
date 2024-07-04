dev = serialport("COM8", 115200);
%%
figure
hold on
grid on
datacursormode on
al = animatedline("LineWidth",1.25, "Color",'blue');
count = 1;
fnh = @(src,evt) updatePlot(src,evt,al);
configureCallback(dev,"byte",1*4*125,fnh);
%%
function [] = updatePlot(src,evt,a)
    raw = read(src, 1*125, "single");
    %{
    sp = zeros(1,125);
    for i=1:125
        sp(i) = typecast(raw(i), "single");
    end
    %}

    [x,~] = getpoints(a);
    start = numel(x);
    addpoints(a, (start:start+1*125-1)/125, raw);
    drawnow
end