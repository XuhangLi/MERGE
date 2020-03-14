function [result, status] = eval_gpr(rule, genes, levels, f_and, f_or)

EVAL_OK = 1;
PARTIAL_MEASUREMENTS = 0;
NO_GPR_ERROR = -1;
NO_MEASUREMENTS = -2;
MAX_EVALS_EXCEEDED = -3;

MAX_EVALS = 1000;
NONETYPE = 'NaN';% by default, the undetected genes are ?

NUMBER = '[0-9\.\-e]+';
MAYBE_NUMBER = [NUMBER '|' NONETYPE];

expression = rule;
result = 'NaN';
status = EVAL_OK;

if isempty(expression)
    status = NO_GPR_ERROR;
else
    rule_genes = setdiff(regexp(expression,'\<(\w|\-|\.)+\>','match'), {'and', 'or'});

    total_measured = 0;

    for i = 1:length(rule_genes)
        j = find(strcmp(rule_genes{i}, genes));
        if isempty(j)
            level = NONETYPE;
        else
            level = num2str(levels(j));
            total_measured = total_measured + 1;
        end
        expression = regexprep(expression, ['\<', rule_genes{i}, '\>'], level );
    end
    if total_measured < length(rule_genes)
        status = PARTIAL_MEASUREMENTS;
    end
    if total_measured > 1 %processing multiple gene GPR measurement
        expression_logic = freezeANDlogic(expression);
        maybe_and = @(a,b)maybe_functor(f_and, a, b);
        maybe_or = @(a,b)maybe_functor(f_or, a, b); 
        str_wrapper = @(f, a, b)num2str(f(str2double(a), str2double(b)));

        counter = 0;

        %fold all the or connected genes
        while contains(expression_logic,'or') 
            counter = counter + 1;
            if counter > MAX_EVALS
                status = MAX_EVALS_EXCEEDED;
                break
            end
            paren_expr = ['\(\s*(', MAYBE_NUMBER,')\s*\)'];
            and_expr = ['(',MAYBE_NUMBER,')\s+and\s+(',MAYBE_NUMBER,')'];
            or_expr = ['(',MAYBE_NUMBER,')\s+or\s+(',MAYBE_NUMBER,')'];
            len_pre = length(expression_logic);
            expression_logic = regexprep(expression_logic, and_expr, '${str_wrapper(maybe_and, $1, $2)}');
            expression_logic = regexprep(expression_logic, or_expr, '${str_wrapper(maybe_or, $1, $2)}');
            len_post = length(expression_logic);
            if len_pre == len_post %wrap needed
                expression_logic = regexprep(expression_logic, paren_expr, '$1');
            end
            expression_logic = freezeANDlogic(regexprep(expression_logic,'[fz_|_fz]','')); % freeze the exposed AND
        end
        result = regexprep(expression_logic,'[fz_|_fz|(|)]','');
        result = regexprep(result,' +',' ');

    elseif total_measured == 0
        status = NO_MEASUREMENTS;
        result = 'NaN';
    else %only one measurement; just put the measurement there
        % remove all possible symbols
        result = regexprep(expression,'[ |(|)]','');
    end
end

%post processing ==> convert to the matrix in cell
result = str2double(strsplit(result,' and '));
end
function c = maybe_functor(f, a, b)
    
    if isnan(a) && isnan(b)
        c = nan;
    elseif ~isnan(a) && isnan(b)
        c = a;
    elseif isnan(a) && ~isnan(b)
        c = b;
    else 
        c = f(a,b);
    end
end