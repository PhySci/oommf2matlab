function substractBack
    sim = OOMMF_sim;
    sim.fName = fullfile(pwd,'static.stc');
    [Mx,My,Mz] = sim.loadMagnetisation;
    
    MFile = matfile(fullfile(pwd,'Mx.mat'));
    MFile2 = matfile(fullfile(pwd,'Mx2.mat'));
    M = MFile.Mx;
    for timeInd = 1:size(M,1)
        disp(timeInd);
        M(timeInd,:,:,:) = squeeze(M(timeInd,:,:,:)) - Mx; 
    end
    disp('Save Mx')
    MFile2.Mx = M; 
    
    MFile = matfile(fullfile(pwd,'My.mat'));
    MFile2 = matfile(fullfile(pwd,'My2.mat'));
    M = MFile.My;
    for timeInd = 1:size(M,1)
        disp(timeInd);
        M(timeInd,:,:,:) = squeeze(M(timeInd,:,:,:)) - My; 
    end
    disp('Save My')
    MFile2.My = M;
    
    MFile = matfile(fullfile(pwd,'Mz.mat'));
    MFile2 = matfile(fullfile(pwd,'Mz2.mat'));
    M = MFile.Mz;
    for timeInd = 1:size(M,1)
        disp(timeInd);
        M(timeInd,:,:,:) = squeeze(M(timeInd,:,:,:)) - Mz; 
    end
    disp('Save Mz')
    MFile2.Mz = M;
    
end