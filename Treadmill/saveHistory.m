function [success, history] = saveHistory(history, fullfilename)
    if(~isfield(history,'ratid'))
        warndlg('Invalid history file.','Save Failed');
        success = false;
        return
    end
    
    if(isfield(history,'settings') && isfield(history,'sessions'))
        if(~isfield(history.sessions,'settings') || ...
           isempty(history.sessions(end).settings))
            history.sessions(end).settings = history.settings;
        end
        history = rmfield(history,'settings');
    end
    
    if(nargin < 2)
        if(~isfield(history,'pathname') || isempty(history.pathname))
            pathname = uigetdir('','Select Directory for History File');
            if(pathname == 0)
                pathname = [pwd filesep];
            else
                pathname = [pathname filesep];
            end
            history.pathname = pathname;
        else
            pathname = history.pathname;
        end
        
        if(~isfield(history,'filename') || isempty(history.filename))
            filename = [lower(history.ratid) '.mat'];
            history.filename = filename;
        else
            filename = history.filename;
        end
        fullfilename = fullfile(pathname, filename);
    else
        [history.pathname, history.filename] = smartfileparts(fullfilename);
        if(isempty(history.filename))
            history.filename = [lower(history.ratid) '.mat'];
        end
        if(isempty(history.pathname))
            pathname = uigetdir('','Select Directory for History File');
            if(pathname == 0)
                pathname = [pwd filesep];
            else
                pathname = [pathname filesep];
            end
            history.pathname = pathname;
        end
        fullfilename = fullfile(history.pathname, history.filename);
    end
    
    if(exist([fullfilename '.back3'], 'file') == 2)
        try
            success = movefile([fullfilename '.back3'], [fullfilename '.back4']);
            if(~success);
                warndlg('Error backing up file 3.','Save Failed');
                success = false;
                return
            end
        catch
            warndlg('Error backing up file 3.','Save Failed');
            success = false;
            return
        end
    end

    if(exist([fullfilename '.back2'], 'file') == 2)
        try
            success = movefile([fullfilename '.back2'], [fullfilename '.back3']);
            if(~success);
                warndlg('Error backing up file 2.','Save Failed');
                return
            end
        catch
            warndlg('Error backing up file 2.','Save Failed');
            success = false;
            return
        end
    end
    
    if(exist([fullfilename '.back1'], 'file') == 2)
        try
            success = movefile([fullfilename '.back1'], [fullfilename '.back2']);
            if(~success);
                warndlg('Error backing up file 1.','Save Failed');
                return
            end
        catch
            warndlg('Error backing up file 1.','Save Failed');
            success = false;
            return
        end
    end
    
    if(exist(fullfilename, 'file') == 2)
        try
            success = movefile(fullfilename, [fullfilename '.back1']);
            if(~success);
                warndlg('Error backing up file.','Save Failed');
                return
            end
        catch
            warndlg('Error backing up file.','Save Failed');
            return
        end
    end
    
    if(exist(fullfilename,'file') == 7)
        warndlg('Destination appears to be a folder. Aborting.','Save Failed');
        success = false;
        return
    end

    if(exist(fullfilename,'file') == 2)
        warndlg('Refusing to overwrite existing file. Aborting.','Save Failed');
        success = false;
        return
    end
    
    %Save text file containing treadmill timestamps. 
    save(fullfile(pathname,['Treadmillts',date,'.mat']),'treadmillStartts','treadmillStopts'); 

    try
        disp(['Saving: ' fullfilename])
        save(fullfilename,'history');
        success = true;
    catch
        warndlg('Error saving file.','Save Failed');
        success = false;
        return
    end
end
