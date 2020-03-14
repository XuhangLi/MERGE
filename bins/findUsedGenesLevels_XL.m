function [gene_id, gene_expr] = findUsedGenesLevels_XL(model, exprData, printLevel)
% Returns vectors of gene identifiers and corresponding gene expression
% levels for each gene present in the model ('model.genes').
%
% USAGE:
%    [gene_id, gene_expr] = findUsedGenesLevels(model, exprData)
%
% INPUTS:
%
%   model:               input model (COBRA model structure)
%
%   exprData:            mRNA expression data structure
%       .gene                cell array containing GeneIDs in the same
%                            format as model.genes
%       .value               Vector containing corresponding expression value (FPKM)
%
% OPTIONAL INPUTS:
%    printLevel:         Printlevel for output (default 0);
%
% OUTPUTS:
%
%   gene_id:             vector of gene identifiers present in the model
%                        that are associated with expression data
%
%   gene_expr:           vector of expression values associated to each
%                        'gened_id'
%
%   
% Authors: - S. Opdam & A. Richelle May 2017
% 08072019 modified by XL. set the default score as 0 instead of -1.
% meaning that those undetected genes will be taken as zero expression
% instead of being exluded
% 08072019 it conflicts with ND,NA gene and complicated the problem,
% disgard this modification
if ~exist('printLevel','var')
    printLevel = 0;
end

gene_expr=[];
gene_id = model.genes;

for i = 1:numel(gene_id)
        
    cur_ID = gene_id{i};
	dataID=find(ismember(exprData.gene,cur_ID)==1);
	if isempty (dataID)
    	gene_expr(i)= 0; %here, changed from -1 to 0!!
    elseif length(dataID)==1
    	gene_expr(i)=exprData.value(dataID);
    elseif length(dataID)>1    	
        if printLevel > 0
            disp(['Double for ',num2str(cur_ID)])
        end
    	gene_expr(i)=mean(exprData.value(dataID));
    end
end
           
end