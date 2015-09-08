function [history, success, num] = addSession(session, history, num)
    % $Id: addSession.m 1345 2010-03-09 03:11:25Z bkraus $
    
    if(nargin < 3); num = 0; end
    success = false;
    ratid = '';
    
    % Process history input
    if(nargin < 2 || isempty(history))
        history = loadHistory();
    elseif(ischar(history))
        history = loadHistory(history);
    end
    
    % Process session input
    if(isfield(session,'ratid') && isfield(session,'sessions'))
        ratid = session.ratid;
        session = session.sessions;
    end
    
    % Check that we have a history to work with.
    if(isempty(history))
        warndlg('Failed to load history file.','Add Session Failed');
        
    % Check that we have a session to work with.
    elseif(isempty(session))
        warndlg('Invalid session.','Add Session Failed');
        
    % Check that the history is valid.
    elseif(~isstruct(history) || ~isfield(history,'ratid'))
        warndlg('Invalid history file.','Add Session Failed');
        
    % If ratID was provided in session, then check that ratIDs match.
    elseif(~isempty(ratid) && ~strcmpi(history.ratid,ratid))
        warndlg('Rat IDs do not match','Add Session Failed');
        
    % If there are existing sessions in the history, then we must append to
    % existing sessions.
    elseif(isfield(history,'sessions'))
        % First check that the field names match.
        origfields = sort(fieldnames(history.sessions));
        sessionfields = sort(fieldnames(session));
        
        % Find what fields are present in session but not history (new
        % fields), or present in history but not session (missing fields).
        missingfields = ~isfield(session,origfields);
        newfields = ~isfield(history.sessions,sessionfields);
        keepnew = true;
        
        % Fail if there are fields in the history that aren't in the session
        if(sum(missingfields)>0)
            keepnew = false;
            warndlg(['New session is missing field(s): ' ...
                sprintf([repmat('''%s'', ',1,sum(missingfields)-1) '''%s''.'],...
                origfields{missingfields})],'Add Session Failed.');
        
        % If there are new fields in the session that aren't in the
        % history, ask the user what to do. If the users says no, then
        % cancel the addition, and return false.
        elseif(sum(newfields)>0)
            for j = find(newfields');
               if(keepnew)
                    button = questdlg(...
                        {sprintf('New field ''%s'' in session but not history.',sessionfields{j}),...
                         sprintf('Add field ''%s'' to history?',sessionfields{j})},'Adding session...',...
                         'Yes','No','Yes');
                    switch button
                        case {'Yes'}; history.sessions(1).(sessionfields{j}) = [];
                        otherwise; keepnew = false;
                    end
                end
            end
        end
        
        % If all the fields line up, or necessary adjustments were made,
        % then continue with the addition.
        if(keepnew)
            session = orderfields(session,history.sessions);
        
            % If more than a single session, append to end of history.
            if(length(session)>1)
                num = length(history.sessions)+1;
                history.sessions = [history.sessions session];
                
            % If just a single session, append to end, or replace existing
            % if a number is specified.
            else
                if(nargin < 3 || num == 0 || num > length(history.sessions))
                    num = length(history.sessions)+1;
                end
                history.sessions(num) = session;            
            end
            success = true;
        end
        
    % If there are no existing sessions in the history, then make this the
    % first session in the history.
    else
        num = 1;
        history.sessions(1) = session;
        success = true;
    end
end