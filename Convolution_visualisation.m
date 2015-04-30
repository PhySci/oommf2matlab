% A script reading in multiple omf files (in binary format), finding the dynamic magnetizaion of the x-,y- or z- component,
% then returning a spatial mapping of the component (either convolved with a Gaussian filter, or not).
% THIS SCRIPT CALLS THE FUNCTION FILE 'b2r.m'.

% Specify the simulation parameters
nx = 800;
ny = 800;
nz = 13;

% And what component we want to look i.e. Mx = 1, My = 2, My = 3
comp = 3;

% What depth do you want to look at? The bottom surface = 1, and upper surface = nz
depth = 1;
read_static = false;

if (read_static) 

% Now set the suffix of the relaxed file to .stc.
% Load in the static data
static_name = dir('*.stc');
stc = fopen(static_name.name);

% In the static file, we need to move to the 39th line, where the data starts.
q = 1;
while q < 39
    fgetl(stc);
    skip_lines = ftell(stc);
    q = q+1;
end

% Now read out the data. This is returned as a matrix, with the data laid out in pixel-by-pixel form.
fseek(stc,skip_lines+8+(comp-1)*8+(depth-1)*nx*ny*24,'bof');
s = fread(stc,[ny,nx],'1*double',16);

end 
% With the static data in play, now load in the dynamic data.
% files = dir('*.omf');
files = 'D:\Micromagnet\OOMMF\proj\Transducer APl\transducer-Oxs_TimeDriver-Magnetization-0000000-0000099.omf';
data_box = ones(ny,nx);

c = 0;
%for file = files
    % Repeat the stuff above, to find the dynamic magnetization
	t_step = 1 + c;
	A = fopen(files); %file.name);
    q = 1;
        while q < 39
            fgetl(A);
            skip_lines = ftell(A);
            q = q+1;
        end
	fseek(A,skip_lines+8+(comp-1)*8+(depth-1)*nx*ny,'bof');
	D = fread(A,[ny,nx],'1*double',16);
    disp('D component');
    disp(D(1,1));
    if (read_static)
      data_box = D - s;
    else
      data_box = D;
    end  
    data_box = data_box.';
	
	% Now, apply the convolution filter (if necessary), and plot out the spatial map.
	G = fspecial('gaussian',[9 9], 3);
	Ig = imfilter(data_box,G,'circular','same','conv');
	Img = imagesc(Ig);
	colormap(b2r(-2000,2000));
	hcb=colorbar('SouthOutside');
	set(hcb,'XTick',[-2000,0,2000])
    axis([0,nx,0,ny]);
    axis xy;
    xlabel('x (\mum)', 'FontSize', 20);
    ylabel('y (\mum)', 'FontSize', 20);
    %set(gca,'YTick',[200,400],'YTickLabel',[20,40],'XTick',[0,50,400],'XTickLabel',[0,5,40]);
	set(hcb,'FontSize', 20);
    axis off;
	saveas(Img, strcat('image_',num2str(t_step),'.png'));
	
	c = c + 1;
%end