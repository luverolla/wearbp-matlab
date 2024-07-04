function res = custom_conv(u, v)
    res = conv(u, v);
    cl = numel(res);
    sl = numel(u);
    if rem(cl, 2) == 0
        cent_l = cl/2;
        cent_r = cl/2 + 1;
        quant = floor(sl/2);
        if rem(sl, 2) == 0
            res = res(cent_l-quant+1:cent_r+quant-1);
        else
            res = res(cent_r-quant:cent_r+quant);
        end
    else
        cent = floor(cl/2) + 1;
        quant = floor((sl - 1) / 2);
        if rem(sl, 2) == 0
            res = res(cent-quant:cent+quant+1);
        else
            res = res(cent-quant:cent+quant);
        end
    end
end