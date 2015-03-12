omf = OOMMF_result;

path = 'C:\Micromagnet\OOMMF\proj\Transducer APL\Carl_simulations_20150306\1d_pbc\cw_5.7GHz';
% omf.scanMFolder(path,'','saveObj',true,'savePath',strcat(path,'\obj\'));
res = collectSliceData(path,...
                 1:200,... % X range
                 20:61,... % Y range
                 1:10,...   % Z range
                 'save',true,...
                 'savePath',strcat(path,'\..\'));
%res = permute(res,[2 1 3 4 5]);
plotImgBat(strcat(path,'\obj'));             

path = 'C:\Micromagnet\OOMMF\proj\Transducer APL\Carl_simulations_20150306\1d_pbc\cw_5.9GHz';
%omf.scanMFolder(path,'','saveObj',true,'savePath',strcat(path,'\obj\'));
%res = collectSliceData(strcat(path,'\obj\'),...
%                 1:200,... % X range
%                 21:60,... % Y range
%                 1:10,...   % Z range
%                 'save',true,...
%                 'savePath',strcat(path,'\..\'));
%res = permute(res,[2 1 3 4 5]);
plotImgBat(strcat(path,'\obj'));              
