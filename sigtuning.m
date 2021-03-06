function [sigcurve,deltacurve,ci,pvalue,tuningcurves,shufdelta] = sigtuning(ratebylap,trialtype,iter,sigp)
%SIGTUNING - Find significant differences in tuning curves
%
%ratebylap - MxN matrix.  M trials of N bins, each containing a rate.
%trialtype - Mx1 vector. Categorical designations for each trial (currently
%           supports two trial types, but more are feasible)
%sigp - scalar. Proportional of the bootstrapped population that the true
%           values must exceed to be considered significant. Default: 0.95
%
%Output:
%sigcurve - binary. Portions of the tuning curves that are significantly
%           different
%deltacurve - Difference between the tuning curves
%ci - Confidence intervals around the differences of curves taken from
%           resampled trial combinations
%pvalue - p-values of likelihood of difference along the tuning curves
%tuningcurves - Tuning curves of each condition
%shufdelta - Full distribution of the differences of curves taken from
%           resampled trial combinations
%
%Jon Rueckemann 2015

%% Initialize 
    if nargin<4
        sigp=0.95;
    end
    
    nTrials = length(trialtype);
    nBins = size(ratebylap,2);
%% Develop tuning curves for left and right turns.
    tuningcurves=nan(2,nBins);
    for m=1:2
        tuningcurves(m,:)=nanmean(ratebylap(trialtype==m,:));
        %tuningcurves(m,:)=smooth(tuningcurves(m,:),5,'rlowess');
    end

    %Subtract left curve from right to see where they differ
    deltacurve=diff(tuningcurves);

%% Bootstrap significance: 
%   Resample curves after shuffling trial identities and subtract for each
%   iteration.
    shufdelta=nan(iter,nBins);
    
    %Permute trialtypes
    randtt = nan(nTrials,iter); 
    for x=1:iter
        randtt(:,x) = trialtype(randperm(nTrials));
    end
    
    for x=1:iter
        %Resample trials and calculate tuning curves
        randcurves=nan(2,size(ratebylap,2));
        for m=1:2
            randcurves(m,:)=nanmean(ratebylap(randtt(:,x)==m,:));
            %randcurves(m,:)=smooth(randcurves(m,:),5,'rlowess'); 
        end

        %Find difference in tuning for shuffled curves. White noise is
        %added to the signal to fix some screwy things that happen with
        %permuting discrete variables. 
        shufdelta(x,:)=diff(randcurves);
        whitenoise = 0.01*randn(1,nBins);
        shufdelta(x,:) = shufdelta(x,:)+whitenoise;
    end

%% Identify significance regions. 
    %Identify regions of the tuning curve that exceed the chance levels of the
    %shuffled population.
    shufdelta=sort(shufdelta);
    pvalue=sum(shufdelta>repmat(deltacurve,iter,1))./iter;
    negpvalue=1-pvalue;
    negdelta=deltacurve<0;
    pvalue(negdelta)=negpvalue(negdelta);   %Substitute p-value when sign reverses
    pvalue(deltacurve==0) = 1;              %Stem bins where there is no tuning curve difference are not considered. 
    sigcurve=pvalue<(1-sigp);

    %Create confidence intervals
    idxci=round([sigp;(1-sigp)].*iter);
    ci=shufdelta(idxci,:);
 end