# NOTE: These methods don't work as well as I'd hoped. Need to rethink the dashboard processes

# NGS Print Execute
#
# This is a specialized version of Soar's p (or print) command.
# It defaults to printing as a tree and to depth 2. You can pass 
#  an optional depth number to change the printing depth.
# This used to be the np command, but has been renamed npx
# and is called from within the new np command at the bottom of
# this file.
#
# Usage: npx s1 (print the top state to depth 2)
# Usage: npx 3 s1 (print the top state to depth 3)
# Usage: npx i2 i3 (print input and output links to depth 2)
# Usage: npx 3 i2 i3 (print the input and output linkks to depth 3)
#
# args - An optional depth (integer) followed by identifiers. If the
#          depth is not provided, a default print depth of 2 is used.
#
proc npx { args } {

    if { [llength $args] == 0} {
        echo "+---------------------------------------+"
        echo "Usage: npx (depth=2) id1 id2 id3 ..."
    }

    set prev_id_list ""
    set depth 1
    set first [lindex $args 0]

    if { [string is integer [string index $first 0]] == 1 } {
        set depth $first
        set args [lrange $args 1 end]
    }

    set print_this ""
    foreach id $args {
        set id [string toupper $id]
        echo "================================================================================"
        set print_this "+ OBJECT:"
        if {[string index [CORE_GetCommandOutput print $id] 0] != "("} {
            echo "$print_this $id does not exist"
        } else {
	        set print_this "$print_this [ngs-print-identifiers-attributes-details $id 1 $depth prev_id_list]"
	        echo $print_this
        }
    }
    # Note: np prints this now
	#echo "================================================================================"
}

# Helps pretty print the WME tree
proc ngs-debug-tree-view-prefix { level } {

    set ret_val ""
    set final_level [expr $level - 1]
    for {set i 0} { $i < $final_level } {incr i} {
        set ret_val "${ret_val}|  "
    }

    return "${ret_val}+-" 
}

# Prints out the WME tree (recursively called)
proc ngs-print-identifiers-attributes-details { id level target_level prev_id_dict {lti_id ""}} {

    upvar $prev_id_dict id_dict
    dict set id_dict $id $id

    set prefix [ngs-debug-tree-view-prefix $level]
    set print_this "$id ("

    set attributes [ngs-debug-get-all-attributes-for-id $id]

    # Not sure why this is here, but it seems like debug code
    #if {$level == 2} { echo $id: $attributes }

    if { [dict exists $attributes "my-type"] == 1 } {
        set my_type    [dict get $attributes my-type]
        set print_this "$print_this$my_type"
    } else {
        set my_type [ngs-debug-get-single-id-for-attribute $id "name"]
        if { $my_type != "" } {
            set print_this "$print_this$my_type"
        } elseif { $lti_id != "" } {
            set print_this "$print_this$lti_id in SMEM"
        } else {
            set print_this "${print_this}UNDEFINED"
        }
    }

    if { [dict exists $attributes types] == 1 } {
        foreach type_props [dict get $attributes types] {
            set type_name [lindex $type_props 1]
            if { $type_name != $my_type } {
                set print_this "$print_this, $type_name"
            }
        }
    }
    set print_this "$print_this)"

    if { [dict exists $attributes "activation"] == 1 } {
        set activation_val [dict get $attributes activation]
        set print_this "$print_this, ACTIVATION: $activation_val"
    }

    if { [dict exists $attributes attributes] == 1 } {
        foreach attr_props [dict get $attributes attributes] {
            set attr_name  [lindex $attr_props 0]
            set attr_value [lindex $attr_props 1]
            set attr_type  [lindex $attr_props 2]
            set ctx_value  [lindex $attr_props 3]
            set lti_value  [lindex $attr_props 4]
        
            if { $level == $target_level || [dict exists $id_dict $attr_value] == 1 || [ngs-debug-is-identifier $attr_value] == 0 } {
                set print_this "$print_this\n$prefix $attr_name: $attr_value"
                if {$ctx_value != "" && $ctx_value != $attr_value} {
                    set print_this "$print_this == $ctx_value"
                }
                if {$attr_type != ""} {
                    set print_this "$print_this ($attr_type)"
                }
                if {$lti_value != ""} {
                    set print_this "$print_this (lti: $lti_value)"
                }
            } else {
               # echo "ngs-print-identifiers-attributes-details $attr_value [expr $level + 1] $target_level \{$id_dict\}"
               set print_this "$print_this\n$prefix $attr_name: [ngs-print-identifiers-attributes-details $attr_value [expr $level + 1] $target_level id_dict $lti_value]"
            }
        }
    }

    if { [dict exists $attributes operators] == 1 } {
        foreach op_props [dict get $attributes operators] {
            set op_attr  [lindex $op_props 0]
            set op_value [lindex $op_props 1]
            set op_name  [lindex $op_props 2]

            if { [lindex $op_props 4] == "+" } {
                set op_attr "OPERATOR (PROPOSAL)"
            } else {
                set op_attr "OPERATOR (SELECTED)"
            }
            if { $level == $target_level || [dict exists $id_dict $op_value] == 1 } {
               set print_this "$print_this\n$prefix $op_attr: $op_value ($op_name)"
            } else {
               #echo "OPERATOR: ngs-print-identifiers-attributes-details $op_value [expr $level + 1] $target_level \{$id_dict\}"
               set print_this "$print_this\n$prefix $op_attr: [ngs-print-identifiers-attributes-details $op_value [expr $level + 1] $target_level id_dict]"
            }
        }
    }

    if { [dict exists $attributes tags] == 1 } {
        foreach tag_props [dict get $attributes tags] {
            set tag_name  [lindex $tag_props 0]
            set tag_value [lindex $tag_props 1]
            set tag_type  [lindex $tag_props 2]
            set ctx_value  [lindex $tag_props 3]
            set lti_value  [lindex $tag_props 4]

            set print_this "$print_this\n$prefix TAG: $tag_name: $tag_value"
            if {$ctx_value != "" && $ctx_value != $tag_value} {
                set print_this "$print_this == $ctx_value"
            }
            if {$tag_type != ""} {
                set print_this "$print_this ($tag_type)"
            }
            if {$lti_value != ""} {
                set print_this "$print_this (lti: $lti_value)"
            }
        }
    }

    return $print_this
} 

# Returns 1 if the given symbol is a Soar identifier, 0 otherwise
#
# Used by debug code
proc ngs-debug-is-identifier { symbol } {

    set first_letter [string index $symbol 0]
    set the_rest     [string range $symbol 1 end]

    if { $the_rest != "" && [string is digit $first_letter] == 0 && [string is integer $the_rest] == 1  }  {
        return 1
    }

    return 0
}

proc ngs-debug-is-lti { symbol } {

    set first_letter [string index $symbol 0]
    set the_rest     [string range $symbol 1 end]

    if { $first_letter == "@" && $the_rest != "" && [string is integer $the_rest] == 1 } {
        return 1
    }

    return 0
}

proc ngs-debug-is-activation { symbol } {

    set first_letter [string index $symbol 0]
    set the_rest     [string range $symbol 1 end]

    if { ($first_letter == "+" || $first_letter == "-") && $the_rest != "" && [string is double $the_rest] == 1 } {
        return 1
    }

    return 0
}

# Grab a single attribute from an identifier
proc ngs-debug-get-single-id-for-attribute { identifier attribute } {

    set print_string [string trim [CORE_GetCommandOutput print -e "($identifier ^$attribute *)"]]
    if {$print_string != "" && [string index $print_string 0] == "(" } {
        set elements [split $print_string " "]
        return [string trim [lindex $elements 2] " )"]
    }

    return ""
}

proc ngs-debug-process-id-print { line } {

    set TRIM_DEFAULTS " \n\r\t"

    set ret_list ""
    set attr_value_pairs [split $line "^"]

    foreach pair $attr_value_pairs {
        if { [string index $pair 0] != "("  && $pair != " " } {

	        set $pair [string trim $pair "$TRIM_DEFAULTS)"]
	        set end_of_attribute [string first " " $pair]
	        if { $end_of_attribute > 0 } {
	            lappend ret_list [string trim [string range $pair 0 $end_of_attribute] "$TRIM_DEFAULTS)"]
	            
	            set value     [string trim [string range $pair $end_of_attribute end] "$TRIM_DEFAULTS)"]
	            if { $value == "" } {
                    lappend ret_list "***EMPTY***"
                } 
                # For LTIs in WM
                set lti_id_start [string first "(@" $value]
                # For activations
                set activation_start [string first " \[" $value]
                if { $lti_id_start > 0 } {
                    lappend ret_list [string trim [string range $value 0 [expr $lti_id_start - 2]] "$TRIM_DEFAULTS"]
                    lappend ret_list [string trim [string range $value $lti_id_start end] "( $TRIM_DEFAULTS)"]
                } elseif { $activation_start > 0 } {
                    lappend ret_list [string trim [string range $value 0 [expr $activation_start - 1]] "$TRIM_DEFAULTS"]
                    lappend ret_list [string trim [string range $value $activation_start end] "\[ $TRIM_DEFAULTS\])"]
                } elseif { [string index $value end] != "+" } { 
	                lappend ret_list $value
	            } else {
                    set end_of_value [expr [string length $value] - 2]
	                lappend ret_list [string trim [string range $value 0 $end_of_value] " $TRIM_DEFAULTS)"]
                    lappend ret_list "+"
	            }
	        }
        }
    }
    
    return $ret_list
}

# Pull out all attributes as a dictionary of categories
#
# Categories:
#
# internal
# tags
# attributes
# operatrors
# types
# my-type (a single string value)
#
# Each category contains a list of tuples (except my-type)
# 1 - the name of the attribute
# 2 - the value of the attribute
# 3 - the type of the attribute (or name of the operator)
# 4 - operator preference (if attribute is an operator) OR value if context variable
# 5 - the LTI if the WM is a mirror from SMEM
#
#   | context variable value (if attribute is a context variable)
#
proc ngs-debug-get-all-attributes-for-id { identifier {attribute ""} } {

    variable NGS_TAG_PREFIX
    variable NGS_TAG_CONSTRUCTED
    variable NGS_TAG_I_SUPPORTED
    variable NGS_YES
    variable NGS_NO
    variable NGS_UNKNOWN

    set print_string     [CORE_GetCommandOutput p $identifier]
    if { [string index $print_string 0] != "(" } { 
        return ""
    }

    set attr_value_pairs [ngs-debug-process-id-print $print_string]

    set is_attribute 1
    set attribute_info ""

    # internal, tags, attributes, types, my-type
    set ret_val ""
    set cur_key ""

    foreach attr_val $attr_value_pairs {
        set attr_val [string trim $attr_val]

        if { $attr_val != "" } {

            if { $is_attribute == 1 && $attr_val != "+" && [ngs-debug-is-lti $attr_val] == 0 } {

                # Insert the last value before starting a new one
                if { $cur_key == "my-type" } {
                    dict set ret_val $cur_key [lindex $attribute_info 1]
                } elseif { $cur_key != "" } {
                    if { $attribute == "" || $attribute == [lindex $attribute_info 0] } {
                        dict lappend ret_val $cur_key $attribute_info
                    }
                }

                set attribute_info ""

                # I don't handle attribute idenfiers in this list
                if { $attr_val == [ngs-tag-for-name $NGS_TAG_CONSTRUCTED] || $attr_val == [ngs-tag-for-name $NGS_TAG_I_SUPPORTED]} {
                    set cur_key "internal"
                    lappend attribute_info [string range $attr_val [string length $NGS_TAG_PREFIX] end]
                } elseif { [string first $NGS_TAG_PREFIX $attr_val] > -1 } {
                    set cur_key "tags"
                    lappend attribute_info [string range $attr_val [string length $NGS_TAG_PREFIX] end]
                } elseif { $attr_val == "type"} {
                    set cur_key "types"
                    lappend attribute_info $attr_val
                } elseif { $attr_val == "my-type"} {
                    set cur_key "my-type"
                    lappend attribute_info $attr_val
                } elseif { $attr_val == "operator" } {
                    set cur_key "operators"
                    lappend attribute_info $attr_val
                } elseif { [ngs-debug-is-activation $attr_val] == 1 } {
                    set cur_key "activation"
                    lappend attribute_info "ACTIVATION"
                    lappend attribute_info $attr_val 
                    continue
                } else {
                    set cur_key "attributes"
                    lappend attribute_info $attr_val
                }
        
                set is_attribute 0

            } else {

                lappend attribute_info $attr_val
                set identifier_type ""

                if { $attr_val == "+" } {
                    # lappend attribute_info "+"
                } elseif { [ngs-debug-is-lti $attr_val] == 1 && [llength $attribute_info] > 1 } {
                    # We already appended the LTI above
                } elseif { [ngs-debug-is-identifier $attr_val] == 1 } {
#
                    # This is an identifier
                    set identifier_type [ngs-debug-get-single-id-for-attribute $attr_val "my-type"]
                    if { $identifier_type == "" } {
                        set identifier_type [ngs-debug-get-single-id-for-attribute $attr_val "name"]
                    }
                    lappend attribute_info $identifier_type
                    set variable_value [ngs-debug-get-single-id-for-attribute $attr_val "value"]
                    if { $variable_value != "" } {
                        lappend attribute_info $variable_value
                    } else {
                        # Append a second time if this does NOT have a value under it
                        # We need to have some value here
                        lappend attribute_info $attr_val
                    }

                } elseif { [string is integer $attr_val] == 1 } {
                    lappend attribute_info ""
                    lappend attribute_info ""
                } elseif { [string is double $attr_val] == 1 } {
                    lappend attribute_info ""
                    lappend attribute_info ""
                } elseif { $attr_val == $NGS_YES || $attr_val == $NGS_NO || $attr_val == $NGS_UNKNOWN } {
                    lappend attribute_info ""
                    lappend attribute_info ""
                } else {
                    lappend attribute_info ""
                    lappend attribute_info ""
                }

                set is_attribute 1
            } 
            
        }
    }

    # Final insertion
    if { $cur_key == "my-type" || $cur_key == "activation" } {
        dict set ret_val $cur_key [lindex $attribute_info 1]
    } elseif { $cur_key != "" } {
        if { $attribute == "" || $attribute == [lindex $attribute_info 0] } {
            dict lappend ret_val $cur_key $attribute_info
        }
    }

    return $ret_val
}


#
# nps task output-command
# =========================================================================================================
# + AchieveMission: G3, task: T14 (Mission)
# +- AchieveAbstractWarfighterTask: G14, task: T67 (DismountedInfiltration) 
# |  +- AchieveConcreteWarfighterTask: G21, task: T91 (TravelWithFireteam)
# |  |  +- AchieveManeuverTask: G32, task: T105 (WaitForTeamToCatchUp), output-command: C23 (Pause)
# |  |  +- AchieveManeuverTask: G30, task: T99 (MoveInFormation), output-command: C24 (FollowFormation)
# |  |  |  +- AchieveWedgeFormation: G41
# |  |  |  +- AchieveModWedgeFormation: G42
# |  |  |  +- AchieveFileFormation: G43
# |  |  |  +- DECISION formation (*G42* G41, G43)
# |  |  +- AchieveSensorTask: G34, task: T107 (HorizontalSensorScan), output-command: C31 (PanCamera)
# |  |  +- DECISION: maneuver-control (*G32*, G30)
# |  |  +- DECISION: ptz-camera-1 (*G34*)
# |  +- AchieveConcreteWarfighterTask: G19, task: T80 (TravelingOverwatch)
# |  +- DECISION: robot1 (*G21*, G19)
# +- DECISION: robot1 (*G14*)
# =========================================================================================================

# Print out the goal stacks
#
# Use to print out all goal stacks. Because this must be implemented
#  as productions, it will execute 1 elaboration cycle to trigger the productions
#  Depending on where  you are in the decision cycle when you pause, you may not see
#  a printout because one elaboration cycle may not trigger the productions. If you don't
#  see an output, execute the command again.
#
# Usage: nps (print all goal stacks)
# Usage: nps attribute-name-1 attribute-name-2, etc (also print those attributes if they exist on the goal)
#
# args - (Optional) Pass in space-separated list of attributes that you would like printed. These attributes
#         will only be printed if they are members of the goal.
#                                                                                                    
proc nps { args } {

    set goal_pool_id [ngs-debug-get-single-id-for-attribute S1 "goals"]
    set forest_dict [ngs-debug-build-goal-forest $goal_pool_id [string trim $args]]
    set list_of_goals [dict get $forest_dict "all"]
    set subgoal_dict  [dict get $forest_dict "subgoals"]
    set supergoal_dict [dict get $forest_dict "supergoals"]
    
#   echo $forest_dict

    echo "================================================================================"
    foreach goal_id $list_of_goals {
        if { [dict exists $supergoal_dict $goal_id] != 1 } {
            echo [ngs-print-goal-tree-recursive $goal_id $forest_dict 1]
            echo "================================================================================"
        }
    }
}

# Return a string with the goal tree
#
# goal_id - root goal of the goal tree
# forest_dict - A forest dictionary as returned by ngs-debug-build-goal-forest
# level - The current recursion level (1 if calling from the top)
proc ngs-print-goal-tree-recursive { goal_id forest_dict level } {

    # Unpack the structures so we can start printing them.
    set my_type_dict  [dict get $forest_dict "my-type"]
    set other_goal_attributes_dict [dict get $forest_dict "other-attributes"]

    set subgoal_dict  [dict get $forest_dict "subgoals"]
    set goal_decision_requests_dict [dict get $forest_dict "requested-decisions"]

    set decision_dict [dict get $forest_dict "assigned-decision"]

    set prefix [ngs-debug-tree-view-prefix $level]
    set next_level_prefix [ngs-debug-tree-view-prefix [expr $level + 1]]

    # First, print out the type of goal and its id
    set goal_line "$prefix [dict get $my_type_dict $goal_id]: $goal_id"
    if { [dict exists $other_goal_attributes_dict $goal_id] == 1 } {
        set attr_val_pair_list [dict get $other_goal_attributes_dict $goal_id]
        foreach attr_val_pair $attr_val_pair_list {
            set attr [lindex $attr_val_pair 0]
            set val  [lindex $attr_val_pair 1]

            set goal_line "$goal_line, $attr: $val"

            if { [ngs-debug-is-identifier $val] == 1 } {
                set attr_type [ngs-debug-get-single-id-for-attribute $val "my-type"]
                set goal_line "$goal_line ($attr_type)"
            }
        }
    }

    if { [dict exists $subgoal_dict $goal_id] == 1 } {
        set subgoal_id_list [dict get $subgoal_dict $goal_id]
        foreach subgoal_id $subgoal_id_list {
            set goal_line "$goal_line\n[ngs-print-goal-tree-recursive $subgoal_id $forest_dict [expr $level + 1]]"
        }
    }
    
    if { [dict exists $goal_decision_requests_dict $goal_id] == 1 } {
     
        set decision_name_list [dict get $goal_decision_requests_dict $goal_id]
        foreach decision_name $decision_name_list {
            
            set goal_line "$goal_line\n$next_level_prefix DECISION: $decision_name"

	        if { [dict exists $decision_dict "$decision_name-$goal_id"] == 1 } {
                set print_list_of_goals ""
	            set deciding_goal_id_list [dict get $decision_dict "$decision_name-$goal_id"]
	            foreach deciding_goal_id $deciding_goal_id_list {
                    variable NGS_TAG_SELECTION_STATUS
                    variable NGS_NO
                    variable NGS_YES
                    set selected_tag [ngs-debug-get-single-id-for-attribute $deciding_goal_id [ngs-tag-for-name $NGS_TAG_SELECTION_STATUS]]
                    if { $selected_tag == "$NGS_NO" } {            
                        set print_list_of_goals "$print_list_of_goals $deciding_goal_id-"
                    } elseif { $selected_tag == "$NGS_YES" } {
                        set print_list_of_goals "$print_list_of_goals $deciding_goal_id+"
                    } else {
                        set print_list_of_goals "$print_list_of_goals $deciding_goal_id?"
                    }
	            }
	            set goal_line "$goal_line ([string trim $print_list_of_goals])"
	        } else {
                set goal_line "$goal_line (NO OPTIONS)"
            }
        }
    }
    
    return $goal_line
}

# Returns a dictionary containing the following:
#
# (key) "all" - a list of all of the goals in the goal pools
# (key) "my-type" - A dictionary mapping goal_id --> my-type string
# (key) "subgoals" - A dictionary mapping goal_id --> list of subgoal ids
# (key) "supergoals" - A dictionary mapping goal_id --> supergoal id
# (key) "requested_decisions" - A dictionary mapping goal_id --> list of decision names requested by that goal
# (key) "assigned-decision" - A dictionary mapping decision name --> list of goal ids assigned to that decision
# (key) "other-attributes" - A dictionary mapping goal_id --> list of {attribute value} pairs from the $other_attributes list
#
# Pass in the goal pool id
# Optionally pass in a list of other goal attributes you want returned (if they exist on the goals) 
proc ngs-debug-build-goal-forest { goal_pool_id { other_attributes "" } } {

    set decision_dict ""
    set my_type_dict ""
    set subgoal_dict ""
    set supergoal_dict ""
    set goal_decision_requests_dict ""
    set other_goal_attributes_dict ""

    set list_of_goals [ngs-debug-get-all-goal-ids $goal_pool_id]

    foreach goal_id $list_of_goals {
        
        set assigned_decision ""
        set supergoal_id ""

        set goal_attributes [ngs-debug-get-all-attributes-for-id $goal_id]
        if {[dict exists $goal_attributes "my-type"] == 1} {
            dict set my_type_dict $goal_id [dict get $goal_attributes "my-type"]
        } 

        if {[dict exists $goal_attributes "attributes"] == 1} {
            set goal_intrinsic_attributes [dict get $goal_attributes "attributes"]
            foreach attribute $goal_intrinsic_attributes {
                # Each attribute is a tuple where the first item is the name and the second the value
                set attr_name [lindex $attribute 0]
                set attr_val  [lindex $attribute 1]

                if { $attr_name == "decides" } {
                    # Store till the end when we have a supergoal too
                    set assigned_decision $attr_val
                } elseif { $attr_name == "supergoal" } {
                    set supergoal_id $attr_val
                    dict lappend supergoal_dict $goal_id $supergoal_id
                } elseif { $attr_name == "subgoal" } {
                    dict lappend subgoal_dict $goal_id $attr_val
                } elseif { $attr_name == "requested-decision"} {
                    set decision_name [ngs-debug-get-single-id-for-attribute $attr_val "name"]
                    if { $decision_name != "" } {
                        dict lappend goal_decision_requests_dict $goal_id $decision_name
                    }
                } elseif { [string first "$attr_name" $other_attributes] >= 0 } {
                    dict lappend other_goal_attributes_dict $goal_id "$attr_name $attr_val"
                }
            }
        }

        if { $assigned_decision != "" && $supergoal_id != "" } {
            dict lappend decision_dict "$assigned_decision-$supergoal_id" $goal_id
            set assigned_decision ""
            set supergoal_id ""
        }
    }

    set result_dict ""
    dict set result_dict "all" $list_of_goals
    dict set result_dict "my-type" $my_type_dict
    dict set result_dict "subgoals" $subgoal_dict
    dict set result_dict "supergoals" $supergoal_dict
    dict set result_dict "requested-decisions" $goal_decision_requests_dict
    dict set result_dict "assigned-decision" $decision_dict
    dict set result_dict "other-attributes" $other_goal_attributes_dict

    return $result_dict
}

# Returns a list of all goals that currently exist in the goal pool
proc ngs-debug-get-all-goal-ids { goal_pool_id } {

    set GOAL_ATTR         "^goal "
    set GOAL_ATTR_LEN     [string length $GOAL_ATTR]

    set result_string     [CORE_GetCommandOutput p --depth 2 $goal_pool_id]
    if { [string index $result_string 0] != "(" } { 
        return ""
    }

    set result_string [string map { "(" " " ")" " " } $result_string]

    set result_dict ""
    set goal_index [string first $GOAL_ATTR $result_string]
    while { $goal_index >= 0 } {
        
        set begin_goal_id [expr $goal_index + $GOAL_ATTR_LEN]
        set end_goal_id   [string first " " $result_string $begin_goal_id]

        if { $end_goal_id >= 0 } {
            set goal_id [string range $result_string $begin_goal_id $end_goal_id]
            dict set result_dict [string trim $goal_id] $goal_id
        }

        set goal_index [string first $GOAL_ATTR $result_string $end_goal_id]
    }
    return [dict keys $result_dict]
}






##########################################################################################################3
# DEPRECATED: Debug Trace Pool support
#
# The debug trace pool is a pool of wmes stored on the top-state under the debug-trace-pools attribute.
# You use these pools to gather and print the state of the system for use when debugging.
#
# 

# Prints a line at load time. Do not put this in a production, it won't work.
#
proc NGS_DebugPrintLine { } {
    echo "|------------------------------------------------------------------------------------------------------|"
}

# Turn on debug trace pools (by default they are off).
# You can turn them off after turning them on by using ngs-dtp-off
#
proc ngs-dtp-on { } {
    sp "ngs*debug-trace-pool*create-root
        [ngs-match-top-state <s>]
    -->
        [ngs-create-typed-object <s> debug-trace-pools Bag <dtp>]"
}

# Turn off debug trace pools (the default).
# You can turn them on using ngs-dtp-on
#
proc ngs-dtp-off { } {
    excise ngs*debug-trace-pool*create-root    
}

# Creates a new debug trace pool
#
# Use this to create a new pool that will collect values for tracing. Do not use a pool
#  name that exists in the path (e.g. in the example below, the pool name should not be
#  "robo-agent" or "me" because these existin in the path)
#
# E.g. ngs-create-debug-trace-pool robot robo-agent.me <me>
#
# pool_name - name of the pool. It can be any valid Soar attribute name, but it should NOT
#              be the same as an element in the path (next parameter)
# path - Soar path to the object that will serve as the root of the pool. All of the items collected in the
#          pool should be somewhere under this path.
# pool_root_id - Variable bound to the root object id of the pool. Usually this is the last element of the path,
#                    but it doesn't have to be.                                                     
proc ngs-create-debug-trace-pool { pool_name path pool_root_id } { 

    set pool_id [CORE_GenVarName pool]
    set path_for_name $path
    regsub -all {\.} $path_for_name "*" path_for_name

    sp "ngs*debug-trace-pool*$pool_name*exists
        [ngs-match-top-state <s> debug-trace-pools]
        [ngs-bind <s> $path]
    -->
        [ngs-create-typed-object <debug-trace-pools> $pool_name Bag $pool_id]
        [ngs-create-attribute $pool_id root-id $pool_root_id]"

    sp "ngs*debug-trace-pool*$pool_name*not-exists
        [ngs-match-top-state <s> debug-trace-pools]
        [ngs-not [ngs-bind <s> $path]]
    -->
        [ngs-create-attribute <debug-trace-pools> $pool_name **MISSING**]"

}

# Creates productions to collect a debug trace item
#
# A debug trace item is a single attribute and its coresponding value.
# These items are placed in a pool that you create using ngs-create-ebug-trace-pool
#
# The following example traces the x location (renaming it loc-x) within the pool "robot"
# 
# E.g. ngs-create-debug-trace-item robot <me> robo-agent.me.pose.location x loc-x
#
# pool_name - name of the pool. This should be the same name used in the call to ngs-create-debug-trace-pool
# pool_root_id - A variable bound to the root object of the pool. This should be the same as teh root_pool_id
#                  used when constructing the trace pool
# item_name - Name of the attribute you want to trace
# debug_name - (Optional) Alias for the attribute. This alias is what you will see in the pool. 
#
proc ngs-create-debug-trace-item { pool_name pool_root_id path item_name { debug_name "" } } { 

    if { $debug_name == "" } {
        set debug_name $item_name
    }

    sp "ngs*debug-trace-pool*$pool_name*$debug_name*exists
        [ngs-match-top-state <s> debug-trace-pools.$pool_name.root-id:$pool_root_id]
        [ngs-bind <s> $path.$item_name]
    -->
        [ngs-create-attribute <$pool_name> $debug_name <$item_name>]"

    sp "ngs*debug-trace-pool*$pool_name*$debug_name*not-exists
        [ngs-match-top-state <s> debug-trace-pools.$pool_name.root-id:$pool_root_id]
        [ngs-not [ngs-bind <s> $path.$item_name]]
    -->
        [ngs-create-attribute <$pool_name> $debug_name **MISSING**]"

}

# Report Missing Values
#
# Call this macro at the start of your program (or any time afterward) to print 
#  missing values every time they occur.
#
# after_cycle - (Optional) If provided, will only print missing values after the given decision cycle
#
proc ngs-dtp-report-missing-values { { after_cycle 0 } } {

    sp "ngs*debug-trace-pool*report-missing-values
        [ngs-match-top-state <s> debug-trace-pools.<pool-name>:<pool-id>]
        [ngs-eq <pool-id> <item-name> **MISSING**]
        [ngs-cycle-gt <s> $after_cycle]
    -->
        (write (crlf) |+-- *** MISSING: | <pool-name> |: | <item-name>)"

}

# Print out debug trace values
#
# Call this when the Soar agent is paused and it will print out the current values in 
#  the specified pool.
#
# Note that you can also just print out the trace values using "np" on the trace-pool's
#  identifier, but this can often be easier and doesn't contain the NGS tags.
#
# pool_name - (Optional) The name of the pool to print. If empty, will print all of the pools.
# missing_only - (Optional) If NGS_YES, will only print missing values, otherwise, prints all values
#
proc ngs-dashboard { {pool_name ""} {missing_only ""}} {

    variable NGS_YES
    CORE_SetIfEmpty pool_name "<all-pools>"

    NGS_DebugPrintLine

    if { $missing_only == $NGS_YES } {
        set item_test "**MISSING**"
    } else {
        set item_test "<item-val>"
    }
    
    sp "ngs*debug-trace-pool*report-category
        [ngs-match-top-state <s> debug-trace-pools.$pool_name:<pool-id>]
        [ngs-eq <pool-id> <item-name> $item_test <item-id>]
        (<pool-id> -^{ <item-name> type })
        (<pool-id> -^{ <item-name> my-type }) 
        (<pool-id> -^{ <item-name> root-id }) 
        (<pool-id> -^{ <item-name> __tagged*ngs*i-supported })
        (<pool-id> -^{ <item-name> __tagged*ngs*constructed }) 
    -->
        (write (crlf) |+-- | $pool_name |: | <item-name> | = | <item-id>)"

    run -e 2

    NGS_DebugPrintLine

    excise ngs*debug-trace-pool*report-category
}


######################### Dotted Expression Printing Functions #########################
# added by gillies 20181130

## Returns the list attribute/value pairs from a supplied identifier.
## In the returned list, the odd numbered items are attribute names, 
## and the even numbered items are the corresponding values.
proc ngs-debug-get-att-value-pairs { identifier } {
    set print_string [CORE_GetCommandOutput p $identifier]
    set attr_value_pairs [ngs-debug-process-id-print $print_string]
    return $attr_value_pairs
}

## Get all values of the supplied attribute off of the supplied identifier.
## If the attribute starts with @, remove, the @ and prepend "__tagged*".
## The resut is a list of values (Either identifiers or literal values such as strings or numbers)
     
proc ngs-debug-get-attribute-values { identifier attribute } {
    set result ""
    set attr_value_pairs [ngs-debug-get-att-value-pairs $identifier]
    set is_key 1
    if { [string index $attribute 0] == "@" } {
        set attribute [string cat "__tagged*" [string range $attribute 1 end]]
    }
    #echo "attribute =" $attribute
    foreach item $attr_value_pairs {
        if { $is_key == 1 } {
            set curr_key $item
            set is_key 0
        } else {
            #echo "curr_key =" $curr_key $attribute
            if { $curr_key == $attribute } {
                lappend result $item
            }
            set is_key 1
        }
    }

    return $result
}

## print key/value pairs from a tcl dict
proc pdict { d } {
    dict for { k v } $d {
        echo $k $v
    }
}

proc ngs-debug-get-dotted-values { identifier dotted } {
    set chain [split $dotted "."]
    set values $identifier
    foreach attribute $chain {
        set new_values ""
        #echo $values $attribute
        foreach id $values {
            foreach val [ngs-debug-get-attribute-values $id $attribute] {
                lappend new_values $val
            }
        }
        set values $new_values
    }
    return $values
}


## prints the value of a single dotted expression
proc npv1 { arg } {
    set args [split $arg "."]
    set identifier [lindex $args 0]
    set dotted [join [lrange $args 1 end] "."]
    set values [ngs-debug-get-dotted-values $identifier $dotted]
    foreach value $values {
        echo $value
    }
}

proc npo1 { depth arg } {
    set args [split $arg "."]
    set identifier [lindex $args 0]
    set dotted [join [lrange $args 1 end] "."]
    set values [ngs-debug-get-dotted-values $identifier $dotted]
    foreach value $values {
	    if { [ngs-debug-is-identifier $value] == 1 } {    
            npx $depth $value
        } else {
            echo "================================================================================"
            echo $value
        }
    }
}


# npv - NGS Print Value
#
# This command prints the value of one or more dotted expresions.
# If the value is an object, it prints that object's identifier.
# Otherwise it ptints the literal vallue, for example a number or a string.
# If the expression has multiple values, all values are printed (on separate lines).
#
# A dotted expression is of the form identifier.attribute1.attribute2...attributeN
# The value of a dotted expression is the item at the end of the chain of attributes starting with the initial identifier.
#
# Example: npv s1.io.input-link (prints "I2" - the input link identifier)
# Example: npv s1.io.input-link s1.io.input-link (prints "I2" and "I3" - the input and output link identifiers on separate lines)
# Example: npv s1.aps.my-type (prints "AutoPilotSoar", the my-type attribute of s1.aps - note that in this case the value is a string instead of an identifier)
# Example: npv s1.operator.name (prints the name of all current operators)
#
# args - one or more dotted expressions, separated by spaces.
#

proc npv { args } {
    foreach arg $args {
        npv1 $arg
    }
}

# np - NGS Print
#
# This used to be the npo command, but has subsumed and extended np functionality and renamed np.
#
# This command prints one or more items, specified by dotted expressions.
# If the item is an identifier, the object is printed np-style.
# If the item is a literal value, such as a string or number, it is printed using echo.
# If the expression yields multiple items, they are all printed.
# 
#
# A dotted expression is of the form identifier.attribute1.attribute2...attributeN
# The value of a dotted expression is the item at the end of the chain of attributes starting with the initial identifier.
#
# Example: np s1.io.input-link (prints the input-link object using npx)
# Example: np s1.io.input-link s1.io.input-link (prints both the input and output link objects using npx)
# Example: np s1.aps.my-type (prints "AutoPilotSoar", the my-type attribute of s1.aps)
# Example: np s1.operator.name (prints the name of all current operators)
#
# args - optional depth followed by one or more dotted expressions.
#

proc np { args } {

    if { [llength $args] == 0} {
        echo "+---------------------------------------+"
        echo "Usage: np (depth=1) expression1 expression2 expression3 ..."
    }

    set depth 1
    set first [lindex $args 0]

    if { [string is integer [string index $first 0]] == 1 && [llength $args] > 0 } {
        set depth $first
        set args [lrange $args 1 end]
    }
    foreach arg $args {
        npo1 $depth $arg
    }
    echo "================================================================================"
}


# Print out rule names matching a pattern
#
# Rule names are printed in alphabetical order.
#
# Simple string literals require no special syntax.
# E.g., "npp propose" to print all rules that contain the string literal "propose"
#
# Note that *'s in rule names need to be escaped, and the backslash for the escape also needs to be escaped.
# E.g., "npp propose\\*foo" to match on rules that contain the string literal "propose*foo"
#
# prodNamePattern - A regex (in Tcl format) for the rule names to print.
#
proc npp { prodNamePattern } {
    set prodNames [CORE_GetCommandOutput print]
    set prodNamesList [split $prodNames]
    set prodNamesList [lsort $prodNamesList]
    set filteredProdNamesList [lsearch -regexp -inline -all $prodNamesList $prodNamePattern]
    foreach element $filteredProdNamesList {
        echo $element
    }
}
