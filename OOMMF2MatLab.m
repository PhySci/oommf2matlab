function res = OOMMF2MatLab(fname)
 %% open file and check errors 
 if (nargin == 0)
    disp('Enter the name of file');
    return;
 end    
 fid = fopen(fname);

 if (fid == -1)
     disp('File not found');
     return;
 end    
 
 [IOmess, errnum] = ferror(fid);
 if (errnum ~= 0)
   disp(IOmess);
   return;
 end
 
%% read file
 line = fgetl(fid); 
 while (isempty(strfind(line,'Begin: Data Binary')))   
  line = fgetl(fid);
  disp(line);
 end
 
 % determine file format
 format='';
 if (~isempty(strfind(line,'8')))
     format = 'double';
     testVal = 123456789012345.0;
 elseif (~isempty(strfind(line,'4')))
     format = 'single';
     testVal = 1234567.0;
 else
     disp('Unknown format');
     return
 end    
     
% read first test value
fTestVal = fread(fid, 1, format, 0, 'ieee-le');
if (fTestVal == testVal)
    disp('Correct format')
else
    disp('Wrong format');
    return;
end

data = fread(fid, 4400, format, 0, 'ieee-le');
 
 fclose(fid);
end