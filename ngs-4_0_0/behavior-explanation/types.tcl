NGS_DeclareType NGS_Explanation {
	agent-id ""
	context-variables ""
	current-goal-hierarchy ""
	task-awareness ""
	internal-operating-picture ""
}

NGS_DeclareType NGS_ExplanationVariable {
	variable-type ""
	scope ""
	id ""
	name ""
	value ""
	value-type ""
}

NGS_DeclareType NGS_ExplanationVariableScope {
	scope-type ""
	scope-id ""
	scope-path ""
}

NGS_DeclareType NGS_ExplanationGoalHierarchy {
	roots ""
	goals ""
}

NGS_DeclareType NGS_ExplanationGoal {
	id ""
	selected ""
	goal-my-type ""
	goal-types ""
	children ""
	reasons ""
}

NGS_DeclareType NGS_ExplanationTaskAwareness {
}

NGS_DeclareType NGS_ExplanationInternalOperatingPicture {}
