
# NGS Interal (do not call)
proc ngs-rl-create-root-bindings { name body } {
    
    variable NGS_RL_OP_PURPOSE_CREATE
    variable NGS_RL_OP_PURPOSE_REMOVE

    set op_id      [lindex $body 0] 
    set op_purpose [lindex $body 1]
    set op_params  [lindex $body 2]

    set additional_tests ""
    if { [llength $body] > 3 } {
        set additional_tests [lindex $body 3]
    }

    set dest_obj  [lindex $op_params 0]
    set dest_attr [lindex $op_params 1]
    set dest_val  [lindex $op_params 2]

    set bind_line ""
    if { $op_purpose == $NGS_RL_OP_PURPOSE_CREATE } { 
        set bind_line [ngs-bind-creation-operator $op_id $dest_obj $dest_attr $dest_val] 
    } elseif { $op_purpose == $NGS_RL_OP_PURPOSE_REMOVE } { 
        set bind_line [ngs-bind-removal-operator  $op_id $dest_obj $dest_attr $dest_val]
    }
 
    return "[ngs-match-proposed-operator <s> $op_id]
            $bind_line
            $additional_tests"
    
}

# NGS Interal (do not call)
proc ngs-rl-create-bindings-dict { binding_list } {

    set ret_val ""
    foreach binding $binding_list {
        set root_id [lindex $binding 0]
        set path    [lindex $binding 1]
        set expanded [ngs-bind $root_id $path]

        set expanded_list [split $expanded "\n"]
        foreach line $expanded_list {
            regexp {(<[^>]*>)([^<]*)(<[^>]*>)} $line match_str obj attr val
            dict set ret_val $val "$obj {($obj [string trim $attr] $val)}"
        }
    }

    return $ret_val
}

# NGS Interal (do not call)
proc ngs-rl-create-binding-for-leaf { leaf_variable bindings_dict } {
    set ret_val_dict ""
    set cur_var $leaf_variable

    set valid [dict exists $bindings_dict $cur_var]
    while { $valid } {
        set pair [dict get $bindings_dict $cur_var]
        dict set ret_val_dict $cur_var [lindex $pair 1]
        set cur_var [lindex $pair 0]
        set valid [dict exists $bindings_dict $cur_var]
    }

    #echo "\n =============== $leaf_variable; $ret_val_dict"
    return $ret_val_dict
}

# NGS Interal (do not call)
# variation name root_binding_dict list_of_leaf_variations
proc ngs-rl-create-variation-dict { variations_dict bindings_dict } {

    variable NGS_RL_EXPAND_DISCRETE
    variable NGS_RL_EXPAND_STATIC_BINS

    set ret_val ""
    dict for { variation_name variation_body } $variations_dict {
        set leaf_var  [lindex $variation_body 0]
        set leaf_attr [ngs-expand-tags [lindex $variation_body 1]]
        set var_type  [lindex $variation_body 2]

        if { $var_type == $NGS_RL_EXPAND_DISCRETE } {
            set var_list [lindex $variation_body 3]
            set expanded_variations ""
            foreach variation $var_list {
                lappend expanded_variations "($leaf_var ^$leaf_attr $variation)"
            }
        } elseif { $var_type == $NGS_RL_EXPAND_STATIC_BINS } {
            set var_list [lindex $variation_body 3]
            set expanded_variations ""
            
            set bin_min ""
            foreach bin_max $var_list {
                if { $bin_min != "" } {
                    lappend expanded_variations "($leaf_var ^$leaf_attr \{ >= $bin_min < $bin_max \})"
                } else {
                    lappend expanded_variations "($leaf_var ^$leaf_attr < $bin_max)"
                }
                set bin_min $bin_max
            }
            lappend expanded_variations "($leaf_var ^$leaf_attr >= $bin_max)"
        } else {
            set expanded_variations "{($leaf_var -^$leaf_attr)} {($leaf_var ^$leaf_attr)}"
        }

        dict set ret_val $variation_name "{[ngs-rl-create-binding-for-leaf $leaf_var $bindings_dict]} {$expanded_variations}"
    }

    return $ret_val
}

# NGS Interal (do not call)
proc ngs-rl-recursive-expansion { prod_name prod_body prod_pref variation_list variation_list_index  } {

    variable NGS_OP_ID

    if { $variation_list_index >= [expr [llength $variation_list] - 1] } {
        # print out the production
        set production "$prod_name
          $prod_body
        -->
          (<s> ^operator $NGS_OP_ID = $prod_pref)" 
        
        #echo $production
        sp $production

        return
    }

    set var_name  [lindex $variation_list $variation_list_index]
    set var_tests [lindex $variation_list [expr $variation_list_index + 1]]

    set i 0
    foreach var_test $var_tests {
        set prod_body_new "$prod_body
                           $var_test"

        ngs-rl-recursive-expansion "$prod_name*$var_name*$i" $prod_body_new $prod_pref $variation_list [expr $variation_list_index + 2]

        incr i
    }
}

# Defines RL rule expansions (i.e. rules that set numeric indifferent preferences)
#
# Use this macro to create RL rules conditioned by a variety of state variables
# This macro automates the generation of rules that test combinations of these state variables
#  It can generate a large number of rules, so use carefully.
#
# This macro uses the following standard bindings:
#  - Operators are bound to the variable $NGS_OP_ID
#  - The state in which the operator is proposed is to '<s>' per Soar's usual convention
#
# name: The first parameter is the name of the expansion. This becomes the first part of each RL preference
#         production that this macro generates
# body: The body is a complex structure with the following format
#
# Expansions are defined in four segments, provided as part of the parameter 'body'
#  The 'body' variable is a dictionary with the following elements:
#
# op-descriptions: a dictionary with named operator descriptions describing your RL operators
#          Format: operator_id operator_purpose_enum operator_param_tuple other_tests*
#
#          operator_id: The id you will bind to the operator (use $NGS_OP_ID)  
#          operator_purpose: One of NGS_RL_OP_PURPOSE_CREATE or NGS_RL_OP_PURPOSE_REMOVE indicating whether
#                             the operator is creating or removing a WME
#          operator_param_tuple: A list of three values { dest_obj dest_attr dest_val } that is bound
#                             and/or matched to the WME the RL operator is creating/removing.
#          other_tests: (Optional) Any additional conditions you want applied (e.g. type of object being created, etc)
# bindings: a list of ngs-bind pairs { variable path }. Each of these pairs is passed to ngs-bind internally and
#            expanded as they would normally be expanded.  The variables bound can be used in the expansion section.
#            Note: you cannot do conditional binding (:<:) or type testing (!ObjectType) in these bindings. Variable
#             names that are the same are assumed to be bound to the same object.
# variations: a dictionary with named variations.  Each variation is an object/attribute that is systematically varied
#             creating at least one production per variation depending on how they are expanded (see the expansions section)
#          Format: object_id attribute_name variation_type value_list*
#
#          object_id: variable (should be in the bindings section) for which to create systematic variations
#          attr_name: name of the attribute (does NOT HAVE to be in the bindings section) for which to create 
#                      systematic variations
#          variation_type: One of NGS_RL_EXPAND_EXISTANCE, NGS_RL_EXPAND_DISCRETE, or NGS_RL_EXPAND_STATIC_BINS
#                          NGS_RL_EXPAND_EXISTANCE - expands for cases when the attribute exists and doesn't exist
#                          NGS_RL_EXPAND_DISCRETE - expands once with equality test for each value in the value_list
#                          NGS_RL_EXPAND_STATIC_BINS - expands to test for attribute's value being within one of the
#                              bins specified by the list of numbers in value_list (each value is the boundary of
#                              another bin)
#          value_list: Required for NGS_RL_EXPAND_DISCRETE and NGS_RL_EXPAND_STATIC_BINS. A list of discrete values or
#                          static bin boundaries (numbers) respectively.
# expansions: a dictionary of named expansions that define which variation combinations to expand into RL preference productions
#          Format: op_description_name numeric_pref_init_value list_of_expansions
#
#          op_description_name: The name of the operator description to expand (this expansion will set preferences
#             on the given operator).  See the op-descriptions section.
#          numeric_pref_init_value: The initial preference value to give to the operator (e.g. 0.0)
#          list_of_expansions: A list of variation names. RL preference productions are generated for the cross product
#             of all values each variation defines.                                                                                                                                          
# 
# Example:
#
# NGS_DefineRLExpansion aps-rl "
#    op-descriptions {
#        select-macro-behavior    { $NGS_OP_ID $NGS_RL_OP_PURPOSE_CREATE { <g> @$APS_TAG_GOAL_STACK_STABLE $NGS_YES } { [ngs-is-type <g> AchieveMacroBehavior] } }
#        select-concrete-behavior { $NGS_OP_ID $NGS_RL_OP_PURPOSE_CREATE { <g> @$APS_TAG_GOAL_STACK_STABLE $NGS_YES } { [ngs-is-type <g> AchieveConcreteBehavior] } }
#    }
#    bindings {
#        { <g> task }
#        { <s> aps.situation:<sit> } 
#        { <sit> other-vehicles.lead }
#    }
#    variations {
#        lead-existance     { <other-vehicles> lead     $NGS_RL_EXPAND_EXISTANCE }
#        lead-distance      { <lead>           distance $NGS_RL_EXPAND_STATIC_BINS { 1 2 4 8 16 32 64 128 } }
#        macro-task-type    { <task>           type     $NGS_RL_EXPAND_DISCRETE    { FollowLeadVehicle MeetLegalConstraint ReactToConflict ProceedAsPlanned WaitInPlace } }  
#        concrete-task-type { <task>           type     $NGS_RL_EXPAND_DISCRETE    { CruiseBehindLead Cruise GoAtIntersection MoveUpToIntersection StopForLeadVehicle StopForStopSign StopInQueue StopNow WaitAtIntersection } }  
#    }
#    expansions {
#        macro-lead-dist     { select-macro-behavior 0.0 { macro-task-type lead-distance } }
#        macro-lead          { select-macro-behavior 0.0 { macro-task-type lead-existance } }
#        concrete-lead-dist  { select-concrete-behavior 0.0 { concrete-task-type lead-distance } }
#        concrete-lead       { select-concrete-behavior 0.0 { concrete-task-type lead-existance } }    
#    }
# "
#
proc NGS_DefineRLExpansion { name body } {

    set root_bindings_dict ""

    set op_descs [dict get $body "op-descriptions"]
    dict for { desc_name desc_body } $op_descs {
        dict set root_bindings_dict $desc_name [ngs-rl-create-root-bindings $desc_name $desc_body]
    }

    set bindings_dict [ngs-rl-create-bindings-dict [dict get $body "bindings"]]

    set variations_dict [ngs-rl-create-variation-dict [dict get $body "variations"] $bindings_dict]

    set expansions [dict get $body "expansions"]
    dict for { expansion_name expansion_body } $expansions {

        set prod_name "$name*$expansion_name"
        set prod_root [dict get $root_bindings_dict [lindex $expansion_body 0]]
        set prod_pref [lindex $expansion_body 1]
        set prod_variation_names [lindex $expansion_body 2]

        # Build unified root dictionary
        set unified_root_dict ""
        set var_tests_list ""
        foreach variation_name $prod_variation_names {
            set cur_variation_pair [dict get $variations_dict $variation_name]
            set var_roots [lindex $cur_variation_pair 0]
            set var_tests [lindex $cur_variation_pair 1]
            
            lappend var_tests_list $variation_name 
            lappend var_tests_list $var_tests

            dict for { var_name line } $var_roots {
                dict set unified_root_dict $var_name $line
            }
        }

        # Code gen unified root dictionary and append to root_binding
        set variations_root ""
        dict for { var_name line } $unified_root_dict {
            set variations_root "$line
                                 $variations_root"
        }

        # Set the core production body (without the test variations)
        set prod_root "$prod_root
                       $variations_root"

        # Generate all of the productions
        ngs-rl-recursive-expansion $prod_name $prod_root $prod_pref $var_tests_list 0
    }
}
