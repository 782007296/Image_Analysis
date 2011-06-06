%%                          optimizing _dotfinding.m
% Alistair Boettiger                                   Date Begun: 01/31/11
% Levine Lab 

% Just a testing script to optimize dot finding algorithm and parameters.
% This is a faster testbed then running the whole stack analysis as in
% imsinglemolecule.fig
% 
% 
% Modified to require images from projected files.  This is more memory
% efficient than reading in directly the whole lsm file.  


clear all;


dispdata = 0; % display dots around a chosen z section for visual cross-check.  
max_size = 200; % Biggest linear dimension at which to attempt 3D projection; 



    


tic; 
disp('loading data...');

%folder = '/Volumes/Data/Lab Data/Raw_Data/02-17-11/';
%fname = 'MP05_22C_sna_y'; emb = '02';
%fname = 'MP09_22C_hb_y_d'; emb = '01';

folder = '/Volumes/Data/Lab Data/Raw_Data/2011-05-22/';

rawfolder =  folder; % '/Volumes/Data/Lab Data/Raw_Data/2011-05-22/s12_cntrl_2label/';
  stackfolder = 's12_cntrl_2label/';
  fname = 's12_cntrl_2label_2'; emb ='01';

% stackfolder = 's14_comp_cntrl/';
% fname = 's14_comp_cntrl_1'; emb ='01';

filename = [folder,'/',fname];
handles.Im = lsm_read_mod([filename,'.mat'],str2double(emb),1.9E4); 

% fname = 's14_comp_cntrl'; xp1 = 1700; yp1 = 1500;
 fname = 's12_cntrl_2label'; emb ='02';  xp1 = 50; yp1 = 900;
handles.mRNAchn1 = 1;

toc

%fdata = '/Users/alistair/Documents/Berkeley/Levine_Lab/ImageProcessing/';
%save([fdata,'opt_data'],'handles');
%load([fdata,'opt_data']); 




%---- Dot Finding Parameters ----- %
    sigmaE = 3;%  IMPORTANT
    sigmaI = 4; % IMPORTANT
    min_int  = 0.04;    %  5    ;% .05 % not necessary Fix at Zero
    FiltSize = 30;% 
    min_size = 30;% 
   
    % Build the Gaussian Filter   
    Ex = fspecial('gaussian',FiltSize,sigmaE); % excitatory gaussian
    Ix = fspecial('gaussian',FiltSize,sigmaI); % inhibitory gaussian
    Filt = Ex -Ix;
%---------------------------------%


%% Set-up

% zoom in on specific region
 m =  .9; % 1/2048;  % .7; %   1/2048;   % .9; % .85;
Zs = length(handles.Im);
[h,w] = size(handles.Im{1,1}{1}); 

% 
% xp1= floor(h/2*m)+1; 
% xp2 = floor(h/2*(2-m))+1;
% yp1 = floor(w/2*m)+1;
% yp2 = floor(w/2*(2-m))+1;

%xp1 = 1000; yp1 = 1700;

xp2 = xp1+200;
 yp2 = yp1+200;

    Imax = imread([rawfolder,stackfolder,'max_',fname,'_',emb,'.tif']); 
    Imax_dots = Imax(xp1:xp2,yp1:yp2,1:3);  
    figure(1); clf; imagesc(Imax(:,:,1:3));
    figure(2); clf; imagesc(Imax_dots);
    
disp(['Coordinates:  ', num2str(xp1), ' : ', num2str(xp2), ',   ' num2str(yp1), ' : ', num2str(yp2) ] );

   
    % Build the Gaussian Filter   
    Ex = fspecial('gaussian',FiltSize,sigmaE); % excitatory gaussian
    Ix = fspecial('gaussian',FiltSize,sigmaI); % inhibitory gaussian
   
Filt = Ex -Ix;
% figure(1); clf; imagesc(Filt); colorbar;  colormap jet; 
% set(gcf,'color','k');  set(gca,'FontSize',14); 

 
%% Quick view around layer z

if dispdata == 1
tic
z = 20;
 disp(['running sample filter on layer', num2str(z),'...']); 
 
     I0 = handles.Im{1,z-1}{handles.mRNAchn1}( xp1:xp2,yp1:yp2 );
     D0 = dotfinder(I0,Ex,Ix,min_int,min_size);

     I1 = handles.Im{1,z}{handles.mRNAchn1}( xp1:xp2,yp1:yp2 );
     D1 = dotfinder(I1,Ex,Ix,min_int,min_size);

     I2 = handles.Im{1,z+1}{handles.mRNAchn1}( xp1:xp2,yp1:yp2 );
     D2 = dotfinder(I2,Ex,Ix,min_int,min_size);
     
     I3 = handles.Im{1,z+2}{handles.mRNAchn1}( xp1:xp2,yp1:yp2 );
     D3 = dotfinder(I3,Ex,Ix,min_int,min_size);
     
    
     [h,w] = size(I2);    
%  plotting    
     Iz = uint16(zeros(h,w,3));
     Iz(:,:,1) = 3*I1 +   I3  + .5*I0;
     Iz(:,:,2) = 1*I2 + 2*I3  +  2*I0;
     Iz(:,:,3) = 3*I2 +   I3  + .4*I0;
  figure(6); clf;  
     imagesc(Iz);    hold on;    
     plot(D1(:,1),D1(:,2),'y+');
     plot(D2(:,1),D2(:,2),'co'); 
     plot(D3(:,1),D3(:,2),'+','color',[1,1,1]);
     plot(D0(:,1),D0(:,2),'+','color',[1,.2,.2]); 

     clear D0 D1 D2 D3  I1 I2 I3 I0;
     
     toc
end
     
%% Find all dots


[hs,ws] = size( handles.Im{1,1}{handles.mRNAchn1}( xp1:xp2,yp1:yp2 )); 

%im_folder{z} = [rawfolder,stackfolder,fname,'_',emb,'_z',num2str(z),'.tif'];
%          Iin_z = imread(im_folder{z}); 


if hs< max_size
    % NEEDS to be Double 
    Isect1 = zeros(hs,ws,Zs);
    % Isect2 = zeros(hs,ws,Zs);
    % Inuc = zeros(hs,ws,Zs);
    Alldots = uint16(zeros(hs,ws,Zs)); 
end


plotdata = 0 ;% don't show 

 DotData1 = cell(1,Zs);    
  DotMasks1 = cell(1,Zs); 
 im_folder = cell(1,Zs);
 
  DotData2 = cell(1,Zs);    
  DotMasks2 = cell(1,Zs); 
 
 tic; disp('finding dots...'); 
for z = 1:Zs % z = 20        
      % Dot finding for channel 1
          im_folder{z} = [rawfolder,stackfolder,fname,'_',emb,'_z',num2str(z),'.tif'];
          Iin_z = imread(im_folder{z}); 
            
          mRNAchn = 1;   min_int =.06;  % .05; % 
          
         % [cent,labeled] = dotfinder(I,Ex,Ix,min_int,min_size)
          
         [DotData1{z},DotMasks1{z}] = dotfinder(Iin_z(xp1:xp2,yp1:yp2,mRNAchn),Ex,Ix,min_int,min_size);
        
          % figure(2); clf; imagesc(Alldots(:,:,z)); 
          
%           if hs< max_size
%               Alldots(:,:,z) =   Iin_z; % 2 
%               bnd1 = imdilate(bw1,strel('disk',2)) -bw1;         
%              % figure(2); clf; imshow(bnd2);
%               mask = double(2*bw1)+bnd1;   
%               mask(mask==0)=NaN; 
%               mask(mask==1) = 0; 
%               Isect1(:,:,z) = double(I1).*double(mask);
%              %  figure(2); clf; imagesc(mask);   
%               % figure(2); clf; imagesc(Isect1(:,:,z) );   colormap hot;
%           end
          
       mRNAchn = 2;    min_int = .05;   % .05;    %
        [DotData2{z},DotMasks2{z}] = dotfinder(Iin_z(xp1:xp2,yp1:yp2,mRNAchn),Ex,Ix,min_int,min_size);
 
          
end
toc;
%%

   consec_layers = 3;
   ovlap = 4; 
   intype = class(Iin_z);
   
   show_projected = 1; % show max-project with all dots and linked dots.  
   plotZdata = 1 ;% show z-map of data
   getpreciseZ = 0;

ck_dots = tic;
        NewDotC1 = CheckDotUpDown(DotData1,DotMasks1,im_folder,1,plotZdata,getpreciseZ,consec_layers,ovlap,xp1,xp2,yp1,yp2,intype);
        NewDotC2 = CheckDotUpDown(DotData2,DotMasks2,im_folder,2,plotZdata,getpreciseZ,consec_layers,ovlap,xp1,xp2,yp1,yp2,intype);
 toc(ck_dots) 
        %% Project all layers
  
        D1 = cell2mat(DotData1');
        D2 = cell2mat(DotData2');
        
        if show_projected == 1
            Imax = imread([rawfolder,stackfolder,'max_',fname,'_',emb,'.tif']); 
            Imax_dots = 3*Imax(xp1:xp2,yp1:yp2,1:3);  
            Imax_dots(:,:,3) = .1*Imax_dots(:,:,3);
            figure(2);  clf;  imagesc(Imax_dots);
            colordef black; set(gcf,'color','k'); 
            %colormap hot;
            hold on;
            plot(  NewDotC1(:,1),NewDotC1(:,2),'mo','MarkerSize',5 );
            plot(  NewDotC2(:,1),NewDotC2(:,2),'co','MarkerSize',5 ); 
            plot(  D1(:,1),D1(:,2),'m+','MarkerSize',4);
             plot(  D2(:,1),D2(:,2),'c+','MarkerSize',4);
           % saveas(Iout,[folder,fname,'_',emb,'_chn',num2str(mRNAchn),'.fig']); 
           
           figure(4); clf;  imagesc(Imax_dots(:,:,1)+Imax_dots(:,:,2));
            hold on; set(gcf,'color','k');
            plot(  NewDotC1(:,1),NewDotC1(:,2),'b+','MarkerSize',5);
            plot(  NewDotC2(:,1),NewDotC2(:,2),'go','MarkerSize',5);
            colormap hot; colorbar;
           
           figure(3); clf; subplot(2,1,1); set(gcf,'color','k');
           Imax_r = Imax_dots; Imax_r(:,:,2) = 0*Imax_r(:,:,2);
           imagesc(Imax_r); hold on;           
            plot(  NewDotC1(:,1),NewDotC1(:,2),'m+','MarkerSize',5 );
            
            subplot(2,1,2); 
            Imax_g = Imax_dots; Imax_g(:,:,1) = 0*Imax_g(:,:,1);
           imagesc(Imax_g); hold on;
            plot(  NewDotC2(:,1),NewDotC2(:,2),'go','MarkerSize',5 ); 
           
        end
        
%         figure(2); 
%         for z=1:Zs
%             text(DotData2{z}(:,1),DotData2{z}(:,2),[num2str(z)],'color','w','FontSize',8);
%             text(DotData1{z}(:,1),DotData1{z}(:,2),[num2str(z)],'color','m','FontSize',8);
%         end
%         
        
                
           % plot(  NewDotC2(:,1),NewDotC2(:,2),'co','MarkerSize',14 ); 
        
           minS = 6;
           
            d2 = 10*zeros(1,length(NewDotC2));
            jn = zeros(1,length(NewDotC2));
            for n = 1:length(NewDotC2)
                [d2(n),jn(n)] = min(sqrt( (NewDotC2(n,1) - NewDotC1(:,1)).^2 + (NewDotC2(n,2) - NewDotC1(:,2)).^2 + (NewDotC2(n,3) - NewDotC1(:,3)).^2) );
            end
            
           
            
            figure(10); clf; hist(d2);
            sum(d2< minS)/length(d2)
            
            d1 = 10*zeros(1,length(NewDotC1));
            for n = 1:length(NewDotC1)
                d1(n) = min(sqrt( (NewDotC1(n,1) - NewDotC2(:,1)).^2 + (NewDotC1(n,2) - NewDotC2(:,2)).^2 + (NewDotC1(n,3) - NewDotC2(:,3)).^2)  );
            end
            
            figure(10); clf; hist(d1);
            sum(d1< minS)/length(d1)
            
             figure(4); hold on; plot(NewDotC1((d1< minS),1),NewDotC1((d1< minS),2),'c*')
             
              figure(3); subplot(2,1,1); hold on; plot(NewDotC2((d2> minS),1),NewDotC2((d2> minS),2),'y*')
              figure(3); subplot(2,1,2); hold on; plot(NewDotC1((d1> minS),1),NewDotC1((d1> minS),2),'y*')
            
%% Project all layers

first = 1; last = Zs;
depth_code = jet(last-first+1);   
Alldots_proj = max(Alldots(:,:,first:last),[],3); % perform max project

figure(2); clf; colormap hot; imagesc(Alldots_proj); hold on;
plot(  NewDotC(:,1),NewDotC(:,2),'bo','MarkerSize',4 );

%% 3-D visualization

if hs<max_size
    [X,Y] = meshgrid((1:ws)*50,(1:hs)*50);
    Istack = zeros(hs,ws,Zs);
    %nmax = round(max(Inuc(:)));
    c1max = round(max(Isect1(:)));
    %c2max = round(max(Isect2(:)));
    figure(1);  clf;
    colordef black; set(gca,'color','k'); set(gcf,'color','k');

    % % Plot nuclei data
    % for z=first:last
    %     In = Inuc(:,:,z) + c1max + c2max; 
    %     Z = (Zs - z*ones(hs,ws))*340;
    %     surf(X,Y,Z,In); hold on;
    % end
    % shading interp;
    % alpha(.45);  % make nuclei transparent 

    figure(1); clf;  
    for z=first:last
        figure(1);  hold on;
        I1 = Isect1(:,:,z) ;
       Z = (Zs - z*ones(hs,ws))*340;
        surf(X,Y,Z,I1); hold on;

       %plot3(D2u_Z{z}(:,1)*50,D2u_Z{z}(:,2)*50,((Zs-z)*340)*ones(1,length(D2u_Z{z})),'o','MarkerSize',10,'Color',depth_code(z,:)   ); hold on;
    end
    plot3(NewDotC(:,1)*50,NewDotC(:,2)*50,340*(Zs-NewDotC(:,3)) ,'.','MarkerSize',20); 

    shading interp;

    % figure(1);  hold on;
    % for z=first:last
    %     I2 = Isect2(:,:,z) + c1max+1; 
    %     Z = (Zs - z*ones(hs,ws))*340;
    %     surf(X,Y,Z,I2); hold on;
    % end
    % shading interp;
    % 
    % C2 = zeros(c2max,3);
    % for cc = 1:c2max
    %     C2(cc,:) = [((cc-1)/c2max)^3,((cc-1)/c2max)^.5,((cc-1)/c2max)^2];
    % end


    C1 = hot(c1max);
    %C1 = flipud(1-hot(c1max));
    %CN = cool(nmax); 

    % colormap([0,0,0;C1;C2;CN]); colorbar; caxis([0,nmax+c1max+c2max]); 
    colormap(C1); colorbar; caxis([0,c1max]);
    %view(-109,50); 
    view(40,-30); axis on;
    set(gca,'FontSize',12);
    zlim([(Zs-last)*340,(Zs-first+1)*340]);
    xlabel('nanometers');  ylabel('nanometers'); zlabel('nanometers');

end
%%  Can we extract the intensities inside the sphere and rplot just the
% sphere with the intensity of the original dot?  
