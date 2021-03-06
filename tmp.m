train_T = readtable('data/spam_train.csv','ReadVariableNames',false);
test_T = readtable('data/spam_test.csv','ReadVariableNames',false);

%train_T = readtable('data/train_data.csv','ReadVariableNames',false);
%test_T = readtable('data/test_data.csv','ReadVariableNames',false);

d = length(train_T.Properties.VariableNames);
X_train = train_T{:,1:d-1};
y_train = train_T{:,d};
n_train = length(y_train);

rows = randperm(n_train, 0.1*n_train); 
X_build = X_train(rows, :);
y_build = y_train(rows, 1);

N = X_build((y_build == -1),:);
P = X_build((y_build == 1),:);
PN = [P; N];
PNL = [ones(length(P),1); -1*ones(length(N),1)];

%output_adsvm(1,1) = (correct/(length(Nt) + length(Ptattk)))*100;
%{
train_T = readtable('data/spam_train.csv','ReadVariableNames',false);
test_T = readtable('data/spam_test.csv','ReadVariableNames',false);

%train_T = readtable('data/train_data.csv','ReadVariableNames',false);
%test_T = readtable('data/test_data.csv','ReadVariableNames',false);

d = length(train_T.Properties.VariableNames);
train = train_T{:,:};
X_train = train_T{:,1:d-1};
y_train = train_T{:,d};
n_train = length(y_train);

N = X_train((y_train == -1),:);
P = X_train((y_train == 1),:);

X_test = test_T{:,1:d-1};
y_test = test_T{:,d};
n_test = length(y_test);

Nt = X_test((y_test == -1),:);
Pt = X_test((y_test == 1),:);

C = 1;
cdf = 1;

Cd = [0.9, 0.7, 0.5, 0.3, 0.1];
%Cd = [0.9];
cd_len = length(Cd);

f_attack = [0, 0.3, 0.5, 0.7, 1.0];
%f_attack = [0.3];
fa_len = length(f_attack);

output_adsvm = zeros(cd_len, fa_len);
w_result = zeros(cd_len, d-1);

round = 1;

x_mean = mean(N);                        
x_t = repmat(x_mean,length(P),1);

ColOfOnes = ones(d-1,1);

for i=1:cd_len
    cd = Cd(i);  
    e = cdf*((1- cd*abs(x_t - P)./(abs(x_t)+abs(P))).*((x_t-P).^2));
    ze = zeros(length(N),d-1);
    e = [e; ze];
    xe = x_t-P;
    xe = [xe;ze];
    for j=1:fa_len
        correct = 0;
        fa = f_attack(j);     
        cvx_begin                 
            variable w(d-1) 
            variable b;
            variable xi(n_train);
            variable t(n_train);
            variable u(n_train,d-1);
            variable v(n_train,d-1);

            minimize 1/2 *(norm(w)) + C*sum(xi);
            subject to
                xi >= 0;
                xi - 1 + y_train.*(X_train*w+b)- t >= 0;
                t - (u.*e)*ColOfOnes >= 0;
                (v - u).*xe - 0.5*repmat((1+y_train),1,d-1).*repmat(w',n_train,1) == 0;
                u >= 0;
                v >= 0;       
        cvx_end

        %Ntr = reshape(Nt(randperm(length(Nt)*2)), length(Nt), 2);
        Ntr = zeros(length(Pt), d-1);
        for k=1:length(Pt)
            ra = randi([1 length(Nt)]);
            Ntr(k,:) = Nt(ra,:);
        end

        Ptattk = Pt+fa*(Ntr-Pt);
        X_test_attk = [Ptattk;Nt];

        ypred = Nt*w+b;
        correct = correct + sum(ypred<=0);

        ypred = Ptattk*w+b;
        correct = correct + sum(ypred>0);
        disp(cd)
        disp(fa) 
        output_adsvm(i,j) = (correct/round/n_test)*100;
    end
    %w_result(i,:) = w;
end

train_T = readtable('data/spam_train.csv','ReadVariableNames',false);
test_T = readtable('data/spam_test.csv','ReadVariableNames',false);

d = length(train_T.Properties.VariableNames);
X_train = train_T{:,1:d-1};
y_train = train_T{:,d};
n_train = length(y_train);

%N = X_train((y_train == -1),:);
%P = X_train((y_train == 1),:);

X_test = test_T{:,1:d-1};
y_test = test_T{:,d};
n_test = length(y_test);

Nt = X_test((y_test == -1),:);
Pt = X_test((y_test == 1),:);

rows = randperm(n_train, 0.1*n_train); 
X_train = X_train(rows, :);
y_train = y_train(rows, 1);
n_train = length(rows);

N = X_train((y_train == -1),:);
P = X_train((y_train == 1),:);

cdf = 1;
cd = 0.9;

x_mean = mean(N);                        
x_t = repmat(x_mean,length(P),1);
e = cdf*((1- cd*abs(x_t - P)./(abs(x_t)+abs(P))).*((x_t-P).^2));
ze = zeros(length(N),d-1);
e = [e; ze];
xe = x_t-P;
xe = [xe;ze];

col = ones(1,d-1);
tmpp = dot(sum(isnan(e)),col);

A = [-1, -2]; B = [1, 2];  
Sigma = [1 .5; 0.5 2]; R = chol(Sigma);
m = 100; 
n = 1;

P = normc(repmat(A,m,1) + randn(m,2)*R); % positive data
[rowp, colp] = size(P);
N = normc(repmat(B,m,1) + randn(m,2)*R); % negative data
[rown, coln] = size(N);
X_train = [P;N];
PL = ones(rowp,1);
NL = -ones(rown,1);
y_train = [PL;NL];

Pt = normc(repmat(A,m,1) + randn(m,2)*R);
[rowp, colp] = size(Pt);
Nt = normc(repmat(B,m,1) + randn(m,2)*R);
[rown, coln] = size(Nt);
y_test = ones(rowp,1);
y_test(rowp+1:rowp+rown) = -1;

n_train = length(y_train);
n_test = length(y_test);
d = 2;

C = 1;

Cf = [0.1, 0.3, 0.5, 0.7, 0.9];
cf_len = length(Cf);

f_attack = [0, 0.3, 0.5, 0.7, 1.0];
fa_len = length(f_attack);

output_adsvm = zeros(cf_len, fa_len);

negative_test = [];
positive_test = [];
for i=1:n_test
   if y_test(i,1) == -1
       negative_test(end+1) = i;
   else 
       positive_test(end+1) = i;
   end    
end

maxx = zeros(1,d);
minn = zeros(1,d);
for k = 1:d
    maxx(1,k) = max(X_train(:,k));
    minn(1,k) = min(X_train(:,k));
end

X_max = zeros(n_train,d);
X_min = zeros(n_train,d);

for k = 1:d
    X_max(:, k) = maxx(1,k) - X_train(:,k);
    X_min(:, k) = minn(1,k) - X_train(:,k);
end

ColOfOnes = ones(d,1);
w2 = zeros(length(Cf), d);

for i=1:cf_len
    cf = Cf(i);
    cvx_begin quiet                       
        variable w(d) 
        variable b;
        variable xi(n_train);
        variable t(n_train);
        variable u(n_train,d);
        variable v(n_train,d);

        minimize 1/2 *(norm(w)) + C*sum(xi);
        subject to
            xi >= 0;
            xi - 1 + y_train.*(X_train*w+b)- t >= 0;
            t >= cf*(((v.*X_max) - (u.*X_min))*ColOfOnes);
            u-v == 0.5*repmat((1+y_train),1,d).*repmat(w',n_train,1);
            u >= 0;
            v >= 0;    
    cvx_end
    for j=1:fa_len
        correct = 0;
        fa = f_attack(j);
        Ntr = reshape(Nt(randperm(m*2)), m, 2);
        Ptattk = Pt+fa*(Ntr-Pt);
        X_test = [Ptattk;Nt];
        
        ypred = Nt*w+b;
        correct = correct+sum(ypred<=0);
        
        ypred = Ptattk*w+b;
        correct = correct + sum(ypred>0);
        output_adsvm(i,j) = (correct/n_test)*100;
    end
    w2(i,:) = w;
end

train_T = readtable('data/train_data.csv','ReadVariableNames',false);
test_T = readtable('data/test_data.csv','ReadVariableNames',false);

X_train = train_T{:,1:2};
y_train = train_T{:,3};
n_train = length(y_train);

X_test = test_T{:,1:2};
y_test = test_T{:,3};
n_test = length(y_test);

d = 2;
C = 1;
Cf = [0.1, 0.3, 0.5, 0.7, 0.9];
cf_len = length(Cf);
f_attack = [0, 0.3, 0.5, 0.7, 1.0];
fa_len = length(f_attack);

output_adsvm = zeros(cf_len, fa_len);

ntpos = [];
ptpos = [];
for i=1:n_test
   if y_test(i,1) == -1
       ntpos(end+1) = i;
   else 
       ptpos(end+1) = i;
   end    
end



maxx = zeros(1,d);
minn = zeros(1,d);
for k = 1:d
    maxx(1,k) = max(X_train(:,k));
    minn(1,k) = min(X_train(:,k));
end

X_max = zeros(n_train,d);
X_min = zeros(n_train,d);

for k = 1:d
    X_max(:, k) = maxx(1,k) - X_train(:,k);
    X_min(:, k) = minn(1,k) - X_train(:,k);
end

ColOfOnes = ones(d,1);

for i=1:cf_len
    cf = Cf(i);
    cvx_begin quiet                       
        variable w(d) 
        variable b;
        variable xi(n_train);
        variable t(n_train);
        variable u(n_train,d);
        variable v(n_train,d);

        minimize 1/2 *(norm(w)) + C*sum(xi);
        subject to
            xi >= 0;
            xi - 1 + y_train.*(X_train*w+b)- t >= 0;
            t >= cf*(((v.*X_max) - (u.*X_min))*ColOfOnes);
            u-v == 0.5*repmat((1+y_train),1,d).*repmat(w',n_train,1);
            u >= 0;
            v >= 0;    
    cvx_end
    for j=1:fa_len
        fa = f_attack(j);
        delta = zeros(n_test, d);
        for k=1:n_test
            if y_test(k,1) == 1
                r = randi([1 length(ntpos)]);
                delta(k,:) = fa*(X_test(ntpos(r),:) - X_test(k, :));
            end
        end
        X_delta = X_test + delta;
        
        %{
        scatter(X_delta(:,1),X_delta(:,2));
        saveas(gcf,'img/fa = ' + string(fa) + '.png');
        %}
        correct = 0;
        for k=1:n_test
            y_pred = sign(dot(w,X_delta(k,:)) + b);
            if y_pred == y_test(k,1)
                correct = correct + 1;
            end
        end
        output_adsvm(i,j) = (correct/n_test)*100;
    end
end

train_T = readtable('data/spam_train.csv','ReadVariableNames',false);
test_T = readtable('data/spam_test.csv','ReadVariableNames',false);

d = length(train_T.Properties.VariableNames);
X_train = train_T{:,1:d-1};
y_train = train_T{:,d};
n_train = length(y_train);

X_test = test_T{:,1:d-1};
y_test = test_T{:,d};
n_test = length(y_test);

Nt = X_test((y_test == -1),:);
Pt = X_test((y_test == 1),:);

C = 1;
Cf = [0.1, 0.3, 0.5, 0.7, 0.9];
cf_len = length(Cf);
f_attack = [0, 0.3, 0.5, 0.7, 1.0];
fa_len = length(f_attack);

output_adsvm = zeros(cf_len, fa_len);

maxx = zeros(1,d-1);
minn = zeros(1,d-1);
for k = 1:d-1
    maxx(1,k) = max(X_train(:,k));
    minn(1,k) = min(X_train(:,k));
end

X_max = zeros(n_train,d-1);
X_min = zeros(n_train,d-1);

for k = 1:d-1
    X_max(:, k) = maxx(1,k) - X_train(:,k);
    X_min(:, k) = minn(1,k) - X_train(:,k);
end

ColOfOnes = ones(d-1,1);

for i=1:cf_len
    cf = Cf(i);
    cvx_begin                      
        variable w(d-1) 
        variable b;
        variable xi(n_train);
        variable t(n_train);
        variable u(n_train,d-1);
        variable v(n_train,d-1);

        minimize 1/2 *(norm(w)) + C*sum(xi);
        subject to
            xi >= 0;
            xi - 1 + y_train.*(X_train*w+b)- t >= 0;
            t >= cf*(((v.*X_max) - (u.*X_min))*ColOfOnes);
            u-v == 0.5*repmat((1+y_train),1,d-1).*repmat(w',n_train,1);
            u >= 0;
            v >= 0;    
    cvx_end
    for j=1:fa_len
        correct = 0;
        fa = f_attack(j);
        %Ntr = reshape(Nt(randperm(length(Nt)*2)), length(Nt), 2);
        Ntr = zeros(length(Pt), d-1);
        for k=1:length(Pt)
            r = randi([1 length(Nt)]);
            Ntr(k,:) = Nt(r,:);
        end
        Ptattk = Pt+fa*(Ntr-Pt);
        X_test_attk = [Ptattk;Nt];
        
        ypred = Nt*w+b;
        correct = correct+sum(ypred<=0);
        
        ypred = Ptattk*w+b;
        correct = correct + sum(ypred>0);
        output_adsvm(i,j) = (correct/n_test)*100;
    end
end
%}