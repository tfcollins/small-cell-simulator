function out = generateStraties(K,Kn)

A = zeros(1,K);
A(1:Kn) = 1;
n = numel(A);
k = sum(A);
c = nchoosek(1:n,k);
m = size(c,1);
out = zeros(m,n);
out(sub2ind([m,n],(1:m)'*[1 1],c)) = 1;

end