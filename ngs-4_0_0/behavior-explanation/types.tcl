NGS_DeclareType NGS_Explain_Explanation {
	agent-id ""
	context-variables ""
	current-goal-hierarchy ""
	task-awareness ""
	internal-operating-picture ""
}

NGS_DeclareType NGS_Explain_ContextVariables {}

NGS_DeclareType NGS_Explain_Variable {
	variable-type ""
	scope ""
	id ""
	name ""
	value ""
}

NGS_DeclareType NGS_Explain_VariableIdSet {}

NGS_DeclareType NGS_Explain_VariablePool {}

NGS_DeclareType NGS_Explain_VariablePools {}

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

NGS_DeclareType NGS_Explain_Task {
    id ""
    task-my-type ""
}

NGS_DeclareType NGS_Explain_DecisionSet {
    type Set
}

NGS_DeclareType NGS_Explain_Decision {
    name ""
}

NGS_DeclareType NGS_Explain_VariablePools {
    pool ""
}

NGS_DeclareType NGS_Explain_VariablePool {
    id ""
    name ""
}

# TODO: Fill in
NGS_DeclareType NGS_Explain_TaskAwareness {}

# TODO: Fill in
NGS_DeclareType NGS_Explain_InternalOperatingPicture {}




###################### Spatial Types ############################
# These are the built in IOP spatial object types. Feel free to derive
#  from them to create your own.

# Root spatial object (all spatial objects should inherit from this)
NGS_DeclareType IOPSpatialObject {
    name     ""
    children ""
    location ""
}

NGS_DeclareType IOPPoint {
    type IOPSpatialObject
}

NGS_DeclareType IOPDestination {
    type { IOPSpatialObject IOPPoint }
}

NGS_DeclareType IOPWaypoint {
    type { IOPSpatialObject IOPPoint }
}

NGS_DeclareType IOPArea {
    type IOPSpatialObject
}

NGS_DeclareType IOPCircle {
    type { IOPSpatialObject IOPArea }
    radius ""
}

NGS_DeclareType IOPPolygon {
    type { IOPSpatialObject IOPArea }
    points ""
}

NGS_DeclareType IOPPolyLine {
    type IOPSpatialObject
    points ""
}

NGS_DeclareType IOPRoute {
    type { IOPSpatialObject IOPPolyLine }
    route-id ""
}

NGS_DeclareType IOPPhaseLine {
    type { IOPSpatialObject IOPPolyLine }
}

NGS_DeclareType IOPOrientedObject {
    type IOPSpatialObject
    orientation ""
}

NGS_DeclareType IOPMovingObject {
    type { IOPSpatialObject IOPOrientedObject }
    velocity ""
}

NGS_DeclareType IOPEntity {
    type { IOPSpatialObject IOPOrientedObject IOPMovingObject }
}

NGS_DeclareType IOPHuman {
    type { IOPSpatialObject IOPOrientedObject IOPMovingObject IOPEntity }
}

NGS_DeclareType IOPVehicle {
    type { IOPSpatialObject IOPOrientedObject IOPMovingObject IOPEntity }
}

NGS_DeclareType IOPUGV {
    type { IOPSpatialObject IOPOrientedObject IOPMovingObject IOPEntity IOPVehicle }
}

NGS_DeclareType IOPUAV {
    type { IOPSpatialObject IOPOrientedObject IOPMovingObject IOPEntity IOPVehicle }
}
