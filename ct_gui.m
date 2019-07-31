function varargout = ct_gui(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ct_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @ct_gui_OutputFcn, ...
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

% --- Executes just before ct_gui is made visible.
function ct_gui_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for ct_gui
handles.output = hObject;

% Update handles structure
handles.enhance_list={};
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = ct_gui_OutputFcn(hObject, eventdata, handles)

varargout{1} = handles.output;




% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)

file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)

printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.

function popupmenu1_Callback(hObject, eventdata, handles)
handles = guidata(hObject); 
popup_sel_index = get(handles.popupmenu1, 'Value');% 1 2 3 4 5 
if popup_sel_index == 7
    set(handles.uipanel1,'visible', 'on');
else
    set(handles.uipanel1,'visible', 'off');
end
guidata(hObject,handles); %update


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
     set(hObject,'BackgroundColor','white');
end



%% --- Executes on button press in Open_button.
function Open_button_Callback(hObject, eventdata, handles) 
handles = guidata(hObject);   

handles.folder = uigetdir;
handles.threedarray = NaN;    
guidata(hObject,handles); %update
gatherImages(hObject, eventdata, handles);
handles = guidata(hObject);   
[handles.P, handles.Q, handles.R] = size(handles.threedarray);

handles.axvert = 1:handles.P; handles.sagvert = 1:handles.P; handles.corvert = 1:handles.Q;
handles.axhorz = 1:handles.Q; handles.saghorz = 1:handles.R; handles.corhorz = 1:handles.R;
handles.x = ceil(handles.P/2); handles.y = ceil(handles.Q/2); handles.z = ceil(handles.R/2);

guidata(hObject,handles); %update
preprocess(hObject, eventdata, handles)


set(handles.axes1,'visible', 'on');
set(handles.axes2,'visible', 'on');
set(handles.axes3,'visible', 'on');
set(handles.slider1,'visible', 'on');
set(handles.slider2,'visible', 'on');
set(handles.slider3,'visible', 'on');
set(handles.update_button,'Enable', 'on');
set(handles.popupmenu1,'Enable', 'on');

guidata(hObject,handles); %update





function edit1_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function preprocess(hObject, eventdata,handles) %Update all three images
handles = guidata(hObject);  
dispAxial(hObject, eventdata,handles);  % z R
dispSagittal(hObject, eventdata,handles);  % y Q
dispCoronal(hObject, eventdata,handles);  % x P
guidata(hObject,handles); %update

function dispAxial(hObject, eventdata,handles) %Update axial image
handles = guidata(hObject);  %receive
imz = double(squeeze(handles.threedarray(handles.axvert,handles.axhorz,handles.z)));
%imz = imz/max(imz(:));
multiplier = 1/(max(max(imz(:))));
imz = multiplier*imz;
imz = imresize(imz,[512 512]);
imz = flipdim(imz ,2);
imz = do_enhance(hObject, eventdata,handles,imz);
imshow(imz ,'Parent', handles.axes1)
guidata(hObject,handles); %update    

function dispSagittal(hObject, eventdata,handles) %Updata sagittal image
handles = guidata(hObject);  %receive
imy = double(squeeze(handles.threedarray(handles.sagvert,handles.y,handles.saghorz)));
multiplier = 1/(max(max(imy(:))));
imy = multiplier*imy';
imy = imresize(imy,[512 512]); 
imy = do_enhance(hObject, eventdata,handles,imy);
imshow(imy ,'Parent', handles.axes2)
guidata(hObject,handles); %update

function dispCoronal(hObject, eventdata,handles) %Update coronal image
handles = guidata(hObject);  %receive
imx = double(squeeze(handles.threedarray(handles.x,handles.corvert,handles.corhorz)));
multiplier = 1/(max(max(imx(:))));
imx = multiplier*imx';
imx = imresize(imx,[512 512]);
imx = do_enhance(hObject, eventdata,handles,imx);
imshow(imx ,'Parent', handles.axes3)
guidata(hObject,handles); %update

function gatherImages(hObject,eventdata,handles)
handles = guidata(hObject);  

sortDirectory(hObject,eventdata,handles); %Sort in ascending order of instance number
handles = guidata(hObject);  

topimage = dicomread(strcat(handles.folder,filesep,handles.d(1,:)));
metadata = dicominfo(strcat(handles.folder,filesep,handles.d(1,:)));


[group1, element1] = dicomlookup('PixelSpacing');
[group2, element2] = dicomlookup('SliceThickness');
resolution = metadata.(dicomlookup(group1, element1));
handles.xthickness = resolution(1); 
handles.ythickness = resolution(2);
handles.zthickness = metadata.(dicomlookup(group2, element2));
guidata(hObject,handles); %update
handles = guidata(hObject); 
handles.threedarray = zeros(size(topimage,1),size(topimage,2),size(handles.d,1));
handles.threedarray(:,:,1) = topimage;

for i = 2:size(handles.d,1)
   handles.threedarray(:,:,i) = dicomread(strcat(handles.folder,filesep,handles.d(i,:))); 
end
set(handles.add_button,'Enable', 'on');
set(handles.pushbutton6,'Enable', 'on');
guidata(hObject,handles); %update





function sortDirectory(hObject,eventdata,handles)
handles = guidata(hObject);  
dtemp = ls(strcat(handles.folder,'\*.dcm'));

m = size(dtemp,1);

[group, element] = dicomlookup('InstanceNumber');
sdata(m) = struct('imagename','','instance',0);

for i = 1:m
    metadata = dicominfo(strcat(handles.folder,filesep,dtemp(i,:)));
    position = metadata.(dicomlookup(group, element));
    sdata(i) = struct('imagename',dtemp(i,:),'instance',position);
end

[~, order] = sort([sdata(:).instance],'ascend');
sorted = sdata(order).';

for i = 1:m
    handles.d(i,:) = sorted(i).imagename;
end


guidata(hObject,handles); %update


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
set(hObject, 'max', handles.R);

handles.z = round(get(hObject,'Value'));
set(handles.textR,'string',strcat(num2str(handles.z),'/',num2str(handles.R)));
dispAxial(hObject, eventdata,handles);  % z R
guidata(hObject,handles); %update

function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
set(hObject, 'max', handles.Q);
handles.y = round(get(hObject,'Value'));
set(handles.textQ,'string',strcat(num2str(handles.y),'/',num2str(handles.Q)));
dispSagittal(hObject, eventdata,handles);  % y Q
guidata(hObject,handles); %update

function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
handles = guidata(hObject);
set(hObject, 'max', handles.P);
handles.x = round(get(hObject,'Value'));
set(handles.textP,'string',strcat(num2str(handles.x),'/',num2str(handles.P)));
dispCoronal(hObject, eventdata,handles);  % x P
guidata(hObject,handles); %update

function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
%% DO ENHANCE




% --- Executes on button press in update_button.
function update_button_Callback(hObject, eventdata, handles)
preprocess(hObject, eventdata, handles)

function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox1


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in add_button.
function add_button_Callback(hObject, eventdata, handles)
handles = guidata(hObject);   

popup_sel_index = get(handles.popupmenu1, 'Value');% 1 2 3 4 5 6
contents = get(handles.popupmenu1,'String'); 

switch popup_sel_index
   
    case 1
        handles.enhance_list{end+1}='Histogram Equalization'; 
    case 2
        handles.enhance_list{end+1} = 'Adaptive Histogram Equalization';
    case 3
        handles.enhance_list{end+1}='Laplacian';
    case 4
        handles.enhance_list{end+1}='Robert';    
    case 5
        handles.enhance_list{end+1}='Sobel';
    case 6
        handles.enhance_list{end+1}='Moving Average';    
    case 7
        handles.enhance_list{end+1}=strcat('Power',' c = ',get(handles.editc,'String'),' gamma = ',get(handles.editgamma,'String'));               
end
set(handles.listbox1, 'String', handles.enhance_list);
guidata(hObject,handles); %update



function im=do_enhance(hObject, eventdata, handles,im)
handles = guidata(hObject);   

for i = 1:numel(handles.enhance_list)
    if strcmp(handles.enhance_list{i},'Histogram Equalization')
        im = histeq(im);
    elseif strcmp(handles.enhance_list{i},'Adaptive Histogram Equalization')    
        im = adapthisteq(im);
        
    elseif strcmp(handles.enhance_list{i},'Laplacian')
        im = imfilter(im,[0 -1 0;-1 5 -1;0 -1 0]);
        
    elseif strcmp(handles.enhance_list{i},'Robert')
        rob_gx = imfilter(im,[-1 0;0 1]);
        rob_gy = imfilter(im,[0 -1;1 0]);
        im = sqrt(rob_gx.^2+rob_gy.^2);
    
    elseif strcmp(handles.enhance_list{i},'Sobel')
        rob_gx = imfilter(im,[-1 -2 -1;0 0 0;1 2 1]);
        rob_gy = imfilter(im,[-1 0 1;-2 0 2;-1 0 1]);
        im = sqrt(rob_gx.^2+rob_gy.^2);
   
    elseif strcmp(handles.enhance_list{i},'Moving Average')
        kernel = (1/9)*[1 1 1;1 1 1;1 1 1];
        im = imfilter(im,kernel);
    
      
    elseif strncmpi(handles.enhance_list{i},'Power',5)
        c = str2num(get(handles.editc,'String')); 
        gamma = str2num(get(handles.editgamma,'String'));
        if isempty(c)
            c = 1;
        elseif isempty(gamma)
            gamma = 1 ; 
       
        end
        im = c*(im).^gamma;
        
        
        
        
        
    end
   
    
end
guidata(hObject,handles); %update

function pushbutton6_Callback(hObject, eventdata, handles)
handles = guidata(hObject);   
handles.enhance_list={};

set(handles.listbox1, 'String', handles.enhance_list);
set(handles.listbox1,'Value',1);
guidata(hObject,handles); %update



function editc_Callback(hObject, eventdata, handles)
% hObject    handle to editc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editc as text
%        str2double(get(hObject,'String')) returns contents of editc as a double


% --- Executes during object creation, after setting all properties.
function editc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editgamma_Callback(hObject, eventdata, handles)
% hObject    handle to editgamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editgamma as text
%        str2double(get(hObject,'String')) returns contents of editgamma as a double


% --- Executes during object creation, after setting all properties.
function editgamma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editgamma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
