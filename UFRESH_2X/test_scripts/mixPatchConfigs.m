clear;
dwtmode('per')

addpath('vinay')
addpath('../Python/data_files')

n = 8192;
nvals = [5,6,6,6,7,7,8,8,8,8;
         3,3,4,5,4,5,4,5,6,4];
meanpsnrs = zeros(length(nvals),2);
meanssims = zeros(length(nvals),2);
meantimeperpixel = zeros(length(nvals),2);
starttime = tic;
for set = 1:2
    directory_x = sprintf('Testing_Images/FRESH_upscaled/Set%i',9*set-4); 
    pattern = '*.bmp';
    directory_y = sprintf('Testing_Images/GT/Set%i',9*set-4);  

    XpathCell = glob(directory_x, pattern);
    Xcell = load_images(XpathCell);
    YpathCell = glob(directory_y, pattern);
    Ycell = load_images(YpathCell);

    stepsize = [1, 1];  
    if length(Xcell) ~= length(Ycell)	
        error('Error: The number of X images is not equal to the number of Y images!');
    end          
    for p = 1:10
        %% Load trained models for patch sizes N1xN1 and N2xN2 (N1 > N2)     
        psz1 = nvals(1,p);
        psz2 = nvals(2,p);
        stage = 1;
        if psz1 == 5
            load(sprintf('%ipyHeirarchy%i',stage,n));
            heirN1 = single(heirarchy); 
            indexN1 = index;
            load(sprintf('%ipyMap%icell192',stage,n));
            MapN1 = Map;
        else
            load(sprintf('%ipyHeirarchy%i_%ix%i',stage,n,psz1,psz1));
            heirN1 = single(heirarchy); 
            indexN1 = index;
            load(sprintf('%ipyMap%icell192_%ix%i',stage,n,psz1,psz1));
            MapN1 = Map;
        end
        if psz2 == 5
            load(sprintf('%ipyHeirarchy%i',stage,n));
            heirN2 = single(heirarchy); 
            indexN2 = index;
            load(sprintf('%ipyMap%icell192',stage,n));
            MapN2 = Map;
        else
            load(sprintf('%ipyHeirarchy%i_%ix%i',stage,n,psz2,psz2));
            heirN2 = single(heirarchy); 
            indexN2 = index;
            load(sprintf('%ipyMap%icell192_%ix%i',stage,n,psz2,psz2));
            MapN2 = Map;
        end
        fprintf('################   %d    #####################\n',p)
        postpsnr=zeros(1,length(Xcell)); prepsnr = zeros(1,length(Xcell));
        postssim=zeros(1,length(Xcell)); pressim = zeros(1,length(Xcell));
        tpp = zeros(1,length(Xcell));
        %% Specify wavelet function        
        filt = 'bior4.4'; % db2 gives much better results for FRESH input
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
                tic            
                ensembleSize = 4; % low ensemble size --> not too big of a drop in quality
                Xrec = zeros([size(Xtest),ensembleSize]);
                for rot = 1:ensembleSize
                    X = rot90(Xtest, (rot-1));                        
                    if (p == 2) || (p == 10)
                        X = ufresh4(X, [psz1,psz1], heirN1, indexN1, MapN1, heirN2, indexN2, MapN2);                
                    else
                        X = ufresh3(X, [psz1,psz1], heirN1, indexN1, MapN1, heirN2, indexN2, MapN2);
                    end
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
        fprintf('Average Time Per Pixel = %f\n',mean(tpp)*1e6)
        meanpsnrs(p,set) = mean(postpsnr);
        meanssims(p,set) = mean(postssim);
        meantimeperpixel(p,set) = mean(tpp);    
    end
end
endtime = toc;
fprintf('==============================================================\n')
fprintf('ALL TESTS took %.1f seconds\n',endtime-starttime)

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


        