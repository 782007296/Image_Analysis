%%                              CheckDotUpDown
% Alistair Boettiger                                   Date Begun: 01/30/11
% Levine Lab                                        Last Modified: 02/06/11


%% Description
% Stitch multi-stack data together to find 3D positions of all dots. 
% avoids multiple dot counting and avoids fusion of dots in Z.


function [NewDotC] = CheckDotUpDown(DotData,DotMasks,Alldots,h,w,plotdata)
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
% h = hs; w = ws;
maxdots = 300; 

% create list of 3d corrdinates of all dots.  Also assigns all dots a
% unique linear index.
Zs = length(DotData);
dotsinlayer = zeros(1,Zs);
dotC = [];
for z = 1:Zs
    dotsinlayer(z) = size(DotData{z},1);
    dotC = [dotC; DotData{z}, z*ones(dotsinlayer(z),1)];
end
        % Rather memory inefficient, I have the same centroid data stored
        % in 2 different data structures.  Could build this guy to start
        % with.  


NDots = length(dotC); % total number of dots;
DotConn = single(zeros(2*NDots,Zs)); % empty connectivity matrix for all dots;  as a uint16 restricts this to 65,536 dots per image.  
ConnInt = single(zeros(2*NDots,Zs)); 
LayerJoin = false(2*NDots,Zs); 
% Only enter data in every other line. This leaves black space to allow
% for image segmentation routines to be used that will treat each dot as
% separate.  

for Z = 1:Zs % The primary layer
         % convert to pixel linear-index
         inds1 = floor(DotData{Z}(:,2))+floor(DotData{Z}(:,1))*h;  % indices in this layer  
         inds1(inds1>w*h) = w*h; 
         R1 = false(h,w); R1(inds1) = 1; % convert indices to raster map               
         st1_dot_num = sum(dotsinlayer(1:Z-1)); % starting dot number for the layer under study
         
    for z=1:Zs % compare primary layer to all other layers    
         Loz = uint16(maxdots*R1) + DotMasks{z};  % detect overlap with indices   
        % figure(3); clf; imagesc(Loz); 
        % figure(3); clf; imagesc(DotMasks{z}); 
         Loz(Loz<maxdots+1) = 0; % remove non-overlapping dots;
         Loz = Loz - maxdots; Loz(Loz<0) = 0;
              % figure(3); clf; imagesc(Loz);   
         
      % Need to get linear index to stick correctly in array of all dots.  
         stz_dot_num = sum(dotsinlayer(1:z-1));  % starting dot number for the comparison layer     
         inds_zin1 = Loz(inds1); % indices of layer z overlapping layer 1.
         indsT = inds_zin1 + stz_dot_num; % convert layer indices to total overall dot indices 
         indsT(indsT == stz_dot_num) = 0; % makes sure missing indices are still 'missing' and not last of previous layer.   
         DotConn(2*st1_dot_num+1:2:2*(st1_dot_num + dotsinlayer(Z)),z) =  single(indsT); % STORE in DotConn matrix the indices 
         
         % The single pixel version
         Iw = Alldots(:,:,z); % Im{1,z}{handles.mRNAchn1}( xp1:xp2,yp1:yp2 );
         Ivals = Iw(inds1);  % also store the actual intenisites  
         ConnInt(2*st1_dot_num+1:2:2*(st1_dot_num + dotsinlayer(Z)),z) = single(Ivals);   
         % figure(3); clf; imagesc(DotConn); shading flat;
    end
    LayerJoin( 2*st1_dot_num+1 :2*(st1_dot_num + dotsinlayer(Z)),Z) = true(2*dotsinlayer(Z),1); 
    
end
toc
%%
tic
disp('counting total dots...');
% figure(3); clf; imagesc(LayerJoin); 
% figure(3); clf; imagesc(DotConn); colormap hot; shading flat;
% figure(3); clf; imagesc(ConnInt); colormap hot; shading flat;  
 ConnInt_T = ConnInt.*(DotConn>0);
%ConnInt_T(ConnInt_T <.02*2^16)=0;
 
 MD = LayerJoin+ConnInt_T; % figure(4); clf; imagesc(MD);
 MD = MD>0;  MD = bwareaopen(MD,20); % mask of major axis 
 ConnInt_T = ConnInt_T.*MD;
 
 




mask = ConnInt_T>0;
W = ConnInt_T.*mask;
W = watershed(max(W(:)) - W); 
% figure(3); clf; imagesc(W); colormap lines;
mask(W==0) = 0; 
%figure(2); clf; imagesc(mask);

labeled = bwlabel(mask);
R1 = regionprops(labeled,ConnInt,'WeightedCentroid');
cent = reshape([R1.WeightedCentroid],2,length(R1))';

if plotdata == 1;
    figure(4); clf; 
    colordef black; set(gcf,'color','k'); 
    imagesc( ConnInt_T ); colormap hot; shading flat;  colorbar;
    ylabel('mRNA index'); xlabel('z-depth'); 
    hold on; plot(cent(:,1),cent(:,2),'co'); 
    title('Cross-Section of all dots'); 
end
mask = bwareaopen(mask,2);



%%

masked_inds = mask.*DotConn;
remove_dot = zeros(NDots,1); 
stacked_dots =0;
% loop through all dots

for i = 1:2:2*NDots % i = 605 i = 5401; i=5693 i = 5547  i = 6549
    j = find(masked_inds(i,:));
    counted = masked_inds(i,j(2:end));   
    if isempty(j) == 0
        stacked_dots = max(j)-min(j) > length(j)-1;
    
        if stacked_dots == 0
             ii = find(cent(:,2)==i);
             dotC((i+1)/2,3) = cent(ii(1),1);
        end
    else
        remove_dot((i+1)/2) = 1;
    end
    if stacked_dots == 1% if stacked dots split up.  
        brk_pts =[0, find(diff(j)>1),length(j),length(j)]; % breakpoints in stack 
        possibles = masked_inds(i,j); % all possible multicounted indices 
        ii = find(possibles == (i+1)/2) ; % find this breakpoint    
        % only need this if low intensity points have been removed
        if isempty(ii); [jnk, ii] = min( ((i+1)/2 - possibles).^2 );  end
       % find nearest breakpoint without going over
          kk = (ii-brk_pts); kk(kk<0) = 100; [jnk,bi] = min(kk);    
          counted = possibles(brk_pts(bi)+2:brk_pts(bi+1));  
    %     try 
          ii = find(cent(:,2)==i);
          dotC((i+1)/2,3) = cent(ii( min(bi,length(ii)) ),1);
%          catch err
%              disp(i)
%          end
    stacked_dots =0;      
    end
    remove_dot(counted) = 1; 
    
    
    
end
toc
sum(remove_dot);
% sum(stacked_dots)
          % NB can't sum stacked dots, all stack dots are also multiply
          % counted.  i.e. the first time a doublet is enountered we say
          % Tstacked = Tstacked + 1, and then we enounter that the other of
          % the pair and again say Tstacked = Tstacked + 1;  

NewDotC = dotC(~remove_dot,:);
N_dots = NDots - sum(remove_dot) % sum(stacked_dots)



%    %%  Approach 2
%         % New approach. Take each dot.  Try to string together all the way
%      % down, using min distance.  Then find local maximia.  
%    
%      Z= 12;
%      ovlap = 3;
%      h = hs; w = ws;
%      
%      Ds = length(DotData{Z});
%       stack = zeros(Ds,Zs);
%       Ivalue = zeros(Ds,Zs);
%      for j=1:Ds   
%         
%        %  Compare up
%         z = Z; dist = 0;   
%         while dist< ovlap && z>1
%             [dist,i] = min( sqrt( (DotData{Z}(j,1) - DotData{z-1}(:,1)).^2 +  (DotData{Z}(j,2) - DotData{z-1}(:,2)).^2 ) ) ;
%             stack(j,z) = i;
% %             xmatch = round(DotData{z-1}(i,1)); if xmatch > w; xmatch = w; end
% %             ymatch = round(DotData{z-1}(i,2)); if ymatch > h; ymatch = h; end
% %             Ipatch = Im{1,z-1}{handles.mRNAchn1}( max(1,xmatch-5):min(w,xmatch+5),max(1,ymatch-5):min(h,ymatch+5) );
%             
%             
%             Iw = Im{1,z-1}{handles.mRNAchn1}( xp1:xp2,yp1:yp2 );
%             Imask = zeros(hs,ws); 
%             pts = find(DotMasks{z-1}==i);
%             Imask(pts) = 1;                     %figure(3); clf; imagesc(Imask);
%             Imask(Imask==0) = NaN; 
%             Ipatch = Imask.*double(Iw); 
%             
%            % figure(3); clf; imagesc(Ipatch);  colorbar; colormap hot; caxis([0,2^13]); pause(.1);
%             Ivalue(j,z) = nanmean( Ipatch(:) );
%             
%             z=z-1;
%         end
%           
%        % Compare down 
%         z = Z; dist = 0; 
%         while dist < ovlap && z<Zs+1 % max pixel seperation to be considered part of same dot.  
%             [dist,i] = min( sqrt( (DotData{Z}(j,1) - DotData{z+1}(:,1)).^2 +  (DotData{Z}(j,2) - DotData{z+1}(:,2)).^2 ) ) ;
%             stack(j,z) = i;
% %                    xmatch = round(DotData{z+1}(i,1)); if xmatch > w; xmatch = w; end
% %                    ymatch = round(DotData{z+1}(i,2));  if ymatch > h; ymatch = h; end
% %             Ipatch = Im{1,z+1}{handles.mRNAchn1}( max(1,xmatch-5):min(w,xmatch+5),max(1,ymatch-5):min(h,ymatch+5) );
% 
% 
%             Iw = Im{1,z+1}{handles.mRNAchn1}( xp1:xp2,yp1:yp2 );
%             Imask = zeros(hs,ws); 
%             pts = find(DotMasks{z+1}==i);
%             Imask(pts) = 1;                     %figure(3); clf; imagesc(Imask);
%             Imask(Imask==0) = NaN; 
%             Ipatch = Imask.*double(Iw); 
% 
%           %   figure(3); clf; imagesc(Ipatch);  colorbar; colormap hot;  caxis([0,2^13]);   pause(.1);
%             Ivalue(j,z) = nanmean( Ipatch(:) );    
%             z=z+1;
%         end
%         
%        
%      end
%      
%        dep =  sum(Ivalue>0,2);
%        sum(dep>1) / length(dep)
%        length(dep)
%        
%        % min_int = 0.00, Z = 12; count=  185, 70% multilayer  ~129 dots
%        % min_int = 0.05, Z = 12; count=  159, 79% multilayer  ~126 dots
%        % min_int = .1  Z=12 count 91, 78% multilayer.  
%       % Multilayer correction to 0 intensity is within 2.5% of the .05 threshold count.   
%      
%      figure(3); imagesc(Ivalue); colormap hot;
%      set(gcf,'color','k'); colordef black;
%      ylabel('Index of dot'); xlabel('z-axis');
%      
     
     
     
     %% Approach 1:
     % check channel above and below
     % 
     % Problems: 
     % Doesn't avoid duplicated dots (anything in n channels becomes n-2
     % dots.  Some real dots are probably in 4+ channels.
     
     
     
%      
%      function [inds_out, D1r,R3d] = CheckDotUpDown(ovlap,D0,D1,D2,h,w,plotdata)
%      fdata = '/Users/alistair/Documents/Berkeley/Levine_Lab/ImageProcessing/';
% 
%      if isnan(sum(D2(:))) || isnan(sum(D0(:)))
%          D1r = NaN*ones(1,2);
%          inds_out = [];
%          R3d = false(h,w); 
%      else
%             
%    % h = hs; w = ws; 
% 
% 
%          % convert to indices. 
%          inds0 = floor(D0(:,2))+floor(D0(:,1))*h; 
%          inds1 = floor(D1(:,2))+floor(D1(:,1))*h; 
%          inds2 = floor(D2(:,2))+floor(D2(:,1))*h; 
%          
%          inds0(inds0>w*h) = w*h; 
%          inds1(inds1>w*h) = w*h; 
%          inds2(inds2>w*h) = w*h; 
%          
%          % Convert to raster
%          R0 = false(h,w); R0(inds0) = 1;
%          R1 = false(h,w); R1(inds1) = 1;
%          R2 = false(h,w); R2(inds2) = 1;
%          R0z = imdilate(R0,strel('disk',ovlap)); % must be within overlap number of pixels     
%          R2z = imdilate(R2,strel('disk',ovlap)); % must be within overlap number of pixels 
%         
% 
%          %  save([fdata,'/','test2']);
%          % load([fdata,'/','test2']);
%    
%           R3d = R0z+ R1+ R2z; 
%           
%             % R1 must be in the shared region of the overlap, does not get
%          % dilated.
%           
%          
%     %     figure(3); clf; imagesc(R3d); 
%          R3d(R3d<3)=0;  R3d = logical(R3d);
%          
%    
%          
% %   % Is          
% %         R1z = imdilate(R3d,strel('disk',ovlap)); % must be within overlap number of pixels    
% %              mid_max10 = (double(I1).*double(R1z) - double(I0).*double(R0z).*double(R1z) );
% %              mid_max12 = (double(I1).*double(R1z) - double(I2).*double(R2z).*double(R1z) );
% %        
% %               
% %              figure(2); clf; subplot(1,2,1); imagesc(mid_max10); colormap jet; colorbar;
% %              subplot(1,2,2); imagesc(mid_max12); colormap jet; colorbar;
% %              
% %               darker = R3d; 
% %               darker(mid_max10<0) = 0; darker(mid_max12<0) = 0; 
% %               figure(3); clf;  imagesc(R3d + darker); colormap hot; 
% %               
% %               figure(4); clf;  subplot(1,3,1);  imagesc(double(I1).*double(R1z));
% %               subplot(1,3,2);  imagesc(double(I0).*double(R0z).*double(R1z)); 
% %               subplot(1,3,3);  imagesc(double(I2).*double(R2z).*double(R1z) ); 
%               
%               
%          
%          RL = bwlabel(R3d);  
%          % figure(3); clf; imagesc(RL); colormap(jet);
%          
%          Rdata = regionprops(RL,'Centroid'); 
%          D1r = reshape([Rdata.Centroid],2,length(Rdata))'; % vector centroids of 'real' dots
% 
%          % inds_out =  floor(D2u(:,2))+floor(D2u(:,1))*h;  % raster indexed based centroids of unique dots ;
%         % inds_out = inds_out'; 
% 
%               xx = D1r(:,1);  yy = D1r(:,2);
%              inds_out = sub2ind([h,w],xx,yy);
%         
%         
%         %      % Plotting for troubleshooting  
%         %         It = uint8(zeros(h,w,3));
%         %         It(:,:,1) = uint8(55*R1z);
%         %         It(:,:,2) = uint8(155*R2);
%         %       figure(1); clf; imshow(It(1:300,1:300,:)); hold on;
%         %       plot(D1(:,1),D1(:,2),'m+');
%         %       plot(D2u(:,1),D2u(:,2),'co');
% 
% 
%         %  % plotting for troubleshooting     
%         %      figure(4); clf;  
%         %      imshow(Iz(1:300,1:300,:));    hold on;    
%         %      plot(D1(:,1),D1(:,2),'go');
%         %      plot(D2(:,1),D2(:,2),'y+'); 
%     
%           
%          if plotdata == 1 
%              It = uint16(zeros(h,w,3));
%              It(:,:,1) = 4*I0 +2^15*uint16(R3d);
%              It(:,:,2) = 4*I1+2^15*uint16(R3d);
%              It(:,:,3) = 4*I2+2^16*uint16(R3d);
%              figure(5); clf;  imshow(It); hold on;
%              plot(D1r(:,1),D1r(:,2),'c.','MarkerSize',10);
%          end
%      end
% 
% 
%      