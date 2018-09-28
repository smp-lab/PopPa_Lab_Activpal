% PopPA Lab Activity Tracker Analysis Program 
% Created by: Anthony Chen, PhD Student 
% Start Date: July 4th, 2018
% Associated Objs 
    % journal_data.m
    % AP_data.m
    
function varargout = PoPA_Lab_Activ_Program(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PoPA_Lab_Activ_Program_OpeningFcn, ...
                   'gui_OutputFcn',  @PoPA_Lab_Activ_Program_OutputFcn, ...
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

% --- Executes just before PoPA_Lab_Activ_Program is made visible.
function PoPA_Lab_Activ_Program_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject; guidata(hObject, handles);

try 
    J_obj = journal_data; % Get Journal Data Object
    
    [j_header_format, ~] = J_obj.j_initialize; % Run Journal Table Header Method
    
    % Journal Header Bootup File determine the number of headers per day
    % when reading journal file
      
    % Set Journal Table Header
    set(handles.journal_table, 'ColumnName', j_header_format{1}); 
    set(handles.journal_table, 'ColumnWidth', num2cell(zeros(1,length(j_header_format{1}))+150));
    
    % Set Default Journal Table Data
    handles.journal_data.default = cell(100,length(j_header_format{1})); guidata(hObject, handles); 
    handles.journal_data.memory = cell(100,length(j_header_format{1})); guidata(hObject, handles); 
    set(handles.journal_table, 'Data', handles.journal_data.default, 'ColumnEditable', false); 
    
    % Initialize Activpal Data 
    handles.activpal_data.working = cell(25, 7); guidata(hObject, handles); 
    handles.activpal_data.memory = cell(25, 7); guidata(hObject, handles); 
    
    % Print Log Event 
    master_logstr{2} = horzcat('[',datestr(datetime),']: Created by Anthony Chen');
    master_logstr{1} = horzcat('[',datestr(datetime),']: Initialized Activpal Analysis Program');
    set(handles.log_box, 'String', master_logstr, 'Min', 0, 'Max', 2, 'Value', []);
    
catch ME
    errordlg(ME.message, 'Error Alert');
    set(handles.activpal_import, 'Enable', 'off');  
    set(handles.journal_table, 'Enable', 'off');
end 

% --- Executes on button press in import_journal button.
function import_journal_Callback(hObject, eventdata, handles)
try
    
    AP_data.delete_activpal_plots(handles)
    
    J_obj = journal_data; % Get Journal Data Object
    [~, journal_header_count] = J_obj.j_initialize; % Run Journal Table Header Method
    [Column_Head, Column_Width, table_data, column_count, duration, logstr] = J_obj.import_j_func(journal_header_count);
    
    % Print Journal Data to Journal Table 
    set(handles.journal_table, 'ColumnName', Column_Head);
    set(handles.journal_table, 'ColumnWidth', Column_Width);
    set(handles.journal_table, 'Data', table_data);
    
    % Save Journal Data to Memory 
    handles.journal_data.memory =  table_data; guidata(hObject, handles);
    handles.journal_data.column_count = column_count; guidata(hObject, handles);
    handles.journal_data.expDuration= duration ; guidata(hObject, handles); 
    
    % Enable Activpal Button 
    handles.activpal_import.Enable = 'on';     
    
    % Print Log Event 
    logMessage.GenerateLogMessage(handles.log_box, logstr) 

catch ME
    errordlg(ME.message, 'Error Alert');
end 

% --- Outputs from this function are returned to the command line.
function varargout = PoPA_Lab_Activ_Program_OutputFcn(~, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in activpal_import button.
function activpal_import_Callback(hObject, eventdata, handles)
try
    % Create instance of Class AP_data 
    AP_obj = AP_data; 
    
    % Run Import Activpal Function    
    [activpal_imported_data_datevec, activpal_imported_data, AP_metadata, AP_subjectID, AP_datelist] = AP_obj.import_activpal_func;
    
    
    % Save Activpal Subject ID in Memory
    handles.subject_id = AP_subjectID; guidata(hObject, handles);
    
    % Save Activpal Data in Memory
    handles.activpal_data.working = {activpal_imported_data_datevec, activpal_imported_data}; guidata(hObject, handles);
    handles.activpal_data.memory = {activpal_imported_data_datevec, activpal_imported_data}; guidata(hObject, handles);
    
    % Print Selected Activpal Metadata in GUI
    set(handles.AP_file_name,'String',AP_metadata, 'FontSize', 8.5);
    
    % Find Journal Column from Activpal Metadata
    start_date = handles.journal_data.memory{strcmp(cellstr(num2str(AP_subjectID)), handles.journal_data.memory(:,1)), 3};
    
    % Set Datelist for Dropdown Menu Control 
    [~, k] = min(abs(datenum(AP_datelist) - datenum(start_date)));
    set(handles.ID_list, 'Enable', 'on', 'String', AP_datelist, 'Value', k); 
    
    % Parse Activpal Date Based on Time Frame
    [parsed_data, logstr] = AP_data.parse_activpal_data(handles.activpal_data.memory, start_date);
    
    % Plot Hourly Plots
    AP_obj.gen_subplot_coordinates(handles, parsed_data, start_date)
    
    % Set Journal List Command & Undo Check
    set(handles.journal_command, 'Enable', 'on', 'String', AP_obj.activpal_action_list{1}); 
    
    % Enable Journal Table for Interaction
    handles.journal_table.Enable = 'on'; 
    
    % Enable Work Start/End Boxes for Interaction
    handles.WorkStartInput.Enable = 'on'; 
    handles.WorkEndInput.Enable = 'on'; 
    
    % Print Log Event 
    logMessage.GenerateLogMessage(handles.log_box, logstr) 
    
catch ME
     errordlg(ME.message, 'Error Alert');
end 

% --- Executes on selection change in ID_list.
function ID_list_Callback(hObject, eventdata, handles)
try
    % Find Journal Column from Activpal Metadata
    start_date = hObject.String(get(hObject,'Value'),:); 
    
    % Parse Activpal Date Based on Time Frame
    [parsed_data, logstr] = AP_data.parse_activpal_data(handles.activpal_data.memory, start_date);
        
    % Create instance of Class AP_data
    AP_obj = AP_data;
    
    % Run Plot Activpal Function
    AP_obj.gen_subplot_coordinates(handles, parsed_data, start_date)
    
    % Print Log Event 
    logMessage.GenerateLogMessage(handles.log_box, logstr) 
    
catch ME
    errordlg(ME.message, 'Error Alert');
end

% --- Executes when selected cell(s) is changed in journal_table.
function journal_table_CellSelectionCallback(hObject, eventdata, handles)
try
    str = hObject.Data{eventdata.Indices(1,1), eventdata.Indices(1,2)};
    if size(eventdata.Indices,1) == 1 ...
            && ~isempty(regexp(str, '\d{1,2}:\d{2,}', 'once'))...
            && strcmp(num2str(handles.subject_id), hObject.Data{eventdata.Indices(1)}) == 1
        
        handles.journal_data.cell_selection = eventdata.Indices; guidata(hObject, handles);
        
        % Make Action Panel Indicator Visible
        handles.action_panel_indicator.Enable = 'on';
        handles.action_panel_indicator.ForegroundColor = [0.3 1 0.2]; 
        
    else
        handles.action_panel_indicator.ForegroundColor = [1 0 0]; 
    end
        
catch ME
    errordlg(ME.message, 'Error Alert');
end


% --- Executes on selection change in journal_command.
function journal_command_Callback(hObject, eventdata, handles)

J_obj = journal_data; % Get Journal Data Object
AP_obj = AP_data;
try
    if isfield(handles.journal_data, 'cell_selection')
        listselection = hObject.Value;
        j_data = handles.journal_data.memory;
        j_selection = handles.journal_data.cell_selection;
        RecordingDuration = handles.journal_data.expDuration;
        
        
        time_selected = j_data{j_selection(1), j_selection(2)};
        
        [InsertDay, ~] = ...
            J_obj.find_day(...
            length(handles.journal_table.ColumnName)-5, ... % Non-fixed Journal Column #
            str2double(RecordingDuration),...               % # of Experimental Recording in Journal
            j_selection,...                                 % Selected Cell in J Table
            get(handles.journal_table), ...                 % Journal Table Struct
            handles.activpal_data.memory);                  % Activpal Data in Working Memory
        
        switch listselection
            case 1
                % Run Insert Function 
                [inserted_data, logstr] = AP_obj.insertToActivpalData(handles.activpal_data.working,...
                    time_selected,...
                    InsertDay);
                
                % Save Current Activpal State for Undo
                handles.activpal_data.working = handles.activpal_data.memory; guidata(hObject, handles);
                
                % Save Inserted Activpal Data to Memory
                handles.activpal_data.memory{1} = inserted_data{1};
                handles.activpal_data.memory{2} = inserted_data{2};
                guidata(hObject, handles);
                
                % Find Journal Column from Activpal Metadata
                start_date = handles.ID_list.String(get(handles.ID_list,'Value'),:);
                
                % Parse Activpal Date Based on Time Frame
                [parsed_data, logstr] = AP_data.parse_activpal_data(handles.activpal_data.memory, start_date);

                % Plot Hourly Plots
                AP_obj.gen_subplot_coordinates(handles, parsed_data, start_date);
                
                % Open Undo Option
                set(handles.journal_command, 'Enable', 'on', 'Value', length(AP_obj.activpal_action_list(:)), 'String', AP_obj.activpal_action_list(:));      
                
            case 2
                tempStart_time = datenum(handles.WorkStartInput.String);
                tempEnd_time = datenum(handles.WorkEndInput.String);
                              
                activpal_data = handles.activpal_data.memory;
   
                [total_time, Time_In_MET, sit_to_upright_transitions, prolonged_sitting] = AP_data.calculate_activpalData(activpal_data, tempStart_time, tempEnd_time); 
                
                L1 = horzcat('Total time spent in Sitting (', sprintf('%.2f', total_time(1)), ' mins), Standing (', sprintf('%.2f', total_time(2)), ' mins) and Stepping (', sprintf('%.2f', total_time(3)), ' mins)');
                L2 = horzcat('Total time spent in Light MET (', sprintf('%.2f', Time_In_MET(1)), ' mins), Moderate MET (', sprintf('%.2f', Time_In_MET(2)), ' mins) and Vigorous MET (', sprintf('%.2f', Time_In_MET(3)), ' mins)');
                L3 = horzcat('Number of Sit to Upright Transitions: ', sprintf('%.2f', sit_to_upright_transitions)); 
                L4 = horzcat('Total time spent in prolonged sitting: ', sprintf('%.2f', prolonged_sitting)); 

                % formatSpec = '%s\n%s\n%s\n%s\n';
                % fprintf(formatSpec, L1, L2, L3, L4);
                
                msg = cell(4,1);
                msg{1} = sprintf(L1);
                msg{2} = sprintf(L2);
                msg{3} = sprintf(L3);
                msg{4} = sprintf(L4);
                msb = msgbox(msg);
 
            case 3
                
                % Undo Inserted Activpal Data from Working Memory
                handles.activpal_data.memory = handles.activpal_data.working; guidata(hObject, handles); 
                
                % Find Journal Column from Activpal Metadata
                start_date = handles.ID_list.String(get(handles.ID_list,'Value'),:);
                
                % Parse Activpal Date Based on Time Frame
                [parsed_data, logstr] = AP_data.parse_activpal_data(handles.activpal_data.memory, start_date);

                % Plot Hourly Plots
                AP_obj.gen_subplot_coordinates(handles, parsed_data, start_date);
                
                set(handles.journal_command, 'Enable', 'on', 'Value', length(AP_obj.activpal_action_list(1:2)), 'String', AP_obj.activpal_action_list(1:2));
                
            otherwise
                
        end
    end
catch ME
    errordlg(ME.message, 'Error Alert');
end

% --- Executes during object creation, after setting all properties.
function journal_command_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
obj = journal_data;
set(hObject, 'String', obj.initialization_text); 


% --------------------------------------------------------------------
function journal_table_ButtonDownFcn(hObject, eventdata, handles)
function WorkStartInput_Callback(hObject, eventdata, handles)
function WorkStartInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function WorkEndInput_Callback(hObject, eventdata, handles)
function WorkEndInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function ID_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Wake/Sleep Detection 
% Marking Work/PW
% Exporting 
% Validity Idx 
% MET Segregation and Find time spent in those MET zones 






% --- Executes on selection change in log_box.
function log_box_Callback(hObject, eventdata, handles)
% hObject    handle to log_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns log_box contents as cell array
%        contents{get(hObject,'Value')} returns selected item from log_box


% --- Executes during object creation, after setting all properties.
function log_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to log_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
