%%                              CheckDotUpDown
% Alistair Boettiger                                   Date Begun: 01/30/11
% Levine Lab                                        Last Modified: 02/06/11


%% Description
% Stitch multi-stack data together to find 3D positions of all dots. 
% avoids multiple dot counting and avoids fusion of dots in Z.


function New_dotC = CheckDotUpDown(DotData,DotMasks,im_folder,mRNAchn,hs,ws,plotdata,getpreciseZ,consec_layers,ovlap)
%% Updates
% Rewritten 03/07/11 to convert more things to uint16 / uint8 to save
% memory (even fragment of single stack is several gigs of active mem). 
%  
%

%% Approach 3: 
% use 'ovlap'-size pixel masks instead of min distance for speed
% use linear indexing of all dots
tic 
disp('connecting dots in Z...') 
%plotdata = 1; 
% h = hs; w = ws; mRNAchn = 1; ovlap = 4;
  % I = Im{1,z}{mRNAchn}( xp1:xp2,yp1:yp2 );
  




% create list of 3d corrdinates of all dots.  Also assigns all dots a
% unique linear index.
Zs = length(DotData);
dotsinlayer = zeros(1,Zs);
dotC = [];
for z = 1:Zs
    dotsinlayer(z) = size(DotData{z},1);
    dotC = [dotC; DotData{z}, z*ones(dotsinlayer(z),1)];
end


maxdots = max(dotsinlayer) +100
totaldots = length(dotC)

        % Rather memory inefficient, I have the same centroid data stored
        % in 2 different data structures.  Could build this guy to start
        % with.  


NDots = length(dotC); % total number of dots;
DotConn = single(zeros(2*NDots,Zs)); % empty connectivity matrix for all dots;  as a uint16 restricts this to 65,536 dots per image.  
ConnInt = uint16(zeros(2*NDots,Zs)); 
LayerJoin = false(2*NDots,Zs); 
% Only enter data in every other line. This leaves black space to allow
% for image segmentation routines to be used that will treat each dot as
% separate.  

% pre-calc
Rs = cell(Zs,1);
Inds = cell(Zs,1); 
for z=1:Zs
         inds = floor(DotData{z}(:,2))+floor(DotData{z}(:,1))*hs;  % indices in this layer  
         inds(inds>ws*hs) = ws*hs;  
         Rz = uint16(zeros(hs,ws));   
         Rz(inds) = DotMasks{z}(inds); % convert indices to raster map 
         Inds{z} = inds; 
         Rs{z} = imdilate(Rz,strel('disk',ovlap));
end




for Z = 1:Zs % The primary layer Z = 10
         % convert to pixel linear-index
         inds1 = floor(DotData{Z}(:,2))+floor(DotData{Z}(:,1))*hs;  % indices in this layer  
         inds1(inds1>ws*hs) = ws*hs;  
         R1 = uint16(zeros(hs,ws));   
         R1(inds1) = maxdots; % convert indices to raster map   
        % figure(3); clf; imagesc(R1d);  colorbar; colormap jet;
         st1_dot_num = sum(dotsinlayer(1:Z-1)); % starting dot number for the layer under study     
        Iw = imread(im_folder{z}); 
        Iw = Iw(:,:,mRNAchn);
         
    for z=1:Zs % compare primary layer to all other layers  z = Z+1                  
         Loz = R1 + Rs{z}; 
       %  Loz = R1 + DotMasks{z}; (only makes a small difference to use overlap box rather than within found dot.  
         
        % figure(3); clf; imagesc(Loz);  colorbar; colormap jet;
        % figure(3); clf; imagesc(DotMasks{z}); 
         Loz(Loz<maxdots+1) = 0; % remove non-overlapping dots;
         Loz = Loz - maxdots; % LoZ is already positive, so we don't need to worry about negative values.  
        %  figure(2); clf;  imagesc(Loz); colorbar; colormap jet;

      % Need to get linear index to stick correctly in array of all dots.  
         stz_dot_num = sum(dotsinlayer(1:z-1));  % starting dot number for the comparison layer     
         inds_zin1 = Loz(inds1); % indices of layer z overlapping layer 1.
         indsT = inds_zin1 + stz_dot_num; % convert layer indices to total overall dot indices 
         indsT(indsT == stz_dot_num) = 0; % makes sure missing indices are still 'missing' and not last of previous layer.   
         DotConn(2*st1_dot_num+1:2:2*(st1_dot_num + dotsinlayer(Z)),z) =  single(indsT); % STORE in DotConn matrix the indices 
         ConnInt(2*st1_dot_num+1:2:2*(st1_dot_num + dotsinlayer(Z)),z) = Iw(inds1) ;   % store actual intensities.  
        % figure(3); clf; imagesc(DotConn); shading flat;
    end
    LayerJoin( 2*st1_dot_num+1 :2*(st1_dot_num + dotsinlayer(Z)),Z) = true(2*dotsinlayer(Z),1);    
end
toc

%%
% plotdata = 1; getpreciseZ = 1;

tic
disp('counting total dots...');
% figure(3); clf; imagesc(LayerJoin); 
% figure(3); clf; imagesc(DotConn); colormap hot; shading flat;
% figure(3); clf; imagesc(ConnInt); colormap hot; shading flat;  

% The road blocks in this process are the imageprocessing algorithms which
% require a labeled matrix of regionprops: watershed, bwareaopen

stp = 1000;  
Nsects = floor(2*NDots/stp);  
masked_inds = single(zeros(2*NDots,Zs)); 
cent = [];

for k=1:Nsects
% For each dot in the system, there is a row i, which contains all the dots
% above and below it.  We want to concentrate only on the dots in z~=i
% which are connected to the dot as z=i.  For this we use the LayerJoin
% object.  
     mask = DotConn(1+(k-1)*stp:min(k*stp,2*NDots),:)>0; % where dots exist 
     ConnInt_T = ConnInt(1+(k-1)*stp:min(k*stp,2*NDots),:).*uint16(mask); % report intensities where dot connections are found 
     MD = uint16(LayerJoin(1+(k-1)*stp:min(k*stp,2*NDots),:))+ConnInt_T; 
     % figure(4); clf; imagesc(MD);
     MD = MD>0;   
     MD = bwareaopen(MD,20); % Remove all dots in z not connected to the dot at z=i  
     % figure(4); clf; imagesc(MD);
     ConnInt_T = ConnInt_T.*uint16(MD);


    % Watershed to split dots
     mask = ConnInt_T>0;
    % W = ConnInt_T.*uint16(mask.*longDots); figure(4); clf; imagesc(W);
    W = ConnInt_T.*uint16(mask); 
    % figure(4); clf; imagesc(W);
    W = watershed(max(W(:)) - W);   % This is the Memory Kill Step; 
     % figure(3); clf; imagesc(W); colormap lines;
    mask(W==0) = 0; 
    % figure(4); clf; imagesc(mask);

    if getpreciseZ == 1
        labeled = bwlabel(mask);
        R = regionprops(labeled,ConnInt_T,'WeightedCentroid');
        tcent =  reshape([R.WeightedCentroid],2,length(R))';
       % tcent(:,2) =  ;% 
        cent = [cent; tcent(:,1),(k-1)*stp + tcent(:,2)];
        
        if plotdata == 1;
            figure(4); clf; 
            colordef black; set(gcf,'color','k'); 
            imagesc( ConnInt_T ); colormap hot; shading flat;  colorbar;
            ylabel('mRNA index'); xlabel('z-depth'); 
            hold on; plot(tcent(:,1),tcent(:,2),'co'); 
            title('Cross-Section of all dots'); 
        end
    end

    % This is very expensive for big images
       mask = bwareaopen(mask,consec_layers); % figure(3); clf; imagesc(mask);
       masked_inds(1+(k-1)*stp:min(k*stp,2*NDots),:) = mask.*DotConn(1+(k-1)*stp:min(k*stp,2*NDots),:);
end

% clear DotConn;
toc
%%

tic
disp('Building spheres from cross-section disks...');

% figure(3); clf; imagesc(masked_inds); colormap hot;

% testL = NaN*zeros(1,2*NDots); 
remove_dot = zeros(NDots,1); 
stacked_dots =0;
% loop through all dots

for i = 1:2:2*NDots-1 % i = 605 i = 5401; i=5693 i = 5547  i = 6549 
    j = find(masked_inds(i,:));
    counted = masked_inds(i,j(2:end));   
    if isempty(j) == 0
        stacked_dots = max(j)-min(j) > length(j)-1;
    
        if stacked_dots == 0  && getpreciseZ == 1
             ii = find(cent(:,2)==i,1);
             dotC((i+1)/2,3) = cent(ii(1),1);
        end
    else
        remove_dot((i+1)/2) = 1;
    end
    if stacked_dots == 1% if stacked dots split up.  
        brk_pts =[0, find(diff(j)>1),length(j),length(j)]; % breakpoints in stack 
        possibles = masked_inds(i,j); % all possible multicounted indices 
        ii = find(possibles == (i+1)/2,1) ; % find this breakpoint    
        % only need this if low intensity points have been removed
        if isempty(ii); [jnk, ii] = min( ((i+1)/2 - possibles).^2 );  end
       % find nearest breakpoint without going over
          kk = (ii-brk_pts); kk(kk<0) = 100; [jnk,bi] = min(kk);    
          counted = possibles(brk_pts(bi)+2:brk_pts(bi+1)); 
          if  getpreciseZ == 1
              ii = find(cent(:,2)==i);
              dotC((i+1)/2,3) = cent(ii( min(bi,length(ii)) ),1);
          end
    stacked_dots =0;      
    end
     remove_dot(counted) = 1;   
   % testL(i) = length(remove_dot);
end
toc
sum(remove_dot);

% figure(1); clf; plot(testL,'w.');
% sum(stacked_dots)
          % NB can't sum stacked dots, all stack dots are also multiply
          % counted.  i.e. the first time a doublet is enountered we say
          % Tstacked = Tstacked + 1, and then we enounter that the other of
          % the pair and again say Tstacked = Tstacked + 1;  

New_dotC = dotC(~remove_dot,:);
%N_dots = NDots - sum(remove_dot) % sum(stacked_dots)
N_dots = length(New_dotC); 
disp(['Counted ',num2str(N_dots),' spheres']); 

if plotdata ==1
    test_dotC = dotC; test_dotC(logical(remove_dot),3) = 0;
    figure(4); clf; imagesc(masked_inds); colormap hot;
    hold on; plot(test_dotC(:,3),linspace(1,2*NDots-1,NDots),'co');
end
