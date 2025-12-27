function varargout = ICA_GUI(varargin)
% ICA_GUI MATLAB code for ICA_GUI.fig
%      ICA_GUI, by itself, creates a new ICA_GUI or raises the existing
%      singleton*.
%
%      H = ICA_GUI returns the handle to a new ICA_GUI or the handle to
%      the existing singleton*.
%
%      ICA_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ICA_GUI.M with the given input arguments.
%
%      ICA_GUI('Property','Value',...) creates a new ICA_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ICA_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ICA_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ICA_GUI

% Last Modified by GUIDE v2.5 01-May-2017 14:52:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ICA_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ICA_GUI_OutputFcn, ...
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

function ICA_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to ICA_GUI (see VARARGIN)

    % get Varargin
    p = inputParser;
    p.addRequired('EEG');
    p.addParamValue('channelsOfInterest', [1]);
    
    p.parse(varargin{:});
    
    handles.EEG = p.Results.EEG;
    
    % some initial values and variables
    handles.whatToPlot = 'eegsignal';
    handles.spaceBeetweenChannels = 50;
    handles.xLim = [0 10];
    handles.channelsToPlot = 1:handles.EEG.nbchan;
    handles.channelsToPlot = handles.channelsToPlot(end:-1:1);
    chanLabels = {handles.EEG.chanlocs.labels};
    chanLabels = chanLabels(end:-1:1);
    handles.channelsOfInterest = find(ismember(chanLabels, p.Results.channelsOfInterest));
    handles.originalSignalPlotColor = [0.9 0.4 0.4];
    handles.originalSignalPlotColorColorOfInterest = [1 0 0];
    handles.originalSignalPlotWidth = 1;
    
    handles.compsRemovedPlotColor = [0.5 0.5 0.5];
    handles.compsRemovedPlotColorColorOfInterest = [0 0 0];
    handles.compsRemovedPlotWidth = 1;
    
    handles.color = [0, 0, 1];
    handles.dataWithCompsRemoved = handles.EEG.data;
    handles.SourceActivity = handles.EEG.icaactivations;
    
    % Update listbox with components
    [componentsToRemove] = fillComponentsListbox(handles);
    handles.componentsToRemove=componentsToRemove;
    
    % Choose default command line output for ICA_GUI
    handles.output = hObject;

    % Prepare axes
    if length(size(handles.EEG.data)) == 3
        handles.isEpoched = 1;
    else
        handles.isEpoched = 0;
    end
    
    [xtickPositions, ytickPositions_eeg, yLabels_eeg, ytickPositions_ica, yLabels_ica] = createFigureToPlotSignal(handles, handles.isEpoched);
    handles.xtickPositions=xtickPositions;
    handles.ytickPositions_eeg=ytickPositions_eeg;
    handles.ytickPositions_ica=ytickPositions_ica;
    handles.yLabels_eeg=yLabels_eeg;
    handles.yLabels_ica=yLabels_ica;
    updateFigureToPlotSignal(handles, handles.isEpoched)
        
    % Update handles structure
    guidata(hObject, handles); 
    
    % UIWAIT makes ICA_GUI wait for user response (see UIRESUME)
    uiwait(handles.figure1);


function varargout = ICA_GUI_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.EEG;
    delete(handles.figure1);
function components_listbox_Callback(hObject, eventdata, handles)
    entryNumber = get(hObject, 'Value');
    contents = cellstr(get(hObject,'String'));
    newText = contents{entryNumber};
    
     c = round([0.8,0.8,0.8]*255);
     colorHex =sprintf('%s%s%s', dec2hex(c(1),2), dec2hex(c(2),2), dec2hex(c(3),2));
     
     % add component
     if handles.componentsToRemove(entryNumber)
        handles.SourceActivity(entryNumber, :)  = handles.EEG.icaactivations(entryNumber, :);
        handles.componentsToRemove(entryNumber) = 0;
        newColor = strrep(newText, '○', '●');% sprintf('● %s', newText);
     
     %remove component
     else
        handles.SourceActivity(entryNumber, :)  = 0;
        handles.componentsToRemove(entryNumber) = 1; 
        newColor = strrep(newText, '●', '○');
        %newColor = sprintf('○ %s', newText);
     end
     
    handles.dataWithCompsRemoved = pinv(handles.EEG.icaweights) * handles.SourceActivity;
          
    updateFigureToPlotSignal(handles, handles.isEpoched)
    
    contents{entryNumber} = newColor;
    set(hObject, 'String',contents);
    guidata(hObject, handles); 

function components_listbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to components_listbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

function xLimleft_pushbutton_Callback(hObject, eventdata, handles)
    step = diff(handles.xLim)-1;
    if handles.xLim(1) > step
       handles.xLim = handles.xLim-step;
    elseif handles.xLim(1) <= step
       handles.xLim(1) = 0;
       handles.xLim(2) = step+1;
    end
    guidata(hObject, handles);
    updateFigureToPlotSignal(handles, handles.isEpoched)    
function xLimright_pushbutton_Callback(hObject, eventdata, handles)
    step = diff(handles.xLim)-1;
    signalMaxLen = size(handles.EEG.data, 2)/handles.EEG.srate;
    if handles.xLim(2)+step <= signalMaxLen
       handles.xLim = handles.xLim+step;
    end
    guidata(hObject, handles);
    updateFigureToPlotSignal(handles, handles.isEpoched)
function overlayOrig_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to overlayOrig_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of overlayOrig_checkbox
    handles.overlayOriginalData = get(hObject,'Value');
    updateFigureToPlotSignal(handles, handles.isEpoched)
    guidata(hObject, handles);
function OK_button_Callback(hObject, eventdata, handles)
    % hObject    handle to OK_button (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    handles.EEG.data = handles.dataWithCompsRemoved;
    guidata(hObject, handles);
    uiresume(handles.figure1);

function componentsToRemove=fillComponentsListbox(handles)
    comps = {};
    for i = 1:size(handles.EEG.icaweights,1)
        comps{end+1} = sprintf('● C %g', i);
    end  
    set(handles.components_listbox, 'String', comps)
    componentsToRemove=zeros(1, length(comps));

    % Store the clean labels for later use in the toggle
    handles.cleanLabels = comps; 
    guidata(handles.figure1, handles);

function [xtickPositions, ytickPositions_eeg, yLabels_eeg, ytickPositions_ica, yLabels_ica] = createFigureToPlotSignal(handles, isEpoched)
%     axes(handles.axes);
    
%% Yticks positions and labels for EEG display
    % setting up channels labels and y=ticks positions
    ytickPositions_eeg=zeros(1,length(handles.channelsToPlot));
    for i=1:length(handles.channelsToPlot)
        ytickPositions_eeg(i)=i*handles.spaceBeetweenChannels;
        %ylim([0, i*50+50])
%         xlim(handles.xLim*round(handles.EEG.srate));
    end
    yLabels_eeg = {handles.EEG.chanlocs.labels};
    yLabels_eeg = yLabels_eeg(end:-1:1);
    
    % if data is epoched xlabel refers to epoch. If not xlabel refers to secs
    if isEpoched
        xtickPositions = 0 : size(handles.EEG.data, 2) : size(handles.EEG.data, 2)*(xLim(2)*Fs/size(handles.EEG.data, 2));            
        xLabels = repmat({'trial'}, size(xtickPositions, 2));           
    else
        xLabels = handles.xLim(1):handles.xLim(2);
        xtickPositions = linspace(0, 1, length(xLabels)); % 1:handles.EEG.srate:(handles.xLim(2)+1)*handles.EEG.srate;
    end
    
%% Yticks positions and labels for ICA comps display     
    % setting up components labels and y=ticks positions
    ytickPositions_ica=zeros(1,size(handles.EEG.icaweights, 1));
    yLabels_ica = {};
    for i=1:size(handles.EEG.icaweights, 1)
        ytickPositions_ica(i)=i*handles.spaceBeetweenChannels;
        yLabels_ica{i} = sprintf('C %g', i);
    end
    yLabels_ica = yLabels_ica(end:-1:1);
    % if data is epoched xlabel refers to epoch. If not xlabel refers to secs
    if isEpoched
        xtickPositions = 0 : size(handles.EEG.icaactivations, 2) : size(handles.EEG.icaactivations, 2)*(xLim(2)*Fs/size(handles.EEG.icaactivations, 2));            
        xLabels = repmat({'trial'}, size(xtickPositions, 2));           
    else
        xLabels = handles.xLim(1):handles.xLim(2);
        xtickPositions = linspace(0, 1, length(xLabels)); % 1:handles.EEG.srate:(handles.xLim(2)+1)*handles.EEG.srate;
    end

%% Xticks positions (common for EEG and ICA display)
    % display vertical lines on the plot:
    for j= 1 : size(xtickPositions, 2)
        line([xtickPositions(j) xtickPositions(j)], [1 j*handles.spaceBeetweenChannels+handles.spaceBeetweenChannels], 'LineStyle', '--', 'Color', [0 0 0])
    end
    
    set(gca,'yTick', ytickPositions_eeg, 'yTickLabel', yLabels_eeg);
    set(gca,'Ydir', 'reverse');
    set(gca,'xTick', xtickPositions, 'xTickLabel', xLabels);
    ylim([0 handles.spaceBeetweenChannels *length(handles.channelsOfInterest)])    
function updateFigureToPlotSignal(handles, isEpoched)
        cla
          if ~isEpoched
            xLabels = handles.xLim(1):handles.xLim(2);
          end
        
    %% ==== plot EEG signals ====
    if isequal(handles.whatToPlot, 'eegsignal')
        % plot original data
        if get(handles.overlayOrig_checkbox, 'Value')
        for i=1:length(handles.channelsToPlot)
            toPlot = handles.EEG.data(handles.channelsToPlot(i), handles.xLim(1)*round(handles.EEG.srate)+1:handles.xLim(2)*round(handles.EEG.srate))+i*handles.spaceBeetweenChannels ;
            if ismember(i, handles.channelsOfInterest)
                plot(linspace(0, 1, length(toPlot)),toPlot, 'color', handles.originalSignalPlotColorColorOfInterest,'LineWidth', handles.originalSignalPlotWidth+1)
            else
                plot(linspace(0, 1, length(toPlot)),toPlot, 'color', handles.originalSignalPlotColor,'LineWidth', handles.originalSignalPlotWidth)
            end
            hold on;       
        end
        end

        % plot data after components removed
        for i=1:length(handles.channelsToPlot)
            toPlot = handles.dataWithCompsRemoved(handles.channelsToPlot(i), handles.xLim(1)*round(handles.EEG.srate)+1:handles.xLim(2)*round(handles.EEG.srate))+i*handles.spaceBeetweenChannels ;
            if ismember(i, handles.channelsOfInterest)
                plot(linspace(0, 1, length(toPlot)),toPlot, 'color', handles.compsRemovedPlotColorColorOfInterest,'LineWidth', handles.compsRemovedPlotWidth+1)
            else
                plot(linspace(0, 1, length(toPlot)),toPlot, 'color', handles.compsRemovedPlotColor,'LineWidth', handles.compsRemovedPlotWidth)
            end
            hold on;       
        end
%         display vertical lines on the plot:
        for j= 1 : size(handles.xtickPositions, 2)
            line([handles.xtickPositions(j) handles.xtickPositions(j)], [1 length(handles.channelsToPlot)*handles.spaceBeetweenChannels+handles.spaceBeetweenChannels ], 'LineStyle', '--', 'Color', [0 0 0])
        end 
        set(gca,'xTick', handles.xtickPositions, 'xTickLabel', xLabels);
        set(gca,'yTick', handles.ytickPositions_eeg, 'yTickLabel', handles.yLabels_eeg);
        ylim([-handles.spaceBeetweenChannels, handles.spaceBeetweenChannels+handles.spaceBeetweenChannels*length(handles.channelsToPlot)])

        
    %% ==== plot ICA components ====
    elseif isequal(handles.whatToPlot, 'icacomps');
        for i=1:size(handles.EEG.icaweights,1)
            toPlot = handles.EEG.icaactivations(1+size(handles.EEG.icaweights,1)-i, handles.xLim(1)*round(handles.EEG.srate)+1:handles.xLim(2)*round(handles.EEG.srate));
            % normalize component amplitude, for better display
%             toPlot = (toPlot/(std(toPlot)*0.08))+i*handles.spaceBeetweenChannels
            toPlot = (i*0.02*toPlot/(std(toPlot)*0.08))+i*handles.spaceBeetweenChannels;
            plot(linspace(0, 1, length(toPlot)),toPlot, 'color', [0.2 0.2 0.5],'LineWidth', handles.originalSignalPlotWidth)
            hold on; 
        end
        % display vertical lines on the plot:
        for j= 1 : size(handles.xtickPositions, 2)
            line([handles.xtickPositions(j) handles.xtickPositions(j)], [1 size(handles.EEG.icaweights,1)*handles.spaceBeetweenChannels+handles.spaceBeetweenChannels], 'LineStyle', '--', 'Color', [0 0 0])
        end 
        set(gca,'xTick', handles.xtickPositions, 'xTickLabel', xLabels);
        set(gca,'yTick', handles.ytickPositions_ica, 'yTickLabel', handles.yLabels_ica);
        ylim([-handles.spaceBeetweenChannels,handles.spaceBeetweenChannels+handles.spaceBeetweenChannels*size(handles.EEG.icaweights, 1)])
 
    end
        
      


function plotEEG_togglebutton_Callback(hObject, eventdata, handles)
    if get(hObject,'Value')
        set(handles.plotComps_togglebutton, 'Value', 0);
        handles.whatToPlot = 'eegsignal';
    end
    updateFigureToPlotSignal(handles, handles.isEpoched)
    guidata(hObject, handles); 
function plotComps_togglebutton_Callback(hObject, eventdata, handles)
    if get(hObject,'Value')
        set(handles.plotEEG_togglebutton, 'Value', 0);
        handles.whatToPlot = 'icacomps';
    end
    updateFigureToPlotSignal(handles, handles.isEpoched)
    guidata(hObject, handles);    

    
    
    
    
