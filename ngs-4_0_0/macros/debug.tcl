# NOTE: These methods don't work as well as I'd hoped. Need to rethink the dashboard processes


# NGS Print 
#
# This is a specialized version of Soar's p (or print) command.
# It defaults to printing as a tree and to depth 2. You can pass 
#  an optional depth number to change the printing depth.
#
# Usage: np s1 (print the top state to depth 2)
# Usage: np 3 s1 (print the top state to depth 3)
# Usage: np i2 i3 (print input and output links to depth 2)
# Usage: np 3 i2 i3 (print the input and output linkks to depth 3)
#
# args - An optional depth (integer) followed by identifiers. If the
#          depth is not provided, a default print depth of 2 is used.
#
proc np { args } {

    if { [llength $args] == 0} {
        echo "+---------------------------------------+"
        echo "Usage: np (depth=2) id1 id2 id3 ..."
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
	        set print_this "$print_this [ngs-print-identfiers-attributes-details $id 1 $depth prev_id_list]"
	        echo $print_this
        }
    }
	echo "================================================================================"
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
proc ngs-print-identifiers-attributes-details { id level target_level prev_id_dict } {

    upvar $prev_id_dict id_dict
    dict set id_dict $id $id

    set prefix [ngs-debug-tree-view-prefix $level]
    set print_this "$id ("

    set attributes [ngs-debug-get-all-attributes-for-id $id]

    if { [dict exists $attributes "my-type"] == 1 } {
        set my_type    [dict get $attributes my-type]
        set print_this "$print_this$my_type"
    } else {
        set my_type [ngs-debug-get-single-id-for-attribute $id "name"]
        if { $my_type != "" } {
            set print_this "$print_this$my_type"
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

    if { [dict exists $attributes attributes] == 1 } {
        foreach attr_props [dict get $attributes attributes] {
            set attr_name  [lindex $attr_props 0]
            set attr_value [lindex $attr_props 1]
            set attr_type  [lindex $attr_props 2]
        
            if { $level == $target_level || [dict exists $id_dict $attr_value] == 1 ||
                 $attr_type == "string" || $attr_type == "double" || $attr_type == "integer" || $attr_type == "boolean" } {
               set print_this "$print_this\n$prefix $attr_name: $attr_value ($attr_type)"
            } else {
               set print_this "$print_this\n$prefix $attr_name: [ngs-print-identifiers-attributes-details $attr_value \
                                                [expr $level + 1] $target_level id_dict]"
            }
        }
    }

    if { [dict exists $attributes operators] == 1 } {
        foreach op_props [dict get $attributes operators] {
            set op_attr  [lindex $op_props 0]
            set op_value [lindex $op_props 1]
            set op_name  [lindex $op_props 2]

            if { [lindex $op_props 3] == "+" } {
                set op_attr "OPERATOR (PROPOSAL)"
            } else {
                set op_attr "OPERATOR (SELECTED)"
            }
            if { $level == $target_level || [dict exists $id_dict $op_value] == 1 } {
               set print_this "$print_this\n$prefix $op_attr: $op_value ($op_name)"
            } else {
               set print_this "$print_this\n$prefix $op_attr: [ngs-print-identifiers-attributes-details $op_value \
                                                [expr $level + 1] $target_level id_dict]"
            }
        }
    }

    if { [dict exists $attributes tags] == 1 } {
        foreach tag_props [dict get $attributes tags] {
            set tag_name  [lindex $tag_props 0]
            set tag_value [lindex $tag_props 1]
            set tag_type  [lindex $tag_props 2]
            if { $level == $target_level || [dict exists $id_dict $tag_value] == 1 ||
                 $tag_type == "string" || $tag_type == "double" || $tag_type == "integer" || $tag_type == "boolean"} {
               set print_this "$print_this\n$prefix TAG: $tag_name: $tag_value ($tag_type)"
            } else {
               set print_this "$print_this\n$prefix TAG: $tag_name: [ngs-print-identifiers-attributes-details $tag_value \
                                                [expr $level + 1] $target_level id_dict]"
            }
        }
    }

    return $print_this
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
# 4 - operator preference (if attribute is an operator)
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

    set print_string     [string trim $print_string " ()"]
    set end_of_print     [expr [string length $print_string] - 1]
    set print_string     [string range $print_string 0 $end_of_print]
    set attr_value_pairs [split $print_string " ^"]

    set is_attribute 1
    set attribute_info ""

    # internal, tags, attributes, types, my-type
    set ret_val ""
    set cur_key ""
    foreach attr_val [lrange $attr_value_pairs 1 [llength $attr_value_pairs]] {
        set attr_val [string trim $attr_val]

        if { $attr_val != "" } {

            if { $is_attribute == 1 && $attr_val != "+"} {

                # Insert the last value before starting a new one
                if { $cur_key == "my-type" } {
                    dict set ret_val $cur_key [lindex $attribute_info 1]
                } elseif { $cur_key != "" } {
                    if { $attribute == "" || $attribute == [lindex $attribute_info 0] } {
                        dict lappend ret_val $cur_key $attribute_info
                    }
                }

                set attribute_info ""

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
                } else {
                    set cur_key "attributes"
                    lappend attribute_info $attr_val
                }
        
                set is_attribute 0

            } else {

                lappend attribute_info $attr_val
                set first_letter [string index $attr_val 0]
                set the_rest     [string range $attr_val 1 end]
                set identifier_type ""

                if { $attr_val == "+" } {
                    lappend attribute_info "+"
                } elseif { $the_rest != "" && [string is digit $first_letter] == 0 && [string is integer $the_rest] == 1 } {
                    # This is an identifier
                    set identifier_type [ngs-debug-get-single-id-for-attribute $attr_val "my-type"]
                    if { $identifier_type == "" } {
                        set identifier_type [ngs-debug-get-single-id-for-attribute $attr_val "name"]
                        if { $identifier_type == "" } {
                            set identifier_type identifier
                        }
                    }
                    lappend attribute_info $identifier_type
                } elseif { [string is integer $attr_val] == 1 } {
                    lappend attribute_info "integer"
                } elseif { [string is double $attr_val] == 1 } {
                    lappend attribute_info "double"
                } elseif { $attr_val == $NGS_YES || $attr_val == $NGS_NO || $attr_val == $NGS_UNKNOWN } {
                    lappend attribute_info "boolean"
                } else {
                    lappend attribute_info "string"
                }

                set is_attribute 1
            } 
            
        }
    }
    return $ret_val
}



# Print out the goal stacks
#
# Use to print out all goal stacks. Because this must be implemented
#  as productions, it will execute 1 elaboration cycle to trigger the productions
#  Depending on where  you are in the decision cycle when you pause, you may not see
#  a printout because one elaboration cycle may not trigger the productions. If you don't
#  see an output, execute the command again.
#
# Usage: nps (print all goal stacks)
# Usage: nps GoalName1 GoalName2 (print goal stacks rooted at GoalName1 and GoalName2)
#
# args - (Optional) Pass in space-separated list of goal types to only show goal stacks
#          that are rooted at the given goal type.
#
proc nps { args } {

	if { $args != "" } {
		set goal_constraint [ngs-is-my-type <top-goal> "<< $args >>"]
	} else {
		set goal_constraint ""
	}

	# sp some productions
	sp "debug*print-isolated-goals
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-subgoal <top-goal> <subgoal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)
		(write (crlf) |+ ISOLATED GOAL|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)"

	sp "debug*print-goal-stack*1
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-my-type <sg1> <sg1-type>]
		[ngs-is-not-subgoal <sg1> <sg2>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)
		(write (crlf) |+   | <sg1-type> |: | <sg1>)"

	sp "debug*print-goal-stack*2
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-my-type <sg1> <sg1-type>]
		[ngs-is-subgoal <sg1> <sg2>]
		[ngs-is-my-type <sg2> <sg2-type>]
		[ngs-is-not-subgoal <sg2> <sg3>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)
		(write (crlf) |+   | <sg1-type> |: | <sg1>)
		(write (crlf) |+     | <sg2-type> |: | <sg2>)"

	sp "debug*print-goal-stack*3
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-my-type <sg1> <sg1-type>]
		[ngs-is-subgoal <sg1> <sg2>]
		[ngs-is-my-type <sg2> <sg2-type>]
		[ngs-is-subgoal <sg2> <sg3>]
		[ngs-is-my-type <sg3> <sg3-type>]
		[ngs-is-not-subgoal <sg3> <sg4>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)
		(write (crlf) |+   | <sg1-type> |: | <sg1>)
		(write (crlf) |+     | <sg2-type> |: | <sg2>)
		(write (crlf) |+       | <sg3-type> |: | <sg3>)"

	sp "debug*print-goal-stack*4
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-my-type <sg1> <sg1-type>]
		[ngs-is-subgoal <sg1> <sg2>]
		[ngs-is-my-type <sg2> <sg2-type>]
		[ngs-is-subgoal <sg2> <sg3>]
		[ngs-is-my-type <sg3> <sg3-type>]
		[ngs-is-subgoal <sg3> <sg4>]
		[ngs-is-my-type <sg4> <sg4-type>]
		[ngs-is-not-subgoal <sg4> <sg5>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)
		(write (crlf) |+   | <sg1-type> |: | <sg1>)
		(write (crlf) |+     | <sg2-type> |: | <sg2>)
		(write (crlf) |+       | <sg3-type> |: | <sg3>)
		(write (crlf) |+         | <sg4-type> |: | <sg4>)"

	# run -e 1
	run -e 1
	echo +---------------------------------------------------------------------------+

	# excise some productions
	excise debug*print-isolated-goals
	excise debug*print-goal-stack*1
	excise debug*print-goal-stack*2	
	excise debug*print-goal-stack*3
	excise debug*print-goal-stack*4
}




##########################################################################################################3
# Debug Trace Pool support
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



