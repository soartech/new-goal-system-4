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

######## Basic left hand side condition test macros ###########
# Basic comparisons
#
# Use this sequence of macros to do tests on the left hand side
#  of productions. Each macro allows you to do a test AND bind
#  the value as a separate action (if desired). If you want to
#  quickly bind several attributes of an object, use ngs-bind
#  instead.
#
# [ngs-COMP obj_id attr val (val_id)]
#
# obj_id - variable bound to the object to test
# attr   - attribute to test
# val    - value to compare to
# val_id - (Optional) if provided, will be bound to the
#            value (separately from the test)
#
proc ngs-eq { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  # Probably should put in some processing to handle disjunctions
  return [ngs-test $NGS_TEST_EQUAL $obj_id $attr $val $val_id]
}

# NOT Equal to
#
# Note that this is more general than just "<>". It will correctly
#  handle cases when the attribute you are testing doesn't exist
#  so long as you don't bind to the variable (i.e. don't pass in
#  a val_id). You cannnot bind to an attribute that doesn't exist
#  so the standard inequality method (<>) is used when you do need
#  to bind.
#
proc ngs-neq { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  # If not binding is provided, we use the more comprehensive
  #  negation that will match even if the attribute doesn't exist
  if {$val_id == ""} {
    return "-{ [ngs-test $NGS_TEST_EQUAL $obj_id $attr $val $val_id] }"
  } else {
    return [ngs-test $NGS_TEST_NOT_EQUAL $obj_id $attr $val $val_id]
  }
}
# Less Than "<"
proc ngs-lt { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  return [ngs-test $NGS_TEST_LESS_THAN $obj_id $attr $val $val_id]
}
# Less Than or Equal To "<="
proc ngs-lte { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  return [ngs-test $NGS_TEST_LESS_THAN_OR_EQUAL $obj_id $attr $val $val_id]
}
# Greater Than ">"
proc ngs-gt { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  return [ngs-test $NGS_TEST_GREATER_THAN $obj_id $attr $val $val_id]
}
# Greater Than or Equal To ">="
proc ngs-gte { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  return [ngs-test $NGS_TEST_GREATER_THAN_OR_EQUAL $obj_id $attr $val $val_id]
}

# Negated versions of the inequality comparisons (useful for input-link testing)
proc ngs-nlt { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  return "-{[ngs-test $NGS_TEST_LESS_THAN $obj_id $attr $val $val_id]}"
}
proc ngs-nlte { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  return "-{[ngs-test $NGS_TEST_LESS_THAN_OR_EQUAL $obj_id $attr $val $val_id]}"
}
proc ngs-ngt { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  return "-{[ngs-test $NGS_TEST_GREATER_THAN $obj_id $attr $val $val_id]}"
}
proc ngs-ngte { obj_id attr val { val_id ""} } {
  CORE_RefMacroVars
  return "-{[ngs-test $NGS_TEST_GREATER_THAN_OR_EQUAL $obj_id $attr $val $val_id]}"
}

# Range versions of the inequality comparisons
proc ngs-gte-lt { obj_id attr low_val high_val { val_id ""} } {
  CORE_RefMacroVars
  return "[ngs-test $NGS_TEST_GREATER_THAN_OR_EQUAL $obj_id $attr $low_val $val_id]
          [ngs-test $NGS_TEST_LESS_THAN $obj_id $attr $high_val]"
}
proc ngs-gte-lte { obj_id attr low_val high_val { val_id ""} } {
  CORE_RefMacroVars
  return "[ngs-test $NGS_TEST_GREATER_THAN_OR_EQUAL $obj_id $attr $low_val $val_id]
          [ngs-test $NGS_TEST_LESS_THAN_OR_EQUAL $obj_id $attr $high_val]"
}

# Evaluates to true when an attribute does NOT exist
#
# This is equivilent to -^attribute sytax in Soar, but is
#  consistent with the NGS naming/syntax scheme
#
# [ngs-nex object_id attribute]
#
# object_id - variable bound to the object to test
# attribute - the attribute to test for lack of existence
proc ngs-nex { object_id attribute } {
  return "($object_id -^$attribute)"
}

# Bind variables to an object's attributes
# 
# Use this macro to quickly and easily bind variables to an object's
#  attributes. The variables will have the same name as the attributes.
#  E.g. an attribute called "foo" will be bound to the variable <foo>.
#
# You can also use this macro to quick bind chains of attributes. E.g.
#  you can bind system.time to <system> and <time> by doing the following
#  [ngs-bind <input-link> system.time]. 
#
# If you need any attribute to bind to a variable with a different name
#  than the attribute, you can indicate this via the : symbol. E.g.
#  [ngs-bind <input-link> system:<sys>.time:<my-time>] which will convert
#  to the following Soar code:
#  (<input-link> ^system <sys>)
#  (<sys>        ^time   <my-time>)
#
# Finally, if you want, you can constrain a binding to only occur
#  for attributes of a specific type using the ! operator. E.g.
#  [ngs-bind <input-link> agent!RobotAgent:<me>.location!Location] will expand to
#  (<input-link> ^agent <me>)
#  (<me>         ^type RobotAgent)
#  (<me>         ^location <location>)
#  (<location>   ^type Location)
#  
# [ngs-bind obj_id attr1 attr2 ...]
#
# obj_id - variable bound to the object for which to bind attributes
# attr_list - list of attributes to bind
#
proc ngs-bind { obj_id args } {
  set lhs_ret ""

  foreach attr $args {
    set obj $obj_id

    # Handles dot notation
    set segments [split $attr "."]
    foreach segment $segments {

      # Handle renaming the attributes in variable names
      set names [split $segment ":"]
      if { [llength $names] > 1} {
        set attr_name [lindex $names 0]
        set attr_var  [lindex $names 1]
      } else {
        set attr_name $segment
        set attr_var  "<$segment>"
      }

      # Handle case of testing the type
      set attr_type_pair [split $attr_name "!"]
      if { [llength $attr_type_pair] > 1} {
        set attr_name [lindex $attr_type_pair 0]
        set attr_type [lindex $attr_type_pair 1]

        if { [llength $names] < 2 } {
          set attr_var "<$attr_name>"
        }

      } else {
        set attr_type ""
      }

      if { $lhs_ret == "" } {
        set lhs_ret "($obj ^$attr_name $attr_var)"
      } else {
        set lhs_ret "$lhs_ret
                     ($obj ^$attr_name $attr_var)"        
      }

      if { $attr_type != "" } {
        set lhs_ret "$lhs_ret
                     [ngs-is-type $attr_var $attr_type]"
      }

      # prep for next iteration
      set obj $attr_var 
    }

  }
  return $lhs_ret
}

# The general test macro
#
# This macro is used by the more specific test macros to 
#  generate the Soar code for left hand side tests. You
#  typically don't need to use this in your productions.
#
# test_type - one of the NGS_TEST constants specifying the
#              type of comparison to do
# obj_id - variable bound to the object to test
# attr   - the attribute to test
# val    - the comarison value (the value to compare to)
# val_id - (Optional) if provided, this variable will be bound
#          to the value. 
#
proc ngs-test { test_type obj_id attr val { val_id ""} } {
  if { $val_id == "" } {
    return "($obj_id ^$attr $test_type $val)"
  } else {
    return "($obj_id ^$attr \{ $val_id $test_type $val \})"
  }
}

############## Other standard testing macros ##########################

# Binds to the time variables on the input link 
#
# Use to get the time for use in an agent
#
# [ngs-time state_id time (time_id) (time_test) (input_link_id)]
#
# state_id - variable bound to the state object 
# time - variable to bind to the time or a constant to test the time 
# time_id - (Optional) if you are testing the time (and not just binding)
#            you can pass a variable name to bind to the time
# time_test - (Optional) if you wish to compare the test to some value,
#              pass one of the NGS_TEST constants in this parameter
# input_link_id - (Optional) if provided, a variable that will be bound
#                   to the input link identifier
# 
proc ngs-time { state_id time {time_id ""} {time_test ""} {input_link_id ""}} {
  
  CORE_RefMacroVars

  set system_id [CORE_GenVarName "system"]

  CORE_GenVarIfEmpty input_link_id "input-link"
  CORE_SetIfEmpty time_test $NGS_TEST_EQUAL
  
  set lhs_ret "[ngs-input-link $state_id $input_link_id]
               ($input_link_id ^system $system_id)"

  return "$lhs_ret
          [ngs-test $time_test $system_id time $time $time_id]"
}

# Same as ngs-time, but tests for time being between two values (using ngs-gte-lt)
#
# [ngs-time-range state_id start_time end_time (time_id) (input_link_id)]
#
proc ngs-time-range { state_id start_time end_time { time_id "" } { input_link_id "" }} {
  set system_id [CORE_GenVarName "system"]
  CORE_GenVarIfEmpty input_link_id "input-link"
  
  set lhs_ret "[ngs-input-link $state_id $input_link_id]
               ($input_link_id ^system $system_id)"

  return "$lhs_ret
          [ngs-gte-lt $system_id time $start_time $end_time $time_id]"  
}

# Same as ngs-time, except for the cycle cycle-count
#
# [ngs-cycle state_id cycle (cycle_id) (cycle_test) (input_link_id)]
#
proc ngs-cycle { state_id cycle {cycle_id ""} {cycle_test ""} {input_link_id ""}} {
  set system_id [CORE_GenVarName "system"]
  CORE_GenVarIfEmpty input_link_id "input-link"
  
  set lhs_ret "[ngs-input-link $state_id $input_link_id]
               ($input_link_id ^system $system_id)"

  return "$lhs_ret
          [ngs-test $cycle_test $system_id cycle-count $cycle $cycle_id]"
}

# Binds to an object's type, if it has a type attribute
#
# [ngs-is-type object_id type_name]
#
# If the object has more than one type, this will bind to them all
#  (though later tests may filter out some of the bindings)
#
proc ngs-is-type { object_id type_name } {
  return "($object_id ^type $type_name)"
}

# Evaluates to true if the given object is not of the given type
# 
# [ngs-is-not-type object_id typename]
#
proc ngs-is-not-type { object_id type_name } {
  return "-($object_id ^type $type_name)"
}

# Binds to an object's name, if it has a name attribute
#
# [ngs-is-named object_id name]
#
# Goals and operators are the standard NGS named objects
# NGS names are not required to be unique, and are typically designed
#  to be descriptive enough to help identify an object during debugging
#
proc ngs-is-named { object_id name } {
  return "($object_id ^name $name)"
}

# Evaluates to true if the given object does not have the given name
# 
# [ngs-is-not-named object_id typename]
#
proc ngs-is-not-named { object_id name } {
  return "($object_id -^name $name)"
}

# Evaluates to true if the given object's most derived type is type_name
# 
# The most derived type is denoted as "my-type"
#
# [ngs-is-my-type object_id type_name]
#
proc ngs-is-my-type { object_id type_name } {
  return "($object_id ^my-type $type_name)"
}

# Evaluates to true if the given object's most derived type is NOT type_name
# 
# The most derived type is denoted as "my-type"
#
# [ngs-is-not-my-type object_id type_name]
#
proc ngs-is-not-my-type { object_id type_name } {
  return "($object_id -^my-type $type_name)"
}

# Binds to a given tag, if the tag exists.
#
# A list of the NGS built-in tags can be found in ngs-variables.tcl
#
# [ngs-is-tagged object_id tag_name *tag_val]
#
# If tag_val is not provided, it is defaulted to NGS_YES
#
# Tags are prefixed by a special string, so you cannot
proc ngs-is-tagged { object_id tag_name {tag_val "" } } {
  CORE_RefMacroVars
  CORE_SetIfEmpty tag_val $NGS_YES
  return "($object_id  ^[ngs-tag-for-name $tag_name] $tag_val)"
}

# Evaluates to true if the given object does not have the given tag
#
# A list of the NGS built-in tags can be found in ngs-variables.tcl
# 
# [ngs-is-not-tagged object_id typename]
#
proc ngs-is-not-tagged { object_id tag_name {tag_val "" } } {
  CORE_RefMacroVars
  CORE_SetIfEmpty tag_val $NGS_YES
  return "-($object_id ^[ngs-tag-for-name $tag_name] $tag_val)"
}

########################################################
## Goal states (normally don't need to test this way, but sometimes need to)
########################################################

# Evaluates to true if the given goal is active
#
# An Active goal is one that is bound to a selected decide operator
#  (i.e. that has no-changed to a sub-state) or one of its supergoals.
#
# This macro tests the goal's tags to see if it is active.
# Use some other macro to bind to the goal itself.
#
# Typically you will bind to active goals using ngs-match-active-goal
#  or ngs-match-top-state-active-goal.
#
# [ngs-is-active <goal>]
#
proc ngs-is-active { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-tagged $goal_id $NGS_GS_ACTIVE]"
}

# Evaluates to true if the given goal is NOT active
#
# An Active goal is one that is bound to a selected decide operator
#  (i.e. that has no-changed to a sub-state) or one of its supergoals.
#
# This macro tests the goal's tags to see if it is not active.
# You cannot use this macro to bind to the goal or to the active tag.
#
# [ngs-is-not-active goal_id]
#
proc ngs-is-not-active { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-not-tagged $goal_id $NGS_GS_ACTIVE]"
}


# Evaluates to true if the given goal is tagged NGS_GS_ACHIEVED
#
# O-supported goals are marked achieved using ngs-tag-goal-achieved (typically)
#  under domain-specific conditions for the given model)
#
# This macro tests the goas's tags and cannot be used to bind to the
#  goal itself. 
#
# Note that this macro will only ever evaluate to true for o-supported goals.
# I-supported goals are retracted when achieved.
#
# [ngs-is-achieved goal_id]
#
proc ngs-is-achieved { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-tagged $goal_id $NGS_GS_ACHIEVED]"
}

# Evaluates to true if the given goal is not tagged NGS_GS_ACHIEVED
#
# O-supported goals are marked achieved using ngs-tag-goal-achieved (typically)
#  under domain-specific conditions for the given model)
#
# This macro tests the goas's tags and cannot be used to bind to the
#  goal itself. 
#
# [ngs-is-achieved goal_id]
#
proc ngs-is-not-achieved { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-not-tagged $goal_id $NGS_GS_ACHIEVED]"
}

# Evaluates to true if a decision has been made on this goal
#
# [ngs-has-decided goal_id (decision_value)]
#
# goal_id - variable bound to the goal identifer to check for a decision
# decision_value - (Optional) can be a variable or constant (NGS_YES/NGS_NO)
#      that binds to the value of the decision. NGS_YES means that this
#      goal _was_ selected to make the decision while NGS_NO means that the
#      goal was not selected to make the decision. Note that if this is not
#      provided, this macro will match either a YES or NO decision.
# 
proc ngs-has-decided { goal_id { decision_value "" } } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty decision_value "decision-value"
  return "[ngs-is-tagged $goal_id $NGS_TAG_DECIDED $decision_value]"
}

# Evaluates to true if a decision has NOT been made on this goal
#
# [ngs-has-not-decided goal_id (decision_value)]
#
# goal_id - variable bound to the goal identifer to check for a decision
# decision_value - (Optional) can be a variable or constant (NGS_YES/NGS_NO)
#      that binds to the value of the decision. NGS_YES means that this
#      goal _was_ selected to make the decision while NGS_NO means that the
#      goal was not selected to make the decision. Note that if this is not
#      provided, this macro will match either a YES or NO decision.
# 
proc ngs-has-not-decided { goal_id { decision_value "" } } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty decision_value "__decision-value"
  return "[ngs-is-not-tagged $goal_id $NGS_TAG_DECIDED $decision_value]"
}

# Evaluates to true if the given goal has been assigned a given decision
#
# [ngs-is-assigned-decision goal_id decision_name]
#
# goal_id - goal to test for whether it has been assigned a decision
# decision_name - name of the decision to test foreach 
#
proc ngs-is-assigned-decision { goal_id decision_name } {
  CORE_RefMacroVars
  return "($goal_id ^$NGS_DECIDES_ATTR $decision_name)"
}

# Evaluates to true and binds to the decision information if the given
#  goal has requested a decision of the gien name
#
# The typical use for this macro is to create and act for goals that
#  make decisions. You would use this macro to determine whether a goal's
#  supergoal has requested a decision to be made. If necessary, you can
#  bind to the information about the decision to be made and get the
#  decision's object and attribute.
#
# [ngs-requested-decision goal_id decision_name (decision_obj) (decision_attr) (replacement_behavior) (decision_info_id)]
#
# goal_id - variable bound to the goal for which to check for a requested decision
# decision_name - name of the decision to check for being requested
# decision_obj - (Optional) a variable to bind to the decision object (object that
#                  recieves the result of the decision)
# decision_attr - (Optional) a variable to bind to the decision attribute (attribute
#                  that recieves the result of the decision)
# replacement_behavior - (Optional) a variable to bind to the replacement behavior for this decision object.attribute
# decision_info_id - (Optional) a variable that is bound to the decision information object.
#                   Typically only ngs code needs to do this.
# 
proc ngs-requested-decision { goal_id 
                              decision_name 
                              { decision_obj ""  }
                              { decision_attr "" }
                              { replacement_behavior "" }
                              { decision_info_id ""} } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty decision_info_id "decision-info"

  set lhs_ret "($goal_id ^$NGS_DECISION_ATTR $decision_info_id)
               ($decision_info_id ^name $decision_name)"

  if { $decision_obj != "" } {
    set lhs_ret "$lhs_ret
                 ($decision_info_id ^destination-object $decision_obj)"
  }

  if { $decision_attr != "" } {
    set lhs_ret "$lhs_ret
                 ($decision_info_id ^destination-attribute $decision_attr)"
  }

  if { $replacement_behavior != "" } {
    set lhs_ret "$lhs_ret
                 ($decision_info_id ^replacement-behavior $replacement_behavior)"
  }

  return $lhs_ret
}

# Evaluates to true if the given choice is valid for the given sub-state
#
# Use this macro to bind to the choices in a decision substate for making
#  goal-based choices.
#
# [ngs-is-decision-choice state_id choice_id (choice_type)]
#
# state_id - variable bound to a substate within which to check for a choice
# choice_id - variable bound (or to be bound) to the choice. Choices are
#              goal objects, each of which represents a choice.
# choice_type - (Optional) type (my-type) of the choice to which to bind. This is
#                the goal type. If not provided, this will match any
#                choice.
#
proc ngs-is-decision-choice { state_id choice_id { choice_type ""} } {
  if { $choice_type == ""} {
    return "($state_id ^decision-choice $choice_id)"
  } else {
    return "($state_id ^decision-choice $choice_id)
            [ngs-is-my-type $choice_id $choice_type]"
  }
}

# Evaluates to true if the given choice is NOT valid for the given sub-state
#
# state_id - variable bound to a substate within which to check for a choice
# choice_id - variable bound to the choice. Choices are
#              goal objects, each of which represents a choice.
# choice_type - (Optional) type of the choice to check for. This is
#                the goal type. If not provided, this will match any
#                choice.
#
proc ngs-is-not-decision-choice { state_id choice_id { choice_type ""} } {
  if { $choice_type == ""} {
    return "($state_id -^decision-choice $choice_id)"
  } else {
    return "-{
              ($state_id ^decision-choice $choice_id)
              [ngs-is-my-type $choice_id $choice_type]
             }"
  }
}

# Eliminates choices that don't meet a set of condition
#
# Use this macro in combination with ngs-is-decision-choice to select between
#  different choices in a decision sub-state. This method takes 3+ parameters
#  where the 3rd and later parameters are strings generated by other lhs macros.
#  These strings define the conditions that should NOT be true for other
#  decision choices. The negation is importan to ensure that the decision
#  operator only matches once when there are multiple decision choices.
#
# If you need to test the type of the 'other' decision choice you need to do this 
#  as part of your condition parameters.
#
# Example: Select the choice with the most recent creation time. Note the
#   use of the continuation operator "\" which allows the command to 
#   be broken up into multiple lines for readability.
#
#  sp "maintain-my-role*decide*use-most-recent-role-assignment
#      [ngs-match-to-make-choice <s> ...]
#      [ngs-is-decision-choice <s> <choice1>]
#      [ngs-bind <choice1> role:<role1>]
#      [ngs-is-tagged <role1> $RS_TAG_CREATION_TIME <time1>]
#
#      [ngs-conditions-true-for-no-other-choices <choice1> <choice2> \
#         [ngs-bind <choice2> role:<role2>] \
#         [ngs-is-tagged <role2> $RS_TAG_CREATION_TIME { > <time1> }]]
#
# -->
#   [ngs-make-choice-by-operator <s> <choice1>]"
#
# [ngs-conditions-false-for-all-other-choices choice_id other_choice_id condition1 condition2 ...]
#
# choice_id - variable bound to the selected (good) choice 
# other_choice_id - variable bound to the other (bad) choice. Note that you cannot use this id
#                    in the rest of the production as it will be nested within a negation block. The 
#                    only way you could use it elsewhere is by binding through another method (e.g.
#                    ngs-is-decision-choice) in some other part of the production.
# args - One or more conditions generated via other LHS macros. See comments and example above
#          on the semantics and format of these conditions
#
proc ngs-conditions-false-for-all-other-choices { choice_id other_choice_id args } {

  set lhs_ret "[ngs-is-decision-choice <s> "{ $other_choice_id <> $choice_id }"]"

  foreach condition $args {
    set lhs_ret "$lhs_ret
                 $condition"
  }

  return "-{
              $lhs_ret
           }"
}

# Evaluates to true if the object linked to the given attribute
#  has been completely constructed (i.e. is tagged with NGS_TAG_CONSTRUCTED)
#
# NOTE: This macro used to be necessary to use when testing whether object
#  creation had complete. With the new all-or-nothing creation process, you
#  rarely need to use this macro anymore (though it still works).
#
# See also - ngs-is-obj-constructed for version where attribute already exists
#
# Upon matching, the "object_id" will be bound to the constructed object and can
#  be used elsewhere within the production.
#
# [ngs-is-attr-constructed parent_id attribute object_id]
#
proc ngs-is-attr-constructed { parent_id attribute object_id } {
  CORE_RefMacroVars
  return "($parent_id ^$attribute $object_id)
          [ngs-is-tagged $object_id $NGS_TAG_CONSTRUCTED]"
}

# Evaluates to true if the object linked to the given attribute
#  has NOT yet been completely constructed (i.e. is tagged with NGS_TAG_CONSTRUCTED)
#
# NOTE: This macro used to be necessary to use when testing whether object
#  creation had complete. With the new all-or-nothing creation process, you
#  rarely need to use this macro anymore (though it still works).
#
# See also - ngs-is-obj-not-constructed for version where attribute already exists
#
# The object_id parameter may be bound to the object even before the entire condition
#  is matched, thus it could be used for other tests in the production.
#
# [ngs-is-attr-not-constructed parent_id attribute object_id]
#
proc ngs-is-attr-not-constructed { parent_id attribute {object_id ""} } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty object_id "__new-obj"
  return "-{ [ngs-is-attr-constructed $parent_id $attribute $object_id] }"
}

# Evaluates to true if the object has been completely constructed 
#  (i.e. is tagged with NGS_TAG_CONSTRUCTED)
#
# NOTE: This macro used to be necessary to use when testing whether object
#  creation had complete. With the new all-or-nothing creation process, you
#  rarely need to use this macro anymore (though it still works).
#
# See also - ngs-is-attr-constructed for version when the attribute linking
#   the object to its parent may not exist.
#
# This version does not bind the object being tested. Use some other method
#  or macro to bind the object before testing it.
#
# [ngs-is-obj-constructed object_id]
#
proc ngs-is-obj-constructed { object_id } {
  CORE_RefMacroVars
  return "[ngs-is-tagged $object_id $NGS_TAG_CONSTRUCTED]"
}

# Evaluates to true if the object l has NOT yet been completely constructed 
#  (i.e. is tagged with NGS_TAG_CONSTRUCTED)
#
# NOTE: This macro used to be necessary to use when testing whether object
#  creation had complete. With the new all-or-nothing creation process, you
#  rarely need to use this macro anymore (though it still works).
#
# See also - ngs-is-attr-constructed for version when the attribute linking
#   the object to its parent may not exist.
#
# This version does not bind the object being tested. Use some other method
#  or macro to bind the object before testing it.
#
# [ngs-is-obj-not-constructed object_id]
#
proc ngs-is-obj-not-constructed { object_id } {
  return "-{ [ngs-is-obj-constructed $object_id] }"
}

# Binds to a specified return value, using the name of the return value as 
#  the principle match condition.
#
# It is not usually necessary to use this macro. It is used internally by ngs-match-to-set-return-typed-obj
#  which is the macro you will typically need to use when dealing with return values.
#
# This macro is most useful in a sub-state when you wish to test for the existance of
#  and/or bind to a return value. Return values are stored in NGS_TYPE_STATE_RETURN_VALUE objects.
#  This macro abstracts you from the details of this internal structure and allows you to
#  bind directly to the return value. If you like, you can also bind to the NGS_TYPE_STATE_RETURN_VALUE
#  wrapper object.
#
# [ngs-is-return-val ret_val_set_id ret_val_name *ret_value_id *ret_val_desc_id]
#
# ret_val_set_id: The identifier bound to the return value set on the sub-state (or operator). Typically
#  you would bind this using some other methods (e.g. (<s> ^$NGS_RETURN_VALUES <ret-vals>)). 
# ret_val_name: The name of the return value (a string)
# ret_value_id: (Optional) Identifier for the return value. This will bound to the return value object
#  if this macro matches.  This identifer can be used to modify or even remove the return value.
# ret_val_desc_id: (Optional) Identifier for the NGS_TYPE_STATE_RETURN_VALUE object that describes
#  the return value (you will rarely need to bind to this)
#
proc ngs-is-return-val { ret_val_set_id ret_val_name {ret_value_id ""} { ret_val_desc_id "" } } {
  
    CORE_RefMacroVars
    CORE_GenVarIfEmpty ret_val_desc_id "val-desc"

    set lhs_val "($ret_val_set_id  ^value-description $ret_val_desc_id)
                 ($ret_val_desc_id ^name $ret_val_name)
                 [ngs-is-tagged $ret_val_desc_id $NGS_TAG_CONSTRUCTED]"

    if { $ret_value_id != "" } {
        set lhs_val "$lhs_val
                     ($ret_val_desc_id ^value $ret_value_id)"
    }

    return $lhs_val
}

########################################################
##
########################################################

# Use to bind to a goal's supergoal
#
# This macro does not bind the subgoal. Use a different macro
#  (e.g. ngs-match-active-goal) to bind the subgoal.
# 
# [ngs-is-supergoal goal_id supergoal_id (supergoal_type)]
#
# goal_id: Subgoal (already bound)
# supergoal_id: Supergoal of "goal_id." Will be bound by this macro
# supergoal_type: (Optional) If provided, the supergoal will only be bound
#                   if it has the given type.
#
proc ngs-is-supergoal { goal_id supergoal_id {supergoal_type ""} } {

  set main_test_line "($goal_id ^supergoal $supergoal_id)"
  if { $supergoal_type != "" } {
	   return "$main_test_line 
            [ngs-is-my-type $supergoal_id $supergoal_type]"
  } else {
      return $main_test_line
  }

}

# Use this to check if a given goal does not have a given supergoal
#
# Because this macro is a negation test, you cannot use variables
#  that are bound exclusively in this macro
# 
# [ngs-is-not-supergoal goal_id supergoal_id (supergoal_type)]
#
# goal_id: Subgoal (already bound)
# supergoal_id: Supergoal of "goal_id" You cannot use this variable unless
#                 it is also bound somewhere else on the LHS. 
# supergoal_type: (Optional) If provided, tests only for supergoals with the given type.
#
proc ngs-is-not-supergoal { goal_id supergoal_id {supergoal_type ""} } {
  return "-{ [ngs-is-supergoal $goal_id $supergoal_id $supergoal_type] }"
}

# Use to bind to a goal's subgoal
#
# This macro does not bind the supegoal. Use a different macro
#  (e.g. ngs-match-active-goal) to bind the supergoal.
# 
# [ngs-is-subgoal goal_id subgoal_id (subgoal_type)]
#
# goal_id: Supergoal (already bound)
# subgoal_id: Subgoal of "goal_id." Will be bound by this macro
# subgoal_type: (Optional) If provided, the subgoal will only be bound
#                   if it has the given type.
#
proc ngs-is-subgoal { goal_id subgoal_id {subgoal_type ""} } {
  set main_test_line "($goal_id ^subgoal $subgoal_id)"
  if { $subgoal_type != "" } {
    return "$main_test_line 
            [ngs-is-my-type $subgoal_id $subgoal_type]"
  } else {
    return $main_test_line
  }
}

# Use this to check if a given goal does not have a given subgoal
#
# Because this macro is a negation test, you cannot use variables
#  that are bound exclusively in this macro
# 
# [ngs-is-not-supergoal goal_id subgoal_id (subgoal_type)]
#
# goal_id: Subgoal (already bound)
# subgoal_id: Subgoal of "goal_id" You cannot use this variable unless
#                 it is also bound somewhere else on the LHS. 
# subgoal_type: (Optional) If provided, tests only for subgoals with the given type.
#
proc ngs-is-not-subgoal { goal_id subgoal_id {subgoal_type ""} } {
  return "-{ [ngs-is-subgoal $goal_id $subgoal_id $subgoal_type] }"
}

#######################################################################################

# Start an open ended production that simply binds to the top state
# 
# [ngs-match-top-state state_id (bindings) (input_link) (output_link)]
#
# state_id - Variable bound to the the state identifer (bound by this macro)
# bindings - (Optional) If provided, a string to be passed to ngs-bind as
#               [ngs-bind <state_id> $bindings]
# input_link - (Optional) If provided, a variable to bind to the input link
# output_link - (Optional) If provided, a varaible to bind to the output link
proc ngs-match-top-state { state_id {bindings ""} {input_link ""} {output_link ""}} {

  set lhs_ret "(state $state_id ^superstate nil)"
  set io_id [CORE_GenVarName io]

  if { ($input_link != "") || ($output_link != "")} {
    
    set lhs_ret "$lhs_ret
                 ($state_id ^io $io_id)"
    
    if { $input_link != "" } {
      set lhs_ret "$lhs_ret
                   ($io_id ^input-link $input_link)"
    }
    
    if { $output_link != "" } {
      set lhs_ret "$lhs_ret
                   ($io_id ^output-link $output_link)"
    }

  }

  if { $bindings != "" } {
     set lhs_ret "$lhs_ret
                  [ngs-bind $state_id $bindings]"
  } 
  
  return $lhs_ret
}

# Use to bind to the input link
#
# Typically you would use this in your input handling macros, not often
#  in your productions directly.
#
# [ngs-input-link state_id input_link_id]
#
# state_id - variable bound to the state (should be bound with a match production)
# input_link_id - variable that will be bound to the root of the input link
# bindings - (Optional) If provided, a string to be passed to ngs-bind as
#               [ngs-bind <input_link_id> $bindings]
#
proc ngs-input-link { state_id input_link_id {bindings ""} } {
  if {$bindings == ""} {
    return "($state_id ^io.input-link $input_link_id)"
  } else {
    return "($state_id ^io.input-link $input_link_id)
            [ngs-bind $input_link_id $bindings]"
  }
}

# Use to bind to the output link
#
# Typically you would use this in your output handling macros, not often
#  in your productions directly.
#
# [ngs-output-link state_id input_link_id]
#
# state_id - variable bound to the state (should be bound with a match production)
# output_link_id - variable that will be bound to the root of the input link
# bindings - (Optional) If provided, a string to be passed to ngs-bind as
#               [ngs-bind <output_link_id> $bindings]
#
proc ngs-output-link { state_id output_link_id {bindings ""} } {
  if {$bindings == ""} {
    return "($state_id ^io.output-link $output_link_id)"
  } else {
    return "($state_id ^io.output-link $output_link_id)
            [ngs-bind $output_link_id $bindings]"
  }
}

# Start a production to create a stand-alone goal
#
# If you are creating a sub-goal, use ngs-match-goal-to-create-subgoal instead.
#  It has many more of the bindings you need.
#
# If you don't give this macro a goal type, it will bind to the root goal pool
#  which holds all of the goal sets (referenced through the goal types). If
#  you provide a type, it will bind to the goal set of the given goal type.
#  Providing a goal type is by far the most common use case.
#
# [ngs-match-goalpool state_id goal_pool (goal_type) (state_bindings)]
#
# state_id - variable that will be bound to the top state.
# goal_pool - variable that will be bound to the goal pool.  See note above
#              on which pool this will be depending on the value of goal_type.
# goal_type - (Optional) If provided, the goal_pool variable will be bound
#               to the goal set for goals of the given type. If it is not
#               provided, the goal_pool variable will be bound to the root
#               goal pool.
# state_bindings - (Optional) If provided, a binding string to be passed to 
#                   ngs-bind as in [ngs-bind $state_id $state_bindings]
#
proc ngs-match-goalpool { state_id goal_pool {goal_type ""} { state_bindings ""}} {
  CORE_RefMacroVars

  if { $state_bindings != "" } {
    set state_bindings [ngs-bind $state_id $state_bindings]
  }

  if {$goal_type != ""} {
    return "(state $state_id ^superstate nil 
                             ^$WM_GOAL_SET.$goal_type $goal_pool)
            $state_bindings"
  } else {
    return "(state $state_id ^superstate nil 
                             ^$WM_GOAL_SET $goal_pool)
            $state_bindings"
  } 
}

# Start a prodution that does something with a goal on the top state
#
# This is a general purpose match production for cases when you need to do something with
#  a goal from the top-state pools. For example, you might want to elaborate something onto 
#  the goal. There are other more specific match macros that help with other common tasks.
#
# [ngs-match-goal state_id goal_type goal_id (basetype) (goal_pool_id)]
#
# state_id - variable that will be bound to the top state.
# goal_type - type of the goal to be bound
# goal_id - variable that will be bound to the goal of the given type
# basetype - (Optional) constrains which goals can bind to one of NGS_GB_ACHIEVE or NGS_GB_MAINT.
#            If it isn't provided, both types of goals are accepted.
# goal_pool_id - (Optional) If provided, this is a variable that will be bound to the
#     goal pool for goals of the given goal_type
#
proc ngs-match-goal { state_id
                      goal_type 
                      goal_id 
                      {basetype ""}
                      {goal_pool_id ""}} {
  CORE_RefMacroVars

  # Default value initialization
  CORE_GenVarIfEmpty goal_pool_id "goal-pool"

  set lhs_ret "[ngs-match-goalpool $state_id $goal_pool_id $goal_type]
               ($goal_pool_id ^goal $goal_id)
               [ngs-is-tagged $goal_id $NGS_TAG_CONSTRUCTED]"

  if { $basetype != "" } {
    set lhs_ret "$lhs_ret
                 [ngs-is-type $goal_id $basetype]"
  }

  return $lhs_ret
}

# Start a production that acts after a goal is selected in a decision.
#
# This helper macro reduces the complexity associated with matching a goal that has been selected in
#  the goal selection process. It provides convenient bindings for the decision object and attribute
#  which can be useful when writing productions that carry out the action implied by the decision.
#
# This macro will only bind goals for which [ngs-has-decided <goal> $NGS_YES] evaluates to true.
#
# [ngs-match-decided-goal state_id goal_type goal_id  decision_obj decision_attr (replacement_behavior) (decision_name) (basetype) (goal_pool_id)]
#
# state_id - variable that will be bound to the top state.
# goal_type - type of the goal to be bound
# goal_id - variable that will be bound to the goal of the given type
# decision_obj - variable that will be bound to the object that should recieve the decision's resulting action
# decision_attr - variable/constant that will be bound to the attribute that should recieve the decision's resulting action
# replacement_behavior - variable or constant bound to the replacement-behavior of the decision WME. See rhs-fragments.tcl
#                           for examples of how this is used. Typically you don't need to bind this since the infrastructure
#                           handles it for you.
# decision_name - (Optional) If provided, constrains the match to only be for goals that are deciding the given decision name.
# basetype - (Optional) constrains which goals can bind to one of NGS_GB_ACHIEVE or NGS_GB_MAINT.
#            If it isn't provided, both types of goals are accepted.
# goal_pool_id - (Optional) If provided, this is a variable that will be bound to the
#     goal pool for goals of the given goal_type
#
proc ngs-match-decided-goal { state_id
                              goal_type
                              goal_id
                              decision_obj
                              decision_attr
                              { replacement_behavior "" }
                              { decision_name "" }
                              { basetype "" } 
                              { goal_pool_id "" }} {
  
  CORE_RefMacroVars

  set supergoal_id [CORE_GenVarName "supergoal"]
  CORE_GenVarIfEmpty decision_name "decision-name"

  return "[ngs-match-goal $state_id $goal_type $goal_id $basetype $goal_pool_id]
          [ngs-has-decided $goal_id $NGS_YES]
          [ngs-is-assigned-decision $goal_id $decision_name]
          [ngs-is-supergoal $goal_id $supergoal_id]
          [ngs-requested-decision $supergoal_id $decision_name $decision_obj $decision_attr $replacement_behavior]"
}

# Start a production to create a subgoal of another goal
# 
# This helper greatly simplifies the code you need to write to prepare to create a sub-goal.
#  It provides convenient bindings for all of the major elements needed to create the sub-goal.
#
# [ngs-match-goal-to-create-subgoal state_id supergoal_type supergoal_id subgoal_type subgoal_pool_id (supergoal_type)]
#
# state_id - variable that will be bound to the top state. 
# supergoal_type - type of the supergoal of the sub-goal you want to create
# supergoal_id - variable that will be bound to the supergoal
# subgoal_type - type of the subgoal you wish to create
# subgoal_pool_id - variable that will get bound to the goal set for goals of subgoal_type. You will
#                    place you new goal in this set.
# supergoal_basetype - (Optional) You can additionaly constrain your supergoal match to one of NGS_GB_ACHIEVE 
#                     or NGS_GB_MAINT using this parameter
#
proc ngs-match-goal-to-create-subgoal { state_id 
                                        supergoal_type 
                                        supergoal_id 
                                        subgoal_type
                                        subgoal_pool_id 
                                        { supergoal_basetype "" } } {

  CORE_RefMacroVars

  set goal_pool_id      [CORE_GenVarName "goals"]
  set supergoal_pool_id [CORE_GenVarName "supergoals"]

  set lhs_ret "(state $state_id ^superstate nil
                                ^$WM_GOAL_SET    $goal_pool_id)
               ($goal_pool_id   ^$supergoal_type $supergoal_pool_id
                                ^$subgoal_type   $subgoal_pool_id)
               ($supergoal_pool_id ^goal         $supergoal_id)
               [ngs-is-tagged $supergoal_id      $NGS_TAG_CONSTRUCTED]"

  if { $supergoal_basetype != "" } {
    set lhs_ret "$lhs_ret
                 [ngs-is-type $supergoal_id $supergoal_basetype]"
  }

  return $lhs_ret
}

##################### SUBSTATES ###############################

# Start a vanilla sub-state production that binds to a substate's key objects
#
# There are other helper macros that make bindings for common substate actions easier.
#
# [ngs-match-substate substate_id (params_id) (top_state_id) (superstate_id)]
#
# substate_id - variable that will be bound to the substate_id
# params_id - (Optional) If provided, this variable will be bound to the params structure
#               in the substate. The params structure is a link to the selected decide
#               operator in the superstate.
# top_state_id - (Optional) If provided, this variable is bound to the top state 
# superstate_id - (Optional) If provided, this variable is bound to the superstate
#
proc ngs-match-substate { substate_id {params_id ""} {top_state_id ""} {superstate_id ""}} {

  CORE_RefMacroVars

  variable superstate_test
  variable top_state_test
  variable params_test

  CORE_GenVarIfEmpty superstate_id "superstate"
  
  set superstate_test "^$WM_SUPERSTATE \{ $superstate_id <> nil \}"
  
  if {$top_state_id != ""} {
     set top_state_test "\n^$WM_TOP_STATE $top_state_id"
  } else {
     set top_state_test ""
  }

  if {$params_id != ""} {
     set params_test "\n^$NGS_SUBSTATE_PARAMS $params_id"
  } else {
     set params_test ""
  }

  return "(state $substate_id $superstate_test $top_state_test $params_test)"
}

# Start a production to bind to an active goal
#
# This is a common match macro in sub-state, providing you with bindings to the
#  goal that caused the sub-state.
#
# Active goals have been selected for processing in a sub-state. This macro
#  binds to the sub-state and tests the WM_ACTIVE_GOAL attribute in the 
#  substate. If you want to bind through the top-state goal pool use
#  ngs-match-top-state-active-goal instead.
#
# [ngs-match-active-goal substate_id goal_type goal_id (params_id) (top_state_id) (superstate_id)]
#
# substate_id - variable that will be bound to the substate_id
# goal_type - type constraining which active goals will get bound
# goal_id - variable that will be bound to the active goal (in the substate)
# params_id - (Optional) If provided, this variable will be bound to the params structure
#               in the substate. The params structure is a link to the selected decide
#               operator in the superstate.
# top_state_id - (Optional) If provided, this variable is bound to the top state 
# superstate_id - (Optional) If provided, this variable is bound to the superstate
#
proc ngs-match-active-goal { substate_id
                             goal_type 
                             goal_id
                             {params_id ""}
                             {top_state_id ""}
                             {superstate_id ""} } {
  CORE_RefMacroVars

  set lhs_ret "[ngs-match-substate $substate_id $params_id $top_state_id $superstate_id]
               ($substate_id ^$WM_ACTIVE_GOAL $goal_id)
               [ngs-is-my-type $goal_id $goal_type]"

  return $lhs_ret
}


# Start a production to bind to an active goal at the top-state
#
# Active goals have been selected for processing in a sub-state, but this version
#  of the match macro binds to the top-state and tests for an active goal through
#  the top state goal pool. If you want to bind to the sub-state that processes
#  this active goal, use ngs-match-active-goal instead.
#
# [ngs-match-top-state-active-goal state_id goal_type goal_id]
#
# state_id - variable that will be bound to the top state 
# goal_type - type constraining which active goals will be bound 
# goal_id - variable that will be bound to an _active_ goal of the given type 
#
proc ngs-match-top-state-active-goal { state_id
                                       goal_type 
                                     goal_id } {
  CORE_RefMacroVars

  set lhs_ret = "(state $state_id ^$WM_GOAL_SET.$goal_type $goal_id)
                 [ngs-is-active $goal_id]"

  return $lhs_ret
}

# Start a production that will propose an operator to make a decision
#  in a decision sub-state
#
# Typically you pair this match macro with the ngs-make-choice-by-operator RHS macro
#
# [ngs-match-to-make-choice substate_id decision_name decision_goal_id decision_goal_type (params_id) (top_state_id) (superstate_id)]
#
# substate_id - variable bound to the substate in which to make the choice
# decision_name - name of the decision being made
# decision_goal_id - variable to be bound to the id of the goal that requested the decision. To bind
#   to one of the goal's that represent the choice, use the ngs-is-decision-choice macro
# decision_goal_type - type of the goal that requested the decision
# params_id - (Optional) If provided, a variable that will be bound to the params structure in the substate
# top_state_id - (Optional) If provided, a variable that will be bound to the top state identifier
# superstate_id - (Optional) If provided, a variable that will be bound to the superstate identifier
#
proc ngs-match-to-make-choice { substate_id 
                                decision_name 
                                decision_goal_id
                                decision_goal_type
                                {params_id ""} 
                                {top_state_id ""} 
                                {superstate_id ""} } {

  CORE_RefMacroVars
  CORE_GenVarIfEmpty params_id "params"

  set return_value_desc_id [CORE_GenVarName "ret-vals"]

  return "[ngs-match-active-goal $substate_id $decision_goal_type $decision_goal_id $params_id $top_state_id $superstate_id]
          [ngs-is-named $substate_id $NGS_OP_DECIDE_GOAL]
          ($params_id ^decision-name $decision_name)
          ($substate_id ^$NGS_RETURN_VALUES.value-description $return_value_desc_id)
          ($return_value_desc_id    ^name  $NGS_DECISION_RET_VAL_NAME
                                   -^destination-object)"

}

# Start a production to set a return value to a typed object
#
# Use this method in substates when you want to set a return value. This macro can be used both
#  in cases where you want to set the return value to anything other than a goal. To set return 
#  of a goal use ngs-match-to-create-return-goal. The difference is the retraction condition
#  in each macro (goal creation uses a different retraction condition).
#
# [ngs-match-to-set-return-val substate_id goal_type goal_id return_value_name (return_value_desc_id) (params_id) (top_state_id) (superstate_id)]
#
# substate_id - variable bound to the substate in which the value is being returned 
# goal_type - type of the active goal 
# goal_id - variable to be bound to the active goal
# return_value_name - name of the return value to set 
# return_value_desc_id - (Optional) If provided, a variable to be bound to the object of type $NGS_TYPE_STATE_RETURN_VALUE
#                           which contains the meta information about the return value. You typically do  not need to bind this.
# params_id - (Optional) If provided, a variable to be bound to the parameters for the substate.
# params_id - (Optional) If provided, a variable that will be bound to the params structure in the substate
# top_state_id - (Optional) If provided, a variable that will be bound to the top state identifier
# superstate_id - (Optional) If provided, a variable that will be bound to the superstate identifier
#
proc ngs-match-to-set-return-val { substate_id
                                     goal_type 
                                     goal_id
                                     return_value_name
                                     {return_value_desc_id ""} 
                                     {params_id ""}
                                     {top_state_id ""}
                                     {superstate_id ""} } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty return_value_desc_id "val-desc"

  # This method of retracting is probably no longer necessary given all-or-nothing construction
  set lhs_ret "[ngs-match-active-goal $substate_id $goal_type $goal_id $params_id $top_state_id $superstate_id]
               ($substate_id ^$NGS_RETURN_VALUES.value-description $return_value_desc_id)
               ($return_value_desc_id    ^name  $return_value_name)
               [ngs-nex $return_value_desc_id value]"

  return $lhs_ret
}


# Start a production to return a goal from a substate
#
# Use this method in substates when you want to create a goal as a return value. If you want to 
#  return some other type of value, use ngs-match-to-create-return-val instead. The main difference 
#  between the two macros is that they use different retraction conditions. This macro also requires
#  fewer paramers.
#
# [ngs-match-to-create-return-goal substate_id goal_type goal_id new_goal_type (params_id) (top_state_id) (superstate_id)]
#
# substate_id - variable bound to the substate in which the value is being returned 
# goal_type - type of the active goal 
# goal_id - variable to be bound to the active goal
# new_goal_type - type of the goal being created
# params_id - (Optional) If provided, a variable to be bound to the parameters for the substate.
# params_id - (Optional) If provided, a variable that will be bound to the params structure in the substate
# top_state_id - (Optional) If provided, a variable that will be bound to the top state identifier
# superstate_id - (Optional) If provided, a variable that will be bound to the superstate identifier
#
proc ngs-match-to-create-return-goal { substate_id
                                       goal_type 
                                       goal_id
                                       new_goal_type
                                       {params_id ""}
                                       {top_state_id ""}
                                       {superstate_id ""} } {
  CORE_RefMacroVars
  set return_value_set [CORE_GenVarName "ret-vals"]
  set new_goal_id      [CORE_GenVarName "new-goal"]

  set lhs_ret "[ngs-match-active-goal $substate_id $goal_type $goal_id $params_id $top_state_id $superstate_id]
               ($substate_id ^$NGS_RETURN_VALUES $return_value_set)
              -{
                  [ngs-is-return-val $return_value_set $NGS_GOAL_RETURN_VALUE $new_goal_id]
                  [ngs-is-my-type $new_goal_id $new_goal_type]
               }"

  return $lhs_ret
}

# Start a production to elaborate an operator or set operator preferences
#
# Use this macro when you want to elaborate an operator or set its preferences.
#  This macro matches operator _preferences_, not applications. Anything on 
#  the RHS of a production using this macro will get i-support.
#
# [ngs-match-proposed-operator state_id op_id op_name (goal_id) (op_type)]
#
# state_id - variable to be bound to the state in which the operator is proposed 
# op_id - variable to be bound to the proposed (but not selected) operator 
# op_name - (Optional) If provided, the name of the operator that is bound to op_id 
# goal_id - (Optional) If provided, the goal bound to the operator. Not all operators are
#            bound to goals. Decide operators are.
# op_type - (Optional) If provided, a goal type to constrain the match - one of NGS_OP_ATOMIC 
#            or NGS_OP_DECIDE
#
proc ngs-match-proposed-operator { state_id
								                   op_id
                                   {op_name ""}
                				           {goal_id ""}
                 				           {op_type ""} } {

  set lhs_ret "(state $state_id ^operator $op_id +)"

  if { $op_name != "" } {
     set lhs_ret "$lhs_ret
            	  ($op_id ^name $op_name)"
	} 

  if { $goal_id != ""} { 
	    set lhs_ret "$lhs_ret
               		($op_id ^goal $goal_id)" 
  }

  if { $op_type != ""} { 
	     set lhs_ret "$lhs_ret
                    ($op_id ^type $op_type)"
  }

  return $lhs_ret
}

# Start a production to set pairwise operator preferences
#
# Use this macro when you want to set binary preferences betwen two operators.
#  This macro matches operator _preferences_, not applications. Anything on 
#  the RHS of a production using this macro will get i-support.
#
# [ngs-match-two-proposed-operators state_id op1_id op2_id op1_name op2_name (goal1_id) (goal2_id) (op1_type) (op2_type)]
#
# state_id - variable to be bound to the state in which the operator is proposed 
# op1_id - variable to be bound to the first proposed (but not selected) operator 
# op1_id - variable to be bound to the second proposed (but not selected) operator 
# op1_name - (Optional) If provided, the name of the first operator, bound to op1_id 
# op1_name - (Optional) If provided, the name of the second operator, bound to op2_id 
# goal1_id - (Optional) If provided, the goal bound to the first operator. Not all operators are
#            bound to goals. Decide operators are.
# goal2_id - (Optional) If provided, the goal bound to the second operator. Not all operators are
#            bound to goals. Decide operators are.
# op1_type - (Optional) If provided, a goal type to constrain the match of the first operator - 
#            one of NGS_OP_ATOMIC or NGS_OP_DECIDE
# op2_type - (Optional) If provided, a goal type to constrain the match of the second operator - 
#            one of NGS_OP_ATOMIC or NGS_OP_DECIDE
#
proc ngs-match-two-proposed-operators { state_id
                                        op1_id 
                                        op2_id
                                        {op1_name ""}
                                        {op2_name ""} 
                                        {goal1_id ""}
                                        {goal2_id ""}
                                        {op1_type ""}
                                        {op2_type ""} } {


   set lhs_ret "(state $state_id ^operator $op1_id +
							                   ^operator $op2_id +)"


   if { $op1_name != "" } {
     set lhs_ret "$lhs_ret
            	  ($op1_id ^name $op1_name)"
	} 
   if { $op2_name != "" } {
     set lhs_ret "$lhs_ret
            	  ($op2_id ^name $op2_name)"
	} 

  if { $goal1_id != "" } { 
	set lhs_ret "$lhs_ret
           		($op1_id ^goal $goal1_id)" 
  }
  if { $goal2_id != "" } { 
	set lhs_ret "$lhs_ret
           		($op2_id ^goal $goal2_id)" 
  }

  if { $op1_type != "" } {
	set lhs_ret "$lhs_ret
                 ($op1_id ^type $op1_type)"
  }
  if { $op2_type != "" } { 
	set lhs_ret "$lhs_ret
                 ($op2_id ^type $op2_type)"
  }

  return $lhs_ret
}

# Use start a production to apply an operator
#
# IMPORTANT: You almost never need to use this macro because NGS applies all of your operators
#  for you. It is used internally by ngs. Before using this macro, make sure one of the standard
#  operators won't work (e.g. for goal creation, primitive creation, tag creation,
#  object creation, and output command creation).
#
# [ngs-match-selected-operator state_id op_id op_name (goal_id)]
# 
# state_id - variable to be bound to the state in which the operator is selected 
# op_id - variable to be bound to the selected operator 
# op_name - (Optional) If provided, the name of the operator that is bound to op_id 
# goal_id - (Optional) If provided, the goal bound to the operator. Not all operators are
#            bound to goals. Decide operators are.
#
proc ngs-match-selected-operator {state_id
                                  op_id
								                  {op_name ""}
                                  {goal_id ""} } {

  set lhs_ret "(state $state_id ^operator $op_id)"

  if { $op_name != "" } {
    set lhs_ret "$lhs_ret
                 ($op_id ^name $op_name)"
  }

  if { $goal_id != "" } {
    set lhs_ret "$lhs_ret
                 ($op_id ^goal $goal_id)"
  }

  return $lhs_ret  
}


# Use start a production to apply an operator (only on the top state)
#
# IMPORTANT: You almost never need to use this macro because NGS applies all of your operators
#  for you. It is used internally by ngs. Before using this macro, make sure one of the standard
#  operators won't work (e.g. for goal creation, primitive creation, tag creation,
#  object creation, and output command creation).
#
# This version of the match production will only match operators selected on the top state
#
# [ngs-match-selected-operator-on-top-state state_id op_id op_name (goal_id)]
# 
# state_id - variable to be bound to the state in which the operator is selected 
# op_id - variable to be bound to the selected operator 
# op_name - (Optional) If provided, the name of the operator that is bound to op_id 
# goal_id - (Optional) If provided, the goal bound to the operator. Not all operators are
#            bound to goals. Decide operators are.
#
proc ngs-match-selected-operator-on-top-state {state_id
                                               op_id
											                         {op_name ""}
                                               {goal_id ""} } {
 
  return "[ngs-match-selected-operator $state_id $op_id $op_name $goal_id]
          ($state_id ^superstate nil)"
}

# Use start a production to apply an operator (only in a substate)
#
# IMPORTANT: You almost never need to use this macro because NGS applies all of your operators
#  for you. It is used internally by ngs. Before using this macro, make sure one of the standard
#  operators won't work (e.g. for goal creation, primitive creation, tag creation,
#  object creation, and output command creation).
#
# This version of the match production will only match operators selected in a substate
#
# [ngs-match-selected-operator-on-top-state state_id op_id op_name (goal_id)]
# 
# substate_id - variable to be bound to the state in which the operator is selected 
# op_id - variable to be bound to the selected operator 
# op_name - (Optional) If provided, the name of the operator that is bound to op_id 
# goal_id - (Optional) If provided, the goal bound to the operator. Not all operators are
#            bound to goals. Decide operators are.
# top_state_id - (Optional) If provided, a variable that will be bound to the top state identifier
# superstate_id - (Optional) If provided, a variable that will be bound to the superstate identifier
#
proc ngs-match-selected-operator-in-substate {substate_id                                               
                                              op_id
											                        {op_name ""}
                                              {goal_id ""} 
                                              {top_state_id ""}
                                              {superstate_id ""} } {

  CORE_GenVarIfEmpty top_state_id "top-state"
  CORE_GenVarIfEmpty superstate_id "superstate"
  
  return "[ngs-match-substate $substate_id $top_state_id $superstate_id]
          [ngs-match-selected-operator $substate_id $op_id $op_name $goal_id]"
  
}
