function [history, fullfilename] = loadHistory(fullfilename)
% possible inputs:
% nargin == 0 : Prompt for instructions
% fullfilename = '' : Just create a new history, don't ask first.
% fullfilename = pathonly : Create a new history with specified path
% fullfilename = fileonly : Create a new history with specified filename
% fullfilename = fullfilename : Load history if exists, error otherwise

    if(nargin == 0)
        % If you call loadHistory with no input, then prompt for what to do.
        fullfilename = '';
        button = questdlg('Load existing history, or create new history?','Loading History...','New','Existing','Cancel','Existing');

        if(strcmp(button,'New'))
            % If you chose to create a new history, then default to blank
            % filename and pathname.
            filename = '';
            pathname = '';
        elseif(strcmp(button,'Existing'))
            % If you chose to load an existing history, then prompt for the
            % file to load.
            [filename,pathname] = uigetfile('*.mat');
            if(~strcmp(pathname(end),filesep))
                pathname = [pathname filesep];
            end
            if(filename == 0)
                % If no file was selected (pressed cancel), then return.
                history = [];
                return
            end
        else
            % The dialog box was closed without selecting a button.
            history = [];
            return
        end
    else
        if(isempty(fullfilename))
            % If you provided a blank filename, create a new history
            % without asking first.
            pathname = '';
            filename = '';
        else
            % If you provide some input, parse the provided filename.
            [pathname, filename] = smartfileparts(fullfilename);
        end
    end
    
    fullfilename = fullfile(pathname,filename);
    
    if(isempty(filename))
        history = newHistory(fullfilename);
        
        if(isempty(history))
            history = [];
            return
        end
        
        filename = history.filename;
    else
        try
            struct = load(fullfilename);
            history = struct.history;
        catch
            warndlg(['Loading history ' filename ' failed.'],'Load Failed');
            history = [];
            return
        end
        history.pathname = pathname;
        history.filename = filename;
    end

    if(~isfield(history,'ratid'))
        warndlg(['Invalid history file: ' filename '.'],'Load Failed');
        history = [];
        return
    end
    
    if(isfield(history,'pathname') && ~isempty(history.pathname))
        if(~strcmp(history.pathname(end),filesep))
            history.pathname = [history.pathname filesep];
        end
    end
    
    fullfilename = fullfile(history.pathname,history.filename);
end