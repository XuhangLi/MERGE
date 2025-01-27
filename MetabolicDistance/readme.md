This guidance shows how to use MetabolicDistance.py tool to find distances between reactions in a metabolic network model. 

### Finding distance from a reaction of interest to all other reactions

Step-by-step instructions to find distances from a particular reaction of interest (ROI) in the network to all other (reachable) reactions is provided in walkthrough.py. 

The input for this exercise is provided in [Input](./Input/) folder and consists of a stoichioetry matrix (S; rows represent metabolites and columns reactions), list of metabolites (in the same order as in S), list of reactions (in the same order as in S), two lists showing upper and lower boundaries of these reactions (in the same order as in the reaction list), and a list of byproduct metabolites (arbirary order). The example files provided were generated for the <i>C. elegans</i> metabolic network model iCEL1314 (indicated by "regular" in file names) and the dual-tissue version of this model (indicated by "dual" in file names). The tool can be used with any metabolic network provided that the input objects (S matrix, reaction list, <i>etc.</i>) are available in text files or generated by other means.  

Note that the algorithm redefines every reaction in the metabolic model to a forward and/or a reverse reaction (an irreversible reaction is converted to only one of these two), and names these redefined reactions with "f" and "r" in the end of reaction ID, respectively. Thus the directionality label should be included in the ROI ID when using MetabolicDistance module.

For other types of analyses that MetabolicDistance.py can offer, use guidelines for each function of this module:
<i>e.g.</i>
help(MetabolicDistance.rxnnetwork.findForwardLoops)

### Finding distance from every reaction to every other

To obtain a global distance matrix that shows the distance from every reaction (rows) to every other reaction (columns) the network must be traversed from every reaction using the commands provided in walkthrough.py. Doing this by placing the commands in a for loop is an option, but can take many hours if not parallelized. How all distances can be efficiently calculated using a computer cluster is demonstrated using an example pipeline of three codes (see files with names formatted as "exampleCluster_xxx.py").

Run exampleCluster_caller.py to derive distances to all reactions from every possible reaction of interest (ROI) (ROI ID includes directionality, see above). This program repeatedly calls exampleCluster_function.py for each reaction in the network (with directionality) designated as ROI. The output for each ROI is saved in [Reactions](./Output/Reactions/) folder as a pickled tuple object of three elements (a dictionary of paths as reaction ID -> shortest path as a list of reactions, list of reactions that had loops fixed to obtain a valid path, list of reactions that gave error). Verbal output is written for each ROI to [Nohup](./Output/Nohup/) folder.

Run exampleCluster_interpreter.py to generate a distance matrix (distances from reactions in rows to reactions in columns) and save in text format to [Output](./Output/) folder.

The example calculation was carried out in [Massachusetts Green High Performance Computing Center](https://www.mghpcc.org/). This cluster uses LSF as job scheduler. The same code should be applicable in any high performance computing center using LSF, with minor modifications in job description if necessary. 



