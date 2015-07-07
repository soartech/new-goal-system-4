
#
# add a tag to the given 'tags' structure.
#
proc ngs-tag {obj_id tag_name {tag_value ""}} {
  CORE_RefMacroVars
  CORE_SetIfEmpty tag_value $NGS_YES
  return "($obj_id ^$NGS_TAG_PREFIX$tag_name $tag_value)"
}

#
# Marks a goal as achieved (sets the NGS_GS_ACHIEVED attribute
#  to NGS_YES
#
proc ngs-tag-goal-achieved { goal_id } {
  CORE_RefMacroVars
  return "[ngs-tag $goal_id $NGS_GS_ACHIEVED]"
}

# Create a basic object.
#
# Used to remove quote issues in some internal macros
proc ngs-create-attribute { parent_obj_id 
                            attribute
                            value
                            {prefs "+"} } {

  CORE_RefMacroVars
    
 	return "($parent_obj_id ^$attribute $value $prefs)"
 	        
}

# Create an object that has a name
#
proc ngs-create-typed-object-in-place { parent_obj_id 
		                                    attribute
		                                    type
		                                    new_obj_id 
                                        {support_type ""}} {

  CORE_RefMacroVars
  CORE_SetIfEmpty support_type $NGS_I_SUPPORT

  set rhs_val "[ngs-create-attribute $parent_obj_id $attribute $new_obj_id]
               ($new_obj_id ^type $type)"

  if { support_type == $NGS_I_SUPPORT } {
    set rhs_val "$rhs_val
                 [ngs-tag $new_obj_id $NGS_TAG_CONSTRUCTED]"
  }
    
}

proc ngs-create-typed-object-by-operator { state_id
	                                         parent_obj_id 
	                                         attribute
	                                         type
	                                         new_obj_id
	                                         {replacement_behavior ""} 
                                           {add_prefs "="}} {

  CORE_RefMacroVars
  CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

  return "[ngs-create-atomic-operator $state_id $NGS_OP_CREATE_OBJECT <o> $add_prefs]
          (<o> ^dest-object    $parent_obj_id
               ^dest-attribute $attribute
               ^replacement-behavior $replacement_behavior)
          [ngs-tag <o> $NGS_TAG_INTELLIGENT_DEEP_COPY]
          [ngs-create-typed-object-in-place <o> new-obj $type $new_obj_id $NGS_O_SUPPORT]"
}

#
# Always creates using an operator, because it's not necessary to use macros if not using operator
proc ngs-create-primitive-by-operator { state_id
                                        parent_obj_id 
                                        attribute
                                        value
                                       {replacement_behavior ""} 
                                       {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

  return "[ngs-create-atomic-operator $state_id $NGS_OP_CREATE_PRIMITIVE <o> $add_prefs]
          (<o> ^dest-object    $parent_obj_id
               ^dest-attribute $attribute
               ^new-obj        $value
               ^replacement-behavior $replacement_behavior)
          [ngs-tag <o> $NGS_TAG_INTELLIGENT_DEEP_COPY]"

}


# Create an operator
#
proc ngs-create-operator { state_id
                           op_name
                           type
                           {new_obj_id ""}
                           {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_GenVarIfEmpty new_obj_id "o"
  CORE_GenVarIfEmpty state_id "s"
    
  return "[ngs-create-attribute $state_id $NGS_OP_ATTRIBUTE $new_obj_id "+ $add_prefs"]
          ($new_obj_id ^name     $op_name
                       ^type     $type)"
    
}

# Create an atomic operator
#
# An atomic operator has the type set to NGS_OP_ATOMIC. Atomic
#  operators should be applied immediately after selection and should not generate
#  substates.
#
proc ngs-create-atomic-operator { state_id
                                  op_name
                                  new_obj_id
                                 {add_prefs "="} } {
  CORE_RefMacroVars
  return "[ngs-create-operator $state_id $op_name $NGS_OP_ATOMIC $new_obj_id $add_prefs]"                                 
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
    
   return  "[ngs-create-operator $state_id $op_name $NGS_OP_DECIDE $new_obj_id $add_prefs]
            ($new_obj_id ^goal          $goal_id
                         ^return-values $ret_val_set_id)"
}

# Create a basic goal
#
# Typically you should not call this method. Instead call ngs-create-achievement-goal
#  to create a goal that goes away when achieved and ngs-create-maintenance-goal to 
#  create a goal that remains after becoming achieved.
#
proc ngs-create-goal-in-place { goal_set_id 
                                goal_name 
                                type 
                                new_obj_id 
                                {supergoal_id ""} } {

  CORE_RefMacroVars
  variable lhs_val

  set lhs_val "[ngs-create-attribute $goal_set_id $NGS_GOAL_ATTRIBUTE $new_obj_id]
               ($new_obj_id ^name $goal_name
                            ^type $type)"

  if { $supergoal_id != "" } { set lhs_val "$lhs_val
                                            ($new_obj_id ^supergoal $supergoal_id)" }

  return $lhs_val   
}

proc ngs-create-goal-by-operator { state_id
                                   goal_name
                                   type
                                   new_obj_id
                                   {supergoal_id ""} } {

  CORE_RefMacroVars
  variable lhs_val

  set lhs_val "[ngs-create-atomic-operator $named_goal_set_or_state_id $NGS_OP_CREATE_GOAL <o>]
               [ngs-create-attribute <o> new-obj $new_obj_id]
               [ngs-tag <o> $NGS_TAG_INTELLIGENT_DEEP_COPY]
               ($new_obj_id ^name $goal_name
                            ^type $type)"

  if { $supergoal_id != "" } { set lhs_val "$lhs_val
                                            ($new_obj_id ^supergoal $supergoal_id)" }

  return $lhs_val   
}        


# Create a goal to be returned from a sub-state
#
# Creates a special return value in a sub-state that will result in a new goal
#  being created in the top-state, once the sub-state is completed.
#
proc ngs-create-goal-as-return-value { state_id
                                       goal_type
                                       goal_name
                                       new_obj_id
                                       {supergoal_id ""}
                                       {goal_pool_id ""} } {
    
  CORE_RefMacroVars
  variable rhs_val

  set ret_val_id [CORE_GenVarName new-ret-val]

  set rhs_val "[ngs-create-atomic-operator $state_id $NGS_OP_CREATE_GOAL_RET <o>]
	             (<o> ^dest-attribute        value-description
                    ^new-obj               $ret_val_id
                    ^replacement-behavior  $NGS_ADD_TO_SET)
               (<ret_val_id> ^name                  new-goal-to-return
                             ^destination-attribute $NGS_GOAL_ATTRIBUTE
                             ^replacement-behavior  $NGS_ADD_TO_SET)
	             ($new_obj_id  ^name     $goal_name
                             ^type     $goal_type)"
                   
  if { $supergoal_id != "" } { set rhs_val "$rhs_val
                                            ($new_obj_id ^supergoal $supergoal_id)" }

  return $rhs_val
   
}                  

# This is needed for creating return values on operator structures
#
proc ngs-create-ret-val-in-place { ret_val_name
                                   ret_val_set_id
                                   dest_obj_id 
                                   attribute 
                                   {new_val ""} 
                                   {replacement_behavior ""} } {

    CORE_RefMacroVars
    CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

    set ret_val_id [CORE_GenVarName new-ret-val]

    set rhs_val  "[ngs-create-typed-object-in-place $ret_val_set_id value-description $NGS_TYPE_STATE_RETURN_VALUE $ret_val_id]
                  ($ret_val_id     ^name $ret_val_name
                                   ^destination-object $dest_obj_id
                                   ^destination-attribute $attribute
                                   ^replacement-behavior $replacement_behavior)"
    
    if { $new_val != "" } {
      set rhs_val "$rhs_val
                   ($ret_val_id ^value $new_val)"
    }

    return $rhs_val
}

# Needs to work with an elaboration to set the ret_val_set_id (dest-obj)
proc ngs-create-ret-val-by-operator { state_id
                                      ret_val_name
                                      dest_obj_id
                                      attribute 
                                      {new_val ""} 
                                      {replacement_behavior ""}
                                      {add_prefs ""} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

  set ret_val_id [CORE_GenVarName new-ret-val]

  set rhs_val "[ngs-create-atomic-operator $state_id $NGS_OP_CREATE_RET_VAL*$ret_val_name <o> $add_prefs]
               (<o> ^dest-attribute value-description
                    ^replacement-behavior $NGS_ADD_TO_SET)
               [ngs-create-typed-object-in-place <o> new-obj $NGS_TYPE_STATE_RETURN_VALUE $ret_val_id $NGS_O_SUPPORT]
               ($ret_val_id     ^name $ret_val_name
                                ^destination-object $dest_obj_id
                                ^destination-attribute $attribute
                                ^replacement-behavior $replacement_behavior)
               [ngs-tag <o> $NGS_TAG_INTELLIGENT_DEEP_COPY]"
    
  if { $new_val != "" } {
    set rhs_val "$rhs_val
                 ($ret_val_id ^value $new_val)"
  }

  return $rhs_val
}



#
# Constructs an operator that, when applied, sets the return value in a sub-state
#
# Won't work without additional fixes. Need to augment this operator proposal with the 
#  deep copy required attributes (a proposal elaboration) using the information on the operator
#
proc ngs-set-ret-val-by-operator { state_id
                                   ret_val_name 
                                   value } {

    CORE_RefMacroVars

    set rhs_val  "[ngs-create-atomic-operator $state_id $NGS_OP_SET_RETURN_VALUE*$ret_val_name <o>]
                  (<o> ^replacement-behavior $NGS_REPLACE_IF_EXISTS
                       ^new-obj              $value
                       ^ret-val-name         $ret_val_name)
                  [ngs-tag <o> $NGS_TAG_INTELLIGENT_DEEP_COPY]"

    return $rhs_val
}




