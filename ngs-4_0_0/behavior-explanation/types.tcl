NGS_DeclareType NGS_Explain_Explanation {
	agent-id ""
	context-variables ""
	current-goal-hierarchy ""
	task-awareness ""
	internal-operating-picture ""
}

NGS_DeclareType NGS_Explain_Variable {
	variable-type ""
	scope ""
	id ""
	name ""
	value ""
}

# There are three types of scopes.
# The meaning of the parameters for each of the three types is as follows:
# 
# scope-type     : global        | goal          | user
# scope-id       : pool_id       | goal_id       | object_id
# scope-path     : pool name     | goal name     | full path
# scope-category : category_name | category_name | "user-location"
#
NGS_DeclareType NGS_Explain_VariableScope {
	scope-type ""
	scope-id ""
	scope-path ""
    scope-category ""
}

NGS_DeclareType NGS_Explain_GoalHierarchy {
	roots ""
	goals ""
}

NGS_DeclareType NGS_Explain_Goal {
	id ""
	selected ""
	goal-my-type ""
	goal-types ""
	children ""
	reasons ""
}

# TODO: Fill in
NGS_DeclareType NGS_Explain_TaskAwareness {}

# TODO: Fill in
NGS_DeclareType NGS_Explain_InternalOperatingPicture {}
