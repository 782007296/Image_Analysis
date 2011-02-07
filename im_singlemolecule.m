
%%                  im_singlemolecule.m  Multi Channel
% Alistair Boettiger                                  Date Begund: 01/21/11
% Levine Lab, UC Berkeley                        Version Complete:  
% In Progress                            Last Modified: 01/30/11
% 
% 
%% Attribution:
% Feel free to use modify and distribute this code provided that you
% attribute Alistair Boettiger for development and abide by the provisions
% of the  Creative Commons License 3.0, BY-NC-SA.
% http://creativecommons.org/licenses/by-nc-sa/3.0/.
%
%
%
%%  Important Notes:
%  This version written for Mac.  To impliment in PC just change directory
% paths from using '/' to using '\'.  
% 
%  Before running, go scroll down to function setup and save the default
% parameters to your data folder
% 
%
%
%% Overview:
%  This code uses DNA staining to associate cytoplasmic domains with the
%  nearest nucleus.  High reslolution mRNA FISH localizes transcripts
%
%
%% Required subroutines
% fxn_nuc_seg.m  -- segmentation filter, identifies all nuclei
% fxn_nuc_reg.m -- expands nuclei to assign all regions of embryo to one
% nuclei or another.
% dotfinder.m -- locates dots using difference of gaussians and watershed
% DuplicateDots.m -- compares layers to ID duplicate dots
% vect2rast.m -- simple vector to raster conversion, called by DuplicateDots
% 
%% Updates: 
% 


function varargout = im_singlemolecule(varargin)
% IM_SINGLEMOLECULE M-file for im_singlemolecule.fig
%      IM_SINGLEMOLECULE, by itself, launches the GUI
%
%      IM_SINGLEMOLECULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IM_SINGLEMOLECULE.M with the given input arguments.
%
%      IM_SINGLEMOLECULE('Property','Value',...) creates a new IM_SINGLEMOLECULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before im_singlemolecule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to im_singlemolecule_OpeningFcn via varargin.
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help im_singlemolecule
% Last Modified by GUIDE v2.5 21-Jan-2011 18:33:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @im_singlemolecule_OpeningFcn, ...
                   'gui_OutputFcn',  @im_singlemolecule_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before im_singlemolecule is made visible.
function im_singlemolecule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to im_singlemolecule (see VARARGIN)
   handles.output = hObject; % Choose default command line output for im_nucdots_v5
   
  % Some initial setup 
      % Folder to save .mat data files in for normal script function.  
     handles.fdata = '/Users/alistair/Documents/Berkeley/Levine_Lab/ImageProcessing/';
     handles.step = 0;  % starting step is step 0 
     set(handles.stepnum,'String',handles.step); % change step label in GUI
     handles.output = hObject; % update handles object with new step number
     guidata(hObject, handles);  % update GUI data with new handles
     setup(hObject, eventdata, handles); % set up labels and default values for new step
     guidata(hObject, handles); % update GUI data with new labels        
    
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes im_singlemolecule wait for user response (see UIRESUME)
% uiwait(handles.figure1);




%=========================================================================%
%                          Primary Analysis Section                       %      
%=========================================================================%
% % All of the functional processing script is in this function
function run_Callback(hObject, eventdata, handles)
step = handles.step;

% Step 0: Load Data into script
if step == 0;
    disp('running...'); tic
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
    [handles] = imload(hObject, eventdata, handles); % load new embryo
    toc
end

% Step 1: Max Project nuclear channel at 1024  1024 resoultion
if step == 1; 
    disp('running step 1...'); tic
    handles.mRNAchn1 = str2double(get(handles.in1,'String'));
    handles.mRNAchn2 = str2double(get(handles.in2,'String'));
    handles.NUCchn =  str2double(get(handles.in3,'String'));
    NucBlur = str2double(get(handles.in4,'String')); 
    imsize = str2double(get(handles.in5,'String'));
    last_layer = str2double(get(handles.in6,'String'));
    
    nc = handles.NUCchn;
    
    [h,w] = size(handles.Im{1,1}{1});
    m = imsize/h;
    
    
    Zs = last_layer;
    if last_layer == 0 
        Zs = length(handles.Im); 
    end
    
    nuc = uint16(zeros(imsize,imsize,nc)); 
    for i=1:Zs
        nuc(:,:,i) = imresize(handles.Im{1,i}{nc},m); % 2
    end
    
    In = max(nuc,[],3); % perform max project
    Nucs = uint8(double(In)/2^16*255); % convert to uint8
    figure(1); clf; subplot(1,2,1); imshow(Nucs);
    Nucs = imclose(Nucs,strel('disk',NucBlur));
    figure(1);subplot(1,2,2); imshow(Nucs);
    
    handles.Zs = Zs;
    handles.In = In; 
    handles.Nucs = Nucs;
    
    guidata(hObject, handles);  % update GUI data with new handles
    toc
end


% Step 2: Nuclear Threshold
% uses fxn: fxn_nuc_seg
if step == 2;
% load appropriate data
    disp('running step 2...'); tic
    FiltSize = str2double(get(handles.in1,'String'));  % 
    FiltStr = str2double(get(handles.in2,'String'));
    sigmaE = str2double(get(handles.in3,'String'));
    sigmaI = str2double(get(handles.in4,'String'));
    PercP = str2double(get(handles.in5,'String'));
    minN = str2double(get(handles.in6,'String'));   
    I = handles.Nucs; 
    
  % get threshold image 'bw' and nuclei centroids 'cent'  
    [handles.bw,handles.cent] = fxn_nuc_seg(I,FiltSize,FiltStr,sigmaE,sigmaI,PercP,minN);
   
 % Save data values  
 %      handles.output = hObject; guidata(hObject, handles);   
     guidata(hObject, handles);  % update GUI data with new handles 
    toc;
end
 
% Step 3: Get Region for each Nuclei
% uses fxn  fxn_nuc_reg
if step == 3;   
    tic
    disp('running step 3...');
    Mthink = str2double(get(handles.in1,'String'));  % 
    Mthin = str2double(get(handles.in2,'String'));
    Imnn = str2double(get(handles.in3,'String'));
    [H1,Nuc_overlay,conn_map,cell_bords] = fxn_nuc_reg(handles.In,handles.bw,Mthink,Mthin,Imnn);  

    
    figure(1); clf; imshow(handles.In); hold on;
    plot(cell_bords);
    
    % save([handles.fdata,'/','test']);
    % load([handles.fdata,'/','test']);
    
    [h,w] = size(H1);

    Cell_bnd = false(h,w);
    Cell_bnd(cell_bords) = 1;
    Cell_bnd = bwareaopen( Cell_bnd,100);
    
     figure(1); clf; imshow(Cell_bnd);   
    Cell_bnd2 = imresize(Cell_bnd,2);  
    
    handles.H2 = imresize(H1,2,'nearest');
    handles.Cell_bnd2 = Cell_bnd2; 
    handles.Cell_bnd = Cell_bnd; 
    handles.H1 = H1; 
    guidata(hObject, handles);  % update GUI data with new handles  
    toc
end



 
  % Step 4: Identify and count nascent transcripts  
  % uses fxn dotfinder
 if step == 4   

     disp('running step 4...'); tic
    alphaE =   str2double(get(handles.in1,'String')); % alphaE = .955; %
    sigmaE =str2double(get(handles.in2,'String')); %    sigmaE = 2; %
    alphaI =str2double(get(handles.in3,'String')); %   alphaI = .98; % 
    min_int  = str2double(get(handles.in4,'String')); %   min_int  = .07; % 
    FiltSize = str2double(get(handles.in5,'String')); %   FiltSize = 20;% 
    min_size = str2double(get(handles.in6,'String')); %  min_size = 15; % 
    sigmaI = 3/2*sigmaE;
   
    % Build the Gaussian Filter   
    Ex = fspecial('gaussian',FiltSize,sigmaE); % excitatory gaussian
    Ix = fspecial('gaussian',FiltSize,sigmaI); % inhibitory gaussian
   
    DotData = cell(1,handles.Zs); 
    
   for i=1:handles.Zs
       I2 = handles.Im{1,i}{handles.mRNAchn1};
     DotData{i} = dotfinder(I2,alphaE,alphaI,Ex,Ix,min_int,min_size);
   end
     % save([handles.fdata,'/','test']);
    % load([handles.fdata,'/','test']);
   
   handles.DotData = DotData;
    guidata(hObject, handles);  % update GUI data with new handles  
    toc;
    
 end


 % Step 5: Identify overlapping dots. 
 % uses fxn DuplicateDots.m, which calls fxn vect2rast.m
 if step == 5 
     
    %  save([handles.fdata,'/','test']);
     
     disp('running step 5...');
      
     tic
     % This requires square images as written.  
     
        scale = str2double(get(handles.in1,'String')); % shrinking factor to increase speed 
        bins = str2double(get(handles.in2,'String'));
        showim = str2double(get(handles.in3,'String')); % plot all mRNA locations with depth filter results
        showraw = str2double(get(handles.in4,'String')); % polt raw image with labels.   
        % This is also the minimum distance that we consider overlap in two
        % z-adjacent images.  
        
        % Defining some variables we will need
        Zs = handles.Zs;  % number of z-sections
        DotData = handles.DotData; % Dot data for each section (from prev)
        [h,w] = size(handles.Im{1,1}{1});  % original image dimensions 
        NucLabeled = handles.H1; % our nuclei label matrix
        
        [hn,wn] = size(NucLabeled);  % size
        Nnucs = max(NucLabeled(:)); % total nuclei 
        NucLabeled = imresize(NucLabeled,h/hn,'nearest');
        
           
        % Get list of all pixels associated with each nucleus               
        imdata2 = regionprops(NucLabeled,'PixelIdxList','Area');
        
        
 % % $$$$$$$$$ This loop also checks for vertically duplicated dots that have    $$$$$$$$$$ % % 
        % centroids which overlap by 'scale' pixels or less.  
        
        % initialize a few things before looping through sections;  
     
        inds_Z = cell(Zs,1);
        D2u_Z = cell(Zs,1); % store 
        plotdata = 0 ;% don't show 
        for z = 1:Zs           
            if z == 1 % z = 5;
                D1 = []; % there is no previous layer if z = 1; 
            else
                D1 = DotData{z-1}; % all dots in the previous layer
            end
                D2 = DotData{z}; % all dots in this layer
                [inds_Z{z}, D2u_Z{z}] = DuplicateDots(D1,D2,h,w,plotdata); % custom fxn. 
                % Returns indices in layer 2 that are not also in layer 1. 
        end
        %  save([handles.fdata,'/','test']);
        % load([handles.fdata,'/','test']);
        
         inds = vertcat(inds_Z{:});  % stich these together

  % % $$$$$$$     % Loop through nuclei counting total dots in region   $$$$$$$$$ % %  
        C=NucLabeled;
        mRNA_cnt = zeros(1,Nnucs); % store counts of mRNA per cell  
        mRNA_den = zeros(1,Nnucs);  % store densities of mRNA per cell
        nuc_area = zeros(1,Nnucs); 
        for i=1:Nnucs
            mRNA_cnt(i) = length(intersect(imdata2(i).PixelIdxList,inds));
            C(C==i) = mRNA_cnt(i);
            mRNA_den(i) = mRNA_cnt(i)/length(imdata2(i).PixelIdxList)  ; 
            nuc_area(i) = length(imdata2(i).PixelIdxList);
        end
        % normalize density to the average cell area
        mRNA_sadj = mRNA_den*mean([imdata2.Area]);
        
        % more stats  
        m_cnt = mean(mRNA_cnt);
        s_cnt = std(mRNA_cnt);
        m_den = mean(mRNA_sadj);
        s_den = std(mRNA_sadj);
        
        % Plotting 
        colordef white; 
        figure(5); clf; hist(mRNA_cnt,bins); set(gcf,'color','w');
        title(['mRNA per cell. mean = ',num2str(m_cnt,4),' std=',num2str(s_cnt,4)]); 
        figure(4); clf; hist(mRNA_sadj,bins);set(gcf,'color','w');
        title(['Cell size adjusted mRNA per cell. mean = ',...
              num2str(m_den,4),' std=',num2str(s_den,4)]); 
     
          
          % 2048x2048 resolution depth labeled dots with cell boundaries
       if showim ==1                   
%             % depth color coding of mRNA transcripts
            In = imresize(handles.In,h/hn,'nearest'); % resize
            In = uint8(double(In)/2^16*255); % convert to uint8
            Cell_bnd = uint8(255*imresize(handles.Cell_bnd,h/hn,'nearest'));                           
            Idot = cell(1,Zs); 
            Ib = uint8(zeros(h,w,3));
            Ib(:,:,1) = Cell_bnd; 
            Ib(:,:,2) = Cell_bnd; 
            Ib(:,:,3) = In + Cell_bnd;
            Iv = Ib;
            col = spring(Zs);
           for z=1:Zs;
               I1 = false(h,w);
               I1(inds_Z{z}) = 1; % place all dots on array
               % Paint different color for dots of each z-plane.  
               Iv(:,:,1) = Iv(:,:,1) + uint8(col(z,1)*I1*255);  
               Iv(:,:,2) =Iv(:,:,2) +  uint8(col(z,2)*I1*255);
               Iv(:,:,3) = Iv(:,:,3) + uint8(col(z,3)*I1*255);
               Idot{z} = I1; 
            end
             figure(7); clf; colormap(col); colordef black; set(gcf,'color','k'); 
             imshow(Iv); colorbar; caxis([1,Zs]);
       end
       
    %        save([handles.fdata,'/','test']);
    % load([handles.fdata,'/','test']);
       
       
       
       if isnan(showraw) == 0 
          z= showraw;  
     
          Cell_bnd = uint16(2^16*imresize(handles.Cell_bnd,h/hn,'nearest'));
          Iz = uint16(zeros(h,w,3));
          Iz(:,:,1) = 2*handles.Im{1,z-1}{handles.mRNAchn1} + Cell_bnd;
          Iz(:,:,2) = 2*handles.Im{1,z-2}{handles.mRNAchn1} + Cell_bnd;
          Iz(:,:,3) = 2*handles.Im{1,z}{handles.mRNAchn1} + Cell_bnd;
          
           figure(5); clf;  
           imshow(Iz);    hold on;   
           plot(DotData{z-2}(:,1),DotData{z-2}(:,2),'y+');
           plot(DotData{z-1}(:,1),DotData{z-1}(:,2),'ro');
           plot(DotData{z}(:,1),DotData{z}(:,2),'co'); 
           plot(D2u_Z{z-1}(:,1),D2u_Z{z-1}(:,2),'r.','MarkerSize',10);
           plot(D2u_Z{z}(:,1),D2u_Z{z}(:,2),'c.','MarkerSize',10);
          % legend(['in z=',num2str(z)],
       end
        
        handles.nuc_area = nuc_area; 
        handles.mRNA_cnt = mRNA_cnt; % mRNA count per cell
        handles.mRNA_den = mRNA_den; % mRNA density per cell
        handles.mRNA_sadj = mRNA_sadj; % size adjusted mRNA counts
        handles.mRNA_ind = inds_Z;     % inidices of mRNA per layer
        handles.NucLabeled = NucLabeled; % indices and scale that match mRNA counts
        
        guidata(hObject, handles);     
        toc     
 end
 
 
 % export data
 if step == 6
 tic
    fout = get(handles.fout,'String');
    fname = get(handles.in1,'String');
    disp(['exporting data to ',fout,fname,'...']); 
    
    mRNA_cnt = handles.mRNA_cnt;
    mRNA_den = handles.mRNA_den;
    mRNA_ind = handles.mRNA_ind;
    mRNA_sadj = handles.mRNA_sadj;
    DotData = handles.DotData;
    NucLabeled = handles.NucLabeled;
    nuc_cents = handles.cent; 
    nuc_area = handles.nuc_area;
    In = handles.In; 
    
    save([fout,fname],'mRNA_cnt','mRNA_den','mRNA_ind','mRNA_sadj',...
        'DotData','NucLabeled','nuc_cents','nuc_area','In'); 
    disp('data saved'); 
    
    guidata(hObject, handles); 
 toc
     
 end
 
 
%========================================================================%
 %  end of functional processing script
 % The rest of this code is GUI manipulations







% --- Executes on button press in VarButton.
function VarButton_Callback(hObject, eventdata, handles)



% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %
%                        File managining scripts                          %  
% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %
% This function sets up the new steps with the appropriate input labels and
% defalut label parameters

function setup(hObject,eventdata,handles)
 if handles.step == 0; 
       load([handles.fdata, 'singlemolecule_pars0']); % pars = {' ',' ',' ',' ',' ',' '}; save([handles.fdata,'singlemolecule_pars0'], 'pars' );
        set(handles.in1label,'String',' ');
        set(handles.in1,'String', pars(1));
        set(handles.in2label,'String',' ');
        set(handles.in2,'String', pars(2));
       set(handles.in3label,'String',' ');
        set(handles.in3,'String', pars(3));
        set(handles.in4label,'String',' ');
        set(handles.in4,'String', pars(4));
        set(handles.in5label,'String',' ');
        set(handles.in5,'String', pars(5));
        set(handles.in6label,'String',' ');
        set(handles.in6,'String', pars(6));
            set(handles.VarButtonName,'String','');
%         % For aesthetics, grey out input 5 and 6
%         set(handles.in5label,'String',' '); 
%         set(handles.in5,'String',' ');
%         set(handles.in5,'BackgroundColor',[.7 .7 .7]); 
%         set(handles.in6label,'String',' '); 
%         set(handles.in6,'String',' ');
%         set(handles.in6,'BackgroundColor',[.7 .7 .7]);        
        dir = {
       'Load lsm file and display all layers in stack in 3 color';
       'red will be channel 1, green chn 2, blue chn 3'} ;
        set(handles.directions,'String',dir); 
 end
  if handles.step == 1; 
       load([handles.fdata,'/','singlemolecule_pars1']); % pars = {'1','2','3','4','512','0'}; save([handles.fdata,'singlemolecule_pars1'], 'pars' );
        set(handles.in1label,'String','mRNA 1 channel');
        set(handles.in1,'String', pars(1));
        set(handles.in2label,'String','mRNA 2 channel');
        set(handles.in2,'String', pars(2));
       set(handles.in3label,'String','Nuclei channel');
        set(handles.in3,'String', pars(3));
        set(handles.in4label,'String','Nuclear Blur');
        set(handles.in4,'String', pars(4));
        set(handles.in5label,'String','Working Size');
        set(handles.in5,'String', pars(5));
        set(handles.in6label,'String','Last Layer');
        set(handles.in6,'String', pars(6));
        %    set(handles.VarButtonName,'String',''); 
        dir = {'Step 1: Max project nuclear channel';
            'red will be channel 1, green chn 2, blue chn 3';
       'Use imclose to homoginize nuclei before applying difference of Gaussian filter';
       'Blur removes artificats from heterochromatin'; 
       'Image will be scaled down to "working size" for faster execution'} ;
        set(handles.directions,'String',dir); 
 end
 
 
 
   if handles.step == 2; 
       load([handles.fdata,'/','singlemolecule_pars2']); %pars = {'70','.999','40','37','99','10'};  save([handles.fdata,'singlemolecule_pars2'], 'pars' );
        set(handles.in1label,'String','min Nuc size'); % number of pixels in filter (linear dimension of a square)
        set(handles.in1,'String', pars{1});
        set(handles.in2label,'String','Filter Strength'); % width of Gaussian in pixels
        set(handles.in2,'String',pars{2});
        set(handles.in3label,'String','Excitation Width');
        set(handles.in3,'String',pars{3}); 
        set(handles.in4label,'String','Inhibition Width');
        set(handles.in4,'String', pars{4});
        set(handles.in5label,'String','Percent fused');
        set(handles.in5,'String', pars{5});
        set(handles.in6label,'String','Erode fused');
        set(handles.in6,'String', pars{6});  
       dir = {
        'Step 2: Find nuclei.  Uses a difference of Gaussian filter with';
        'a min nucleus size filter and a aspect ratio filter'}; 
        set(handles.directions,'String',dir);
  end      
  if handles.step == 3;  % nuclei segmentation
    load([handles.fdata,'/','singlemolecule_pars3.mat']); % pars = {'45','3','2','','','',''};  save([handles.fdata,'singlemolecule_pars3'], 'pars' );
        set(handles.in1label,'String','thicken nuclei'); 
        set(handles.in1,'String', pars{1});
        set(handles.in2label,'String','thin boundaries');
        set(handles.in2,'String', pars{2});
        set(handles.in3label,'String','erode'); 
        set(handles.in3,'String', pars{3});
        set(handles.in4label,'String',' ');
        set(handles.in4,'String', pars{4}); 
        set(handles.in5label,'String',' ');
        set(handles.in5,'String', pars{5}); 
        set(handles.in6label,'String',' ');
        set(handles.in6,'String', pars{6});  
                dir = {'Step 2: Map nuclear region';
    'nuclei expand until they collide.  Borders are assigned to different nuclei'} ;
        set(handles.directions,'String',dir); 
  end
  
  
  
  if handles.step == 4;  % Find dots in channel 1
     load([handles.fdata,'/','singlemolecule_pars4.mat']); 
     % pars = {'.955','2','.98','.07','20','10'}; save([handles.fdata,'singlemolecule_pars4'], 'pars' );
     
        set(handles.in1label,'String','\alpha_E'); 
        set(handles.in1,'String', pars{1});
        set(handles.in2label,'String','\sigma_E');
        set(handles.in2,'String', pars{2});
        set(handles.in3label,'String','\alpha_I'); 
        set(handles.in3,'String', pars{3}); 
        set(handles.in4label,'String','min intensity');
        set(handles.in4,'String', pars{4});
        set(handles.in5label,'String','Filter Size');
        set(handles.in5,'String', pars{5});
        set(handles.in6label,'String','min dot size');
        set(handles.in6,'String', pars{6});
        set(handles.VarButtonName,'String','Manual Reg Select');
   dir = {'Step 4: identify and count nascent transcripts of mRNA1.';
         'Uses Difference of Gaussian Filter \alpha_E*exp(-x^2/\sigma_E) - alpha_I*exp(-x^2/\sigma_I)'};
  set(handles.directions,'String',dir); 
  end
  
  if handles.step == 5; % Find duplicates in channel 1
     load([handles.fdata,'/','singlemolecule_pars5.mat']); 
     % pars = {'3','50','0',' ',' ',' '}; save([handles.fdata,'singlemolecule_pars5'], 'pars' );
     
        set(handles.in1label,'String','min overlap'); 
        set(handles.in1,'String', pars{1});
        set(handles.in2label,'String','bins');
        set(handles.in2,'String', pars{2});
        set(handles.in3label,'String','Show high res im?'); 
        set(handles.in3,'String', pars{3}); 
        set(handles.in4label,'String','Show chn x data');
        set(handles.in4,'String', pars{4});
        set(handles.in5label,'String',' ');
        set(handles.in5,'String', pars{5});
        set(handles.in6label,'String',' ');
        set(handles.in6,'String', pars{6});
        set(handles.VarButtonName,'String','Manual Reg Select');
   dir = {'Step 5: Count total mRNA in each nucleus across layers';
         'Compares centroids adjacent slices to remove duplicates.'};
  set(handles.directions,'String',dir); 
  end

  
    
  
  if handles.step == 6;  % Find dots in channel 2
     load([handles.fdata,'/','singlemolecule_pars4.mat']); 
     % pars = {'.955','2','.98','.07','20','10'}; save([handles.fdata,'singlemolecule_pars4'], 'pars' );
     
        set(handles.in1label,'String','\alpha_E'); 
        set(handles.in1,'String', pars{1});
        set(handles.in2label,'String','\sigma_E');
        set(handles.in2,'String', pars{2});
        set(handles.in3label,'String','\alpha_I'); 
        set(handles.in3,'String', pars{3}); 
        set(handles.in4label,'String','min intensity');
        set(handles.in4,'String', pars{4});
        set(handles.in5label,'String','Filter Size');
        set(handles.in5,'String', pars{5});
        set(handles.in6label,'String','min dot size');
        set(handles.in6,'String', pars{6});
        set(handles.VarButtonName,'String','Manual Reg Select');
   dir = {'Step 4: identify and count nascent transcripts of mRNA1.';
         'Uses Difference of Gaussian Filter \alpha_E*exp(-x^2/\sigma_E) - alpha_I*exp(-x^2/\sigma_I)'};
  set(handles.directions,'String',dir); 
  end
  
  if handles.step == 7; % Find duplicates in channel 2
     load([handles.fdata,'/','singlemolecule_pars5.mat']); 
     % pars = {'3','50','0',' ',' ',' '}; save([handles.fdata,'singlemolecule_pars5'], 'pars' );
     
        set(handles.in1label,'String','min overlap'); 
        set(handles.in1,'String', pars{1});
        set(handles.in2label,'String','bins');
        set(handles.in2,'String', pars{2});
        set(handles.in3label,'String','Show high res im?'); 
        set(handles.in3,'String', pars{3}); 
        set(handles.in4label,'String','Show chn x data');
        set(handles.in4,'String', pars{4});
        set(handles.in5label,'String',' ');
        set(handles.in5,'String', pars{5});
        set(handles.in6label,'String',' ');
        set(handles.in6,'String', pars{6});
        set(handles.VarButtonName,'String','Manual Reg Select');
   dir = {'Step 5: Count total mRNA in each nucleus across layers';
         'Compares centroids adjacent slices to remove duplicates.'};
  set(handles.directions,'String',dir); 
  end
  
  if handles.step == 8;
     load([handles.fdata,'/','singlemolecule_pars6.mat']); 
     % pars = {' ',' ',' ',' ',' ',' '}; save([handles.fdata,'singlemolecule_pars6'], 'pars' );
     
     froot = get(handles.froot,'String');
     emb = get(handles.embin,'String');
     fname = [froot,'_',emb];  
     
     
        set(handles.in1label,'String','Save Name'); 
        set(handles.in1,'String', fname);
        set(handles.in2label,'String',' ');
        set(handles.in2,'String', pars{2});
        set(handles.in3label,'String',' '); 
        set(handles.in3,'String', pars{3}); 
        set(handles.in4label,'String',' ');
        set(handles.in4,'String', pars{4});
        set(handles.in5label,'String',' ');
        set(handles.in5,'String', pars{5});
        set(handles.in6label,'String',' ');
        set(handles.in6,'String', pars{6});
        set(handles.VarButtonName,'String','Manual Reg Select');
   dir = {'Step 6: Save Data'};
  set(handles.directions,'String',dir); 
  end
  
guidata(hObject, handles); % update GUI data with new labels





% --- Executes on button press in savePars.
function savePars_Callback(hObject, eventdata, handles)
   % record the values of the 6 input boxes for the step now showing
     p1 = get(handles.in1,'String');  
     p2 = get(handles.in2,'String');  
     p3 = get(handles.in3,'String');  
     p4 = get(handles.in4,'String');  
     p5 = get(handles.in5,'String');  
     p6 = get(handles.in6,'String');  
     pars = {p1, p2, p3, p4, p5, p6}; % cell array of strings
  % Export parameters 
     stp_label = get(handles.stepnum,'String');     
     savelabel = ['singlemolecule_pars',stp_label];  
     % labeled as nucdot_parsi.mat where "i" is the step number 
     save([handles.fdata, savelabel], 'pars');        % export values
     disp([handles.fdata, savelabel]);
     disp(pars) ;



% ----------------------STEP CONTROLS----------------------- %
% interfaces to main analysis code 
% --- Executes on button press in nextstep.
function nextstep_Callback(hObject, eventdata, handles)
handles.step = handles.step + 1; % forward 1 step
 set(handles.stepnum,'String', handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
    setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels

% --- Executes on button press in back.
function back_Callback(hObject, eventdata, handles)
handles.step = handles.step-1; % go back a step
 set(handles.stepnum,'String',handles.step); % Change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles); % update GUI data with new handles
    setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels
% -------------------------------------------------------- %


% --- Executes on button press in LoadNext.
function LoadNext_Callback(hObject, eventdata, handles)
    embn = str2num(handles.emb) + 1;  % update embryo number
    if embn<10
        emb = ['0',num2str(embn)];
    else
        emb = num2str(embn);
    end
    set(handles.embin,'String',emb); % update emb number field in GUI 
    handles.emb = emb; % update emb number in handles structure
[handles] = imload(hObject, eventdata, handles); % load new embryo
guidata(hObject, handles); % save for access by other functions


        %========== change source images ================%
function [handles] = imload(hObject, eventdata, handles)
handles.fin = get(handles.source,'String'); % folder
handles.fname = get(handles.froot,'String'); % embryo name
handles.emb = str2double(get(handles.embin,'String')); % embryo number

filename = [handles.fin,'/',handles.fname];
% load images
    jacquestiffread([filename,'.lsm']);
    handles.Im = loadlsm([filename,'.mat'],handles.emb);    
    
    Zs = length(handles.Im);
    [h,w] = size(handles.Im{1,1}{1});
    
    
    % display image stack at 512x512 resolution
    m = 512/h; 
    for j=1:Zs
            I = uint16(zeros(512,512,3));
            I(:,:,1) = imresize(handles.Im{1,j}{1},m);
            I(:,:,2) = imresize(handles.Im{1,j}{2},m);
            I(:,:,3) = imresize(handles.Im{1,j}{3},m);
            figure(1); clf; imshow(I); pause(.001); 
    end
    
    handles.output = hObject; 
    guidata(hObject,handles);% pause(.1);
    disp('image loaded'); 
        %====================================================%



% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %



% Automatically return the program to step 0 if the image source directory,
% file name, or image number are changed.  

function froot_Callback(hObject, eventdata, handles)
 handles.step = 0;  % starting step is step 0 
     set(handles.stepnum,'String',handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
     setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels


function embin_Callback(hObject, eventdata, handles)
 handles.step = 0;  % starting step is step 0 
     set(handles.stepnum,'String',handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
     setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels



function source_Callback(hObject, eventdata, handles)
 handles.step = 0;  % starting step is step 0 
     set(handles.stepnum,'String',handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
     setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels


% Open file browser to select source folder 
function SourceBrowse_Callback(hObject, eventdata, handles)
 sourcefile = uigetdir; % prompts user to select directory
  set(handles.source,'String',sourcefile);





%% GUI Interface Setup
% The rest of this code just sets up the GUI interface


% --- Outputs from this function are returned to the command line.
function varargout = im_singlemolecule_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function embin_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function source_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function froot_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function in2_Callback(hObject, eventdata, handles)
function in2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function in3_Callback(hObject, eventdata, handles)
function in3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function in1_Callback(hObject, eventdata, handles)
function in1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function in5_Callback(hObject, eventdata, handles)
function in5_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function in6_Callback(hObject, eventdata, handles)
function in6_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function in4_Callback(hObject, eventdata, handles)
function in4_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function Untitled_1_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function fout_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function fout_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton14.
function pushbutton14_Callback(hObject, eventdata, handles)
