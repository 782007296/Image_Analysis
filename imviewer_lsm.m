
%%                  imviewer_lsm.m  Multi Channel
% Alistair Boettiger                                  Date Begund: 02/12/11
% Levine Lab, UC Berkeley                        Version Complete: 02/12/11 
% Functionally complete                             Last Modified: 03/10/11
% 
% 
%% Attribution:
% Feel free to use modify and distribute this code provided that you
% attribute Alistair Boettiger and Jacques Bothma for development and abide 
% by the provisions of the  Creative Commons License 3.0, BY-NC-SA.
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
%
%
%% Required subroutines

% 
%% Updates: 
% 03/10/11: changed export name to max_fname from fname_max.
% it's easier to work with filenames with the number at the end, not in the
% middle.  


function varargout = imviewer_lsm(varargin)
% IMVIEWER_LSM M-file for imviewer_lsm.fig
%      IMVIEWER_LSM, by itself, launches the GUI
%
%      IMVIEWER_LSM('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMVIEWER_LSM.M with the given input
%      arguments.
%
%      IMVIEWER_LSM('Property','Value',...) creates a new IMVIEWER_LSM or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before imviewer_lsm_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to imviewer_lsm_OpeningFcn via varargin.
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help imviewer_lsm
% Last Modified by GUIDE v2.5 12-Feb-2011 19:35:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imviewer_lsm_OpeningFcn, ...
                   'gui_OutputFcn',  @imviewer_lsm_OutputFcn, ...
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


% --- Executes just before imviewer_lsm is made visible.
function imviewer_lsm_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imviewer_lsm (see VARARGIN)
   handles.output = hObject; % Choose default command line output for im_nucdots_v5
   
  % Some initial setup 
      % Folder to save .mat data files in for normal script function.  
     handles.fdata = '/Users/alistair/Documents/Berkeley/Levine_Lab/ImageProcessing/';
     handles.dispfl = 0; 
     
     handles.first = [1,1,1,1];
     handles.last = [0,0,0,0];
     handles.nmax = 1.5E4; 
     handles.step = 0;  % starting step is step 0 
     set(handles.stepnum,'String',handles.step); % change step label in GUI
     handles.output = hObject; % update handles object with new step number
     guidata(hObject, handles);  % update GUI data with new handles
     setup(hObject, eventdata, handles); % set up labels and default values for new step
     guidata(hObject, handles); % update GUI data with new labels        
    
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes imviewer_lsm wait for user response (see UIRESUME)
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
    %dispfl = str2double(get(handles.in1,'String')); 
    %handles.dispfl = dispfl;
    handles.nmax = str2double(get(handles.in2,'String'));
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
    [handles] = imload(hObject, eventdata, handles); % load new embryo
    guidata(hObject, handles);  
    %    save([handles.fdata,'/','test']);
    %    load([handles.fdata,'/','test']);
    toc
end

% Step 1: Max Project nuclear channel at 1024  1024 resoultion
if step == 1; 
    disp('running step 1...'); tic
  
    handles.fname = get(handles.in1,'String'); 
    firstc =  get(handles.in2,'String'); 
    lastc = get(handles.in3,'String');
    handles.first = eval(firstc{:});
    handles.last = eval(lastc{:}); 
    
    handles.folderout = get(handles.fout,'String');   
    
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
    [handles] = projectNsave(hObject, eventdata, handles); % load new embryo
    guidata(hObject, handles); 
  
end



function [handles] = projectNsave(hObject, eventdata, handles);    
    fname =handles.fname;
    fout = handles.folderout;
    first = handles.first;
    last = handles.last;
       
    % find if data is uint16 or something else; 
     inttype =  class(handles.Im{1,1}{1}); 
     disp(['data is ',inttype]); 
    
   % Determine the number of channels in the image data
    try 
        test = handles.Im{1,1}{4};
        channels = 4;
    catch chn
        try 
             test = handles.Im{1,1}{3};
             channels = 3;
        catch chn
            try
                 test = handles.Im{1,1}{2};
                 channels = 2;  
            catch chn
                 test = handles.Im{1,1}{1};
                 channels = 1;  
            end
        end
    end
    clear test 
    disp(['Data contains ', num2str(channels),' channels']); 

    
    
    [h,w] = size(handles.Im{1,1}{1});
    
    % interpret last slice of zero as all slices in stack.  
    Zs = length(handles.Im);
    for c=1:channels
        if last(c) == 0 
            last(c) = Zs; 
        end
    end
       
    
   Imax = eval([inttype,'(zeros(h,w,channels));']);
    for i=1:Zs
        Im_layer = eval([inttype,'(zeros(h,w,channels));']);
        for c=1:channels
            Im_layer(:,:,c) = handles.Im{1,i}{c};
            
            % not enough memory to do one shot max project, need to do this
            % progressively.  Fortunately max doesn't care (unlike ave). 
            if i>first(c) && i<last(c)+1
                Imax(:,:,c) = max( cat(3,Imax(:,:,c),Im_layer(:,:,c)),[],3);       
            end
            if channels == 2
                
 %     save([handles.fdata,'/','test']);
%      load([handles.fdata,'/','test']);
                Im_layer(:,:,3) = eval([inttype,'(zeros(h,w,1));']); 
            end
        end
        imwrite(Im_layer,[fout,'/',fname,'_z', num2str(i),'.tif'],'tif');
     end
    
clear handles.Im; 
% Can't write a 2 channel tif, need to convert to a 3 channel version.  
            if channels == 2
                Imax(:,:,3) = eval([inttype,'(zeros(h,w,1))']); 
            end
    imwrite(Imax,[fout,'/','max_',fname,'.tif'],'tif');
    guidata(hObject, handles);  % update GUI data with new handles
    toc


%========================================================================%
 %  end of functional processing script
 % The rest of this code is GUI manipulations



% --- Executes on button press in AutoCycle.
function AutoCycle_Callback(hObject, eventdata, handles)

    froot = get(handles.froot,'String'); % where to find images
    emb = str2double(get(handles.embin,'String'));  
    handles.folderout = get(handles.fout,'String');   % where to save images

     tic 
     
     err = 0; 
    try  
     while err == 0;
         handles.emb = emb; % needed for imload to get the right embyro 

         if emb < 10
             embin = ['0',num2str(emb)];
         else
            embin = num2str(emb);
         end
            handles.fname = [froot,'_',embin];  % needed for savename. 
            set(handles.embin,'String',embin); 

        disp(['running embryo ',embin,'...']); tic
        handles.output = hObject; % update handles object with new step number
        guidata(hObject, handles);  % update GUI data with new handles
        [handles] = imload(hObject, eventdata, handles); % load new embryo
        guidata(hObject, handles);  

        handles.output = hObject; % update handles object with new step number
        guidata(hObject, handles);  % update GUI data with new handles
        [handles] = projectNsave(hObject, eventdata, handles); % load new embryo
        guidata(hObject, handles); 

        emb = emb + 1;    
        toc
     end
         
    catch error
       disp(error.message); 
       disp('Export finished.' ); toc; 
   end
     
    

% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %
%                        File managining scripts                          %  
% ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ %
% This function sets up the new steps with the appropriate input labels and
% defalut label parameters

function setup(hObject,eventdata,handles)
 if handles.step == 0; 
       load([handles.fdata, 'imviewer_lsm_pars0']); 
       % pars = {'1','1.5E4',' ',' ',' ',' '}; save([handles.fdata,'imviewer_lsm_pars0'], 'pars' );
        set(handles.in1label,'String','Display first/last');
        set(handles.in1,'String', pars(1));
        set(handles.in2label,'String','noise max');
        set(handles.in2,'String', pars(2));
       set(handles.in3label,'String',' ');
        set(handles.in3,'String', pars(3));
        set(handles.in4label,'String',' ');
        set(handles.in4,'String', pars(4));
        set(handles.in5label,'String',' ');
        set(handles.in5,'String', pars(5));
        set(handles.in6label,'String',' ');
        set(handles.in6,'String', pars(6));
        dir = {
       'Load lsm file and display all layers in stack in 3 color';
       'red will be channel 1, green chn 2, blue chn 3'} ;
        set(handles.directions,'String',dir); 
 end
  if handles.step == 1; 
       load([handles.fdata,'/','imviewer_lsm_pars1']); 
       
     froot = get(handles.froot,'String');
     emb = get(handles.embin,'String');
     fname = [froot,'_',emb];  
       
       % pars = {' ','[1,1,1,1]','[0,0,0,0]',' ',' ',' '}; save([handles.fdata,'imviewer_lsm_pars1'], 'pars' );
        set(handles.in1label,'String','save name');
        set(handles.in1,'String', fname);
        set(handles.in2label,'String','starting frames');
        set(handles.in2,'String', pars(2));
       set(handles.in3label,'String','end frames');
        set(handles.in3,'String', pars(3));
        set(handles.in4label,'String','Nuclear Blur');
        set(handles.in4,'String', pars(4));
        set(handles.in5label,'String','Working Size');
        set(handles.in5,'String', pars(5));
        set(handles.in6label,'String','First,Last Layer');
        set(handles.in6,'String', pars(6));
        %    set(handles.VarButtonName,'String',''); 
        dir = {'Step 1: Export layer data as tifs and max project between chosen';
            'starting and ending frames.  Use 0 for last frame to use all data.'} ;
        set(handles.directions,'String',dir); 
 end
 
 
 





% --- Executes on button press in savePars.
function savePars_Callback(hObject, eventdata, handles)
   % record the values of the 6 input boxes for the step now showing
     p1 = get(handles.in1,'String');  
     p2 = get(handles.in2,'String');  
     p3 = get(handles.in3,'String');  
     p4 = get(handles.in4,'String');  
     p5 = get(handles.in5,'String');  
     p6 = get(handles.in6,'String');  
     
     try % for some reason the parameters are sometimes retrived as cells instead of strings
         % we need to make sure they are strings.  
       pars = {p1{:}, p2{:}, p3{:}, p4{:}, p5{:}, p6{:}}; % cell array of strings
     catch
        pars = {p1, p2, p3, p4, p5, p6}; % cell array of strings
     end 
  % Export parameters 
     stp_label = get(handles.stepnum,'String');     
     savelabel = ['imviewer_lsm_pars',stp_label];  
     % labeled as nucdot_parsi.mat where "i" is the step number 
     save([handles.fdata, savelabel], 'pars');        % export values
     disp([handles.fdata, savelabel]);
     pars 

%      save([handles.fdata,'/','test']);
%      load([handles.fdata,'/','test']);
     
guidata(hObject, handles); % update GUI data with new labels

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
    embn = handles.emb + 1;  % update embryo number
    if embn<10
        emb = ['0',num2str(embn)];
    else
        emb = num2str(embn);
    end
    set(handles.embin,'String',emb); % update emb number field in GUI 
    handles.emb = emb; % update emb number in handles structure
   [handles] = imload(hObject, eventdata, handles); % load new embryo
   guidata(hObject, handles); % save for access by other functions

% Reset step to step 1; 
    handles.step = 1; % forward 1 step
    set(handles.stepnum,'String', handles.step); % change step label in GUI
    handles.output = hObject; % update handles object with new step number
    guidata(hObject, handles);  % update GUI data with new handles
    setup(hObject, eventdata, handles); % set up labels and default values for new step
    guidata(hObject, handles); % update GUI data with new labels



        %========== change source images ================%
function [handles] = imload(hObject, eventdata, handles)
handles.fin = get(handles.source,'String'); % folder
handles.ename = get(handles.froot,'String'); % embryo name
handles.emb = str2double(get(handles.embin,'String')); % embryo number

filename = [handles.fin,'/',handles.ename];
% load images

if handles.emb == 1 % only need to do this once.  
    jacquestiffread([filename,'.lsm']);
end
   %  handles.Im = loadlsm([filename,'.mat'],handles.emb);  % old version
   
   
    handles.Im = lsm_read_mod([filename,'.mat'],handles.emb,handles.nmax); 
    
    Zs = length(handles.Im);
    [h,w] = size(handles.Im{1,1}{1});
    

    if h ==1 % handles.dispfl == 1; 
        try
        % display image stack at 512x512 resolution
            m = 512/h; 
            for j=1:Zs
                    I = uint16(zeros(512,512,3));
                    I(:,:,1) = imresize(handles.Im{1,j}{1},m);
                    I(:,:,2) = imresize(handles.Im{1,j}{2},m);
                    I(:,:,3) = imresize(handles.Im{1,j}{3},m);
                    figure(10); clf; imshow(I); pause(.001); 
            end
        catch error
            disp(error.message);
            disp('Only 2 data channels found'); 
        end          
    
  %      display first and last in stack
          figure(1); clf; set(gcf,'color','k'); colordef black;
            subplot(1,2,1); imshow(handles.Im{1,1}{1}); title('First slice, chn 1');
            subplot(1,2,2); imshow(handles.Im{1,Zs}{1});  title('Last slice, chn 1');

            figure(2); clf; set(gcf,'color','k'); colordef black;
            subplot(1,2,1); imshow(handles.Im{1,1}{2}); title('First slice, chn 2');
            subplot(1,2,2); imshow(handles.Im{1,Zs}{2}); title('Last slice, chn 2');

        try
            figure(3); clf; set(gcf,'color','k'); colordef black;
            subplot(1,2,1); imshow(handles.Im{1,1}{3}); title('First slice, chn 3');
            subplot(1,2,2); imshow(handles.Im{1,Zs}{3}); title('Last slice, chn 3');  
            
        catch error
            disp(error.message);
            disp('Only 2 data channels found'); 
        end          
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
function varargout = imviewer_lsm_OutputFcn(hObject, eventdata, handles) 
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
