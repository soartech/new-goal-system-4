
#
# add a tag to the given 'tags' structure.
#
proc ngs-tag {tags_id tag_name {tag_value ""}} {
  CORE_RefMacroVars
  CORE_SetIfEmpty tag_value $NGS_YES
  return "($tags_id ^$tag_name $tag_value)"
}


# Create a basic object.
#
# Base class objects by default only specify a tags substructure
# Otherwise they are empty. 
#
# parent_obj_id: the identifier for the object that will contain the new object
# attribute: the attribute to which the new object should be attached
# new_obj_attribute_pairs: a list of lists, where the inner list is a pair. Each pair
#  is an (attribute, value) to place within the object. If no value is specified in 
#  the inner list, a generic ID is created for that attribute. For example, 
#  {{x 5}{y 10}{z -4}{contact-id}} creates four attributes for the new object. x with
#  a value of 5, y with a value of 10, z with a value of -4, and contact-id with a
#  automatically generated identifier value (an empty reference to an object). Specify
#  "" (the default) if no attributes are needed.
# new_obj_tag_pairs: The same as new_obj_attribute_pairs, but the attributes are added
#  under the object's "tags" attribute. Specify "" (the default) if no tags are needed.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-object { parent_obj_id 
                         attribute
                         {new_obj_attribute_pairs ""} 
                         {new_obj_tag_pairs ""}
                         {new_obj_id ""}
                         {new_obj_tags_id ""} } {

  CORE_GenVarIfEmpty new_obj_id "new-obj"
  CORE_GenVarIfEmpty new_obj_tags_id "tags"
    
  if {$attribute == ""} { set attribute $obj_type }
    
 	return "($parent_obj_id ^$attribute $new_obj_id)
 	        ($new_obj_id    ^tags       $new_obj_tags_id)
 	        [ngs-create-object-structure $new_obj_id      $new_obj_attribute_pairs]
 	        [ngs-create-object-structure $new_obj_tags_id $new_obj_tag_pairs]"
 	        
}

# Create an object that has a name
#
# parent_obj_id: the identifier for the object that will contain the new object
# attribute: the attribute to which the new object should be attached
# name: the name of the object (used for operators)
# new_obj_attribute_pairs: a list of lists, where the inner list is a pair. Each pair
#  is an (attribute, value) to place within the object. If no value is specified in 
#  the inner list, a generic ID is created for that attribute. For example, 
#  {{x 5}{y 10}{z -4}{contact-id}} creates four attributes for the new object. x with
#  a value of 5, y with a value of 10, z with a value of -4, and contact-id with a
#  automatically generated identifier value (an empty reference to an object). Specify
#  "" (the default) if no attributes are needed.
# new_obj_tag_pairs: The same as new_obj_attribute_pairs, but the attributes are added
#  under the object's "tags" attribute. Specify "" (the default) if no tags are needed.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-named-object { parent_obj_id 
                               attribute
                               name
                               {new_obj_attribute_pairs ""} 
                               {new_obj_tag_pairs ""}
                               {new_obj_id ""}
                               {new_obj_tags_id ""} } {

  CORE_GenVarIfEmpty new_obj_id "new-obj"
  CORE_GenVarIfEmpty new_obj_tags_id "tags"
    
  if {$attribute == ""} { set attribute $obj_type }
    
 	return "[ngs-create-object $parent_obj_id $attribute 
 	                           $new_obj_attribute_pairs
 	                           $new_obj_tag_pairs
 	                           $new_obj_id
 	                           $new_obj_tags_id]
 	        ($new_obj_id ^name $name)" 	        
}

# Create an object that has a name
#
# parent_obj_id: the identifier for the object that will contain the new object
# attribute: the attribute to which the new object should be attached
# type: the type of the object (used for goals)
# new_obj_attribute_pairs: a list of lists, where the inner list is a pair. Each pair
#  is an (attribute, value) to place within the object. If no value is specified in 
#  the inner list, a generic ID is created for that attribute. For example, 
#  {{x 5}{y 10}{z -4}{contact-id}} creates four attributes for the new object. x with
#  a value of 5, y with a value of 10, z with a value of -4, and contact-id with a
#  automatically generated identifier value (an empty reference to an object). Specify
#  "" (the default) if no attributes are needed.
# new_obj_tag_pairs: The same as new_obj_attribute_pairs, but the attributes are added
#  under the object's "tags" attribute. Specify "" (the default) if no tags are needed.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-typed-object { parent_obj_id 
                               attribute
                               type
                               {new_obj_attribute_pairs ""} 
                               {new_obj_tag_pairs ""}
                               {new_obj_id ""}
                               {new_obj_tags_id ""} } {

  CORE_GenVarIfEmpty new_obj_id "new-obj"
  CORE_GenVarIfEmpty new_obj_tags_id "tags"
    
  if {$attribute == ""} { set attribute $obj_type }
    
 	return "[ngs-create-object $parent_obj_id $attribute 
 	                           $new_obj_attribute_pairs
 	                           $new_obj_tag_pairs
 	                           $new_obj_id
 	                           $new_obj_tags_id]
 	        ($new_obj_id ^type $type)" 	        
}
# Create an operator
#
# This creates a basic operator without a specified behavior type. Typically you
#  will not use this. Instead use create-atomic-operator or create-decide-operator.
#
# op_name: the name of the operator
# behavior: One of NGS_OP_ATOMIC or NGS_OP_DECIDE. Atomic operators are should be
#  applied immediately after selection while Decide operators should create operator
#  no change impasses.
# new_obj_attribute_pairs: a list of lists, where the inner list is a pair. Each pair
#  is an (attribute, value) to place within the object. If no value is specified in 
#  the inner list, a generic ID is created for that attribute. For example, 
#  {{x 5}{y 10}{z -4}{contact-id}} creates four attributes for the new object. x with
#  a value of 5, y with a value of 10, z with a value of -4, and contact-id with a
#  automatically generated identifier value (an empty reference to an object). Specify
#  "" (the default) if no attributes are needed.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object. The default is <o#>
# state_id: If provided, the soar variable that is bound to the state in which to
#  create the operator. The default is given by NGS_DEF_STATE_ID. 
# add_prefs: Additional preferences beyond acceptable ('+'). By default this is the
#  indifferent preference ('='). So by default an operator gets the + = preferences.
# new_obj_tag_pairs: The same as new_obj_attribute_pairs, but the attributes are added
#  under the object's "tags" attribute. Specify "" (the default) if no tags are needed.
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-operator { op_name
                           behavior
                           {new_obj_attribute_pairs ""} 
                           {new_obj_id ""}
                           {state_id ""}
                           {add_prefs "="}
                           {new_obj_tag_pairs ""}
                           {new_obj_tags_id ""} } {

  CORE_GenVarIfEmpty new_obj_id "o"
  CORE_SetIfEmpty state_id $NGS_DEF_STATE_ID
    
  return "[ngs-create-named-object $state_id 
                                    $NGS_OP_ATTRIBUTE
                                    $op_name
                                    $new_obj_attribute_pairs
                                    $new_obj_tag_pairs
                                    "$new_obj_id + $add_prefs"
                                    $new_obj_tags_id]
            ($new_obj_id ^behavior $behavior)"
    
}

# Create an atomic operator
#
# An atomic operator has the "behavior" attribute set to NGS_OP_ATOMIC. Atomic
#  operators should be applied immediately after selection and should not generate
#  substates.
#
# op_name: the name of the operator
# new_obj_attribute_pairs: a list of lists, where the inner list is a pair. Each pair
#  is an (attribute, value) to place within the object. If no value is specified in 
#  the inner list, a generic ID is created for that attribute. For example, 
#  {{x 5}{y 10}{z -4}{contact-id}} creates four attributes for the new object. x with
#  a value of 5, y with a value of 10, z with a value of -4, and contact-id with a
#  automatically generated identifier value (an empty reference to an object). Specify
#  "" (the default) if no attributes are needed.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object. The default is <o#>
# state_id: If provided, the soar variable that is bound to the state in which to
#  create the operator. The default is given by NGS_DEF_STATE_ID. 
# add_prefs: Additional preferences beyond acceptable ('+'). By default this is the
#  indifferent preference ('='). So by default an operator gets the + = preferences.
# new_obj_tag_pairs: The same as new_obj_attribute_pairs, but the attributes are added
#  under the object's "tags" attribute. Specify "" (the default) if no tags are needed.
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-atomic-operator { op_name
                                 {new_obj_attribute_pairs ""} 
                                 {new_obj_id ""}
                                 {state_id ""}
                                 {add_prefs "="}
                                 {new_obj_tag_pairs ""}
                                 {new_obj_tags_id ""} } {
                                 
  return "[ngs-create-operator $op_name
                               $NGS_OP_ATOMIC
                               $new_obj_attribute_pairs
                               $new_obj_id
                               $state_id
                               $add_prefs
                               $new_obj_tag_pairs
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
# op_name: the name of the operator
# behavior: One of NGS_OP_ATOMIC or NGS_OP_DECIDE. Atomic operators are should be
#  applied immediately after selection while Decide operators should create operator
#  no change impasses.
# new_obj_attribute_pairs: a list of lists, where the inner list is a pair. Each pair
#  is an (attribute, value) to place within the object. If no value is specified in 
#  the inner list, a generic ID is created for that attribute. For example, 
#  {{x 5}{y 10}{z -4}{contact-id}} creates four attributes for the new object. x with
#  a value of 5, y with a value of 10, z with a value of -4, and contact-id with a
#  automatically generated identifier value (an empty reference to an object). Specify
#  "" (the default) if no attributes are needed.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object. The default is <o#>
# state_id: If provided, the soar variable that is bound to the state in which to
#  create the operator. The default is given by NGS_DEF_STATE_ID. 
# add_prefs: Additional preferences beyond acceptable ('+'). By default this is the
#  indifferent preference ('='). So by default an operator gets the + = preferences.
# ret_val_list: A list of tuples that describe one or more return value structures
#  that should be copied onto the sub-state. Use this list when you know in advance
#  (e.g. at operator proposal time) one or more of the values you need to set when
#  the sub-goal completes (e.g. "complete" flags). See ngs-create-op-ret-val to 
#  see the structure of ret-value objects. Example: {{<my-goal-tags> processed $NGS_YES}} 
# new_obj_tag_pairs: The same as new_obj_attribute_pairs, but the attributes are added
#  under the object's "tags" attribute. Specify "" (the default) if no tags are needed.
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-decide-operator { op_name
                                  behavior
                                 {new_obj_attribute_pairs ""} 
                                 {new_obj_id ""}
                                 {state_id ""}
                                 {add_prefs "="}
                                 {ret_val_list ""}
                                 {new_obj_tag_pairs ""}
                                 {new_obj_tags_id ""} } {

    CORE_GenVarIfEmpty new_obj_id "o"
    CORE_SetIfEmpty state_id $NGS_DEF_STATE_ID
    
    variable ret_val_tests
    if {$ret_val_list != ""} {
       variable ret_val_set_id
       [CORE_GenVarName ret_val_set_id "ret-val-set"]
       set ret_val_tests "($new_obj_id ^ret-vals $ret_val_set_id)
                          [ngs-construct-ret-vals-from-list $ret_val_set_id $ret_val_list]"
    } else {
       set ret_val_tests ""
    }

   return  "[ngs-create-operator $op_name
                                 $NGS_OP_DECIDE
                                 $new_obj_attribute_pairs
                                 $new_obj_id
                                 $state_id
                                 $add_prefs
                                 $new_obj_tag_pairs
                                 $new_obj_tags_id]
            $ret_val_tests"
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
# new_obj_attribute_pairs: a list of lists, where the inner list is a pair. Each pair
#  is an (attribute, value) to place within the object. If no value is specified in 
#  the inner list, a generic ID is created for that attribute. For example, 
#  {{x 5}{y 10}{z -4}{contact-id}} creates four attributes for the new object. x with
#  a value of 5, y with a value of 10, z with a value of -4, and contact-id with a
#  automatically generated identifier value (an empty reference to an object). Specify
#  "" (the default) if no attributes are needed.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# new_obj_tag_pairs: The same as new_obj_attribute_pairs, but the attributes are added
#  under the object's "tags" attribute. Specify "" (the default) if no tags are needed.
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-goal { named_goal_set_id
                       goal_name
                       behavior
                       {new_obj_attribute_pairs ""} 
                       {new_obj_id ""}
                       {new_obj_tag_pairs ""}
                       {new_obj_tags_id ""} } {

    CORE_GenVarIfEmpty new_obj_id "goal"
    
    return "[ngs-create-named-object $named_goal_set_id 
                                     goal
                                     $goal_name
                                     $new_obj_attribute_pairs
                                     $new_obj_tag_pairs
                                     $new_obj_id
                                     $new_obj_tags_id]
             ($new_obj_id ^behavior $behavior)"
   
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
# new_obj_attribute_pairs: a list of lists, where the inner list is a pair. Each pair
#  is an (attribute, value) to place within the object. If no value is specified in 
#  the inner list, a generic ID is created for that attribute. For example, 
#  {{x 5}{y 10}{z -4}{contact-id}} creates four attributes for the new object. x with
#  a value of 5, y with a value of 10, z with a value of -4, and contact-id with a
#  automatically generated identifier value (an empty reference to an object). Specify
#  "" (the default) if no attributes are needed.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# new_obj_tag_pairs: The same as new_obj_attribute_pairs, but the attributes are added
#  under the object's "tags" attribute. Specify "" (the default) if no tags are needed.
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set
proc ngs-create-achievement-goal { named_goal_set_id
                                   goal_name
                                   {new_obj_attribute_pairs ""} 
                                   {new_obj_id ""}
                                   {new_obj_tag_pairs ""}
                                   {new_obj_tags_id ""} } {
    
    return "[ngs-create-goal $named_goal_set_id 
                             goal
                             $NGS_GB_ACHIEVE
                             $goal_name
                             $new_obj_attribute_pairs
                             $new_obj_tag_pairs
                             $new_obj_id
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
# new_obj_attribute_pairs: a list of lists, where the inner list is a pair. Each pair
#  is an (attribute, value) to place within the object. If no value is specified in 
#  the inner list, a generic ID is created for that attribute. For example, 
#  {{x 5}{y 10}{z -4}{contact-id}} creates four attributes for the new object. x with
#  a value of 5, y with a value of 10, z with a value of -4, and contact-id with a
#  automatically generated identifier value (an empty reference to an object). Specify
#  "" (the default) if no attributes are needed.
# new_obj_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object
# new_obj_tag_pairs: The same as new_obj_attribute_pairs, but the attributes are added
#  under the object's "tags" attribute. Specify "" (the default) if no tags are needed.
# new_obj_tags_id: If provided, this variable is used as a soar variable that will bind
#  to the newly created object tag set

proc ngs-create-maintenance-goal { named_goal_set_id
                                   goal_name
                                   {new_obj_attribute_pairs ""} 
                                   {new_obj_id ""}
                                   {new_obj_tag_pairs ""}
                                   {new_obj_tags_id ""} } {

    return "[ngs-create-goal $named_goal_set_id 
                             goal
                             $NGS_GB_MAINT
                             $goal_name
                             $new_obj_attribute_pairs
                             $new_obj_tag_pairs
                             $new_obj_id
                             $new_obj_tags_id]"
   
}                  

# Creates a single return value
#
# Use this when you need to create a value to be returned from a sub-state.
# Return values can be created in the sub-states or when the original operator is
#  created (e.g. if the flag indicating the end of sub-state process is static)
#
# ret_val_set_id: Identifier for the set containing all of the return values
# dest_obj_id: Identifier of the object that will get the return value
# attribute: Attribute that will hold the return value
# new_val: The actual return value (can be an identifier)
# add_to_set: a boolean that indicates whether to add new_val to a set (e.g. allow 
#  multi-valued attributes) or to replace any current value.
#
proc ngs-create-op-ret-val { ret_val_set_id dest_obj_id attribute new_val {add_to_set ""} } {

    variable ret_val_id
    CORE_SetIfEmpty add_to_set $NGS_NO
    CORE_GenVarName ret_val_id "ret-val"

    return "($ret_val_set_id ^ret-val $ret_val_id)
            ($ret_val_id     ^dest-object $dest_obj_id
                             ^attribute $attribute
                             ^new-val $new_val
                             ^add-to-set $add_to_set)"
}


#####################################################################################
# DO NOT USE THESE UNLESS YOU ARE EXTENDING THE NGS
                           
# INTERNAL
#
# Used by ngs-create-operator to construct default return values for operators
# from more user friendly lists
#
proc ngs-construct-ret-vals-from-list { ret_val_set_id list_of_ret_val_structs } {

  set ret_val_tests ""
	foreach ret_val_struct $list_of_ret_val_structs {
	
	    # Note that lindex $ret_val_struct 3 may return an empty value (this
	    #  is an optional variable). If so, the ngs-create-op-ret-val will
	    #  replace with the default of NGS_NO.
		set ret_val_tests "$ret_val_tests
		                   [ngs-create-op-ret-val $ret_val_set_id
		                       [lindex $ret_val_struct 0]
		                       [lindex $ret_val_struct 1]
		                       [lindex $ret_val_struct 2]
		                       [lindex $ret_val_struct 3]]"
	
	}
	
	return $ret_val_tests
}

# INTERNAL
#
# Used by the various create macros to generate Soar code
#  for lists of attributes and tags
#
proc ngs-create-object-structure { obj_id list_of_pairs } {
  set param_output ""
  
  foreach param $list_of_pairs {
     
     set param_attribute [lindex param 0] 
     set param_val ""
     
     # If no param value is provided, we just set it to a generic id type
     if {[llength param] == 1} { 
       set param_val [CORE_GenVarName $param_attribute]
     } else {
       set param_val [lindex param 1]
     }
       
     set param_output "$param_output ($obj_id ^$param_attribute $param_val)\n"
  }

  return $param_output
}

