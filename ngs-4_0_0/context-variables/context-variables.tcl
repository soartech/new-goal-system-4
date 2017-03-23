##!
# @file
#
# @created jacobcrossman 20161222

# Bind to global context categories and/or variables
#
# Use this macro to bind to the global context in many flexible ways.
#  This macro is more powerful than ngs-bind -- you can do more with it
#  but it only binds context variables.
#
# The "args" list takes the form of alternating categories and variables
#
# Each category can be one of two forms (following ngs-bind syntax):
#  Form 1: category-name - In this case the category is bound to <category-name>
#  Form 2: category-name:<my-name> - In this case the category with the given 
#            name is bound to <my-name>
# 
# Each variable can take three forms (extending ngs-bind syntax):
#  Form 1: variable-name - In this case the variable is bound to <variable-name>
#  Form 2: variable-name:<my-name> - In this case the variable is bound to <my-name>
#  Form 3: variable-name:<test>:test-value - In this case the variable's value is bound or
#            tested depending on <test>.
#
# <test> can be the following in Form 3:
#  EMPTY (i.e. ::): In this case the variable's value is either bound to test-value (if it is
#                    a Soar variable) or is tested against test-value for equality
#  One of >, >=, <, <=, <>: In this case the variable's value is compared to test-value using
#                            the specified comparison operator
#  One of ~>, ~>=, ~<, ~<=: In this case, the variable's value is compared to test-value using
#                            a stable version of the given comparison (i.e. ~> becomes NOT <=)
#
# Examples:
#
# Bind to a category (typically useful when creating new context variables - though you should consider
#    using ngs-match-to-create-context-variable or ngs-match-goal-to-create-context-variable instead):
#
# [ngs-bind-global-ctx <s> my-agent-pool agent-state]  -  the category will bind to the Soar variable <agent-state>
#
# Bind to the velocity variable under the agent-state category. Bind the category to the Soar variable <state>
#   and bind the velocity variable to the Soar variable <my-vel>
#
# [ngs-bind-global-ctx <s> my-agent-pool agent-state:<state> velocity:<my-vel>]
#   
# You can provide more than one variable for each category. To do this, just wrap the variables (each taking 
#  one of the context variable forms above) in quotes or curly brackets. Here's an example that will
#  bind to the x and y values (to Soar variables <x-pos> and <y-pos>) within the agent-position category
#               
# [ngs-bind-global-ctx <s> my-agent-pool agent-position "x::<x-pos> y::<y-pos>"]
#                                                      
# Here's a complex example that tests velocity's value and binds the agent-position
#
# [ngs-bind-global-ctx <s> my-agent-pool agent-state:<state> velocity:>:2.0 agent-position "x::<x-pos> y::<y-pos>"]
#
# 
# [ngs-bind-global-ctx <s> pool_name (category_1) (variable_test_or_list1) (category2) (variable_test_or_list2) ...]
#
# state_id - A variable bound to the top state
# pool_name - Name of the global context variable pool to which to bind
# args - An arbitrarily long list of alternating category names and variable tests (or variable test lists). See
#         above for a detailed description and examples
#
proc ngs-bind-global-ctx { state_id pool_name args } {

    variable WM_CTX_GLOBAL_POOLS

    set master_pool [CORE_GenVarName master]
    set pool_id [CORE_GenVarName pool]
    set pool_bindings "($state_id ^$WM_CTX_GLOBAL_POOLS $master_pool)
                       ($master_pool ^$pool_name $pool_id)"

    return [ngs-ctx-bind-internal $pool_bindings $pool_id $args]
}

# Bind to context categories and/or variables on a goal
#
# Use this macro to bind to the context variables stored on a goal. It has 
#  the exact same bind language/semantics as ngs-bind-global-ctx, but it is rooted
#  at a goal instead of a global context pool.
#
# See ngs-bind-global-ctx for a detailed description of the binding syntax
#
# goal_id - A variable bound to the goal for which you wish to bind and/or test context variables
# args - An arbitrarily long list of alternating category names and variable tests (or variable test lists). See
#         above for a detailed description and examples
#
proc ngs-bind-goal-ctx { goal_id args } {

    return [ngs-ctx-bind-internal "" $goal_id $args]

}

# Bind to a context variable that's located in a user defined location in working memory
#
# This method is more or less the same as ngs-bind-global-ctx except you must provide
#  the id of the object that is holding the context variable instead of a category name.
#
# It supports all of the binding/comparison methods of ngs-bind-global-ctx.
#
# A simple example is as follows:
#
#   [ngs-match-top-state <s> my-agent.vehicle-state.distances]
#   [ngs-bind-user-ctx <distances> "my-dist-to-dest::<my-dist> leader-dist-to-dest:<:<my-dist>"]
#
# You can bind more than one set of variables in one call. For example:
#
#   [ngs-match-top-state <s> my-agent.vehicle-state]
#   [ngs-bind <vehicle-state> distances velocities]
#   [ngs-bind-user-ctx <distances> my-dist-to-dest::<my-dist> <velocities> my-binned-velocity::slow]
#
# Here the same bind all is used to bind and test context variables from two different objects in the same call
#
# [ngs-bind-user-ctx obj_id1 variable_test_or_list1 (obj_id2) (variable_test_or_list2) ...]
#
# args - An arbitrarily long list of alternating object identifiers and variable tests (or variable test lists). See
#         above for a detailed description and examples
#
proc ngs-bind-user-ctx { args } {

    return [ngs-ctx-bind-internal "" "" $args]
}

# Matches against the given top state goal pool
# 
# Use this macro to start a production that will create a global context variable.
# The category_name will bind to the category pool into which you should place
#  your new context variable. The category pool soar variable will be <category_name>
#  unless you specify a different name using the ngs-bind syntax - category_name:<my-var-name>
#  
# [ngs-match-to-create-context-variable state_id pool_name category_name (input_link_id)]
#
# state_id - A variable bound to the top state
# pool_name - Name of the global pool in which you wish to place your new context variable
# category_name - Name of the category in which you wish to place your new context variable. Use
#                   the ngs-bind attr:<var> syntax if you want your category pool to bind to something
#                   other than <category_name>
# input_link_id - (Optional) If provided, will be bound to the input link
#
proc ngs-match-to-create-context-variable { state_id pool_name category_name { input_link_id "" } } {
    return "[ngs-match-top-state $state_id {} $input_link_id]
            [ngs-bind-global-ctx $state_id $pool_name $category_name]"
}

# Matches a goal and context variable category so you can create a new context variable in that category
# 
# Use this macro to start a production that will create a context variable on a goal
# The category_name will bind to the category pool into which you should place
#  your new context variable. The category pool soar variable will be <category_name>
#  unless you specify a different name using the ngs-bind syntax - category_name:<my-var-name>
#  
# [ngs-match-goal-to-create-context-variable state_id goal_type goal_id category_name (input_link_id)]
#
# 
# state_id - A variable bound to the top state
# goal_type - The type of the goal you wish to bind to
# goal_id - A variable bound to the goal on which you will create a context variable
# category_name - Name of the category in which you wish to place your new context variable. Use
#                   the ngs-bind attr:<var> syntax if you want your category pool to bind to something
#                   other than <category_name>
# input_link_id - (Optional) If provided, will be bound to the input link
#
proc ngs-match-goal-to-create-context-variable { state_id goal_type goal_id category_name { input_link_id "" } } {

    set lhs_ret "[ngs-match-goal $state_id $goal_type $goal_id]"

    if { $input_link_id != "" } {
        set lhs_ret "$lhs_ret
                     [ngs-input-link $state_id $input_link_id]"
    }
    return "$lhs_ret
            [ngs-bind-goal-ctx $goal_id $category_name]"
}

# Creates LHS bindings for a context variable's source value. 
#
# This macros is mainly for use internally by the context variable code, but
#  it can be used by user-defined context variables if they follow the
#  SingleSourceVariable pattern (see type-declarations.tcl).
#
# var_id - Variable bound to a context variable identifier
# source_val - Variable to be bound to the current value of the source
#
proc ngs-ctx-var-source-val { var_id source_val } {
    set src_obj_id [CORE_GenVarName "src-obj"]
    set src_attr   [CORE_GenVarName "src-obj"]

    return "($var_id ^src-obj $src_obj_id ^src-attr $src_attr)
            ($src_obj_id ^$src_attr $source_val)"
}

# Sets the current value of a user defined context variable
#
# Call to set the value of a user defined constext variable via i-support.
# Only use this on USER DEFINED context variables. It will conflict with
#  built in context variables which set their values automatically.
#
# var_id - Variable bound to the id of the user defined context variable to set.
# value  - New value to set
#
proc ngs-ctx-var-set-val { var_id value } {
    return "[ngs-create-attribute $var_id value $value]"
}

# Sets the current value of a user defined context variable
#
# Call to set the value of a user defined constext variable via o-support.
# Only use this on USER DEFINED context variables. It will conflict with
#  built in context variables which set their values automatically.
#
# state_id - Variable bound to the state in which to propose the operator
# var_id - Variable bound to the id of the user defined context variable to set.
# value  - New value to set
#
proc ngs-ctx-var-set-val-by-operator { state_id var_id value } {
    return "[ngs-create-attribute-by-operator $state_id $var_id value $value]"
}

# Suppress sampling on a context variable
#
# Suppressing sampling means that the underlying source variable will not be sampled
#  even if the sampling conditions are otherwise matching. Use this method when
#  some condition makes the sampling undesirable or invalid. For example, you might
#  choose to sample the heading of a vehicle when the vehicle is moving,. In this case
#  you'd suppress sampling of the heading when the velocity is at or near zero.  
#
# Note that this flag should be asserted via i-support (there is no o-support version).
#
# Suppression only works for sampled variables. The following are sampled variables
#  * Stable Values
#  * Periodic Sampled Values
#  * Time Delayed Values 
#
# Binned values are not sampled variables (they are inferred values), so this method does
#  not affect them.
# 
# [ngs-suppress-context-variable-sampling var_id]
#
# var_id - A variable bound to the context-variable for which to suppress sampling. While
#   this is asserted, the value attribute of var_id will not change.
#
proc ngs-suppress-context-variable-sampling { var_id } {
    variable NGS_CTX_VAR_SUPPRESS_SAMPLING
    return [ngs-tag $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
}

# Force a sampled value to pass through the value from the source without normal sampling constraints
#
# Use this if you want to set the context variable's value directly from the source
#  under certain conditions. While this flag is set, the variable will use i-support
#  to just link the value to the source value.
#
# Passthrough only works for sampled variables. The following are sampled variables
#  * Stable Values
#  * Periodic Sampled Values
#  * Time Delayed Values 
#
# RIGHT NOW THIS ONLY WORKS FOR PERIODIC SAMPLED VALUES
#
# var_id - Variable bound to the id of the context variable that should stop sampling and
#           just passthrough its source value
#
proc ngs-force-value-passthrough { var_id } {
    variable NGS_CTX_VAR_PASSTHROUGH_MODE
    return [ngs-tag $var_id $NGS_CTX_VAR_PASSTHROUGH_MODE]
}

# Creates a global context variable pool
#
# A context variable is a value that is derived from some logical or sampling process on 
#  another variable. There are several classes of context variable:
#
# * StableValue - a numeric value that stays stable unless its underlying source moves outside of a given range
# * TimeSampledValue - a numeric value sampled from a source very N milliseconds
# * SimpleBinnedValue - a symbolic value derived by binning a numeric value
# * DynamicBinnedValue - a symbolic value derived from binning a numeric value. The current bin expands by
#     a specified amount
# * ChoiceValue - a value that is selected from among multiple possible other values
# * ConditionallySampledValue - a numeric or symbolic value that is sampled based on an arbitrary condition
# * PsuedoFuzzyBinnedValue - a binned value that can have overlapping bins (not implemented yet)
# * FuzzyBinnedValue - binned value that includes membership functions (not implemented yet)
#
# Context variables are stored in pools that are elaborated in a global pool linked off of the top-state or
#  in a local pool linked off of a goal. Because a goal IS a pool, you don't need to create pools for goals.
#  However, you need to explicitly declare your global pool(s).
#
# [NGS_CreateGlobalContextVariablePool pool_name (list_of_categories) ]
#
# pool_name: The name of the pool to create. It should be a valid Soar attribute name
# categories: (Optional) If provided, this list is passed to NGS_CreateContextPoolCategories to create
#     categories within the pool.
#
proc NGS_CreateGlobalContextVariablePool { pool_name { list_of_categories "" } } {

    variable WM_CTX_GLOBAL_POOLS

    sp "ctxvar*elaborate*construct-global-pool*$pool_name
        [ngs-match-top-state <s> $WM_CTX_GLOBAL_POOLS:<pools>]
    -->
        [ngs-create-typed-object <pools> $pool_name NGSContextVariablePool <pool>]"

    if { $list_of_categories != "" } {
        NGS_CreateContextPoolCategories $pool_name $list_of_categories
    }
}

# Creates a context variable pool category
#
# All context variables must be stored under categories. You declare the categories you would like
#  for each pool or goal type using this macro.
#
# Each context variable is then indexable using its pool-name (or goal type), category name, and
#  variable name (see ngs-bind-global-ctx-var)
#
# pool_name_or_goal_type: For goal pools, this should be the type of the
#    goal that you want go create the category under (it can be a goal's based type or "my-type"). 
#    For global pools, this should be the name of the pool in which to create the category.
# list_of_categories: Simple TCL list of category names that you'd like to create.
#
proc NGS_CreateContextPoolCategories { pool_name_or_goal_type list_of_categories} {

    variable WM_CTX_GLOBAL_POOLS
 
    # If we can find a type declared for this pool, then we assume it is for a goal, otherwise
    #  it must be the name of a global pool
    variable NGS_TYPEINFO_$pool_name_or_goal_type
    if {[info exists NGS_TYPEINFO_$pool_name_or_goal_type] != 0} {
        set root_bind "[ngs-match-goal <s> $pool_name_or_goal_type <pool>]"
        set rhs_code "[ngs-create-attribute <pool> type NGSContextVariablePool]
                      [ngs-create-attribute <pool> type HierarchicalBag]"
    } else {
        set root_bind "[ngs-match-top-state <s> $WM_CTX_GLOBAL_POOLS.$pool_name_or_goal_type:<pool>]"
        set rhs_code ""
    }

    set name_suffix $pool_name_or_goal_type
    foreach category_name $list_of_categories {
        set name_suffix "$name_suffix*$category_name"
        set rhs_code "$rhs_code
                      [ngs-create-typed-object <pool> $category_name NGSContextVariableCategory <$category_name>]"
    }

    sp "ctxvar*elaborate*categories$name_suffix
        $root_bind
    -->
        $rhs_code"
}


####################################################################################################

# Internal procedures to expand the args for ngs-bind-global-ctx and ngs-bind-goal-ctx 
#
# DO NOT CALL THIS DIRECTLY
#
# See ngs-bind-global-ctx for a description of the binding syntax/semantics.
#
# pool_ bindings - Soar code binding to the root pool
# pool_id        - Variable bound to the root pool
# category_bindings - A list containing the args list passed to ngs-bind-global-ctx or
#                       ngs-bind-goal-ctx
proc ngs-ctx-bind-internal { pool_bindings pool_id category_bindings } {

    set lhs_ret $pool_bindings

    set on_category 1
    set cat_name ""
    set cat_id ""
    set var_name ""
    set var_id ""
    foreach item $category_bindings {
      
       if { $on_category == 1 } {
          if { $pool_id != "" } {
	          # If the user renames the variable, we need to account for that
	          set name_and_var [split $item ":"]
	          if { [llength $name_and_var] == 1 } {
	            set cat_name $name_and_var
	            set cat_id  [CORE_GenVarName $cat_name]
	          } else {
	            set cat_name [lindex $name_and_var 0]
	            set cat_id  [lindex $name_and_var 1]
	          }       
	
	          set lhs_ret "$lhs_ret
	                       ($pool_id ^$cat_name $cat_id)"
          } else {
              set cat_id $item
          }
          set on_category 0
       } else {

          foreach ctxvar $item {
            # If the user renames the variable, we need to account for that
	        set name_and_var [split $ctxvar ":"]
            set ctxvar_length [llength $name_and_var]
	        
            if { $ctxvar_length == 1 } {
	            set var_name $name_and_var
	            set var_id  "<$var_name>"
                set var_compare ""
                set val_id ""
	          } elseif { $ctxvar_length == 2 } {
	            set var_name [lindex $name_and_var 0]
	            set var_id  [lindex $name_and_var 1]
                set var_compare ""
                set val_id ""
	          } else {
                set var_name [lindex $name_and_var 0]
                set var_compare [lindex $name_and_var 1]
                set var_id  [CORE_GenVarName $var_name]
                set val_id  [lindex $name_and_var 2]
            }

            set var_test "($cat_id ^$var_name $var_id)"               
            if { $val_id != "" } {
	            if { [string index $var_compare 0] == "~" } {
 	              switch -exact $var_compare {
	                "~<" { set val_test "-($var_id ^value {>= $val_id})" }
	                "~<=" { set val_test "-($var_id ^value {> $val_id})" }
	                "~>" { set val_test "-($var_id ^value {<= $val_id})" }                        
	                "~>=" { set val_test "-($var_id ^value {< $val_id})" }
	              }
              } else {
                if {$var_compare != ""} {
                    set attr_test "\{$var_compare $val_id\}"
                } else {
                    set attr_test $val_id
                }
                set val_test "($var_id ^value $attr_test)"
              }
              set var_test "$var_test
                            $val_test"
            }
              
            set lhs_ret "$lhs_ret
                         $var_test"
            set on_category 1
          }
       }
    }

    return $lhs_ret
}

# Generate a suffix for the context variable maintenance production names.
# 
# This is used internally and is not useful for user code.
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the context variable
#
proc ngs-ctx-var-gen-production-name-suffix { pool_goal_or_path category_name variable_name } {
    # set the suffix for the template's names, removing any '.' charaters that appear (not allowed in production names)
    return [string map { "." "*" } "$pool_goal_or_path*$category_name*$variable_name"]
}

# Determine the scope of a context variable
#
#
# This is used internally and is not useful for user code.
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
proc ngs-ctx-var-get-scope-type { pool_goal_or_path category_name } {
    variable NGS_CTX_VAR_USER_LOCATION
	variable NGS_CTX_SCOPE_USER
	variable NGS_CTX_SCOPE_GOAL
	variable NGS_CTX_SCOPE_GLOBAL

	variable NGS_TYPEINFO_$pool_goal_or_path

    if { $category_name == $NGS_CTX_VAR_USER_LOCATION } {
		return $NGS_CTX_SCOPE_USER
	} elseif {[info exists NGS_TYPEINFO_$pool_goal_or_path] != 0} {
		return $NGS_CTX_SCOPE_GOAL
	} else {
		return $NGS_CTX_SCOPE_GLOBAL
	}
}

# Generate the root bindings used by all of the DefineXYZ macross
# 
# This is used internally and is not useful for user code.
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the context variable
# var_id - Soar variable to which to bind the context variable's id.
# scope_id - (Optional) If provided, Soar variable to which to bind either the goal id (for goals), the
#   category id (for globals), or the object id (for user defined paths).
#
proc ngs-ctx-var-gen-root-bindings { pool_goal_or_path category_name { variable_name "" } { var_id "" } { scope_id "" } { goal_id ""} } {
	variable NGS_CTX_SCOPE_USER
	variable NGS_CTX_SCOPE_GOAL
	variable NGS_CTX_SCOPE_GLOBAL

	if { $scope_id == "" } { set scope_id [CORE_GenVarName "scope-id"] }

    set scope_type [ngs-ctx-var-get-scope-type $pool_goal_or_path $category_name]

    if { $var_id == "" } {
        set var_binding ""
    } elseif { $scope_type == $NGS_CTX_SCOPE_USER } {
        set var_binding ".$variable_name:$var_id"
    } else {
        set var_binding "$variable_name:$var_id"
    }

	if { $scope_type == $NGS_CTX_SCOPE_USER } {
        return "[ngs-match-top-state <s> [ngs-expand-tags $pool_goal_or_path]:$scope_id$var_binding]"
	} elseif { $scope_type == $NGS_CTX_SCOPE_GOAL } {
        CORE_GenVarIfEmpty goal_id "goal"
		return "[ngs-match-goal <s> $pool_goal_or_path $goal_id]
                [ngs-bind-goal-ctx $goal_id $category_name:$scope_id $var_binding]"
	} elseif { $scope_type == $NGS_CTX_SCOPE_GLOBAL } {
		return "[ngs-match-top-state <s>]
                [ngs-bind-global-ctx <s> $pool_goal_or_path $category_name:$scope_id $var_binding]"
	}
}

# Creates delta values in a uniform way for all context variables that use them
#
# This is used internally and is not useful for user code.
#
# delta - Either a constant/variable (Form 1), a list with a min/max (Form 2), or
#          a list with a delta source obj/attr (Form 3). All forms specify the bounds
#          on the stable-value, indicating when it will be resampled from the source value.
# obj_id - place to store the delta values once they are parsed out of the delta structure
#
proc ngs-ctx-var-create-deltas { delta obj_id } {

   # Now, figure out what type of delta we have: (1) a constant (default), (2) a range, or
    #  (3) a source object/attribute pair
    if { [llength $delta] == 1 } {
        return [ngs-create-attribute $obj_id delta $delta]
    } else  {
        
        # It's either a max/min or a source object and attribute
        set first_item [lindex $delta 0]
        set second_item [lindex $delta 1]

        # Check to see if the first_item is alpha-numeric, if it is, it is the minimum
        if { [string index $first_item 0] == "<" } {
            return "[ngs-create-attribute $obj_id delta-src-obj  $first_item]
                    [ngs-create-attribute $obj_id delta-src-attr $second_item]"
        } else {
            return "[ngs-create-attribute $obj_id min-delta $first_item]
                    [ngs-create-attribute $obj_id max-delta $second_item]"
        } 
    }

}


# Helper to construct the detailed elements of a time-period based context variable
#
# For internal use only
proc ngs-ctx-var-help-construct-time-based-varible { time_descriptor variable_id global_time_param specialized_param_list } {

    if { [llength $global_time_param] == 1 } {
        # It's just a constant value
        set global_constructs "[ngs-create-attribute $variable_id global-$time_descriptor $global_time_param]"
    } else {
        set global_constructs "[ngs-create-attribute $variable_id global-$time_descriptor-src  [lindex $global_time_param 0]]
                               [ngs-create-attribute $variable_id global-$time_descriptor-attr [lindex $global_time_param 1]]"
    }

    # Handle the specialized delay list (if it exists)
    if { $specialized_param_list != "" } {
        set cond_set_id [CORE_GenVarName "$time_descriptor-set"]
        set global_constructs "$global_constructs
                               [ngs-create-typed-object $variable_id conditional-${time_descriptor}s Set $cond_set_id]"
    } 

    set conds_ret ""
    foreach description $specialized_param_list {

        set condition      [lindex $description 0]
        set time_param     [lindex $description 1]
        set time_param_id  [CORE_GenVarName "conditional-$time_descriptor"]

        if { [llength $time_param] == 1 } {
            set time_param_creation "$time_descriptor $time_param"
        } else {
            set time_param_creation "$time_descriptor-src [lindex $time_param 0] $time_descriptor-attr [lindex $time_param 1]"
        }
                               
        if { [llength $condition] == 1 } {
            set conds_ret   "$conds_ret
                             [ngs-create-typed-object $cond_set_id condition ConditionTimePeriod $time_param_id \
                                                     "$time_param_creation comparison-value $condition "]"
        } else {
            set first_item [lindex $condition 0]
            set second_item [lindex $condition 1]
        
            if { [string is integer $first_item] == 1 || [string is double $first_item] == 1} {
                set conds_ret   "$conds_ret
                                 [ngs-create-typed-object $cond_set_id condition ConditionTimePeriod $time_param_id \
                                                         "$time_param_creation range-min $first_item range-max $second_item"]"
            } else {
                if { $first_item == "<" } {
                    set conds_ret   "$conds_ret
                                     [ngs-create-typed-object $cond_set_id condition ConditionTimePeriod $time_param_id \
                                                             "$time_param_creation range-max $second_item"]"
                } elseif { $first_item == ">=" } {
                    set conds_ret   "$conds_ret
                                     [ngs-create-typed-object $cond_set_id condition ConditionTimePeriod $time_param_id \
                                                             "$time_param_creation range-min $second_item"]"
                } else {
                    echo "Time Delayed Values only support < and >= conditions ($variable_name)"
                }
            }
        }
    }

    return "$global_constructs
            $conds_ret"
}

# Helper to construct the support productions of a time-period based context variable
#
# For internal use only
proc ngs-ctx-var-help-build-time-productions { ctxvar_type time_descriptor production_name_suffix root_bind var_id } {

    ######################### PRODUCTIONS THAT HANDLE THE GLOBAL SOURCE
    set set_attr_name "conditional-${time_descriptor}s"

    # If I have a source for the global delay/period, elaborate it
    sp "ctxvar*$ctxvar_type*elaborate*global-$time_descriptor*$production_name_suffix
        $root_bind
        [ngs-bind $var_id global-$time_descriptor-src global-$time_descriptor-attr]
        (<global-$time_descriptor-src> ^<global-$time_descriptor-attr> <global-$time_descriptor-val>)
    -->
        [ngs-create-attribute $var_id global-$time_descriptor <global-$time_descriptor-val>]"

    # Handle sources for conditional delay/period
    sp "ctxvar*$ctxvar_type*elaborate*conditional-$time_descriptor*$production_name_suffix
       $root_bind
       [ngs-bind $var_id value $set_attr_name.condition]
       [ngs-bind <condition> $time_descriptor-src $time_descriptor-attr]
       (<$time_descriptor-src> ^<$time_descriptor-attr> <$time_descriptor-val>)
    -->        
       [ngs-create-attribute <condition> $time_descriptor <$time_descriptor-val>]"

    ########################## PRODUCTIONS THAT HANDLE ELABORATING TIMES

    sp "ctxvar*$ctxvar_type*elaborate*time-since-last-sampled*$production_name_suffix
        $root_bind
        [ngs-time <s> <time>]
        [ngs-bind $var_id time-last-sampled]
    -->
        [ngs-create-attribute $var_id value-age "(- <time> <time-last-sampled>)"]"

    variable NGS_YES
    variable NGS_NO

    sp "ctxvar*$ctxvar_type*elaborate*value-is-consistent*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value:<src-val>]
        [ngs-ctx-var-source-val $var_id <src-val>]
    -->
        [ngs-create-attribute $var_id is-consistent-with-source $NGS_YES]"

    sp "ctxvar*$ctxvar_type*elaborate*value-is-not-consistent*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value:<>:<src-val>]
        [ngs-ctx-var-source-val $var_id <src-val>]
    -->
        [ngs-create-attribute $var_id is-consistent-with-source $NGS_NO]"


    ############## PRODUCTIONS TO HANDLE CONDITIONAL DELAYS BASED ON THE VALUE OF SRC

    sp "ctxvar*$ctxvar_type*elaborate*custom-$time_descriptor*for-equality*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value $set_attr_name.condition]
        [ngs-bind <condition> comparison-value:<value> $time_descriptor]
    -->
        [ngs-create-attribute $var_id custom-$time_descriptor <$time_descriptor>]"

    sp "ctxvar*$ctxvar_type*elaborate*custom-$time_descriptor*for-range*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value $set_attr_name.condition]
        [ngs-bind <condition> range-min:<=:<value> range-max:>:<value> $time_descriptor]
    -->
        [ngs-create-attribute $var_id custom-$time_descriptor <$time_descriptor>]"

    sp "ctxvar*$ctxvar_type*elaborate*custom-$time_descriptor*for-lte*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value $set_attr_name.condition]
        [ngs-bind <condition> range-max:>:<value> $time_descriptor]
        [ngs-nex <condition> range-min]
    -->
        [ngs-create-attribute $var_id custom-$time_descriptor <$time_descriptor>]"

    sp "ctxvar*$ctxvar_type*elaborate*custom-$time_descriptor*for-gt*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value $set_attr_name.condition]
        [ngs-bind <condition> range-min:<=:<value> $time_descriptor]
        [ngs-nex <condition> range-max]
    -->
        [ngs-create-attribute $var_id custom-$time_descriptor <$time_descriptor>]"

}

