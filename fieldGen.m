% Class for calculation spatial distribution of physical values and save it
% as a ovf files for OOMMF or muMax
classdef fieldGen < hgsetget
    properties
        xmin = 0
        ymin = 0
        zmin = 0
        xmax = 0
        ymax = 0
        zmax = 0
        valuedim = 3
        valuelabels = 'm_full_x m_full_y m_full_z'
        valueunits =  'A/m A/m A/m'
        Desc = 'Total simulation time:  0  s'
        xbase = 5.475e-07
        ybase =  1.25e-07
        zbase = 1.25e-07
        
        xnodes = 4096
        ynodes = 8
        znodes = 32
        
        xstepsize = 1.5e-06
        ystepsize = 2.5e-07
        zstepsize = 2.5e-07
        fName = 'testGieldGen.ovf'
        
        % position of the strip line (in cells)
        xPos = 500
        zPos= 33
        I = 4e-6 % current in the stip line
        w = 40e-6% width of a strip line
        dataArr = 0
    end
    
    properties (Access = protected)
        writeList = {'xmin', 'ymin','zmin','xmax','ymax','zmax',...
             'valuedim','valuelabels','valueunits','Desc','xbase',...
             'ybase','zbase','xnodes','ynodes','znodes','xstepsize',...
             'ystepsize','zstepsize'};
    end
    
    methods
         
        % constructor
        function obj = fieldGen()
            obj.dataArr = rand(obj.xnodes,obj.ynodes,obj.znodes,obj.valuedim);
        end
        
        function writeFile(obj)
            obj.calcMagneticField();
            obj.writeHeader();
            obj.writeData();
        end    
        
        function calcMagneticField(obj)
            I = 4e-6;
            c = 1;
            
            obj.dataArr = zeros(obj.xnodes,obj.ynodes,obj.znodes,obj.valuedim);
            for xInd = 1:obj.xnodes
                dx = (xInd - obj.xPos)*obj.xstepsize;
                for zInd = 1:obj.znodes
                    dz = (zInd - obj.zPos)*obj.zstepsize;
                    c = 4*pi/1e7;
                    I = 1e2;
                    obj.dataArr(xInd,:,zInd,3) = c*I*log(((0.5*obj.w-dx)^2+dz^2)/(0.5*obj.w+dx)^2+dz^2)/(2*pi);
                    obj.dataArr(xInd,:,zInd,1) = c*I*(atan((obj.w+2*dx)/(2*dz))+atan((obj.w-2*dx)/(2*dz)))/pi;
                end    
            end
            
            if true
            figure(1);
            imagesc(squeeze(obj.dataArr(:,1,:,1)).'/1e-4);
            axis xy; title('Hx'); colorbar();

            figure(2);
            imagesc(squeeze(obj.dataArr(:,1,:,3)).'/1e-4);
            axis xy; title('Hz'); colorbar();
            end
        end    
         
    end
    
    methods (Access = protected)
        
        function writeHeader(obj)
            try
                [fid,errMsg] = fopen(obj.fName,'w');
                str =   sprintf(['# OOMMF OVF 2.0 \n',...
                        '# Segment count: 1 \n',...
                        '# Begin: Segment \n',...
                        '# Begin: Header \n',...
                        '# Title: m_full \n',...
                        '# meshtype: rectangular \n',...
                        '# meshunit: m \n']);
                fprintf(fid,str);
                
                for ind = 1:size(obj.writeList,2)
                    parName = obj.writeList{ind};
                    parVal = obj.get(parName);
                    if isnumeric(parVal)
                        parVal = num2str(parVal);
                    end    
                    fprintf(fid,sprintf(['# ',parName,': ',parVal,' \n']));
                end
                fprintf(fid,sprintf('# End: Header \n# Begin: Data Binary 4 \n'));
                
                fclose(fid);
            catch err
                fclose(fid);
                disp(err.message);
            end
        end
        
        function writeData(obj)
            data =[];
            for zInd = 1:obj.znodes
                for yInd = 1:obj.ynodes
                    for xInd = 1:obj.xnodes
                        for projInd = 1:obj.valuedim
                            data = [data obj.dataArr(xInd,yInd,zInd,projInd)];
                            %disp([num2str(xInd) ' ' num2str(yInd) ' ' num2str(zInd)])
                        end
                    end
                end
            end
            
            try
                [fid,errMsg] = fopen(obj.fName,'a+');
                fwrite(fid, single(1234567), 'single', 0, 'ieee-le');
                fwrite(fid, data, 'single', 0, 'ieee-le');                
                fprintf(fid,sprintf('# End: Data Binary 4\n # End: Segment \n'));
                fclose(fid);
            catch err
                fclose(fid);
                disp(err.message);
            end
        end
        
    end
end    