all:
	coqc sflib.v
	coqc Common.v
	coqc Memory.v
	coqc Value.v
	coqc Lang.v
	coqc LoadStore.v
	coqc State.v
	coqc Behaviors.v
	coqc WellTyped.v
	coqc SmallStep.v
	coqc SmallStepAux.v
	coqc SmallStepWf.v
	coqc SmallStepTest.v
	coqc Refinement.v
	coqc SmallStepRefinement.v
	coqc Reordering.v
	coqc TwinExecution.v
	coqc TwinExecutionAux.v
	coqc TwinExecutionProof.v
	coqc GVN1.v
	coqc GVN2.v
	coqc GVN3.v
	coqc GVN4.v
