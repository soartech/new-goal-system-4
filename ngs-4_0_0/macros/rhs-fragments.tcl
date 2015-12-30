#
# Copyright (c) 2015, Soar Technology, Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# 
# * Neither the name of Soar Technology, Inc. nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without the specific prior written permission of Soar Technology, Inc.
# 
# THIS SOFTWARE IS PROVIDED BY SOAR TECHNOLOGY, INC. AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL SOAR TECHNOLOGY, INC. OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Creates a tag from a string of text
#
# Tags have a prefix on them given by $NGS_TAG_PREFIX
# As a general rule, the other macros hide this fact
#  so you don't need to use this macro in all but 
#  very unusual circumstances.
#
# tag_name - User name for a tag. Note that this tag name
#              MUST be a constant (not a Soar variable)
# returns - NGS fully qualified tag name
#
proc ngs-tag-for-name { tag_name } {
  CORE_RefMacroVars
  return $NGS_TAG_PREFIX$tag_name
}

# Add a tag to an object.
#
# Use this method to add a "tag" to an object. Don't try
#  to add the tag manually, use NGS macros to manipulate tags
#  and they will handle the naming conventions and tag structure
#  for you
# 
# [ngs-tag obj_id tag_name (tag_value)]
#
# obj_id - variable bound to an object identifier for the object to tag
# tag_name - your name for the tag
# tag_value - (Optional) the tag's value. Many tags are boolean and take
#              only the values $NGS_YES and $NGS_NO. If you don't specify
#              a value, the value $NGS_YES is assumed and set.
#
proc ngs-tag { obj_id tag_name {tag_value ""}} {
  variable NGS_YES
  CORE_SetIfEmpty tag_value $NGS_YES
  return "($obj_id ^[ngs-tag-for-name $tag_name] $tag_value +)"
}

# Clears a tag from an object
#
# Use this method to remove a tag from an object. Don't try to
#  remove the tag manually, use NGS macros to manipulate tags
#  and they will handle the naming conventions and tag structure
#  for you
#
# [ngs-untag obj_id tag_name tag_value]
#
# obj_id - variable bound to an object identfier for the object to untag
# tag_name - your name for the tag to remove
# tag_value - (Optional) The tag's value. If you don't provide the tag's
#               value, NGS_YES is assumed. If the value of the tag is not
#               NGS_YES in this case, the tag will not get removed. 
#
proc ngs-untag { obj_id tag_name {tag_value ""} } {
  variable NGS_YES
  CORE_SetIfEmpty tag_value $NGS_YES
  return "($obj_id ^[ngs-tag-for-name $tag_name] $tag_value -)"
}

# Marks a goal as achieved (sets the NGS_GS_ACHIEVED attribute
#  to NGS_YES)
#
# Use this method to manually mark a goal as achieved. This version would normally
#  be used to create the tag via i-support. The goal itself could be constructed
#  using i- or o-support. Use ngs-tag-goal-achieved-by-operator to construct
#  the tag using o-support
#
# [ngs-tag-goal-achieved goal_id]
#
# goal_id - variable bound to the identifier of the goal to mark as achieved.                           
#
proc ngs-tag-goal-achieved { goal_id } {
  CORE_RefMacroVars
  return "[ngs-tag $goal_id $NGS_GS_ACHIEVED]"
}

# Marks a goal as achieved using an atomic operator (sets NGS_GS_AHCIEVED attribute
#  to NGS_YES)
#
# Use this method to manually mark a goal as achieved using o-support.
#
# [ngs-tag-goal-achieved-by-operator state_id goal_id (operator_id)]
#
# state_id - Variable bound to the identifier of the state in which you want the operator proposed
# goal_id - Variable bound to the id of the goal to mark as achieved
# operator_id - (Optional) If provided, will bind the newly constructed operator to
#  the variable passed in to this argument.
#                                                                                            
proc ngs-tag-goal-achieved-by-operator { state_id goal_id { operator_id "" } } {
	CORE_RefMacroVars
	CORE_GenVarIfEmpty operator_id "o"
	return "[ngs-create-atomic-operator <s> "(concat |mark-goal-achieved--| $goal_id)" $operator_id]
          [ngs-tag $operator_id $NGS_TAG_MARK_ACHIEVED]
    		  ($operator_id ^goal $goal_id)"
}

# Tags a goal as having been decided
# 
# A goal that was assigned a decision is decided when
#  code executes that selects that goal. 
#
# Note: User code does not typically need to call this direction.
#  Marking the the goal as decided is done by NGS library code.
#
# [ngs-tag-goal-as-decided goal_id (decided_value)]
#
# goal_id - variable bound to the goal to mark as decided
# decided_value - (Optional) A boolean flag indicating whether
#   the goal was decided for (NGS_YES) or against (NGS_NO)
#
proc ngs-tag-goal-as-decided { goal_id { decided_value ""} } {
  CORE_RefMacroVars
  CORE_SetIfEmpty decided_value $NGS_YES
  return [ngs-tag $goal_id "$NGS_TAG_DECIDED" $decided_value]
}

# Create working memory element, i.e. an object "attribute"
#
# This will create the code to generate a simple soar WME 
#  preference(s) (default +, but other's are allowed). Normally
#  you don't need to use this method, but this method is used
#  throughout the NGS to construct goals, operators, and typed
#  objects.
#
# You can simply create object substructure using standard Soar
#  syntax (which is a bit more compact), but in the future, this
#  type of method might be used to do type checking or other 
#  processing, so it's advisable to use it if the standard
#  creation processes won't work for you.
#
# [ngs-create-attribute parent_obj_id attribute value (prefs)]
#
# parent_obj_id - A variable bound to the parent object of the WME (left hand side)
# attribute - A symbol bound to the attribute of the WME (middle value)
# value - A symbol bound to the value of the WME (right hand side)
# prefs - (Optional) The preferences to specify for the WME. The default is +,
#          which is correct for non-operator WME construction. For operators
#          other preferences may be specified. Note that it is possible to use
#          this argument to make the method remove a WME (via the - preference).
#          However, this is not recommended as it would be confusing. Use
#          remove-attribute-by-operator instead.
#
proc ngs-create-attribute { parent_obj_id 
                            attribute
                            value
                            {prefs "+"} } {

  CORE_RefMacroVars
    
  return "($parent_obj_id ^$attribute $value $prefs)"
 	        
}

# Remove a working memory element, i.e. an object "attribute"
#
# This will create the code to generate a simple soar WME 
#  preference to remove a WME. 
#
# You can simply remove a WME using standard Soar
#  syntax (which is a bit more compact), but in the future, this
#  type of method might be used to do type checking or other 
#  processing, so it's advisable to use it if the standard
#  creation processes won't work for you.
#
# [ngs-remove-attribute parent_obj_id attribute value ]
#
# parent_obj_id - A variable bound to the parent object of the WME (left hand side)
# attribute - A symbol bound to the attribute of the WME (middle value)
# value - A symbol bound to the value of the WME (right hand side)
#
proc ngs-remove-attribute { parent_obj_id 
                            attribute
                            value } {

  CORE_RefMacroVars
    
  return "($parent_obj_id ^$attribute $value -)"
          
}
# Creates an object in a form appropriate for i-support
#
# Use this on the righ-hand side of a production to create a typed object
#  using i-support. If you need to construct an object in-place on an operator, 
#  then use ngs-ocreate-typed-object-in-place.
#
# NOTE: before you can create a typed object you must declare it using NGS_DeclareType. 
#
# [ngs-icreate-typed-object-in-place <parrent> attribute-name MyType <new-obj> { attr1 val1 attr2 val2 attr3-set {set1 set2 set3} }]
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

  # Set all of the non-tag attributes
  set rhs_val "$rhs_val
              [ngs-construct $new_obj_id $type [lappend attribute_list type $type]]"

  set rhs_val "$rhs_val
               [ngs-tag $new_obj_id $NGS_TAG_CONSTRUCTED]
               [ngs-tag $new_obj_id $NGS_TAG_I_SUPPORTED]"

  return "$rhs_val
          [core-trace NGS_TRACE_I_TYPED_OBJECTS "I CREATE-OBJECT, $type, (| $parent_obj_id |.$attribute | $new_obj_id |)."]"

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

  return "$rhs_val
          [core-trace NGS_TRACE_O_TYPED_OBJECTS "o CREATE-OBJECT, $type, (| $parent_obj_id |.$attribute | $new_obj_id |)."]"

}

# Create a typed object using an operator
#
# Use this procedure when you want to link a newly constructed
#  object to your state (or some substructure on the state). This
#  macro is for creating the initial object and link. Use
#  ngs-ocreate-typed-object-in-place to create a composed (nested)
#  object that is linked to the newly created object.
#
# [ngs-create-typed-object-by-operator state_id parent_obj_id attribute type new_obj_id (attribute_list) (replacement_behavior) (add_prefs)]
#
# state_id - variable bound the state in which to propose the operator
# parent_obj_id - variable bound to the id of the parent of the object being created
# attribute - attribute to which to bind the newly constructed object
# type - type of the object (declare first with NGS_DeclareType)
# new_obj_id - variable bound to the id of the newly constructed object
# attribute_list - (Optional) List of attribute, value pairs for the given object. If attributes is a set
#                  (i.e. a multi-valued attribute), put the set values in a list (see example above).
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#                                                        
proc ngs-create-typed-object-by-operator { state_id
	                                        parent_obj_id 
	                                        attribute
	                                        type
	                                        new_obj_id
											                   {attribute_list ""}
	                                        {replacement_behavior ""} 
                                            {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

  set op_id [CORE_GenVarName "o"]

  return "[ngs-create-atomic-operator $state_id "(concat |create--| $attribute |--$type--| $new_obj_id)" $op_id $add_prefs]
          ($op_id ^dest-object    $parent_obj_id
               ^dest-attribute $attribute
               ^replacement-behavior $replacement_behavior)
          [ngs-tag $op_id $NGS_TAG_INTELLIGENT_CONSTRUCTION]
          [ngs-ocreate-typed-object-in-place $op_id new-obj $type $new_obj_id $attribute_list]
          [core-trace NGS_TRACE_O_TYPED_OBJECTS "O CREATE-OBJECT, $type, (| $parent_obj_id |.$attribute | $new_obj_id |)."]"
}

# Create an output link command
#
# [ngs-create-output-command-by-operator state_id output_link_id command_type cmd_id (attribute_list) (add_prefs)]
#
proc ngs-create-output-command-by-operator { state_id
                                             output_link_id 
                                             command_type
                                             cmd_id
                                            {attribute_list ""}
                                            {add_prefs "="} } {

  CORE_RefMacroVars

  return "[ngs-create-typed-object-by-operator $state_id $output_link_id $NGS_OUTPUT_COMMAND_ATTRIBUTE \
                                             $command_type $cmd_id $attribute_list $NGS_ADD_TO_SET $add_prefs]
          [ngs-create-attribute $cmd_id name $command_type]
          [core-trace NGS_TRACE_OUTPUT "O OUTPUT-COMMAND-ISSUED, $command_type, (| $output_link_id |.$NGS_OUTPUT_COMMAND_ATTRIBUTE | $cmd_id |)."]"
}

# Creates a primitive working memory element using an atomic operator.
#
# Use this method to create o-supported working memory elements. Primitives
#  can include any of the symbol types exclusing ids (i.e. strings, integers, floating point values).
#  To create identifiers, use other macros such as ngs-create-typed-object-by-operator or any of the
#  various methods to create goals.
# 
# [ngs-create-primitive-by-operator state_id parent_obj_id attribute value (replacement_behavior) (add_prefs)]
#
# state_id - variable bound the state in which to propose the operator
# parent_obj_id - variable bound to the id of the parent of the primitive being created
# attribute - attribute to which to bind the newly constructed primitive
# value - value of the primitive (either a constant string, int, or float or a variable bound to one
#          of those types of values)
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
proc ngs-create-primitive-by-operator { state_id
                                        parent_obj_id 
                                        attribute
                                        value
                                       {replacement_behavior ""} 
                                       {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

  if { [string first $NGS_TAG_PREFIX $attribute] == 0 } {
    set op_name "(concat |create-tag--| [string range $attribute [string length $NGS_TAG_PREFIX] end] |--| $value)"
  } else {
    set op_name "(concat |create-wme--| $attribute |--| $value)"
  }

  set op_id [CORE_GenVarName "o"]

  return "[ngs-create-atomic-operator $state_id $op_name $op_id $add_prefs]
          ($op_id ^dest-object    $parent_obj_id
               ^dest-attribute $attribute
               ^new-obj        $value
               ^replacement-behavior $replacement_behavior)
          [ngs-tag $op_id $NGS_TAG_INTELLIGENT_CONSTRUCTION]
          [core-trace NGS_TRACE_PRIMITIVES "O CREATE-PRIMITIVE, (| $parent_obj_id |.$attribute $value)."]"

}

# Creates an object using Soar's built in deep-copy
# 
# Use this macro when you wish to completely copy a deep structure, 
#  usually from the input link. You cannot create objects using deep
#  copy any other way in NGS as if you use other methods 
#  create-primitive-by-operator) the deep copied structure will get 
#  i-support.
#
# [ngs-deep-copy-by-operator state_id parent_obj_id attribute value (replacement_behavior) (add_prefs)]
#
# state_id - variable bound the state in which to propose the operator
# parent_obj_id - variable bound to the id of the parent of the primitive being created
# attribute - attribute to which to bind the newly constructed primitive
# value - variable bound to the identifier of the object you want to copy
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
proc ngs-deep-copy-by-operator { state_id
                                 parent_obj_id 
                                 attribute
                                 value
                                 {replacement_behavior ""} 
                                 {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

  set op_id [CORE_GenVarName "o"]

  return "[ngs-create-atomic-operator $state_id "(concat |deep-copy--| $attribute |--| $value)" $op_id $add_prefs]
          ($op_id ^dest-object    $parent_obj_id
               ^dest-attribute $attribute
               ^new-obj        $value
               ^replacement-behavior $replacement_behavior)
          [ngs-tag $op_id $NGS_TAG_DEEP_COPY]
          [core-trace NGS_TRACE_O_TYPED_OBJECTS "O DEEP-COPY, (| $parent_obj_id |.$attribute $value)."]"
}


# Remove an o-supported working memory element
#
# Use this method to remove a working memory element (any type) and, via Soar's garbage collection, any
#  sub-structure that becomes orphaned by this removal.
#
# NOTE: Do not use this method to remove tags. Use ngs-remove-tag-by-operator instead.
# 
# [ngs-remove-attribute-by-operator state_id parent_obj_id attribute value (add_prefs)]
#
# state_id - variable bound the state in which to propose the operator
# parent_obj_id - variable bound to the id of the parent of the WME being removed
# attribute - attribute that should be removed
# value - value of the WME to be removed (can be any type of value - primitive or ID)
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#
proc ngs-remove-attribute-by-operator { state_id
									    parent_obj_id
									    attribute
										  value
									    {add_prefs "="} } {

	CORE_RefMacroVars

  set op_id [CORE_GenVarName "o"]

	return "[ngs-create-atomic-operator $state_id "(concat |remove-wme--| $parent_obj_id |--| $attribute |--| $value)" $op_id $add_prefs]
			    ($op_id ^dest-object    $parent_obj_id
       		     ^dest-attribute $attribute
     	         ^value-to-remove $value)
          [ngs-tag $op_id $NGS_TAG_REMOVE_ATTRIBUTE]
          [core-trace NGS_TRACE_PRIMITIVES "O REMOVE-WME, (| $parent_obj_id |.$attribute $value)."]"
}

# Remove an o-supported tag from an object
#
# Use this method to remove a tag from an object. This method properly handles
#  the tag naming convention and structure.
# 
# [ngs-remove-tag-by-operator state_id parent_obj_id attribute (value) (add_prefs)]
#
# state_id - variable bound the state in which to propose the operator
# parent_obj_id - variable bound to the id of the object from which to remove the tag
# tag_name - name of the tag to remove
# value - (Optional) Value of the tag to be removed. Defaults to NGS_YES. If NGS_YES is NOT
#          the value of the tag, you will need to specify the value (or this macro won't work).
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#
proc ngs-remove-tag-by-operator { state_id
								  parent_obj_id
								  tag_name
								 {value ""}
								 {add_prefs "="} } {
	CORE_RefMacroVars
	CORE_SetIfEmpty value $NGS_YES
	return "[ngs-remove-attribute-by-operator $state_id $parent_obj_id [ngs-tag-for-name $tag_name] $value $add_prefs]
          [core-trace NGS_TRACE_TAGS "O REMOVE-TAG, (| $parent_obj_id |.[ngs-tag-for-name $tag_name] $value)."]" 
}

# Creates a tag using an operator. The tag value will be constructed using
#  intelligent construction.
#
# Use this method to add an o-supported tag to an object as a separate step
#  from creation. If you just need to add a tag at the same time you are 
#  constructing an object then use ngs-tag instead.
#
# [ngs-create-tag-by-operator state_id parent_obj_id tag_name (tag_val) (replacement_behavior) (add_prefs)]
#
# state_id - variable bound the state in which to propose the operator
# parent_obj_id - variable bound to the id of the object to which to add the tag
# tag_name - name of the tag to add
# value - (Optional) value of the tag. Default is NGS_YES.
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#
proc ngs-create-tag-by-operator { state_id
								  parent_obj_id
								  tag_name
								  {tag_val ""}
								  {replacement_behavior ""}
                                  {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_SetIfEmpty tag_val $NGS_YES

  return "[ngs-create-primitive-by-operator $state_id $parent_obj_id [ngs-tag-for-name $tag_name] $tag_val $replacement_behavior $add_prefs]
          [core-trace NGS_TRACE_TAGS "O CREATE-TAG, (| $parent_obj_id |.[ngs-tag-for-name $tag_name] $tag_val)."]"
}

# Create a plain operator
#
# This macro is primiarly for use by other NGS macros. It's best to use
#  ngs-create-atomic-operator or ngs-create-decide-operator depending
#  on the type of operator you need.
#
# [ngs-create-operator state_id op_name type (new_obj_id) (add_prefs)]
#
# state_id - variable bound to the state in which the operator should be proposed
# op_name  - name of the operator (this prints out on the state stack in Soar)
# type     - type of operator, one of NGS_OP_ATOMIC or NGS_OP_DECIDE
# new_obj_id - a variable that will be bound to the
#               newly constructed operator.
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#
proc ngs-create-operator { state_id
                           op_name
                           type
                           new_obj_id
                           {add_prefs "="} } {

  CORE_RefMacroVars
  CORE_GenVarIfEmpty state_id "s"
    
  return "[ngs-create-attribute $state_id $NGS_OP_ATTRIBUTE $new_obj_id "+ $add_prefs"]
          ($new_obj_id ^name     $op_name
                       ^type     $type)
          [ngs-tag $new_obj_id $NGS_TAG_I_SUPPORTED]"
    
}

# Create an atomic operator
#
# An atomic operator has the type set to NGS_OP_ATOMIC. Atomic
#  operators are applied immediately after selection and do not generate
#  substates. You rarely need to construct atomic operators directly. Instead
#  most of the macros that create objects (goals, primitives, tags, and typed objects)
#  all have special macros for creation by operator.  Those other macros call this
#  macro internally and do some additional things that make construction easier.
#
# [ngs-create-atomic-operator state_id op_name new_obj_id (add_prefs)]                                         
#
# state_id - variable bound to the state in which the operator should be proposed
# op_name  - name of the operator (this prints out on the state stack in Soar)
# new_obj_id - the variable that will be bound to the
#               newly constructed operator.
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#
proc ngs-create-atomic-operator { state_id
                                  op_name
                                  new_obj_id
                                 {add_prefs "="} } {
  CORE_RefMacroVars
  return "[ngs-create-operator $state_id $op_name $NGS_OP_ATOMIC $new_obj_id $add_prefs]
          [core-trace NGS_TRACE_ATOMIC_OPERATORS "I PROPOSE-ATOMIC, | $state_id |.operator | $new_obj_id |)."]"                                 
}
            
# Create a decision operator
#
# Decision operators are of type NGS_OP_DECIDE. Decision operators do not have apply 
#  productions, instead they trigger an operator no change.
# In the resulting sub-state the operator's actions can be determined and sequenced. Return
#  values are set via the ngs-add-ret-val macro. If an operator needs to set static
#  flags or return values in order to properly return, these can be passed into the 
#  substate via the ret_val_list parameter.
#
# [ngs-create-decide-operator state_id op_name new_obj_id ret_val_set_id goal_id (completion_tag) (add_prefs)]
#
# state_id - variable bound to the state in which the operator should be proposed
# op_name  - name of the operator (this prints out on the state stack in Soar)
# new_obj_id - the variable that will be bound to the newly constructed operator.
# ret_val_set_id - variable to be bound to the operator's return value set. You can use this
#                   to specify where to place sub-state return values. See the macro
#                   ngs-create-ret-val-in-place for info on how to create these return values.
# goal_id - a variable bound to the goal associated with this decide operator. All decide operators
#            should be created to achieve some goal. This goal becomes the active goal upon selection
#            of the decide operator.
# completion_tag - (Optional) the name of a boolean tag that should be placed on the goal given by
#                     goal_id after completion of the decision operator's sub-state. This can be
#                     used to do simple process tagging (i.e. finished step 1).                   
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
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

   return "$rhs_val
           [core-trace NGS_TRACE_DECIDE_OPERATORS "I PROPOSE-DECIDE, $op_name for goal | $goal_id |, (| $state_id |.operator | $new_obj_id |)."]"
}

# Create an i-supported goal
#
# Use this macro to create i-supported goals. I-supported goals should be configured
#  such that they go away when they achieved (unless they are maintenance goals).
#  For o-support goals use ngs-create-goal-by-operator or (in sub-states) 
#  ngs-create-goal-as-return-value. I-Supported maintenance goals should be combined
#  with a production or process that marks them as achieved when conditions are met.
#  See ngs-tag-goal-achieved.
#
# [ngs-create-goal-in-place goal_set_id goal_name type new_obj_id (supergoal_id) (attribute_list)]
#
# goal_set_id - variable bound to the goal set in which to place this goal. Bind this
#                variable on the left side using macro ngs-match-goalpool or ngs-match-goal.
# goal_name - user-defined name of the goal to construct
# type - type of the goal. One of NGS_GB_ACHIEVE or NGS_GB_MAINT for achievement and
#          maintenance goals respectively. Achievement goals are removed upon achievement
#          while maintenance goals are not removed.
# new_obj_id - variable that will be bound to the id of the newly constructed goal
# supergoal_id - (Optional) if provided, this is a varaible bound to the goal that will
#                  serve as the supergoal for this goal. 
# attribute_list - (Optional) List of attribute, value pairs for the given object. If attributes is a set
#                  (i.e. a multi-valued attribute), put the set values in a list (see example above).
#
proc ngs-create-goal-in-place { goal_set_id 
                                goal_name 
                                type 
                                new_obj_id 
                                {supergoal_id ""} 
                                {attribute_list ""} } {

  CORE_RefMacroVars
  variable lhs_val

  lappend attribute_list name $goal_name type $type
  if { $supergoal_id != "" } {
    lappend attribute_list supergoal $supergoal_id
  }

  set lhs_val "[ngs-create-attribute $goal_set_id $NGS_GOAL_ATTRIBUTE $new_obj_id]
               [ngs-construct $new_obj_id $goal_name $attribute_list]
               [ngs-tag $new_obj_id $NGS_TAG_CONSTRUCTED]
               [ngs-tag $new_obj_id $NGS_TAG_I_SUPPORTED]
               [core-trace NGS_TRACE_I_GOALS "I CREATE-GOAL, $goal_name, | $new_obj_id |, $type."]"

  return $lhs_val   
}

# Create an o-supported goal
#
# Use this macro to create o-supported goals. To create i-supported goals use 
#  ngs-create-goal-in-place. 
#
# [ngs-create-goal-by-operator state_id goal_name type new_obj_id (supergoal_id)]
#
# state_id - variable bound to the state in which the operator should be proposed
# goal_name - user-defined name of the goal to construct
# type - type of the goal. One of NGS_GB_ACHIEVE or NGS_GB_MAINT for achievement and
#          maintenance goals respectively. Achievement goals are removed upon achievement
#          while maintenance goals are not removed.
# new_obj_id - variable that will be bound to the id of the newly constructed goal
# supergoal_id - (Optional) if provided, this is a varaible bound to the goal that will
#                  serve as the supergoal for this goal. 
# attribute_list - (Optional) List of attribute, value pairs for the given object. If attributes is a set
#                  (i.e. a multi-valued attribute), put the set values in a list (see example above).
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#
proc ngs-create-goal-by-operator { state_id
                                   goal_name
                                   type
                                   new_obj_id
                                   {supergoal_id ""}
                                   {attribute_list ""} 
                                   {add_prefs "="} } {

  CORE_RefMacroVars
  variable lhs_val

  lappend attribute_list name $goal_name type $type
  if { $supergoal_id != "" } {
    lappend attribute_list supergoal $supergoal_id
  }

  set op_id [CORE_GenVarName "o"]

  set lhs_val "[ngs-create-atomic-operator $state_id "(concat |create-goal--$goal_name--| $new_obj_id)" $op_id $add_prefs]
               [ngs-create-attribute $op_id new-obj $new_obj_id]
               [ngs-tag $op_id $NGS_TAG_INTELLIGENT_CONSTRUCTION]
               [ngs-tag $op_id $NGS_TAG_CREATE_GOAL]
               [ngs-construct $new_obj_id $goal_name $attribute_list]
               [core-trace NGS_TRACE_O_GOALS "O CREATE-GOAL, $goal_name, | $new_obj_id |, $type."]"

  return $lhs_val   
}        


# Create a goal to be returned from a sub-state
#
# Creates a special return value in a sub-state that will result in a new goal
#  being created in the top-state, once the sub-state is completed.
#
# Typically it's not a good idea to make changes to the top-state until you are done with
#  sub-state processing (though NGS doesn't prevent this). This includes goal creation
#  which can be done using the standard macro (ngs-create-goal-by-operator) even in a sub-state.
#  However, if you do this the goal will get created in the middle of the sub-state. 
# If you want the goal to get created at the end of the sub-state (upon return), then
#  use this macro. The goal structure will be created temporarily in the sub-state and
#  stored in the return value set. Then, upon completion of the sub-state it will be moved
#  to the top-state goal pool.
#
# [ngs-create-goal-as-return-value state_id goal_name goal_type new_obj_id (supergoal_id) (goal_pool_id) (add_prefs)]
#
# state_id - variable bound to the _sub-state_ in which the operator to create the goal should be proposed.
# goal_name - user-defined name of the goal to construct
# goal_type - type of the goal. One of NGS_GB_ACHIEVE or NGS_GB_MAINT for achievement and
#              maintenance goals respectively. Achievement goals are removed upon achievement
#              while maintenance goals are not removed.
# new_obj_id - variable that will be bound to the id of the newly constructed goal
# supergoal_id - (Optional) if provided, this is a varaible bound to the goal that will
#                  serve as the supergoal for this goal.
# attribute_list - (Optional) List of attribute, value pairs for the given object. If attributes is a set
#                  (i.e. a multi-valued attribute), put the set values in a list (see example above).
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#
proc ngs-create-goal-as-return-value { state_id
                                       goal_name
									                     goal_type
                                       new_obj_id
                                       {supergoal_id ""}
                                       {attribute_list ""} 
                                       {add_prefs "="} } {
    
  CORE_RefMacroVars
  variable rhs_val

  lappend attribute_list name $goal_name type $goal_type
  if { $supergoal_id != "" } {
    lappend attribute_list supergoal $supergoal_id
  }

  set ret_val_id [CORE_GenVarName new-ret-val]
  set op_id [CORE_GenVarName "o"]

  set rhs_val "[ngs-create-atomic-operator $state_id "(concat |return-goal--$goal_name--| $new_obj_id)" $op_id $add_prefs]
	             ($op_id ^dest-attribute        value-description
                    ^new-obj               $ret_val_id
                    ^replacement-behavior  $NGS_ADD_TO_SET)
               ($ret_val_id ^name                  $NGS_GOAL_RETURN_VALUE
                            ^destination-attribute $NGS_GOAL_ATTRIBUTE
                            ^replacement-behavior  $NGS_ADD_TO_SET
                            ^value    $new_obj_id)
               [ngs-construct $new_obj_id $goal_name $attribute_list]
               [ngs-tag $op_id $NGS_TAG_INTELLIGENT_CONSTRUCTION]
               [ngs-tag $op_id $NGS_TAG_CREATE_GOAL_RET]
               [core-trace NGS_TRACE_RETURN_VALUES "O CREATE-GOAL-RETURN, $goal_name, | $new_obj_id |, $goal_type."]
               [core-trace NGS_TRACE_O_GOALS "O CREATE-GOAL, $goal_name, | $new_obj_id |, $goal_type."]"
                   
  return $rhs_val
   
}                  

# Request a decision for an _i-supported_ goal object
#
# Decisions are named representations of a choice. Decisions
#  are augmentations of goals (achievement or maintenance).
#  A decision is represented by an object attribute (WME)
#  that should be constructed as a result of a decision. For
#  example, your agent might decide on a movement type. This
#  decision would be represented by creating a WME that 
#  links to an object describing the selected movement.
#
# # It is ok to request multiple decisions for a goal. For example,
#  you might request a decision to select a maneuver method and
#  you might request a decision to select a maneuver speed
#
# This version is specifically designed for i-supported goals.
#   USe ngs-orequest-decision for o-supported goals.
#
# [ngs-irequest-decision goal_id decision_name dec_obj dec_attr replacement_behavior]
#
# goal_id - variable bound to the goal identifier to which to assign the decision
# decision_name - your name for the decision (e.g. movement-method)
# dec_obj - variable bound to the object to recieve the decision attribute
# dec_attr - the attribute that links the dec_obj to the decision information (e.g
#              links the object to the movement method information). Subgoals set
#              the object linked to this attribute after making the decision.
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
# 
proc ngs-irequest-decision { goal_id 
                            decision_name 
                            dec_obj 
                            dec_attr 
                            { replacement_behavior ""} } {

   CORE_RefMacroVars
   CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

   set decision_id [CORE_GenVarName "_decision"]
   set attr_list "name $decision_name destination-object $dec_obj destination-attribute $dec_attr replacement-behavior $replacement_behavior" 

   return "[ngs-icreate-typed-object-in-place $goal_id $NGS_DECISION_ATTR $NGS_TYPE_DECISION_STRUCTURE $decision_id $attr_list]
           [core-trace NGS_TRACE_DECISIONS "I REQUEST-DECISION, $decision_name, for goal | $goal_id | result to (| $dec_obj |.$dec_attr)."]"
}

# Request a decision for an _o-supported_ goal object
#
# Decisions are named representations of a choice. Decisions
#  are augmentations of goals (achievement or maintenance).
#  A decision is represented by an object attribute (WME)
#  that should be constructed as a result of a decision. For
#  example, your agent might decide on a movement type. This
#  decision would be represented by creating a WME that 
#  links to an object describing the selected movement.
#
# It is ok to request multiple decisions for a goal. For example,
#  you might request a decision to select a maneuver method and
#  you might request a decision to select a maneuver speed
#
# This version is specifically designed for o-supported goals.
#   USe ngs-irequest-decision for i-supported goals.
#
# [ngs-orequest-decision goal_id decision_name dec_obj dec_attr replacement_behavior]
#
# goal_id - variable bound to the goal identifier to which to assign the decision
# decision_name - your name for the decision (e.g. movement-method)
# dec_obj - variable bound to the object to recieve the decision attribute
# dec_attr - the attribute that links the dec_obj to the decision information (e.g
#              links the object to the movement method information). Subgoals set
#              the object linked to this attribute after making the decision.
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
# 
proc ngs-orequest-decision { goal_id 
                            decision_name 
                            dec_obj 
                            dec_attr 
                            { replacement_behavior ""} } {

   CORE_RefMacroVars
   CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

   set decision_id [CORE_GenVarName "_decision"]
   set attr_list "name $decision_name destination-object $dec_obj destination-attribute $dec_attr replacement-behavior $replacement_behavior" 

   return "[ngs-ocreate-typed-object-in-place $goal_id $NGS_DECISION_ATTR $NGS_TYPE_DECISION_STRUCTURE $decision_id $attr_list]
           [core-trace NGS_TRACE_DECISIONS "o REQUEST-DECISION, $decision_name, for goal | $goal_id | result to (| $dec_obj |.$dec_attr)."]"
}

# Assigns a decision to a goal
#
# Assigning a decision to a goal implies that this goal will make the given
#  decision. By definition decisions imply that there are likely to be more
#  than one way to make a decision and thus more than one goal might
#  be assigned the same decision.
# 
# Typically a goal is used to make only one decision (though it may
#  request multiple decisions). The NGS does nothing to enforce this
#  constraint though.
# 
# This method works for both i-supported and o-supported goals. The support given
#  to the assignment is defined by the support of the production that uses the macro
#
# [ngs-assign-decision goal_id decision_name activate_on_decision]
#
# goals_id - variable bound to the goal identifer to which to assign the decision
# decision_name - the name of the decision to assign to the goal
#
# activate_on_decision - (Optional) If provided, marks the goal to be activated 
#    after it is selected in a decision. Activated goals generate sub-states
#    NOTE: this isn't configured to work yet because there doesn't appear
#     to be a general way to retract the activation operator.
#
proc ngs-assign-decision { goal_id decision_name {activate_on_decision ""} } {
  CORE_RefMacroVars

  if { $activate_on_decision != $NGS_YES } {
      return "($goal_id ^$NGS_DECIDES_ATTR $decision_name)
              [core-trace NGS_TRACE_DECISIONS "? ASSIGN-DECISION, $decision_name, for goal | $goal_id |, AutoActivate = $NGS_NO."]"
  } else {
      return "($goal_id ^$NGS_DECIDES_ATTR $decision_name)
              [ngs-tag $goal_id $NGS_TAG_ACTIVATE_ON_DECISION]
              [core-trace NGS_TRACE_DECISIONS "? ASSIGN-DECISION, $decision_name, for goal | $goal_id |, AutoActivate = $NGS_YES."]"
  }
}

# Creates a structure that defines a return value
#
# Typically you create return value structures when constructing a decide operator.
# These are created with i-support right on the operator. The sub-state code uses
#  the information from this return value structure to determine where to place its
#  return values
#
# [ngs-create-ret-val-in-place ret_val_name ret_val_set_id dest_obj_id attribute (new_val) (replacement_bheavior)]
#
# ret_val_name - Name of the return value. The decide operator should document the return values it constructs such
#  that when you create this operator you know which return values to create. Note that you can create additional 
#  return values (e.g. flags to set) that aren't required by the sub-state. If you do this, you'll need to specify
#  the value for the return value.
# ret_val_set_id - Variable bound to the return value set on the operator. You bind this variable using the
#                    ngs-create-decide-operator macro.
# dest_obj_id - Variable bound to the id of the object that should recieve the return value. If not passed,
#                  the destination object is not set (used internally by NGS)
# attribute - (Optional) Name of the attribute to which the return value should be bound. If not passed, the
#                  destination attribute remains unset (can be used internally by NGS)
# new_val - (Optional) The value of the return value. You only set this if you are creating hour own return
#             value. Leave this empty if you are specifying where to put a return value that will be created
#             in the sub-state
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
#
proc ngs-create-ret-val-in-place { ret_val_name
                                   ret_val_set_id
                                   {dest_obj_id ""}
                                   {attribute ""}
                                   {new_val ""} 
                                   {replacement_behavior ""} } {

    CORE_RefMacroVars
    CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

    set ret_val_id [CORE_GenVarName new-ret-val]
    set attr_list "name $ret_val_name replacement-behavior $replacement_behavior" 

    if { $dest_obj_id != "" } {
      set attr_list "$attr_list destination-object $dest_obj_id"
    }
    if { $attribute != "" } {
      set attr_list "$attr_list destination-attribute $attribute"
    }
    if { $new_val != "" } {
      set attr_list "$attr_list value $new_val"
    } 

    return [ngs-icreate-typed-object-in-place $ret_val_set_id value-description $NGS_TYPE_STATE_RETURN_VALUE $ret_val_id $attr_list]
}

# Creates a return tag on an operator
#
# This macro does the same thing as ngs-create-ret-val-in-place except that it creates a tag. Because you
#  can create return tags as part of decide operator construction (see ngs-create-decide-operator) it is
#  not likely that you will need to use this macro often. However, if sub-state code creates tags as part
#  if its return value set, you will need to macro to tell the sub-state where to put the tag.
#
# [ngs-create-ret-tag-in-place ret_val_name ret_val_set_id dest_obj_id tag_name tag_val replacement_behavior]
#
# ret_val_name - Name of the return value. The decide operator should document the return values it constructs such
#  that when you create this operator you know which return values to create. Note that you can create additional 
#  return values (e.g. flags to set) that aren't required by the sub-state. If you do this, you'll need to specify
#  the value for the return value.
# ret_val_set_id - Variable bound to the return value set on the operator. You bind this variable using the
#                    ngs-create-decide-operator macro.
# dest_obj_id - Variable bound to the id of the object that should recieve the return value. If you pass in
#                    an empty string (or leave out), the destination object remains unset (used internally by NGS)
# tag_name - Name of the tag to construct in the return set.                  
# tag_val - (Optional) The value of the tag. By default this will be NGS_YES
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
#
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

# Creates a return value that will mark a goal as decided in the super-state
#
# In a decision sub-state, multiple domain code chooses between two or more
#  goals as the way to solve a problem. This macro is used by the production
#  that selects one goal over the others. It will set the return value for
#  the sub-state.
#
# [ngs-make-choice-by-operator state_id choice_id]
#
# state_id  - state in which to propose the operator to make the choice
# choice_id - variable bound to the identifier of the goal that was chosen
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#
proc ngs-make-choice-by-operator { state_id choice_id {add_prefs "="}} {
  CORE_RefMacroVars
  set op_id [CORE_GenVarName "o"]
  
  return "[ngs-create-atomic-operator $state_id "(concat |select-option--| $choice_id)" $op_id $add_prefs]
                  ($op_id ^replacement-behavior $NGS_REPLACE_IF_EXISTS
                          ^new-obj              $NGS_YES
                          ^ret-val-name         $NGS_DECISION_RET_VAL_NAME
                          ^choice               $choice_id)
           [ngs-tag $op_id $NGS_TAG_INTELLIGENT_CONSTRUCTION]
           [ngs-tag $op_id $NGS_TAG_SET_RETURN_VALUE]
           [core-trace NGS_TRACE_DECISIONS "O SELECTED-GOAL, | $choice_id | in state | $state_id |."]"
}

# Sets the value of a return value.
#
# Use this macro when writing modular sub-state to set a return value. You don't
#  use this macro in the super-state. 
#
# NOTE: This may need a "replacement_behavior" parameter to say whether to replace the value.
#        Right now it is NGS_REPLACE_IF_EXISTS meaning that you can't create
#        multi-valued return values direction (you could via indirections - e.g.
#        by creating a set object and putting the set values within it ... the set
#        object could be the return value).
#
# 
# [ngs-set-ret-val-by-operator state_id ret_val_name value (add_prefs)]
#
# state_id - variable bound to the _sub-state_ in which the operator to set the return value should be created.
# ret_val_name - name of the return value to set
# value - value of the return value to set
# add_prefs - (Optional) any additional operator preferences over acceptable (+). By default 
#  the indifferent preference is given but you can override using this argument.
#
proc ngs-set-ret-val-by-operator { state_id
                                   ret_val_name 
                                   value 
                                   {add_prefs "="} } {

    CORE_RefMacroVars
    set op_id [CORE_GenVarName "o"]

    return "[ngs-create-atomic-operator $state_id "(concat |return--$ret_val_name--| $value)" $op_id $add_prefs]
                  ($op_id ^replacement-behavior $NGS_REPLACE_IF_EXISTS
                          ^new-obj              $value
                          ^ret-val-name         $ret_val_name)
            [ngs-tag $op_id $NGS_TAG_INTELLIGENT_CONSTRUCTION]
            [ngs-tag $op_id $NGS_TAG_SET_RETURN_VALUE]
            [core-trace NGS_TRACE_RETURN_VALUES "O SET-RETURN, $ret_val_name = $value."]"

}

# Create a typed object to use as a return value
#
# Typically this macro is used in sub-states to create complex return types. Alternatively,
#  you can create return types on the sub-state using multiple staeps and then just copy
#  the root of the return value to the return value structure using ngs-set-ret-val-by-operator.
#
# [ngs-create-typed-object-for-ret-val state_id ret_val_name type_name new_obj_id (attribute_list)]
#
# state_id - Variable bound to the sub-state identifier
# ret_val_name - Name of the return value to set
# type_name - Name of the type of object to create (declare first with NGS_DeclareType)
# new_obj_id - Variable to bind to the newly created return value                                               
# attribute_list - (Optional) List of attribute, value pairs for the given object. If attributes is a set
#                  (i.e. a multi-valued attribute), put the set values in a list (see example above).
#
proc ngs-create-typed-object-for-ret-val { state_id
                                           ret_val_name
                                           type_name
                                           new_obj_id 
 										                       { attribute_list "" } } {

   CORE_RefMacroVars
   set op_id [CORE_GenVarName "o"]

   return  "[ngs-create-atomic-operator $state_id "(concat |return--$ret_val_name--| $type_name |--| $new_obj_id)" $op_id]
                  ($op_id ^replacement-behavior $NGS_REPLACE_IF_EXISTS
                          ^ret-val-name         $ret_val_name)
            [ngs-ocreate-typed-object-in-place $op_id new-obj $type_name $new_obj_id $attribute_list]
            [ngs-tag $op_id $NGS_TAG_INTELLIGENT_CONSTRUCTION]
            [ngs-tag $op_id $NGS_TAG_SET_RETURN_VALUE]
            [core-trace NGS_TRACE_RETURN_VALUES "O CREATE-RETURN, $ret_val_name = $type_name, | $new_obj_id |."]"

}

