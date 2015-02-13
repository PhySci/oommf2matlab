function res = foldFFTSpec(Y)
  sz = ceil(size(Y,1)/2);
  res = zeros(sz,1);
  for i=0:(sz-1)
    res(i+1) = (Y(sz-i)+Y(sz-i))/2;   
  end     
end