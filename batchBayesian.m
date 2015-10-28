function [Mdl,pMap] = batchBayesian(sessionStruct)
%
%
%

%% 
    cd(sessionStruct.Location); 
    
    load('Pos_align.mat','FT','x_adj_cm','y_adj_cm');
    [Mdl,XBin,YBin] = BayesianDecode(x_adj_cm,y_adj_cm,FT);
    disp('Predicting');
    posterior = BayesianPredict(Mdl,FT);
    disp('Rearranging');
    pMap = flattenPosterior(posterior,XBin,YBin);
    
end