function readHdf
    fName = '160304-focus-a.h5';
    
    xMin = h5readatt(fName,'/','Initial x');
    xMax = h5readatt(fName,'/','Final x');
    xSteps = h5readatt(fName,'/','x steps');
    yMin = h5readatt(fName,'/','Initial y');
    yMax = h5readatt(fName,'/','Final y');
    ySteps = h5readatt(fName,'/','y steps');
    xScale = linspace(xMin,xMax,xSteps+1);
    yScale = linspace(yMin,yMax,ySteps+1);
    
    imgGroup = h5info(fName,'/images');
    
    if (size(imgGroup.Groups,1)>0)
        fmArr = zeros(size(imgGroup.Groups,1),2);
        for imgInd = 1:size(imgGroup.Groups,1)
            figure(1);
            groupName = imgGroup.Groups(imgInd).Name;
            fd =  h5readatt(fName,groupName,'Focus distance');
            fm =  h5readatt(fName,groupName,'Focus measure');
            fmArr(imgInd,:) = [fd fm];
            m1 = h5read(fName,strcat(groupName,'/monitor1'));
            m2 = h5read(fName,strcat(groupName,'/monitor2'));
            
            clf();
            %subplot(211);
                imagesc(xScale,yScale,m1);
                axis xy equal;
                colorbar();
                xlabel('x (\mum)','FontSize',14,'FontName','Times');
                ylabel('y (\mum)','FontSize',14,'FontName','Times');
                title(['Focus distance is ' num2str(fd) ' \mum']);
                xlim([min(xScale) max(xScale)]);
                ylim([min(yScale) max(yScale)]);

            %subplot(212);
            %    imagesc(xScale,yScale,m2);
            %    axis xy equal;
            %    colorbar();
            %    xlabel('x (\mum)','FontSize',14,'FontName','Times');
            %    ylabel('y (\mum)','FontSize',14,'FontName','Times');
            %    title(['Focus distance is ' num2str(fd) ' \mum']);
            %    xlim([min(xScale) max(xScale)]);
            %    ylim([min(yScale) max(yScale)]);

            print(gcf,'-dpng',strcat(fName,'-',num2str(imgInd),'.png'))
            
        end
    end
    
    figure(2);
    plot(fmArr(:,1),fmArr(:,2),'rx');
    
    
end

function plotImg(xScale,yScale,val,fd,fm)
      
end