%%                      Unsupervised_DotFinding.m
%
% Alistair Boettiger                                   Date Begun: 03/10/11
% Levine Lab                                        Last Modified: 03/10/11
%

clear all;


% Input options 
rawfolder = '/Volumes/Data/Lab Data/Raw_Data/02-06-11/';
stackfolder = 'MP10_22C_sna_y_c/';
folder = '/Users/alistair/Documents/Berkeley/Levine_Lab/Projects/Enhancer_Modeling/Data/'; 
fname ='MP10_22C_sna_y_c';
%fname = 'MP05_22C_sna_y';
mRNA_channels =  2; % 1; % total mRNA channels

% Focus on subset of image: 
     m =   1/2048;  %  .7; % .5; .7; %   1/2048; % 


   getpreciseZ = 0;
   consec_layers = 2;
   ovlap = 2; 
   thresh = .1;

   show_projected = 1; % show max-project with all dots and linked dots.  
   plotZdata = 0 ;% show z-map of data
   showhist = 0; % show histogram of mRNA counts per cell. 
   showim = 0; % show colorcoded mRNA counts per cell
   bins = 40; % bins for histograms of mRNA
   t = .2; % threshold for region definition plotting
   spread = 1.5; % over/under

%---- Dot Finding Parameters ----- %
    sigmaE = 3.5;%  IMPORTANT
    sigmaI = 4; % IMPORTANT
    min_int  = 0.02  ;    %  5    ;% .05 % not necessary Fix at Zero
    FiltSize = 30;% 
    min_size = 10;% 
   
    % Build the Gaussian Filter   
    Ex = fspecial('gaussian',FiltSize,sigmaE); % excitatory gaussian
    Ix = fspecial('gaussian',FiltSize,sigmaI); % inhibitory gaussian
    Filt = Ex -Ix;
%---------------------------------%

Data = cell(10,mRNA_channels); 

for e= 1:100
    tic 
    disp('loading data...');
    if e<10
        emb = ['0',num2str(e)];
    else
        emb = num2str(e);
    end
   
    try load([folder,fname,'_',emb,'_nucdata.mat']); 
            %
            % Loads the following variables.
            %     NucLabeled = downscaled labeled map 
            %     nuc_cents = nuclei centroids
            %     Nucs = downsized raw nuclei image % NOT SAVED
            %     conn_map = connectivity matrix
            %     Cell_bnd = image map of cell boundaries 
    catch me
        disp(me.message)
        break
    end
       
    filename = [rawfolder,'/',fname];
    Im = lsm_read_mod([filename,'.mat'],str2double(emb),1.5E4);    
    

    Zs = length(Im);
    [h,w] = size(Im{1,1}{1}); 
    xp1= floor(h/2*m)+1; 
    xp2 = floor(h/2*(2-m))+1;
    yp1 = floor(w/2*m)+1;
    yp2 = floor(w/2*(2-m))+1;
    hs = yp2-yp1+1; 
    ws = xp2-xp1+1;
    disp(['Coordinates:  ', num2str(xp1), ' : ', num2str(xp2), ',   ' num2str(yp1), ' : ', num2str(yp2) ] );
   
    toc
    
    % thresh = .1; 
    
    for mRNAchn = 1:mRNA_channels % mRNAchn =2
            DotData = cell(1,Zs);    
            DotMasks = cell(1,Zs); 
            tic; disp('finding dots...'); 
            for z = 1:Zs % z = 11         
                  [cent1,bw1,dL] = dotfinder(Im{1,z}{mRNAchn}( xp1:xp2,yp1:yp2 ),Ex,Ix,min_int,min_size,thresh);
                  DotData{z} = cent1;
                  DotMasks{z} = dL;
            end     
            toc;
            
            Cents = cell2mat(DotData');
            
        %%

         dotC = CheckDotUpDown(DotData,DotMasks,Im{1,z}{mRNAchn}( xp1:xp2,yp1:yp2 ),hs,ws,plotZdata,getpreciseZ,consec_layers,ovlap);
        % Project all layers
         
        if show_projected == 1
            Imax = imread([rawfolder,stackfolder,fname,'_',emb,'_max.tif']); 
             Imax_dots = Imax(xp1:xp2,yp1:yp2,mRNAchn);  
             Iout = figure(2);  clf;  imagesc(Imax_dots);
             colordef black; set(gcf,'color','k'); 
             colormap hot; hold on;
                plot(  dotC(:,1),dotC(:,2),'w+','MarkerSize',14 );
                plot(  Cents(:,1),Cents(:,2),'yo','MarkerSize',4);
               saveas(Iout,[folder,fname,'_',emb,'_chn',num2str(mRNAchn),'.fig']); 
        end
        %%
        
    
        
        %%
        
        tic
        disp('assigning dots to nuclei...');
         inds = floor(dotC(:,2))+floor(dotC(:,1))*hs;   
         inds(inds>ws*hs) = ws*hs;        
        
  % % $$$$$$$ % Loop through nuclei counting total dots in region % $$$$$$$$$ % %        
        
         hn = size(NucLabeled,1);  % size of rescaled nuclear image
         
         NucLabel = imresize(NucLabeled,h/hn,'nearest'); % upscale NucLabeled to resolution of mRNA chanel;  
         NucLabel = NucLabel(xp1:xp2,yp1:yp2);
         %figure(3); clf; imagesc(NucLabel);
         Nend = max(NucLabel(:)); % total nuclei 
          
          Nmin = single(NucLabel); 
          Nmin(Nmin==0)=NaN; 
          Nstart = min(Nmin(:)); 
          Nucs_list = unique(NucLabel);
          Nnucs = length(Nucs_list);
          
%           M = NucLabel;
%           M(inds) = 300; 
%           figure(1); clf; imagesc(M);
         
        % Get list of all pixels associated with each nucleus  
        
        
        imdata2 = regionprops(NucLabeled,'PixelIdxList','Area'); 
                
        
     %   C=NucLabel;
        mRNA_cnt = zeros(1,Nnucs); % store counts of mRNA per cell  
        mRNA_den = zeros(1,Nnucs);  % store densities of mRNA per cell
        nuc_area = zeros(1,Nnucs); 
        if showim == 1
            Plot_mRNA = single(NucLabel);
        end
        for i=1:Nnucs; % i = 4
            nn = Nucs_list(i);
            imdata.Area(i) = length(find(NucLabel==nn));
            imdata.PixelID{i} = find(NucLabel==nn);
            mRNA_cnt(i) = length(intersect(imdata.PixelID{i},inds));
         %   C(NucLabel==nn) = mRNA_cnt(i);
            mRNA_den(i) = mRNA_cnt(i)/imdata.Area(i); 
            nuc_area(i) = length(imdata.PixelID{i});
            if showim == 1
                Plot_mRNA(NucLabel==nn) = single(mRNA_den(i));
            end
        end
        % normalize density to the average cell area
        mRNA_sadj = mRNA_den*mean(imdata.Area);
        
        % more stats  
        m_cnt = mean(mRNA_cnt);
        s_cnt = std(mRNA_cnt);
        m_den = mean(mRNA_sadj);
        s_den = std(mRNA_sadj);  
            % save([handles.fdata,'/','test']);
            % load([handles.fdata,'/','test']);    
        toc
            
            
      %% Plotting counts 
      tic
      disp('plotting and saving data...');
         if showhist == 1
                colordef white; 
                figure(5); clf; hist(mRNA_cnt,bins); set(gcf,'color','w');
                title(['mRNA per cell. mean = ',num2str(m_cnt,4),' std=',num2str(s_cnt,4)]); 
                figure(4); clf; hist(mRNA_sadj,bins);set(gcf,'color','w');
                title(['Cell size adjusted mRNA per cell. mean = ',...
                num2str(m_den,4),' std=',num2str(s_den,4)]); 
            % write to disk? 
         end

         if showim == 1        
            figure(3); clf;  colordef black;
            imagesc(Plot_mRNA); colormap('hot'); colorbar; 
            set(gcf,'color','k');  
         end
         
         
        if t ~= 0 && showim == 1 
            Fig_regvar = figure(40); subplot(1,2,mRNAchn);
            [on_cnts,off_cnts]= fxn_regionvar(NucLabel,Plot_mRNA,mRNA_sadj,t,spread,Nnucs,Nucs_list);
        end
    
        
        %
     %% Export data
     Data{e,mRNAchn}.nucarea = nuc_area;
     Data{e,mRNAchn}.dotC = dotC;
     Data{e,mRNAchn}.mRNAcnt = mRNA_cnt;
     Data{e,mRNAchn}.mRNAden = mRNA_den;
     Data{e,mRNAchn}.mRNAsadj = mRNA_sadj;
     
     toc
    end % end loop over mNRA channels
       %  clean up;
%         clear Im DotData DotMasks I_max cent1 bw dL Cents ...
%             Nmin imdata2 NucLabeled Plot_mRNA M C ...
%             nuc_area dotC mRNA_cnt mRNA_den mRNA_sadj;
%             
    
end % end loop over embryos 