clear;
dwtmode('spd')

addpath('vinay')
addpath('../Python/data_files')
        
directory_x = 'Testing_Images/FRESH_upscaled/Set14'; 
pattern = '*.bmp';
directory_y = 'Testing_Images/GT/Set14'; 

XpathCell = glob(directory_x, pattern );
Xcell = load_images( XpathCell );
YpathCell = glob(directory_y, pattern );
Ycell = load_images( YpathCell );


blocksize = [6, 6]; % the size of patch.
stepsize = [1, 1];  
if length(Xcell) ~= length(Ycell)	
	error('Error: The number of X images is not equal to the number of Y images!');
end
% nvals = [128,256,512,1024,2048,4096,8192,16384];
nvals = [16384];
meanpsnrs = zeros(length(nvals),1);
meanssims = zeros(length(nvals),1);
meantimeperpixel = zeros(length(nvals),1);
for n = nvals
    fprintf('################   %d    #####################\n',n)
    postpsnr=zeros(1,length(Xcell)); prepsnr = zeros(1,length(Xcell));
    postssim=zeros(1,length(Xcell)); pressim = zeros(1,length(Xcell));
    tpp = zeros(1,length(Xcell));
    %% Specify wavelet function        
    filt = 'db2'; % db2 gives much better results for FRESH input
    %% Begin SR
    for imgIdx = 1:length(Xcell)
        stopwatch1 = tic;
        fprintf('--------------------------------------------------------\n')
        fprintf('Processing image %d of total %d ... \n', imgIdx, length(Xcell));

        Xtest = Xcell{imgIdx}; % LowRresolution image X
        Ytest = Ycell{imgIdx}; % HighResolution image Y    
        fprintf('[BEFORE] PSNR = %.1f     SSIM = %.3f\n', psnr(Xtest,Ytest),ssim(Xtest,Ytest));
        prepsnr(imgIdx) = psnr(Xtest,Ytest);
        pressim(imgIdx) = ssim(Xtest,Ytest);    
        %% NEXT STEP - IMPLEMENT RESIDUAL LEARNING(FROM FRESH) IN V2
        %% NEED TO FIGURE OUT A WAY TO USE Res IN pyMapCell TO DO SOME SORT OF ERROR CORRECTION
        for stage = 1:1
            %% Load trained model
            tic
            load(sprintf('%ipyHeirarchy%i_6x6',stage,n));
            heir6x6 = single(heirarchy); 
            index6x6 = index;
            load(sprintf('%ipyMap%icell192_6x6',stage,n));
            Map6x6 = Map;
            load(sprintf('%ipyHeirarchy%i_3x3',stage,n));
            heir3x3 = single(heirarchy); 
            index3x3 = index;
            load(sprintf('%ipyMap%icell192_3x3',stage,n));
            Map3x3 = Map;
            ensembleSize = 4; % low ensemble size --> not too big of a drop in quality
            Xrec = zeros([size(Xtest),ensembleSize]);
            for rot = 1:ensembleSize
                X = rot90(Xtest, (rot-1));                        
%                 X = ufresh2(X, [3,3], heir3x3, index3x3, Map3x3);
%                 X = ufresh2(X, blocksize, heir6x6, index6x6, Map6x6);
                X = ufresh4(X, blocksize, heir6x6, index6x6, Map6x6, heir3x3, index3x3, Map3x3);
                X = rot90(X, 4-(rot-1));
                X = range0toN(X,[0,1]);
                Xrec(:,:,rot) = X;            
            end        
            Xtest = mean(Xrec,3);
            Xtest = backprojection_2X(Xtest, Ytest, filt); 
            % Clip image to 0-1 range
            Xtest = range0toN(Xtest,[0,1]);
        end
        fprintf('[AFTER]  PSNR = %.1f     SSIM = %.3f\n', psnr(Xtest,Ytest),ssim(Xtest,Ytest));
        postpsnr(imgIdx)=psnr(Xtest,Ytest); 
        postssim(imgIdx)=ssim(Xtest,Ytest); 
        toc(stopwatch1)
        tpp(imgIdx) = toc(stopwatch1)/numel(Ytest);
%         visualiseImprovement(Xcell{imgIdx}, Xtest, Ytest)
    end
    fprintf('============================================================\n')
    fprintf('Average PSNR across all images = %.2f\n',mean(postpsnr))
    fprintf('Average SSIM across all images = %.3f\n',mean(postssim))
    fprintf('Average improvement in PSNR = %.2f\n',mean(postpsnr-prepsnr))
    fprintf('Average improvement in SSIM = %.3f\n',mean(postssim-pressim))
    fprintf('Average Time Per Pixel = %f\n',mean(tpp))
    meanpsnrs(log2(n)-6) = mean(postpsnr);
    meanssims(log2(n)-6) = mean(postssim);
    meantimeperpixel(log2(n)-6) = mean(tpp);    
end

plt = 0;
if plt
    % Plot results
    figure;
    plot(nvals, meanpsnrs)
    xlabel('Number of Centroids')
    ylabel('Average PSNR(dB)')
    title('Impact of # Centroids on PSNR(Set 5)');
    % title('Impact of # Centroids on PSNR(Set 14)');

    figure;
    plot(nvals, meanssims)
    xlabel('Number of Centroids')
    ylabel('Average SSIM')
    title('Impact of # Centroids on SSIM(Set 5)');
    % title('Impact of # Centroids on SSIM(Set 14)');

    figure;
    plot(nvals, meantimeperpixel,'o--')
    xlabel('Number of Centroids')
    ylabel('Average Time Per Pixel')
    title('Impact of # Centroids on Runtime Speed');
end


        