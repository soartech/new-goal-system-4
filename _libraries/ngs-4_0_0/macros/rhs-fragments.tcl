
#
# add a tag to the given 'tags' structure.
#
proc ngs-tag {tags_id tag_name {tag_value ""}} {
  CORE_RefMacroVars
  CORE_SetIfEmpty tag_value $NGS_YES
  return "($tags_id ^$tag_name $tag_value)"
}

#
# Marks a goal as achieved (sets the NGS_GS_ACHIEVED attribute
#  to NGS_YES
#
proc ngs-tag-goal-achieved { goal_tags_id } {
  CORE_RefMacroVars
  return "($goal_tags_id ^$NGS_GS_ACHIEVED $NGS_YES)"
}

# Create a basic object.
#
# Base class objects by default only specify a tags substructure
# Otherwise they are empty. 
#
# parent_obj_id: the identifier for the object that will contain the new object
# attribute: the attribute to which the new object should be attached
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
# new_obj_prefs: The preferences for the new object (typically only used for operators)
proc ngs-create-object { parent_obj_id 
                         attribute
                         new_obj_id
                         {new_obj_tags_id ""} 
                         {new_obj_prefs ""} } {

  CORE_RefMacroVars
  CORE_GenVarIfEmpty new_obj_tags_id "tags"
    
 	return "($parent_obj_id ^$attribute $new_obj_id $new_obj_prefs)
 	        ($new_obj_id    ^tags       $new_obj_tags_id)"
 	        
}

# Create an object that has a name
#
# parent_obj_id: the identifier for the object that will contain the new object
# attribute: the attribute to which the new object should be attached
# name: the name of the object (used for operators)
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
# new_obj_prefs: The preferences for the new object (typically only used for operators)
proc ngs-create-named-object { parent_obj_id 
                               attribute
                               name
                               new_obj_id
                               {new_obj_tags_id ""} 
                               {new_obj_prefs ""} } {

  CORE_RefMacroVars
  CORE_GenVarIfEmpty new_obj_tags_id "tags"
        
 	return "[ngs-create-object $parent_obj_id \
                             $attribute \
 	                           $new_obj_id \
 	                           $new_obj_tags_id \
                             $new_obj_prefs]
 	        ($new_obj_id ^name $name)" 	        
}

# Create an object that has a name
#
# parent_obj_id: the identifier for the object that will contain the new object
# attribute: the attribute to which the new object should be attached
# type: the type of the object (used for goals)
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-typed-object { method
                               parent_obj_id 
                               attribute
                               type
                               new_obj_id
                               {state_id ""}
                               {new_obj_tags_id ""} } {

  CORE_RefMacroVars
  CORE_GenVarIfEmpty new_obj_tags_id "tags"

  if { $method == $NGS_PROPOSE_OPERATOR } {
    return "[ngs-create-atomic-operator $state_id $NGS_OP_CREATE_OBJECT <o>]
            (<o> ^dest-object    $parent_obj_id
                 ^dest-attribute $attribute)
            [ngs-create-object <o> new-obj $new_obj_id $new_obj_tags_id]
            ($new_obj_id ^type $type)"
  } else {
    return "[ngs-create-object $parent_obj_id $attribute $new_obj_id $new_obj_tags_id]
            ($new_obj_id ^type $type)"          
  }
}

#
# Add default body to an object (if id already exists)
#
proc ngs-create-typed-object-structure { new_obj_id
                                         type
                                         {new_obj_tags_id ""} } {

  CORE_RefMacroVars
  CORE_GenVarIfEmpty new_obj_tags_id "tags"

  return "($new_obj_id ^tags $new_obj_tags_id
                       ^type $type)"          
}

# Create an operator
#
# This creates a basic operator without a specified behavior type. Typically you
#  will not use this. Instead use create-atomic-operator or create-decide-operator.
#
# state_id: If provided, the soar variable that is bound to the state in which to
#  create the operator.
# op_name: the name of the operator
# behavior: One of NGS_OP_ATOMIC or NGS_OP_DECIDE. Atomic operators are should be
#  applied immediately after selection while Decide operators should create operator
#  no change impasses.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object. The default is <o#>
# add_prefs: Additional preferences beyond acceptable ('+'). By default this is the
#  indifferent preference ('='). So by default an operator gets the + = preferences.
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-operator { state_id
                           op_name
                           behavior
                           {new_obj_id ""}
                           {add_prefs "="}
                           {new_obj_tags_id ""} } {

  CORE_RefMacroVars
  CORE_GenVarIfEmpty new_obj_id "o"
  CORE_GenVarIfEmpty state_id "s"
    
  return "[ngs-create-named-object $state_id \
                                    $NGS_OP_ATTRIBUTE \
                                    $op_name \
                                    $new_obj_id \
                                    $new_obj_tags_id \
                                    "+ $add_prefs"]
            ($new_obj_id ^behavior $behavior)"
    
}

# Create an atomic operator
#
# An atomic operator has the "behavior" attribute set to NGS_OP_ATOMIC. Atomic
#  operators should be applied immediately after selection and should not generate
#  substates.
#
# state_id: If provided, the soar variable that is bound to the state in which to
#  create the operator.
# op_name: the name of the operator
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object. The default is <o#>
# add_prefs: Additional preferences beyond acceptable ('+'). By default this is the
#  indifferent preference ('='). So by default an operator gets the + = preferences.
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-atomic-operator { state_id
                                  op_name
                                  new_obj_id
                                 {add_prefs "="}
                                 {new_obj_tags_id ""} } {
  CORE_RefMacroVars
  return "[ngs-create-operator $state_id \
                               $op_name \
                               $NGS_OP_ATOMIC \
                               $new_obj_id \
                               $add_prefs \
                               $new_obj_tags_id]"                                 
}
            
# Create a decision operator
#
# Decision operators have their behavior attribute set to NGS_OP_DECIDE. Decision operators
#  should not have apply productions and should instead trigger an operator no change.
#  In the sub-state the operator's actions can be determined and sequenced. Return
#  values are set via the ngs-add-ret-val macro. If an operator needs to set static
#  flags or return values in order to properly return, these can be passed into the 
#  substate via the ret_val_list parameter.
#
# state_id: If provided, the soar variable that is bound to the state in which to
#  create the operator. 
# op_name: the name of the operator
# behavior: One of NGS_OP_ATOMIC or NGS_OP_DECIDE. Atomic operators are should be
#  applied immediately after selection while Decide operators should create operator
#  no change impasses.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object. The default is <o#>
# add_prefs: Additional preferences beyond acceptable ('+'). By default this is the
#  indifferent preference ('='). So by default an operator gets the + = preferences.
# ret_val_list: A list of tuples that describe one or more return value structures
#  that should be copied onto the sub-state. Use this list when you know in advance
#  (e.g. at operator proposal time) one or more of the values you need to set when
#  the sub-goal completes (e.g. "complete" flags). See ngs-create-op-ret-val to 
#  see the structure of ret-value objects. Example: {{<my-goal-tags> processed $NGS_YES}} 
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-decide-operator { state_id
                                  op_name
                                  new_obj_id
                                  ret_val_set_id
                                  goal_id
                                 {add_prefs "="}
                                 {new_obj_tags_id ""} } {

   CORE_RefMacroVars
    
   return  "[ngs-create-operator $state_id \
                                 $op_name \
                                 $NGS_OP_DECIDE \
                                 $new_obj_id \
                                 $add_prefs \
                                 $new_obj_tags_id]
            ($new_obj_id ^goal          $goal_id
                         ^return-values $ret_val_set_id)"
}

# Create a basic goal
#
# Typically you should not call this method. Instead call ngs-create-achievement-goal
#  to create a goal that goes away when achieved and ngs-create-maintenance-goal to 
#  create a goal that remains after becoming achieved.
#
# named_goal_set_id: a Soar variable bound to the goal set into which to place the goal
#  In NGS 4, this is not the top level goal set (under top-state.goals), instead it is
#  one level lower under the goal's name (top-state.goals.goal-name <named_goal_set_id>).
# goal_name: name of the goal. There should only be one goal name.
# behavior: One of NGS_GB_ACHIEVE or NGS_GB_MAINT for achievement or maintenance goal
#  respectively
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# supergoal_id: If provided, this will be the goal's supergoal
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-goal { method
                       named_goal_set_or_state_id
                       goal_name
                       behavior
                       new_obj_id
                       {supergoal_id ""}
                       {new_obj_tags_id ""} } {

    CORE_RefMacroVars
    
    variable lhs_val

    if { $method == $NGS_PROPOSE_OPERATOR } {
      set lhs_val "[ngs-create-atomic-operator $named_goal_set_or_state_id $NGS_OP_CREATE_GOAL <o>]
                   [ngs-create-named-object <o> new-obj $goal_name $new_obj_id $new_obj_tags_id]
                   ($new_obj_id ^behavior $behavior)"
                   
    } else {
      set lhs_val "[ngs-create-named-object $named_goal_set_or_state_id goal $goal_name $new_obj_id $new_obj_tags_id]
                   ($new_obj_id ^behavior $behavior)"
    }

    if { $supergoal_id != "" } { set lhs_val "$lhs_val\n($new_obj_id ^supergoal $supergoal_id" }

    return $lhs_val   
}        

# Create an achievement goal
#
# Create a goal that goes away after being achieved. If you are creating the goal
#  via i-support, this is automatic using the i-support system. If you are creating
#  a goal via o-support, an NGS operator will be proposed to remove it once the goal 
#  is tagged as achieved.
#
# named_goal_set_id: a Soar variable bound to the goal set into which to place the goal
#  In NGS 4, this is not the top level goal set (under top-state.goals), instead it is
#  one level lower under the goal's name (top-state.goals.goal-name <named_goal_set_id>).
# goal_name: name of the goal. There should only be one goal name.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# supergoal_id: If provided, this will be the goal's supergoal
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-achievement-goal { method
                                   named_goal_set_or_state_id
                                   goal_name
                                   new_obj_id
                                   {supergoal_id ""}
                                   {new_obj_tags_id ""} } {
    
    CORE_RefMacroVars
    return "[ngs-create-goal $method \
                             $named_goal_set_or_state_id \
                             $goal_name \
                             $NGS_GB_ACHIEVE \
                             $new_obj_id \
                             $supergoal_id \
                             $new_obj_tags_id]"
   
}                  

# Create a maintance goal
#
# Create a goal that remained. If you are creating the goal
#  via i-support, this is automatic using the i-support system. If you are creating
#  a goal via o-support, an NGS operator will be proposed to remove it once the goal 
#  is tagged as achieved.
#
# named_goal_set_id: a Soar variable bound to the goal set into which to place the goal
#  In NGS 4, this is not the top level goal set (under top-state.goals), instead it is
#  one level lower under the goal's name (top-state.goals.goal-name <named_goal_set_id>).
# goal_name: name of the goal. There should only be one goal name.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# supergoal_id: If provided, this will be the goal's supergoal
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-maintenance-goal { method
                                   named_goal_set_or_state_id
                                   goal_name
                                   new_obj_id
                                   {supergoal_id ""}
                                   {new_obj_tags_id ""} } {

    CORE_RefMacroVars
    return "[ngs-create-goal $method \
                             $named_goal_set_or_state_id \
                             $goal_name \
                             $NGS_GB_MAINT \
                             $new_obj_id \
                             $supergoal_id \
                             $new_obj_tags_id]"
   
}                  

# Creates a single return value
#
# Use this when you need to create a value to be returned from a sub-state.
# Return values can be created in the sub-states or when the original operator is
#  created (e.g. if the flag indicating the end of sub-state process is static)
#
# dest_obj_id: Identifier of the object that will get the return value
# attribute: Attribute that will hold the return value
# new_val: The actual return value (can be an identifier)
# add_to_set: a boolean that indicates whether to add new_val to a set (e.g. allow 
#  multi-valued attributes) or to replace any current value.
#
proc ngs-create-op-ret-val { ret_val_name
                             ret_val_set_id
                             dest_obj_id 
                             attribute 
                             {new_val ""} 
                             {add_to_set ""} } {

    CORE_RefMacroVars
    CORE_SetIfEmpty add_to_set $NGS_NO
    
    set ret_val_id [CORE_GenVarName new-ret-val]

    set rhs_val  "[ngs-create-typed-object $NGS_CONSTRUCT_IN_PLACE $ret_val_set_id value-description $NGS_TYPE_STATE_RETURN_VALUE $ret_val_id]
                  ($ret_val_id     ^name $ret_val_name
                                   ^destination-object $dest_obj_id
                                   ^destination-attribute $attribute
                                   ^add-to-set $add_to_set)"
    
    if { $new_val != "" } {
      set rhs_val "$rhs_val
                   ($ret_val_id ^value $new_val)"
    }

    return $rhs_val
}

#
# Constructs an operator that, when applied, sets the return value in a sub-state
#
# This operator has a default application that deep copies ret_val to the ret-val structure
#  in a substate.
#
# state_id: Id for the sub-state into which to place the return value
# ret_val: Id for the return value object (can be created with ngs-create-typed-object)
# ret_val_name: The name of the return value. You may leave this empty if there is only
#  one return value in a state. Otherwise, it is the name of the specific return value
#  to set.
proc ngs-set-ret-val { ret_val_name 
                       state_id
                       value } {

    CORE_RefMacroVars

    set rhs_val  "[ngs-create-atomic-operator $state_id $NGS_OP_SET_RETURN_VALUE <o>]
                  (<o> ^value  $value
                       ^name   $ret_val_name)"

    return $rhs_val
}


