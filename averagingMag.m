tp = permute(rawWaveguide2,[2 1 3 4 5]);
base = 5;
tmp =  zeros(size(tp,1)/base-1,740,41,4,3);
for i=0:(size(tp,1)/base-1)
  disp(base*i+1);
  disp(base*i+base);
  tmp(i+1,:,:,:,:) = mean(tp((base*i+1):(base*i+base),:,:,:,:),1);  
end
res = tmp;