function textreport(history,n)
    addr = 'dmsalz@bu.edu';
    sheehanAddr ='dsheehan@bu.edu';
    mailSheehan= 0;

    
    ratid = history.ratid;
    
    if(nargin == 2)
        if(~isfield(history,'sessions') || n > length(history.sessions'));
            n = [];
        end
    else n = [];
    end
    
    if(isempty(n))
        msg = sprintf('%s, %s',ratid,datestr(now()));
        subject = 'Session Started';
    else
        when = datestr(history.sessions(n).date);
        laps = length(history.sessions(n).turns);
        minspeed= min(history.sessions(n).treadmill(:,3));
        maxspeed= max(history.sessions(n).treadmill(:,3));
        subject = 'Session Report';
        if(laps > 0)
            correct = sum(history.sessions(n).correct);
            time = history.sessions(n).laps(end)/60;
            percorrect = correct/laps*100;
            
            msg = sprintf('%s, %3d/%3d (%3.0f%%), [%d-%d],%5.2f min. %s\n',ratid,correct,laps,percorrect,minspeed,maxspeed,time,when);
        else
            msg = sprintf('%s, %s, %3d Laps at speeds: [%d-%d].\n',ratid,when,laps, minspeed, maxspeed);
        end
        if(strcmp(ratid,'McFlurry')||strcmp(ratid,'McNabb'))
            sheehanMsg = sprintf('%s finished at %s, running %3d Laps at speeds: [%d-%d]\n',ratid,when,laps, minspeed,maxspeed);
            mailSheehan= 1;
        end
    end
    props = java.lang.System.getProperties;
    props.setProperty('mail.smtp.auth','true');
    props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
    props.setProperty('mail.smtp.socketFactory.port','465');
    sendmail(addr,subject,msg);
    if (mailSheehan)
        sendmail(sheehanAddr,'all done',sheehanMsg);
    end
end