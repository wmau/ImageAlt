datefolders = dir;

for thisfolder=4:15
    cd(datefolders(thisfolder).name);
    
    sessionfolders = dir;
    
    for thisSession=3:length(sessionfolders)
        if sessionfolders(thisSession).isdir
            cd(sessionfolders(thisSession).name);
            
            tifs = dir('*.tif'); 
            nTifs = length(tifs);

            for thisTif=1:nTifs
                if ~strcmp(tifs(thisTif).name,'ICmovie_min_proj.tif')
                    try
                        imread(tifs(thisTif).name,5393);
                        disp([tifs(thisTif).name,' is good.']); 
                    catch
                        disp([tifs(thisTif).name,' IS BAD OR LAST CHUNK OF MOVIE.']);
                    end
                end
            end
            
            cd ..
        end
        
    end
    cd ..
end