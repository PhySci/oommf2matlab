% Class for processing results of OOMMF simulations 
classdef OOMMF_odt < hgsetget % subclass hgsetget
 
 properties
   fName = 'transducerCW.odt'
   columnName
   units
 end
 
 methods
   function parse(obj)
     fid = fopen(obj.fName);
     if ((fid == -1))
       disp('File not found');
       return;
     end
     
     [IOmess, errnum] = ferror(fid);
     if (errnum ~= 0)
       disp(IOmess);
       return;
     end
     
     % check format
     line = fgetl(fid);
     
     if (~strcmp(line,'# ODT 1.0'))
       disp('Unknown format');
       return; 
     end    
     
     fgetl(fid);
     fgetl(fid);
     
     % parse column names
     columnsLine = fgetl(fid);
     
     
     while (~feof(fid))
       fgetl(fid)  
     end    
     
   end      
 end
end