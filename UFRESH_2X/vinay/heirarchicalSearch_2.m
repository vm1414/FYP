%% 12s down to 8s by changing xx-2xc+cc to cc-2xc
% Down to 4s with heirarchical search
% Down to 3s with cell array in reconstructFromMap.m
% 12 was for 2048 codewords, 3s is for 4096!!

function [ idx ] = heirarchicalSearch_2( X,heirarchy, index )
%     heirarchy = single(heirarchy);
    idx = zeros(size(X,2),1);
    X = single(X');
    h = heirarchy{end};
    CC = sum(h.^2,1);
    XC = single(X*h);
    dists = bsxfun(@minus, CC, 2*XC);
    [~,ind] = min(dists,[],2);
    for i = 1:length(heirarchy)
        indices = find(ind == i);
        if numel(indices) > 0
            h = heirarchy{i};
            CC = sum(h.^2,1);
            XC = X(indices,:)*h;
            dists = bsxfun(@minus,CC,2*XC);
            [~,idx2] = min(dists,[],2);
            idx(indices) = index{i}(idx2);
        end
    end       
end


% function [ idx ] = heirarchicalSearch( X,heirarchy )
%     heirarchy = single(heirarchy);
%     idx = zeros(size(X,2),2);
%     X = single(X');
%     CC = single(sum(heirarchy(:,:,1).^2, 2)');
%     XC = single(X * heirarchy(:,:,1)');
%     dists = (bsxfun(@minus, CC, 2*XC));
%     [~,idx(:,1)] = min(dists,[],2);
%     for i = 1:size(heirarchy,1)
%         heir = squeeze(heirarchy(i,:,2:end))';
%         CC = sum(heir.^2, 2)';
%         indices = find(idx(:,1)==i);
%         XC = X(indices,:) * heir';
%         dists = bsxfun(@minus, CC, 2*XC);
%         [~,idx2]=min(dists,[],2);
%         idx(indices, 2) = idx2;
%     end        
% end