function [FluxDistribution, latentRxn,Nfit_latent, minTotal] = fitLatentFluxes(MILProblem, model, PFD, Hgenes, epsilon_f,epsilon_r,latentCAP)
% the input MILP should have Nfit constraint, MinLow and 101%TotalFQlux constraint already
% (identical to the MILP before final flux minmization)
% NOTE: the last line in MILP must be the minTotal constraint!
% tip: the MILP in the final flux minization could be used directly, the
% objective will be changed anyway.
% 0811 this function is modified to meet with Safak's algorithm, so
% multiple details are adjusted!
%% take notes on the minTotal constriant!
minTotalInd = length(MILProblem.b);
fprintf('the total flux is constrianed to %.2f \n',MILProblem.b(end));
%% define candidate reactions from HGene list
latentCandi = {};
for i = 1:length(model.rxns)
    mygenes = model.genes(logical(model.rxnGeneMat(i,:)));
    if all(ismember(mygenes,Hgenes)) && ~isempty(mygenes) %note empty is not desired!
        latentCandi = [latentCandi;model.rxns(i)];
    end
end
fprintf('starting the latent fitting loop... \n');
%% start of the loop
latentRxn = {};
count = 0;
while 1
    tic()
    %% define latent reactions
    % get flux capable reaction list 
    fluxProduct = model.S .* PFD';
    MetFlux = sum(abs(fluxProduct),2) / 2;
    %for i = 1:length(model.mets)
    %    fluxProduct = (PFD(model.S(strcmp(model.mets,model.mets{i}),:)~=0) .* (model.S(strcmp(model.mets,model.mets{i}),model.S(strcmp(model.mets,model.mets{i}),:)~=0))');
    %    MetFlux(i) = sum(fluxProduct(fluxProduct >0));
    %end
    FluxCapMet = model.mets(MetFlux >= 1e-5); %the numerical tolerance is 1e-5
    % get the new latent rxns set
    newLatent = {};
    for i = 1:length(latentCandi)
        metsF = model.mets(model.S(:,strcmp(model.rxns,latentCandi{i}))<0);
        metsF(cellfun(@(x) ~isempty(regexp(x,'NonMetConst', 'once')),metsF)) = [];
        metsR = model.mets(model.S(:,strcmp(model.rxns,latentCandi{i}))>0);
        metsR(cellfun(@(x) ~isempty(regexp(x,'NonMetConst', 'once')),metsR)) = [];
        if ((model.lb(strcmp(model.rxns,latentCandi{i}))<0 && model.ub(strcmp(model.rxns,latentCandi{i}))>0) && ((all(ismember(metsF,FluxCapMet))&& ~isempty(metsF)) || (all(ismember(metsR,FluxCapMet))&& ~isempty(metsR))))...% reversible & one side mets all have flux
           ||...
            ((model.lb(strcmp(model.rxns,latentCandi{i}))>=0) && (all(ismember(metsF,FluxCapMet))&& ~isempty(metsF)))...% irreversible & reactant side mets all have flux    
           ||...
            ((model.ub(strcmp(model.rxns,latentCandi{i}))<=0) && (all(ismember(metsR,FluxCapMet))&& ~isempty(metsR))) % irreversible & product side mets all have flux
            newLatent = [newLatent;latentCandi(i)];
        end
    end
    newLatent = newLatent(~ismember(newLatent,model.rxns(abs(PFD)>=1e-5)));% only the closed reaction in PFD are latent
    % union new latent reaction with previous latent reaction!
    % no new latent rxns?
    if isempty(setdiff(newLatent,latentRxn))
        fprintf('...done! \n');
        break;
    else
        fprintf('...found %d new latent rxns \n',length(setdiff(newLatent,latentRxn)));
        latentRxn = union(latentRxn,newLatent);
    end
    %% maximaze number of "on" latent reaction (like iMAT but without minimize low!)
    [A B] = ismember(latentRxn,model.rxns);
    latentInd = B(A);
    epsilon_f_sorted = epsilon_f(latentInd);
    epsilon_r_sorted = epsilon_r(latentInd);
    % Creating A matrix
    A = [MILProblem.A sparse(size(MILProblem.A,1),2*length(latentRxn));...
        sparse(2*length(latentRxn),size(MILProblem.A,2)) sparse(2*length(latentRxn),2*length(latentRxn))];
    for i = 1:length(latentRxn)
        A(i+size(MILProblem.A,1),latentInd(i)) = 1;
        A(i+size(MILProblem.A,1),i+size(MILProblem.A,2)) = model.lb(latentInd(i)) - epsilon_f_sorted(i);
        A(i+size(MILProblem.A,1)+length(latentRxn),latentInd(i)) = 1;
        A(i+size(MILProblem.A,1)+length(latentRxn),i+size(MILProblem.A,2)+length(latentRxn)) = model.ub(latentInd(i)) + epsilon_r_sorted(i);
    end
    % variable type
    vartype1(1:size(MILProblem.A,2),1) = MILProblem.vartype;
    vartype2(1:2*length(latentRxn),1) = 'B';
    vartype = [vartype1;vartype2];
    % Creating csense
    csense1(1:size(MILProblem.A,1)) = MILProblem.csense;
    csense2(1:length(latentRxn)) = 'G';
    csense3(1:length(latentRxn)) = 'L';
    csense = [csense1 csense2 csense3];
    % Creating lb and ub
    lb_y = zeros(2*length(latentRxn),1);
    ub_y = ones(2*length(latentRxn),1);
    lb = [MILProblem.lb;lb_y];
    ub = [MILProblem.ub;ub_y];
    % Creating c
    c_v = zeros(size(MILProblem.A,2),1);
    c_y = ones(2*length(latentRxn),1);
    c = [c_v;c_y];
    % Creating b
    b_s = MILProblem.b;
    lb_rh = model.lb(latentInd);
    ub_rh = model.ub(latentInd);
    b = [b_s;lb_rh;ub_rh];

    MILPproblem_latent.A = A;
    MILPproblem_latent.b = b;
    MILPproblem_latent.c = c;
    MILPproblem_latent.lb = lb;
    MILPproblem_latent.ub = ub;
    MILPproblem_latent.csense = csense;
    MILPproblem_latent.vartype = vartype;
    MILPproblem_latent.osense = -1;
    MILPproblem_latent.x0 = [];
    solution = solveCobraMILP_XL(MILPproblem_latent, 'timeLimit', 7200, 'logFile', 'MILPlog', 'printLevel', 0);
    if solution.stat ~= 1
        error('infeasible or violation occured!');
    end
    fprintf('...total latent fitted: %d \n',sum(solution.int(end-2*length(latentRxn)+1:end)));
    Nfit_latent = sum(solution.int(end-2*length(latentRxn)+1:end));
    %% minimize total flux to update the PFD
    MILPproblem_minFlux = solution2constraint(MILPproblem_latent,solution);
    % minimize total flux
    % NOTE: this section is specific to the MILP structure in previous
    % integration! since we use the V+ variables in the original MILProblem instead of creating new variables
    %create a new objective function
    % Creating c (objective function)
    c_minFlux = zeros(size(MILProblem.A,2),1);
    c_minFlux(end-length(model.rxns)+1:end) = ones(length(model.rxns),1);
    c = [c_minFlux;zeros(2*length(latentRxn),1)];
    MILPproblem_minFlux.c = c;
    MILPproblem_minFlux.osense = 1;
    solution = solveCobraMILP_XL(MILPproblem_minFlux, 'timeLimit', 7200, 'logFile', 'MILPlog', 'printLevel', 0);
    if solution.stat ~= 1
        error('infeasible or violation occured!');
    end
    minTotal = solution.obj;
    PFD = solution.full(1:length(model.rxns));
    count = count +1;
    fprintf('latent fitting cycle completed .... #%d \n',count);
    %% update the minTotal constriant
    MILProblem.b(minTotalInd) = minTotal*(1+latentCAP);
    fprintf('the total flux constriant is updated to %.2f \n',MILProblem.b(minTotalInd));
    toc()
end
% return the PFD
FluxDistribution = PFD;
end