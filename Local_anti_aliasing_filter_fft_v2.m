% LOCAL ANTI-ALIASING (refer to lab-book for description)
tic

comp = 2;
kcap = pi*1e8; % 20nm
nx	 = 1200;
ny 	 = 1200;

dx	= 5e-9;
N	= 1200;
dk	= 2*pi/(N*dx);
kcap_index = floor(kcap/(dk));

% What region do we want to look at
x0 		= 590;
xwide	= 20;
y0		= 540;
ywide	= 40;

% Load in the static data
static = fopen('Relaxed_500Oe.stc');
q = 1;
    while q < 39
        fgetl(static);
        skip_lines = ftell(static);
        q = q+1;
    end
fseek(static,skip_lines+8+comp*8,'bof');
s = fread(static,[nx,ny],'1*double',16);
% Load the dynamic file, find the diff and write to the 3D array, then
% repeat.
files = dir('*.omf');

% Preallocate the 3D array. Limit it to 50
final_result = ones(1500,2);
data_box_all = ones(ywide,xwide,1500);
%parpool(4)
for loop = 1:50
	loop
	data_box = ones(nx,ny,30);
	parfor f = 1:30
		A = fopen(files(f+(loop-1)*30).name);
		q = 1;
			while q < 39
				fgetl(A);
				skip_lines = ftell(A);
				q = q+1;
			end
		fseek(A,skip_lines+8+comp*8,'bof');
		D = fread(A,[nx,ny],'1*double',16);
		data_box(:,:,f) = D - s;
		fclose(A);
    end
    
	% Now perform the fft across the pages that are loaded, apply the k-filter, then rebuild.
	%data_box = fft(fft(data_box,[],1),[],2);
	%data_box = fftshift(fftshift(fft(fft(ifftshift(ifftshift(data_box,1),2),[],1),[],2),1),2);
	data_box = circshift(data_box,[300,120,0]);
	
	data_box = fft(fft(data_box,[],1),[],2);
	data_box(:,[nx/2-kcap_index:1:nx/2+kcap_index],:) = 0;
	%data_box(:,[1:1:kcap_index],:) = 0;
	data_box([ny/2-kcap_index:1:ny/2+kcap_index],:,:) = 0;
	%data_box(600,1,:) = 0;
	%data_box(600,1200,:) = 0;
	%data_box(1,600,:) = 0;
	%data_box(1200,600,:) = 0;
	%data_box([ny-kcap_index:1:ny],:,:) = 0;
			
	data_box = ifft(ifft(data_box,[],2),[],1);
	%data_box = real(ifft(ifft(abs(data_box).*exp(i*angle(data_box)),[],2),[],1));
	% Now apply the cropping probe, to isolate our region of interest
	
    right_columns               = [x0+xwide+1:1:nx];
	data_box(:,right_columns,:) = [];
	lower_rows                  = [y0+ywide+1:1:ny];
	data_box(lower_rows,:,:)    = [];
	upper_rows                  = [1:1:y0];
	data_box(upper_rows,:,:)    = [];
	left_columns                = [1:1:x0];
	data_box(:,left_columns,:)  = [];
    
	% And then find the time-resolved fft across each page, take the amplitude, then 
	% average across each page of the data_box, to obtain the average abs(fft(Mz)).
	% To do this, we need the 3D data_box: should be able to manage the memory, as we've cropped a lot of it.
	data_box_all(:,:,((loop-1)*30 + 1):((loop-1)*30 + 30)) = data_box;
end

%delete(gcp)
data_box_all = abs(fft(data_box_all,[],3));
aver = ones(1,1,1500);
time_intp=[1e-11:1e-11:1.5e-8];
final_result(:,1) = (1/1.5e-8)*[0:size(time_intp,2)-1];
for page3 = 1:1500
	aver(1,1,page3) = mean2(data_box_all(:,:,page3));
	final_result(page3,2) = aver(1,1,page3);
end
%final_result(:,2) = smooth(final_result(:,2));
dlmwrite('Local_probe_5_page_b_pi_1e8.txt',final_result);
plot(final_result(:,1),final_result(:,2))
toc