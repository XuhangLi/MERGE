function model = defineConstriants(model, infDefault,smallFluxDefault)
% This function is to define the uptake constrainst for a native human
% model RECON2.2. It is not designed or tested for any other model.
%
% USAGE:
%
%    model = defineConstriants(model, infDefault,smallFluxDefault)
%
% INPUTS:
%    model:             input RECON2.2 model (COBRA model structure)
%    infDefault:        the default value for infinite fluxes
%    smallFluxDefault:  the default value for trace uptake fluxes
%
% OUTPUT:
%   model:              the constrianed model
%
% `Yilmaz et al. (2020). Final Tittle and journal.
% .. Author: - Xuhang Li, Mar 2020

% set infinite
model.ub(isinf(model.ub)) = infDefault;
model.lb(isinf(model.lb)) = -infDefault;
% open all exchange to a small flux default
model.lb(cellfun(@(x) ~isempty(regexp(x,'^EX_','once')),model.rxns)) = -smallFluxDefault;
model.lb(cellfun(@(x) ~isempty(regexp(x,'^sink_','once')),model.rxns)) = -smallFluxDefault;
% define the freely avaiable inorganic media content 
media = {'EX_ca2(e)',...
        'EX_cl(e)',...
        'EX_fe2(e)',...
        'EX_fe3(e)',...
        'EX_h(e)',...
        'EX_h2o(e)',...
        'EX_k(e)',...
        'EX_na1(e)',...
        'EX_nh4(e)',...
        'EX_so4(e)',...
        'EX_pi(e)',...
        'EX_o2(e)'};
model.lb(ismember(model.rxns,media)) = -infDefault;% media ion set to free

% define the vitamin input
vitamins = {'EX_btn(e)',...
        'EX_chol(e)',...
        'EX_pnto_R(e)',...
        'EX_fol(e)',...
        'EX_ncam(e)',...
        'EX_pydxn(e)',...
        'EX_ribflv(e)',...
        'EX_thm(e)',...
        'EX_adpcbl(e)',...
        };
model.lb(ismember(model.rxns,vitamins)) = -infDefault;%anything available in the media is free
% set the maintaince
model = changeRxnBounds(model,'DM_atp_c_','l',0);%no NGAM

AA = {'EX_his_L(e)';'EX_ala_L(e)';'EX_arg_L(e)';'EX_asn_L(e)';'EX_asp_L(e)';'EX_thr_L(e)';'EX_gln_L(e)';'EX_glu_L(e)';'EX_gly(e)';'EX_ile_L(e)';'EX_leu_L(e)';'EX_lys_L(e)';'EX_met_L(e)';'EX_phe_L(e)';'EX_pro_L(e)';'EX_ser_L(e)';'EX_trp_L(e)';'EX_tyr_L(e)';'EX_val_L(e)';'EX_cys_L(e)'};
model.lb(ismember(model.rxns,AA)) = -infDefault;
model.lb(ismember(model.rxns,{'EX_gln_L(e)'})) = -infDefault;
model.lb(ismember(model.rxns,{'EX_gthrd(e)'})) = -infDefault;
model.lb(ismember(model.rxns,{'EX_glc(e)'})) = -infDefault;%major carbon source in the media

% we fix few blocked reactions by adding transporters
if ~any(strcmp(model.rxns,'transport_dhap'))%not modified model
    % fix some conflicts between model reconstruction and the flux data
    % dhap can only be uptaken but cannot carry influx ==> add a transport rxn
    model = addReaction(model,['transport_dhap'],'reactionFormula','dhap[e] <==> dhap[c]','geneRule', 'NA','printLevel',1);
    % EX_hom_L(e) cannot carry flux ==> add a celluar demand for this
    % it is a co-transporting circular met
    model = addDemandReaction(model,'hom_L[c]');
    % EX_sbt-d(e) can only be uptaken but cannot carry influx ==> change transport reversibility
    model.lb(strcmp(model.rxns,'SBTle')) = -infDefault;
end
end
