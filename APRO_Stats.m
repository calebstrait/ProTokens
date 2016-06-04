function APRO_Stats(analyses,varargin)

SetPars(varargin)

LoadData

AddVars

Analyze(analyses)

end

function SetPars(inits)
global p; p = {};

p.colors = {'--ks' '--bs' '--rs' '--gs' '--cs' '--ys'};
p.inits = inits;

end

function LoadData
global v; global p;

cd('/Users/cstrait/Documents/Data/ProTokens');
savename = ['ProTokensPPD_' strjoin(p.inits,'') '.mat'];
if(exist(savename, 'file')==0)
    v = {};
    [n,t] = deal(0);
    folders = dir;
    for f = 1:numel(folders)
        if ~strcmp(folders(f).name,'.') && ~strcmp(folders(f).name,'..') && ~strcmp(folders(f).name,'Other') && sum(ismember(p.inits,folders(f).name(1)))~=0 && folders(f).isdir == 1
            cd(['/Users/cstrait/Documents/Data/ProTokens/' folders(f).name]);
            files = dir('*.mat');
            for j = 1:length(files)
                n = n + 1;
                filename = ['/Users/cstrait/Documents/Data/ProTokens/' folders(f).name '/' files(j).name];
                if strcmp(files(j).name(1), 'P')
                    v.species = 'Human';
                else
                    v.species = 'Monkey';
                end
                ce = struct2cell(load(filename));
                d = ce{1};
                for i = 1:length(d)
                    t = t + 1;
                    v.L_Top(t) = d{i}.values(d{i}.leftTop_type);
                    v.L_Bot(t) = d{i}.values(d{i}.leftBot_type);
                    v.L_Prb(t) = d{i}.left_gamble;
                    v.R_Top(t) = d{i}.values(d{i}.rghtTop_type);
                    v.R_Bot(t) = d{i}.values(d{i}.rghtBot_type);
                    v.R_Prb(t) = d{i}.rght_gamble;
                    v.tokensAfterCho(t) = d{i}.tokens;
                    v.tokenChange(t) = d{i}.tokenChange;
                    v.rT(t) = d{i}.reactionTime;
                    if strcmp(folders(f).name(1),'J'), v.subj(t) = 1;end
                    if strcmp(folders(f).name(1),'B'), v.subj(t) = 2;end
                    if strcmp(folders(f).name(1),'C'), v.subj(t) = 3;end
                    v.session(t) = str2double(folders(f).name(2:end));
                    if strcmp(d{i}.choice,'left'), v.cho(t) = 1;end
                    if strcmp(d{i}.choice,'right'), v.cho(t) = 0;end
                    if strcmp(d{i}.choice,'canceled'), v.cho(t) = -1;end
                    if strcmp(d{i}.outcome,'top'), v.outcome(t) = 1;end
                    if strcmp(d{i}.outcome,'bot'), v.outcome(t) = 0;end
                end
            end
        end
    end
    eval(['save /Users/cstrait/Documents/Data/ProTokens/' savename ' v']);
else
    load(['/Users/cstrait/Documents/Data/ProTokens/' savename]);
end
end

function AddVars
global v; global p;

cd('/Users/cstrait/Documents/Data/ProTokens');
savename = ['ProTokensACL_' strjoin(p.inits,'') '.mat'];
if(exist(savename, 'file')==0)
    for t = 1:length(v.cho)
        
        %*** Before Choice Tokens
        if v.tokensAfterCho(t) == 0 && v.tokenChange(t) ~= 0
            if t == 1
                v.tokens(t) = 0;
            else
                v.tokens(t) = v.tokensAfterCho(t-1);
            end
        else
            v.tokens(t) = v.tokensAfterCho(t) - v.tokenChange(t);
        end
        if(v.tokens(t) + v.tokenChange(t) ~= v.tokensAfterCho(t) && (v.tokens(t) + v.tokenChange(t)) <= 5 && (v.tokens(t) + v.tokenChange(t)) >= 0 && v.cho(t) ~= -1)
            v.tokens(t) = 0;
            if v.tokenChange(t) > 0, v.cho(t) = -1;end
        end
        if v.tokens(t) < 0 || v.tokens(t) > 5, v.cho(t) = -1;end
        %**
        
        %*** EV
        v.L_EV(t) = (v.L_Top(t) * v.L_Prb(t) + v.L_Bot(t) * (1 - v.L_Prb(t)));
        v.R_EV(t) = (v.R_Top(t) * v.R_Prb(t) + v.R_Bot(t) * (1 - v.R_Prb(t)));
        %**
        
        %*** EV Adjusted for Tokens
        effectiveVals = [v.L_Top(t) v.L_Bot(t) v.R_Top(t) v.R_Bot(t)];
        if v.tokens(t) == 0, effectiveVals(effectiveVals < 0) = 0;end
        if v.tokens(t) == 1, effectiveVals(effectiveVals < -1) = -1;end
        if v.tokens(t) == 4, effectiveVals(effectiveVals > 2) = 2;end
        if v.tokens(t) == 5, effectiveVals(effectiveVals > 1) = 1;end
        v.L_eEV(t) = (effectiveVals(1) * v.L_Prb(t) + effectiveVals(2) * (1 - v.L_Prb(t)));
        v.R_eEV(t) = (effectiveVals(3) * v.R_Prb(t) + effectiveVals(4) * (1 - v.R_Prb(t)));
        %**
        
        %*** Create Optimal Dataset
        if v.L_eEV(t) >= v.R_eEV(t)
            v.choO(t) = 1;
        else
            v.choO(t) = 0;
        end
        %**
        
        %*** Option Variance/Skewness
        Lset = ones(10,1) * v.L_Bot(t);
        Rset = ones(10,1) * v.R_Bot(t);
        for x = 1:(v.L_Prb(t) * 10), Lset(x) = v.L_Top(t);end
        for x = 1:(v.R_Prb(t) * 10), Rset(x) = v.R_Top(t);end
        v.L_Var(t) = var(Lset);
        v.R_Var(t) = var(Rset);
        if v.L_Var(t) == 0
            v.L_Skw(t) = 0;
        else
            v.L_Skw(t) = skewness(Lset);
        end
        if v.R_Var(t) == 0
            v.R_Skw(t) = 0;
        else
            v.R_Skw(t) = skewness(Rset);
        end
        %**
        
    end
    eval(['save /Users/cstrait/Documents/Data/ProTokens/' savename ' v']);
else
    load(['/Users/cstrait/Documents/Data/ProTokens/' savename]);
end
%d = [v.L_Top' v.L_Bot' v.L_Prb' v.R_Top' v.R_Bot' v.R_Prb' v.cho' v.subj' v.session' v.tokens'];
%h = {'r1','q1','p1','r2','q2','p2','choice','subject','session','tokens'};
%csvwrite_with_headers('/Users/cstrait/Documents/Data/ProTokens/PROdata.csv',d,h);
end

function Analyze(analyses)
global v;
close all
if ~isempty(analyses), v.fig = figure;end
[v.Ar,v.Ac] = numSubPlots(length(analyses));
for a = 1:length(analyses)
    v.An = a;
    x = analyses(a);
    switch x,
        
        case 1, JankRiskOverTokens;
        
        case 2, AlphaOverTokens;
        
        case 3, OptimalityOverTokens;
            
        case 4, LogisticRegression;
            
        case 5, PlotSteveAlphas;
            
    end
end
end

function JankRiskOverTokens         %  1
%***** RISK-SEEKINGNESS CHOVAL-UNCVAL OVER TOKENS
global v; global p;

cho = zeros(6,2); %Top 6: summed vals; Bot 6: count
unc = zeros(6,2);
safeCount = 0;
for t = 1:length(v.cho)
    if v.L_Top(t) == 1 && v.L_Bot(t) == 1
        if v.cho(t) == 1 %Cho Safe
            unc(v.tokens(t)+1,1) = unc(v.tokens(t)+1,1) + v.R_EV(t);
            unc(v.tokens(t)+1,2) = unc(v.tokens(t)+1,2) + 1;
        elseif v.cho(t) == 0
            cho(v.tokens(t)+1,1) = cho(v.tokens(t)+1,1) + v.R_EV(t);
            cho(v.tokens(t)+1,2) = cho(v.tokens(t)+1,2) + 1;
        end
    end
    if v.R_Top(t) == 1 && v.R_Bot(t) == 1
        if v.cho(t) == 0 %Cho Safe
            unc(v.tokens(t)+1,1) = unc(v.tokens(t)+1,1) + v.L_EV(t);
            unc(v.tokens(t)+1,2) = unc(v.tokens(t)+1,2) + 1;
        elseif v.cho(t) == 1
            cho(v.tokens(t)+1,1) = cho(v.tokens(t)+1,1) + v.L_EV(t);
            cho(v.tokens(t)+1,2) = cho(v.tokens(t)+1,2) + 1;
        end
    end
    if v.L_Top(t) == 1 && v.L_Bot(t) == 1 || v.R_Top(t) == 1 && v.R_Bot(t) == 1, safeCount = safeCount + 1;end
end
choToPlot = cho(:,1) ./ cho(:,2);
uncToPlot = unc(:,1) ./ unc(:,2);
cho_unc = choToPlot - uncToPlot;
subplot(v.Ar,v.Ac,v.An)
hold on
plot(cho_unc, p.colors{1},'LineWidth',2,'MarkerSize',4)
plot(choToPlot, p.colors{2},'LineWidth',2,'MarkerSize',4)
plot(uncToPlot, p.colors{3},'LineWidth',2,'MarkerSize',4)
legend({'cho-unc','Cho','Unc'});
title(['Risk-Seekingness Over Tokens [' strjoin(p.inits,',') '] (Trials with Gamble vs. Safe n=' num2str(safeCount) ')'],'FontSize',14);
set(gca,'XTick',1:6,'XTickLabel',0:5,'FontSize',14);
xlabel('Tokens','FontSize',14);
ylabel('Mean ChoVal - Mean UncVal','FontSize',14);
hold off
[R,P] = corrcoef(1:6,cho_unc);
fprintf('R = %.2f  P = %.3f\n', R(2,1), P(2,1));
end

function AlphaOverTokens            %  2
%***** RISK-SEEKINGNESS ALPHA OVER TOKENS
global v; global p;

numFit = 10; %Number of EV points included
%Count Safes
safeCount = 0;
for t = 1:length(v.cho)
    if v.L_Top(t) == 1 && v.L_Bot(t) == 1 || v.R_Top(t) == 1 && v.R_Bot(t) == 1, safeCount = safeCount + 1;end
end
%***
Ms = cell(6,1);
xrange = -2:.1:3;
for b = 1:6
    Ms{b} = zeros(length(xrange),2); % #Cho #UCh
end
for t = 1:length(v.cho)
    if v.L_Top(t) == 1 && v.L_Bot(t) == 1 || v.R_Top(t) == 1 && v.R_Bot(t) == 1
        m = Ms{v.tokens(t)+1};
        if v.L_Top(t) == 1 && v.L_Bot(t) == 1
            ind = find(xrange == v.R_EV(t));
            if v.cho(t) == 0, %Cho Risky
                m(ind,1) = m(ind,1) + 1;
            else
                m(ind,2) = m(ind,2) + 1;
            end
        end
        if v.R_Top(t) == 1 && v.R_Bot(t) == 1
            ind = find(xrange == v.L_EV(t));
            if v.cho(t) == 1, %Cho Risky
                m(ind,1) = m(ind,1) + 1;
            else
                m(ind,2) = m(ind,2) + 1;
            end
        end
        Ms{v.tokens(t)+1} = m;
    end
end
alphas = zeros(6,2); % Sum Count
for b = 1:6
    m = Ms{v.tokens(t)+1};
    pcentCho = m(:,1) ./ (m(:,1) + m(:,2));
    
    fg = @(p,xrange) p(1) + p(2) ./ (1 + exp(-(xrange-p(3))/p(4)));
    pg = nlinfit(xrange,pcentCho',fg,[0 20 50 5]);
    fitted = [xrange; fg(pg,xrange)]';
    sortedinds = sortrows([abs(fitted(:,2) - .5) (1:51)']);
    inds = sortedinds(1:numFit,2);
    
    for i = 1:numFit
        foundRs = find(v.L_Top==1 & v.L_Bot==1 & v.R_EV==xrange(inds(i)));
        foundLs = find(v.R_Top==1 & v.R_Bot==1 & v.L_EV==xrange(inds(i)));
        for r = foundRs
            syms a
            alphas(b,1) = alphas(b,1) + solve(v.R_Prb(r) * v.R_Top(r)^a + (1-v.R_Prb(r)) * v.R_Bot(r)^a == 1, a);
            alphas(b,2) = alphas(b,2) + 1;
        end
        for l = foundLs
            syms a
            alphas(b,1) = alphas(b,1) + solve(v.L_Prb(l) * v.L_Top(l)^a + (1-v.L_Prb(l)) * v.L_Bot(l)^a == 1, a);
            alphas(b,2) = alphas(b,2) + 1;
        end
    end
end
toplot = alphas(:,1) ./ alphas(:,2);
subplot(v.Ar,v.Ac,v.An)
hold on
plot(toplot, p.colors{1},'LineWidth',2,'MarkerSize',4);
title(['Risk-Seekingness Over Tokens [' strjoin(p.inits,',') '] (Trials with Gamble vs. Safe n=' num2str(safeCount) ')'],'FontSize',14);
set(gca,'XTick',1:6,'XTickLabel',0:5,'FontSize',14);
xlabel('Tokens','FontSize',14);
ylabel('Mean Alpha of Indifference Trials','FontSize',14);
hold off
end

function OptimalityOverTokens       %  3
%***** PERCENT CHOICES OPTIMAL OVER TOKENS
global v; global p;

c_MAXEV = zeros(6,2); %Correct Wrong
c_EFTEV = zeros(6,2);
c_VARIA = zeros(6,2);
c_HIPRB = zeros(6,2); %cho hi prob
c_MAXsum = zeros(2,1);
for t = 1:length(v.cho)
    if v.cho(t) == 1
        if v.L_EV(t) >= v.R_EV(t)
            c_MAXEV(v.tokens(t)+1,1) = c_MAXEV(v.tokens(t)+1,1) + 1;
        else
            c_MAXEV(v.tokens(t)+1,2) = c_MAXEV(v.tokens(t)+1,2) + 1;
        end
        if v.L_eEV(t) >= v.R_eEV(t)
            c_EFTEV(v.tokens(t)+1,1) = c_EFTEV(v.tokens(t)+1,1) + 1;
        else
            c_EFTEV(v.tokens(t)+1,2) = c_EFTEV(v.tokens(t)+1,2) + 1;
        end
        if v.L_Var(t) >= v.R_Var(t)
            c_VARIA(v.tokens(t)+1,1) = c_VARIA(v.tokens(t)+1,1) + 1;
        else
            c_VARIA(v.tokens(t)+1,2) = c_VARIA(v.tokens(t)+1,2) + 1;
        end
        if v.L_Prb(t) >= v.R_Prb(t)
            c_HIPRB(v.tokens(t)+1,1) = c_HIPRB(v.tokens(t)+1,1) + 1;
        else
            c_HIPRB(v.tokens(t)+1,2) = c_HIPRB(v.tokens(t)+1,2) + 1;
        end
    elseif v.cho(t) == 0
        if v.L_EV(t) <= v.R_EV(t)
            c_MAXEV(v.tokens(t)+1,1) = c_MAXEV(v.tokens(t)+1,1) + 1;
        else
            c_MAXEV(v.tokens(t)+1,2) = c_MAXEV(v.tokens(t)+1,2) + 1;
        end
        if v.L_eEV(t) <= v.R_eEV(t)
            c_EFTEV(v.tokens(t)+1,1) = c_EFTEV(v.tokens(t)+1,1) + 1;
        else
            c_EFTEV(v.tokens(t)+1,2) = c_EFTEV(v.tokens(t)+1,2) + 1;
        end
        if v.L_Var(t) <= v.R_Var(t)
            c_VARIA(v.tokens(t)+1,1) = c_VARIA(v.tokens(t)+1,1) + 1;
        else
            c_VARIA(v.tokens(t)+1,2) = c_VARIA(v.tokens(t)+1,2) + 1;
        end
        if v.L_Prb(t) <= v.R_Prb(t)
            c_HIPRB(v.tokens(t)+1,1) = c_HIPRB(v.tokens(t)+1,1) + 1;
        else
            c_HIPRB(v.tokens(t)+1,2) = c_HIPRB(v.tokens(t)+1,2) + 1;
        end
    end
    if v.cho(t) == 1 && v.L_EV(t) >= v.R_EV(t) || v.cho(t) == 0 && v.L_EV(t) <= v.R_EV(t), c_MAXsum(1) = c_MAXsum(1) + 1;end
    if v.cho(t) ~= -1, c_MAXsum(2) = c_MAXsum(2) + 1;end
end
fprintf('Optimal: %.2f%%\n',(100*c_MAXsum(1)/c_MAXsum(2)));
subplot(v.Ar,v.Ac,v.An)
hold on
toPlot = c_MAXEV(:,1) ./ (c_MAXEV(:,1) + c_MAXEV(:,2));
plot(100*toPlot, p.colors{1},'LineWidth',2,'MarkerSize',4)
toPlot = c_EFTEV(:,1) ./ (c_EFTEV(:,1) + c_EFTEV(:,2));
plot(100*toPlot, p.colors{2},'LineWidth',2,'MarkerSize',4)
toPlot = c_VARIA(:,1) ./ (c_VARIA(:,1) + c_VARIA(:,2));
plot(100*toPlot, p.colors{3},'LineWidth',2,'MarkerSize',4)
toPlot = c_HIPRB(:,1) ./ (c_HIPRB(:,1) + c_HIPRB(:,2));
plot(100*toPlot, p.colors{4},'LineWidth',2,'MarkerSize',4)
title(['Optimality Over Tokens [' strjoin(p.inits,',') '] (n=' num2str(length(v.cho ~= -1)) ')'],'FontSize',14);
legend({'Max EV','Effective EV','Hi Variance','Hi Probability'});
set(gca,'XTick',1:6,'XTickLabel',0:5,'FontSize',14);
axis([-Inf Inf 0 100]);
xlabel('Tokens','FontSize',14);
ylabel('%Choices Optimal','FontSize',14);
hold off
%keyboard
end

function LogisticRegression         %  4
%***** REGRESS CHOICE ONTO TASK VARIABLES
global v; global p;

input = [zscore(v.L_eEV)' zscore(v.R_eEV)' zscore(v.L_Var)' zscore(v.R_Var)' zscore(v.tokens)' zscore(v.tokens .* v.L_Var)' zscore(v.tokens .* v.R_Var)'];
labels = {'Bo' 'L_ev' 'R_ev' 'L_var' 'R_var' 'tkn' 'tkn*Lvr' 'tkn*Rvr'};
val = v.cho ~= -1;
[b,~,stats] = glmfit(input(val,:),v.cho(val)','binomial','link','logit');
subplot(v.Ar,v.Ac,v.An)
hold on
barwitherr(stats.se, abs(b));
title(['Logistic Regression: Choice onto Task Variables [' strjoin(p.inits,',') ']'],'FontSize',14);
set(gca,'XTick',1:length(labels),'XTickLabel',labels,'FontSize',14);
xlabel('Predictors','FontSize',14);
ylabel('ABS(B value)','FontSize',14);
hold off

end

function PlotSteveAlphas            %  5
%***** PLOT PYTHON OUTPUT ALPHAS
global v; global p;

%*** B,J
alphas = [4.1773902 0.898256 1.94441461 2.99755044 1.77436472 1.75732366];
alphasO = [1.67232857 0.96958226 0.99797671 0.99868694 0.67103107 (1.72341825e-09)];

%Behavior: [0, array([ 4.1800459]), array([ 0.88385938]), array([ 2.08594889]), array([ 2.98922245]), array([ 1.79820129])]
%Optimal: [0, array([ 1.71236722]), array([ 0.92198294]), array([ 0.9979046]), array([ 0.99511741]), array([ 0.66909234])]

%**
%*** B
%alphas = [ ];
%alphasO = [ ];
%**
%*** J
%alphas = [ ];
%alphasO = [ ];
%**
subplot(v.Ar,v.Ac,v.An)
hold on
plot(alphas, p.colors{1},'LineWidth',2,'MarkerSize',4)
plot(alphasO, p.colors{2},'LineWidth',2,'MarkerSize',4)
title(['Fitted Alphas Over Tokens [' strjoin(p.inits,',') '] (n=' num2str(length(v.cho ~= -1)) ')'],'FontSize',14);
legend({'Behavior','Optimal'});
set(gca,'XTick',1:6,'XTickLabel',0:5,'FontSize',14);
xlabel('Tokens','FontSize',14);
ylabel('Alpha','FontSize',14);
hold off

end