
proc ngs-tag-for-name { tag_name } {
  variable NGS_TAG_PREFIX
  return $NGS_TAG_PREFIX$tag_name
}

#
# add a tag to the given 'tags' structure.
#
proc ngs-tag { obj_id tag_name {tag_value ""}} {
  variable NGS_YES
  CORE_SetIfEmpty tag_value $NGS_YES
  return "($obj_id ^[ngs-tag-for-name $tag_name] $tag_value +)"
}

proc ngs-untag { obj_id tag_name tag_value } {
  variable NGS_YES
  CORE_SetIfEmpty tag_value $NGS_YES
  return "($obj_id ^[ngs-tag-for-name $tag_name] $tag_value -)"
}

#
# Marks a goal as achieved (sets the NGS_GS_ACHIEVED attribute
#  to NGS_YES
#
proc ngs-tag-goal-achieved { goal_id } {
  CORE_RefMacroVars
  return "[ngs-tag $goal_id $NGS_GS_ACHIEVED]"
}

proc ngs-tag-goal-achieved-by-operator { state_id goal_id { operator_id "" } } {
	CORE_RefMacroVars
	CORE_GenVarIfEmpty operator_id "o"
	return "[ngs-create-atomic-operator <s> $NGS_OP_MARK_ACHIEVED $operator_id]
    		($operator_id ^goal $goal_id)"
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
# DEPRECATED
proc ngs-create-typed-object-in-place { parent_obj_id 
		                                    attribute
		                                    type
		                                    new_obj_id 
                                        {support_type ""} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty support_type $NGS_FOR_I_SUPPORT

  set rhs_val "[ngs-create-attribute $parent_obj_id $attribute $new_obj_id]
               ($new_obj_id ^type $type)"

  if { $support_type == $NGS_FOR_I_SUPPORT } {
    set rhs_val "$rhs_val
                 [ngs-tag $new_obj_id $NGS_TAG_CONSTRUCTED]
                 [ngs-tag $new_obj_id $NGS_TAG_I_SUPPORTED]"
  }
  
  return $rhs_val
}

# Creates an object in a form appropriate for i-support
#
# Use this on the righ-hand side of a production to create a typed object
#  using i-support. If you need to construct an object in-place on an operator, 
#  then use ngs-ocreate-typed-object-in-place.
#
# NOTE: before you can create a typed object you must declare it using NGS_DeclareType. 
#
# E.g. [ngs-icreate-typed-object-in-place <parrent> attribute-name MyType <new-obj> { attr1 val1 attr2 val2 attr3-set {set1 set2 set3} }]
#
# parent_obj_id - Variable bound to the object that will link to the newly constructed object
# attribute - Name of the attribute that should hold the new object
# new_obj_id - Variable that will beind to the new object's identifier
# attribute_list - (Optional) List of attribute, value pairs for the given object. If attributes is a set
#                     (i.e. a multi-valued attribute), put the set values in a list (see example above).
proc ngs-icreate-typed-object-in-place { parent_obj_id
									     attribute
										 type
										 new_obj_id
										 {attribute_list ""} } {
	
  CORE_RefMacroVars

  set rhs_val "[ngs-create-attribute $parent_obj_id $attribute $new_obj_id]"

  set rhs_val "$rhs_val
               [ngs-tag $new_obj_id $NGS_TAG_CONSTRUCTED]
               [ngs-tag $new_obj_id $NGS_TAG_I_SUPPORTED]"

  # Set all of the non-tag attributes
  set rhs_val "$rhs_val
              [ngs-construct $new_obj_id $type [lappend attribute_list type $type]]"

  return $rhs_val

}

# Creates an object in a form appropriate for o-support
#
# Use this on the righ-hand side of a production to create a typed object
#  that you want to elaborate onto an operator. If you need to construct an  
#  i-supported object, then use ngs-icreate-typed-object-in-place.
#
# NOTE: before you can create a typed object you must declare it using NGS_DeclareType. 
#
# E.g. [ngs-icreate-typed-object-in-place <parrent> attribute-name MyType <new-obj> { attr1 val1 attr2 val2 attr3-set {set1 set2 set3} }]
#
# parent_obj_id - Variable bound to the object that will link to the newly constructed object
# attribute - Name of the attribute that should hold the new object
# new_obj_id - Variable that will beind to the new object's identifier
# attribute_list - (Optional) List of attribute, value pairs for the given object. If attributes is a set
#                     (i.e. a multi-valued attribute), put the set values in a list (see example above).
proc ngs-ocreate-typed-object-in-place { parent_obj_id
									     attribute
										 type
										 new_obj_id
										 {attribute_list ""} } {
	
  CORE_RefMacroVars

  set rhs_val "[ngs-create-attribute $parent_obj_id $attribute $new_obj_id]"

  # Set all of the non-tag attributes
  set rhs_val "$rhs_val
              [ngs-construct $new_obj_id $type [lappend attribute_list type $type]]"

  return $rhs_val

}

# DEPRACATED
proc ngs-create-typed-object-by-operator { state_id
	                                         parent_obj_id 
	                                         attribute
	                                         type
	                                         new_obj_id
	                                         {replacement_behavior ""} 
                                           {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

  return "[ngs-create-atomic-operator $state_id $NGS_OP_CREATE_OBJECT <o> $add_prefs]
          (<o> ^dest-object    $parent_obj_id
               ^dest-attribute $attribute
               ^replacement-behavior $replacement_behavior)
          [ngs-tag <o> $NGS_TAG_INTELLIGENT_CONSTRUCTION]
          [ngs-create-typed-object-in-place <o> new-obj $type $new_obj_id $NGS_FOR_O_SUPPORT]"
}

# Create a typed object using an operator
#
# Use this procedure when you want to link a newly constructed
#  object to your state (or some substructure on the state). This
#  macro is for creating the initial object and link. Use
#  ngs-ocreate-typed-object-in-place to create a composed (nested)
#  object that is linked to the newly created object.
#
# state_id
# parent_obj_id
# attribute
# type
# new_obj_id
# attribute_list
# replacement_behavior - 
# add_prefs - any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#                                                        
proc ngs-ocreate-typed-object-by-operator { state_id
	                                        parent_obj_id 
	                                        attribute
	                                        type
	                                        new_obj_id
											{attribute_list ""}
	                                        {replacement_behavior ""} 
                                            {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

  return "[ngs-create-atomic-operator $state_id $NGS_OP_CREATE_OBJECT <o> $add_prefs]
          (<o> ^dest-object    $parent_obj_id
               ^dest-attribute $attribute
               ^replacement-behavior $replacement_behavior)
          [ngs-tag <o> $NGS_TAG_INTELLIGENT_CONSTRUCTION]
          [ngs-ocreate-typed-object-in-place <o> new-obj $type $new_obj_id $attribute_list]"
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
          [ngs-tag <o> $NGS_TAG_INTELLIGENT_CONSTRUCTION]"

}

proc ngs-remove-attribute-by-operator { state_id
									    parent_obj_id
									    attribute
										value
									    {add_prefs "="} } {

	CORE_RefMacroVars
	return "[ngs-create-atomic-operator $state_id $NGS_REMOVE_ATTRIBUTE <o> $add_prefs]
			(<o> ^dest-object    $parent_obj_id
        		 ^dest-attribute $attribute
           	     ^value-to-remove $value)"
}

proc ngs-remove-tag-by-operator { state_id
								  parent_obj_id
								  tag_name
								 {value ""}
								 {add_prefs "="} } {
	CORE_RefMacroVars
	CORE_SetIfEmpty value $NGS_YES
	return "[ngs-remove-attribute-by-operator $state_id $parent_obj_id [ngs-tag-for-name $tag_name] $value $add_prefs]" 
}

#
# Creates a tag using an operator. The tag value will be constructed using
#  intelligent construction.
#
proc ngs-create-tag-by-operator { state_id
								  parent_obj_id
								  tag_name
								  {tag_val ""}
								  {replacement_behavior ""}
                                  {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty tag_val $NGS_YES

  return "[ngs-create-primitive-by-operator $state_id $parent_obj_id [ngs-tag-for-name $tag_name] $tag_val $replacement_behavior $add_prefs]"
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
                       ^type     $type)
          [ngs-tag $new_obj_id $NGS_TAG_I_SUPPORTED]"
    
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
proc ngs-create-decide-operator { state_id
                                  op_name
                                  new_obj_id
                                  ret_val_set_id
                                  goal_id
 								 {completion_tag ""}
                                 {add_prefs "="} } {

   CORE_RefMacroVars
    
   set rhs_val  "[ngs-create-operator $state_id $op_name $NGS_OP_DECIDE $new_obj_id $add_prefs]
                 ($new_obj_id ^goal          $goal_id
                              ^return-values $ret_val_set_id)"

   if { $completion_tag != "" } {
      set rhs_val "$rhs_val
           	       [ngs-create-ret-tag-in-place $NGS_TAG_DECISION_COMPLETE $ret_val_set_id $goal_id $completion_tag]"
   }

   return $rhs_val
}

# Create a basic goal
#
# Typically you should not call this method. Instead call ngs-create-achievement-goal
#  to create a goal that goes away when achieved and ngs-create-maintenance-goal to 
#  create a goal that remains after becoming achieved.
#
# Don't use this to create o-supported goals (or goals on operators)
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
                            ^type $type)
               [ngs-tag $new_obj_id $NGS_TAG_CONSTRUCTED]
               [ngs-tag $new_obj_id $NGS_TAG_I_SUPPORTED]"

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

  set lhs_val "[ngs-create-atomic-operator $state_id $NGS_OP_CREATE_GOAL <o>]
               [ngs-create-attribute <o> new-obj $new_obj_id]
               [ngs-tag <o> $NGS_TAG_INTELLIGENT_CONSTRUCTION]
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
                                       goal_name
									   goal_type
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
               ($ret_val_id ^name                  $NGS_GOAL_RETURN_VALUE
                            ^destination-attribute $NGS_GOAL_ATTRIBUTE
                            ^replacement-behavior  $NGS_ADD_TO_SET
                            ^value    $new_obj_id)
	           ($new_obj_id ^name     $goal_name
                            ^type     $goal_type)              
               [ngs-tag <o> $NGS_TAG_INTELLIGENT_CONSTRUCTION]"
                   
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

proc ngs-create-ret-tag-in-place { ret_val_name
                                   ret_val_set_id
                                   dest_obj_id 
                                   tag_name 
                                   {tag_val ""} 
                                   {replacement_behavior ""} } {

    CORE_RefMacroVars
    CORE_SetIfEmpty tag_val $NGS_YES

	return "[ngs-create-ret-val-in-place $ret_val_name $ret_val_set_id $dest_obj_id [ngs-tag-for-name $tag_name] $tag_val $replacement_behavior]"
}


#
# Constructs an operator that, when applied, sets the return value in a sub-state
#
proc ngs-set-ret-val-by-operator { state_id
                                   ret_val_name 
                                   value } {

    CORE_RefMacroVars

    set rhs_val  "[ngs-create-atomic-operator $state_id $NGS_OP_SET_RETURN_VALUE <o>]
                  (<o> ^replacement-behavior $NGS_REPLACE_IF_EXISTS
                       ^new-obj              $value
                       ^ret-val-name         $ret_val_name)
                  [ngs-tag <o> $NGS_TAG_INTELLIGENT_CONSTRUCTION]"

    return $rhs_val
}

proc ngs-create-typed-object-for-ret-val { state_id
                                           ret_val_name
                                           type_name
                                           new_obj_id } {

    CORE_RefMacroVars

    set rhs_val  "[ngs-create-atomic-operator $state_id $NGS_OP_SET_RETURN_VALUE <o>]
                  (<o> ^replacement-behavior $NGS_REPLACE_IF_EXISTS
                       ^ret-val-name         $ret_val_name)
                  [ngs-create-typed-object-in-place <o> new-obj $type_name $new_obj_id $NGS_FOR_O_SUPPORT]
                  [ngs-tag <o> $NGS_TAG_INTELLIGENT_CONSTRUCTION]"

    return $rhs_val

}

