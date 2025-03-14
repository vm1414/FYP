clear;
%% SET STAGE HERE =========================================================
stage = 3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dwtmode('per')
addpath('vinay')
addpath('../Python/data_files')

nvals = [16384];

directory_x = sprintf('TrainingData/NF_%i',stage-1);
destdir = sprintf('TrainingData/NF_%i',stage);
pattern = '*.bmp';
directory_y = 'TrainingData/GT'; 
Xcell = load_images(glob(directory_x, pattern));
Ycell = load_images(glob(directory_y, pattern ));

n = nvals;
%% Load trained model
load(sprintf('%ipyHeirarchy%i_NF',stage,n));
heirarchy = single(heirarchy);   
load(sprintf('%ipyMap%icell192_NF',stage,n));  


blocksize = [5, 5]; % the size of patch.
stepsize = [1, 1];  
if length(Xcell) ~= length(Ycell)	
	error('Error: The number of X images is not equal to the number of Y images!');
end

names = dir('TrainingData/GT');
names = names(3:end);
names = {names.name};
names = replace(names,'.bmp','');


meanpsnrs = zeros(length(nvals),1);
meanssims = zeros(length(nvals),1);
meantimeperpixel = zeros(length(nvals),1);


fprintf('################   %d    #####################\n',n)
postpsnr=zeros(1,length(Xcell)); prepsnr = zeros(1,length(Xcell));
postssim=zeros(1,length(Xcell)); pressim = zeros(1,length(Xcell));
tpp = zeros(1,length(Xcell));  
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
    for stage = 1:1%2 %Cascading stages actually makes things worse unless you train separate model for each stage
        ensembleSize = 4; % low ensemble size --> not too big of a drop in quality
        Xrec = zeros([size(Xtest),ensembleSize]);
        for rot = 1:ensembleSize
            X = rot90(Xtest, (rot-1));                        
            X = ufresh2(X, blocksize, heirarchy, index, Map);
            X = rot90(X, 4-(rot-1));
            X = range0toN(X,[0,1]);
            Xrec(:,:,rot) = X;            
        end        
        Xtest = mean(Xrec,3);  
        % Clip image to 0-1 range
        Xtest = range0toN(Xtest,[0,1]);
    end
    fprintf('[AFTER]  PSNR = %.1f     SSIM = %.3f\n', psnr(Xtest,Ytest),ssim(Xtest,Ytest));
    postpsnr(imgIdx)=psnr(Xtest,Ytest); 
    postssim(imgIdx)=ssim(Xtest,Ytest); 
    toc(stopwatch1)
    imgname = sprintf('%s//%s_PSNR%.2f.bmp',destdir,names{imgIdx},postpsnr(imgIdx));
    imwrite(Xtest, imgname);
end
fprintf('============================================================\n')    


        