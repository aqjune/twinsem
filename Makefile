all:
	coqc sflib.v
	coqc Common.v
	coqc Memory.v
	coqc Value.v
	coqc Lang.v
	coqc State.v
	coqc LoadStore.v WellTyped.v
	coqc SmallStep.v
