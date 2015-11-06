function [randmeans,FRyesterday,FRtoday] = getSplitterHistory(sessionStructs,sessionMap)
%[randmeans,FRyesterday,FRtoday] = getSplitterHistory(sessionStructs,sessionMap)
%
%   INPUTS
%       sessionStructs: MD entries. The SECOND entry is entry containing
%       splitters. The FIRST entry is the session for which you want to
%       examine firing rates. 
%
%       sessionMap: neuron_reg_batch output.
%
%   OUTPUTS
%       randmeans: nxB matrix (n=number of splitters, B=number of
%       iterations) containing the "firing rates" of randomly sample
%       neurons in the FIRST entry of sessionStruct. 
%
%       FRyesterday: n-element vector containing the number of calcium
%       events divided by the number of frames of neurons-to-be-splitters. 
%
%       FRtoday: "Firing rates" of splitters. 
%

%% Analysis. 
    currdir = pwd; 
    refPath = sessionStructs(2).Location; 
    yesterdayPath = sessionStructs(1).Location; 
    cd(refPath); 
    load('sigSplitters.mat','neuronID'); 
    
    %Get the previous day's activity. 
    [FRtoday,FRyesterday] = getPreviousFR(sessionStructs,neuronID,sessionMap);
    good = sum(~isnan(FRyesterday));    %Number of neurons that mapped to the previous day. 
    
    cd(yesterdayPath); 
    load('Pos_align.mat','FT'); 
    B = 1000;                       %Hard coded for 1000 iterations.
    randmeans = bootstrapFRs(FT,good,B);
    
%% ECDF. 
    figure; 
    ecdf(randmeans(:));
    hold on;
    ecdf(FRyesterday); 
        legend({'Bootstrap','Empirical'}); 
        xlabel('Calcium Events per Frame'); ylabel('Proportion');
        set(gca,'TickDir','out'); 
        
    [~,p] = kstest2(randmeans(:),FRyesterday); 
    
    disp(['KS test p = ',num2str(p)]); 
    
%% Raw histogram. 
    [~,edges] = histcounts(FRyesterday,50); 
    [emp,~] = hist(FRyesterday,edges);
    [boot,bins] = hist(randmeans(:),edges); 
    
    
    %Turn into proportions. 
    boot = boot./(good*B); 
    emp = emp./good;  
    
    figure;
    stairs(bins,boot); 
    hold on
    stairs(bins,emp);
        legend({'Bootstrap','Empirical'});
        xlabel('Calcium Events per Frame'); ylabel('Proportion'); 
        set(gca,'TickDir','out'); 
        
    cd(currdir); 
    
    keyboard; 
end