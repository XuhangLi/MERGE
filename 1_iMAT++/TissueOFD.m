%% this is the main program to generate tissue OFDs in TableS5
%% load model
addpath ~/cobratoolbox/ %path of cobraToolBox
addpath /share/pkg/gurobi/810/linux64/matlab/ %path of gurobi solver
addpath ./../bins/
addpath ./../input/
addpath scripts/
initCobraToolbox(false);
fprintf('C. elegans Tissue Model Fitting Started... \n');
fprintf('loading model and input parameters... \n');
totalTime = tic();
load('Tissue.mat');
% The loaded model is already constrained with default constraints and
% side/storage parameters. One can modify by the following codes;
% worm = changeRxnBounds(worm,'RCC0005',10,'l');
% To change the side proportion
% worm.S(end-1, strcmp('EXC0050',worm.rxns)) = 0.01*9.6641833;%storage
% worm.S(end, strcmp('EXC0050',worm.rxns)) = 0.01*9.6641833; %side

% reset some constraints to make the model ready for integration 
% release the nutrient constraints for integration 
model = changeRxnBounds(model,'EXC0050_L',-1000,'l');
model = changeRxnBounds(model,'EX00001_E',-1000,'l');
model = changeRxnBounds(model,'EX00007_E',-1000,'l');
model = changeRxnBounds(model,'EX00009_E',-1000,'l');
model = changeRxnBounds(model,'EX00080_E',-1000,'l');

model = changeRxnBounds(model,'RM00112_I',-1000,'l');
model = changeRxnBounds(model,'RM00112_X',-1000,'l');
model = changeRxnBounds(model,'RM00112_I',1000,'u');
model = changeRxnBounds(model,'RM00112_X',1000,'u');

model = changeRxnBounds(model,'DMN0033_I',0,'l');
model = changeRxnBounds(model,'DMN0033_X',0,'l');
model = changeRxnBounds(model,'DMN0033_I',1,'u');
model = changeRxnBounds(model,'DMN0033_X',1,'u');


model = changeRxnBounds(model,'RMC0005_I',0,'l');
model = changeRxnBounds(model,'RMC0005_X',0,'l');
model = changeRxnBounds(model,'RMC0005_I',0,'u');
model = changeRxnBounds(model,'RMC0005_X',0,'u');
% parseGPR takes hugh amount of time, so pre-preparse and save result in the model
parsedGPR = GPRparser_xl(model);% Extracting GPR data from model
model.parsedGPR = parsedGPR;
%% load the gene expression data
% the processed gene categories are supplied in json format
fname = 'geneCategories.json';
str = fileread(fname);
for i = 1:length(str)
    if str(i) == "'"
        str(i) = '"';
    end
end
str = regexprep(str,'set(','');
str = regexprep(str,')','');
GeneExpression = jsondecode(str);

% we use a structure variable to store the category information
% now, make expression set for six tissues

% hypodermis
% add compartment label and merge
GeneExpression.Hypodermis.high = strcat(GeneExpression.Hypodermis.high,'_X');
GeneExpression.Hypodermis.lenient = strcat(GeneExpression.Hypodermis.lenient,'_X');
GeneExpression.Hypodermis.low = strcat(GeneExpression.Hypodermis.low,'_X');
GeneExpression.Hypodermis.zero = strcat(GeneExpression.Hypodermis.zero,'_X');
GeneExpression.Intestine.high = strcat(GeneExpression.Intestine.high,'_I');
GeneExpression.Intestine.lenient = strcat(GeneExpression.Intestine.lenient,'_I');
GeneExpression.Intestine.low = strcat(GeneExpression.Intestine.low,'_I');
GeneExpression.Intestine.zero = strcat(GeneExpression.Intestine.zero,'_I');
% merge
ExpCatag = struct();
ExpCatag.high = [GeneExpression.Hypodermis.high];
ExpCatag.low = [GeneExpression.Hypodermis.low;GeneExpression.Intestine.low];
ExpCatag.zero = [GeneExpression.Hypodermis.zero;GeneExpression.Intestine.zero];
% the "dynamic" category refers to lenient in the paper. The naming changing is
% because of historical reason. We keep calling it dynamic throughout the
% Matlab implantation package.
% all the other genes are dynamic (no constriants on) 
ExpCatag.dynamic = setdiff(model.genes, unique([ExpCatag.high;ExpCatag.low;ExpCatag.zero]));
ExpCatag_Hypodermis = ExpCatag;

% Gonad
GeneExpression.Gonad.high = strcat(GeneExpression.Gonad.high,'_X');
GeneExpression.Gonad.lenient = strcat(GeneExpression.Gonad.lenient,'_X');
GeneExpression.Gonad.low = strcat(GeneExpression.Gonad.low,'_X');
GeneExpression.Gonad.zero = strcat(GeneExpression.Gonad.zero,'_X');
ExpCatag = struct();
ExpCatag.high = [GeneExpression.Gonad.high];
ExpCatag.low = [GeneExpression.Gonad.low;GeneExpression.Intestine.low];
ExpCatag.zero = [GeneExpression.Gonad.zero;GeneExpression.Intestine.zero];
ExpCatag.dynamic = setdiff(model.genes, unique([ExpCatag.high;ExpCatag.low;ExpCatag.zero]));
ExpCatag_Gonad = ExpCatag;
% Glia
GeneExpression.Glia.high = strcat(GeneExpression.Glia.high,'_X');
GeneExpression.Glia.lenient = strcat(GeneExpression.Glia.lenient,'_X');
GeneExpression.Glia.low = strcat(GeneExpression.Glia.low,'_X');
GeneExpression.Glia.zero = strcat(GeneExpression.Glia.zero,'_X');
ExpCatag = struct();
ExpCatag.high = [GeneExpression.Glia.high];
ExpCatag.low = [GeneExpression.Glia.low;GeneExpression.Intestine.low];
ExpCatag.zero = [GeneExpression.Glia.zero;GeneExpression.Intestine.zero];
ExpCatag.dynamic = setdiff(model.genes, unique([ExpCatag.high;ExpCatag.low;ExpCatag.zero]));
ExpCatag_Glia = ExpCatag;
% Pharynx
GeneExpression.Pharynx.high = strcat(GeneExpression.Pharynx.high,'_X');
GeneExpression.Pharynx.lenient = strcat(GeneExpression.Pharynx.lenient,'_X');
GeneExpression.Pharynx.low = strcat(GeneExpression.Pharynx.low,'_X');
GeneExpression.Pharynx.zero = strcat(GeneExpression.Pharynx.zero,'_X');
ExpCatag = struct();
ExpCatag.high = [GeneExpression.Pharynx.high];
ExpCatag.low = [GeneExpression.Pharynx.low;GeneExpression.Intestine.low];
ExpCatag.zero = [GeneExpression.Pharynx.zero;GeneExpression.Intestine.zero];
ExpCatag.dynamic = setdiff(model.genes, unique([ExpCatag.high;ExpCatag.low;ExpCatag.zero]));
ExpCatag_Pharynx = ExpCatag;
% Body_wall_muscle
GeneExpression.Body_wall_muscle.high = strcat(GeneExpression.Body_wall_muscle.high,'_X');
GeneExpression.Body_wall_muscle.lenient = strcat(GeneExpression.Body_wall_muscle.lenient,'_X');
GeneExpression.Body_wall_muscle.low = strcat(GeneExpression.Body_wall_muscle.low,'_X');
GeneExpression.Body_wall_muscle.zero = strcat(GeneExpression.Body_wall_muscle.zero,'_X');
ExpCatag = struct();
ExpCatag.high = [GeneExpression.Body_wall_muscle.high];
ExpCatag.low = [GeneExpression.Body_wall_muscle.low;GeneExpression.Intestine.low];
ExpCatag.zero = [GeneExpression.Body_wall_muscle.zero;GeneExpression.Intestine.zero];
ExpCatag.dynamic = setdiff(model.genes, unique([ExpCatag.high;ExpCatag.low;ExpCatag.zero]));
ExpCatag_Body_wall_muscle = ExpCatag;
% Neurons
GeneExpression.Neurons.high = strcat(GeneExpression.Neurons.high,'_X');
GeneExpression.Neurons.lenient = strcat(GeneExpression.Neurons.lenient,'_X');
GeneExpression.Neurons.low = strcat(GeneExpression.Neurons.low,'_X');
GeneExpression.Neurons.zero = strcat(GeneExpression.Neurons.zero,'_X');
ExpCatag = struct();
ExpCatag.high = [GeneExpression.Neurons.high];
ExpCatag.low = [GeneExpression.Neurons.low;GeneExpression.Intestine.low];
ExpCatag.zero = [GeneExpression.Neurons.zero;GeneExpression.Intestine.zero];
ExpCatag.dynamic = setdiff(model.genes, unique([ExpCatag.high;ExpCatag.low;ExpCatag.zero]));
ExpCatag_Neurons = ExpCatag;
% Intestine
ExpCatag = struct();
ExpCatag.high = [GeneExpression.Intestine.high];
ExpCatag.low = [GeneExpression.Intestine.low];
ExpCatag.zero = [GeneExpression.Intestine.zero];
ExpCatag.dynamic = setdiff(model.genes, unique([ExpCatag.high;ExpCatag.low;ExpCatag.zero]));
ExpCatag_Intestine = ExpCatag;

% merge all into one structure variable 
tissues = struct();
tissues.Hypodermis = ExpCatag_Hypodermis;
tissues.Gonad = ExpCatag_Gonad;
tissues.Glia = ExpCatag_Glia;
tissues.Pharynx = ExpCatag_Pharynx;
tissues.Body_wall_muscle = ExpCatag_Body_wall_muscle;
tissues.Neurons = ExpCatag_Neurons;
tissues.Intestine = ExpCatag_Intestine;

%% load epsilon
% epsilon is also supplied as a jason file. We convert it to a vecter
% variable that in the same order as model.rxns.
fname = 'epsilon.json';
str = fileread(fname);
for i = 1:length(str)
    if str(i) == "'"
        str(i) = '"';
    end
end
str = regexprep(str,'u"','"');
epsilon = jsondecode(str);
fields = fieldnames(epsilon);
epsilon_f = 0.01*ones(length(model.rxns),1); % the default epsilon is assumed as 0.01 in this study.
epsilon_r = 0.01*ones(length(model.rxns),1);
for i = 1: length(fields)
    if epsilon.(fields{i})(2) ~= 0
        epsilon_f(strcmp(model.rxns,fields{i})) = epsilon.(fields{i})(2);
    end
    if epsilon.(fields{i})(1) ~= 0
        epsilon_r(strcmp(model.rxns,fields{i})) = epsilon.(fields{i})(1);
    end
end
%% make OFD for the six non-intestinal tissues.
names = fieldnames(tissues);
names = names(1:end-1);
for i = 1:length(names)
    fprintf('now starting to fit %s... \n',names{i});
    fitTime = tic();
    ExpCatag = tissues.(names{i});
    doLatent = 1;
    storeProp = 0.01;
    SideProp = 0.02;
    ATPm = 10;
    doMinPFD = 1;
    latentCAP = 0.05;
    modelType = 1;
    speedMode = 1;
    minLowTol = 1e-5;
    myCSM = struct(); %my context specific model
    [myCSM.OFD,myCSM.PFD,myCSM.N_highFit,myCSM.N_zeroFit,myCSM.minLow,myCSM.minTotal,myCSM.minTotal_OFD,myCSM.MILP,myCSM.MILP_PFD,myCSM.HGenes,myCSM.RLNames,myCSM.OpenGene,myCSM.latentRxn,myCSM.Nfit_latent,myCSM.wasteDW] = IMATplusplus(model,epsilon_f,epsilon_r, ExpCatag, modelType, speedMode, minLowTol, doMinPFD, doLatent,latentCAP,storeProp,SideProp, ATPm);
    save(['output/',names{i},'.mat'],'myCSM');
    eval([names{i},' = myCSM;']);
    toc(fitTime);
end
%% now do the intestine integration
% first get the average flux distribution of all six non-intestinal
% tissues.
weights = [0.16481752424244808;0.19668335945561571;0.029394841229723516;0.055442983787911716;0.35973476877630634;0.19392652250799472];%needs to order by tissuesname
fluxSum_OFD = zeros(length(model.rxns),1);
fluxSum_PFD = zeros(length(model.rxns),1);
for i = 1:length(names)
    eval(['fluxSum_OFD = ',names{i},'.OFD .* weights(i) + fluxSum_OFD;']);
end
for i = 1:length(names)
    eval(['fluxSum_PFD = ',names{i},'.PFD .* weights(i) + fluxSum_PFD;']);
end
% collapse the X compartment in the dual model to save computational power
IntestineModel_PFD = collapseX(model,'X',fluxSum_PFD);
IntestineModel_OFD = collapseX(model,'X',fluxSum_OFD);
% update parsed GPR
parsedGPR = GPRparser_xl(IntestineModel_PFD);% Extracting GPR data from model
IntestineModel_OFD.parsedGPR = parsedGPR;
IntestineModel_PFD.parsedGPR = parsedGPR;
% update the epsilon list
epsilon_new_f = 0.01 * ones(length(IntestineModel_PFD.rxns),1);
epsilon_new_r = epsilon_new_f;
for i = 1: length(IntestineModel_PFD.rxns)
    if any(ismember(IntestineModel_PFD.rxns(i), model.rxns))
        epsilon_new_f(i) = epsilon_f(ismember(model.rxns,IntestineModel_PFD.rxns(i)));
        epsilon_new_r(i) = epsilon_r(ismember(model.rxns,IntestineModel_PFD.rxns(i)));
    end
end
% integration 
fprintf('now starting to fit %s... \n','Intestine');
fitTime = tic();
ExpCatag = tissues.Intestine;
doLatent = 1;
storeProp = 0.01;
SideProp = 0.02;
ATPm = 10;
doMinPFD = 1;
latentCAP = 0.05;
modelType = 1;
speedMode = 1;
minLowTol = 1e-5;
myCSM = struct(); %my context specific model
% PFD fitting
[~,myCSM.PFD,myCSM.N_highFit,myCSM.N_zeroFit,myCSM.minLow,myCSM.minTotal,~,~,myCSM.MILP_PFD,myCSM.HGenes,myCSM.RLNames,myCSM.OpenGene] = IMATplusplus(IntestineModel_PFD,epsilon_new_f,epsilon_new_r, ExpCatag,modelType,speedMode,minLowTol,doMinPFD, ~doLatent,latentCAP, storeProp,SideProp, ATPm);
% OFD fitting
[myCSM.OFD,~,~,~,~,~,myCSM.minTotal_OFD,myCSM.MILP,~,~,~,~,myCSM.latentRxn,myCSM.Nfit_latent,myCSM.wasteDW] = IMATplusplus(IntestineModel_OFD,epsilon_new_f,epsilon_new_r, ExpCatag, modelType, speedMode, minLowTol, doMinPFD, doLatent,latentCAP,storeProp,SideProp, ATPm);
save('output/Intestine.mat','myCSM');
toc(fitTime);
fprintf('C. elegans Tissue Model Fitting Completed! \n');
toc(totalTime);
