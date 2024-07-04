dev = serialport("COM8", 115200);
%%
fnh = @(src,evt) receive(src,evt);
configureCallback(dev,"byte",4,fnh);
%%
function [] = receive(src,evt)
    pred = read(src,1,'single');
    fprintf("%.2f\n", pred);
end