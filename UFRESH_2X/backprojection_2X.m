function I_bp=backprojection_2X(SR,HR,filter) 
    % The LR images were originally made by doing bior4.4 decomposition on
    % HR and taking the LL component
    [c_org,l_org] = wavedec2(HR,1,'bior4.4');
    Ilowc = appcoef2(c_org,l_org,'bior4.4',1)./2;
    
    rangeImg=[min(Ilowc(:)) max(Ilowc(:))];
    SR=range0toN(SR,rangeImg);
    [c1,l1] = wavedec2(SR,1,filter);
    [h1,v1,d1] = detcoef2('all',c1,l1,1);
    
    c_rec=[2*Ilowc(:);  h1(:); v1(:); d1(:);];

    I_rec = waverec2(c_rec,l1,filter);

    I_bp=range0toN(I_rec,rangeImg);
end

