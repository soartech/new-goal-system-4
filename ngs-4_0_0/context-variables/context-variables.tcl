##!
# @file
#
# @created jacobcrossman 20161222

# Creates a global context variable pool
#
# A context variable is a value that is derived from some logical or sampling process on 
#  another variable. There are several classes of context variable:
#
# * StableValue - a numeric value that stays stable unless its underlying source moves outside of a given range
# * TimeSampledValue - a numeric value sampled from a source very N milliseconds
# * SimpleBinnedValue - a symbolic value derived by binning a numeric value
# * DynamicBinnedValue - a symbolic value derived from binning a numeric value. The current bin expands by a
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
        [ngs-icreate-typed-object-in-place <pools> $pool_name NGSContextVariablePool <pool>]"

    if { $list_of_categories != "" } {
        NGS_CreateContextPoolCategories $pool_name $list_of_categories
    }
}

# Creates a context variable pool category
#
# All context variables must be stored under categories. You declare the categories you would like
#  for each pool or goal type using this macro.
#
# Each context variable is then indexible using its pool-name (or goal type), category name, and
#  variable name (see ngs-bind-ctx-var)
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

    set name_suffix ""
    foreach category_name $list_of_categories {
        set name_suffix "$name_suffix*$category_name"
        set rhs_code "$rhs_code
                      [ngs-icreate-typed-object-in-place <pool> $category_name NGSContextVariableCategory <$category_name>]"
    }

    sp* "ctxvar*elaborate*categories$name_suffix
        $root_bind
    -->
        $rhs_code"
}

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
#    using ngs-match-to-create-ctx-var or ngs-match-goal-to-create-ctx-var instead):
#
# [ngs-bind-ctx <s> my-agent-pool agent-state]  -  the category will bind to the Soar variable <agent-state>
#
# Bind to the velocity variable under the agent-state category. Bind the category to the Soar variable <state>
#   and bind the velocity variable to the Soar variable <my-vel>
#
# [ngs-bind-ctx <s> my-agent-pool agent-state:<state> velocity:<my-vel>]
#   
# You can provide more than one variable for each category. To do this, just wrap the variables (each taking 
#  one of the context variable forms above) in quotes or curly brackets. Here's an example that will
#  bind to the x and y values (to Soar variables <x-pos> and <y-pos>) within the agent-position category
#               
# [ngs-bind-ctx <s> my-agent-pool agent-position "x::<x-pos> y::<y-pos>"]
#                                                      
# Here's a complex example that tests velocity's value and binds the agent-position
#
# [ngs-bind-ctx <s> my-agent-pool agent-state:<state> velocity:>,2.0 agent-position "x::<x-pos> y::<y-pos>"]
#
# 
# [ngs-bind-ctx <s> pool_name (category_1) (variable_test_or_list1) (category2) (variable_test_or_list2) ...]
#
# state_id - A variable bound to the top state
# pool_name - Name of the global context variable pool to which to bind
# args - An arbitrarily long list of alternating category names and variable tests (or variable test lists). See
#         above for a detailed description and examples
#
proc ngs-bind-ctx { state_id pool_name args } {

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
#  the exact same bind language/semantics as ngs-bind-ctx, but it is rooted
#  at a goal instead of a global context pool.
#
# See ngs-bind-ctx for a detailed description of the binding syntax
#
# goal_id - A variable bound to the goal for which you wish to bind and/or test context variables
# args - An arbitrarily long list of alternating category names and variable tests (or variable test lists). See
#         above for a detailed description and examples
#
proc ngs-bind-goal-ctx { goal_id args } {

    return [ngs-ctx-bind-internal "" $goal_id $args]

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
# category_name - Name of the category in whic you wish to place your new context variable. Use
#                   the ngs-bind attr:<var> syntax if you want your category pool to bind to something
#                   other than <category_name>
# input_link_id - (Optional) If provided, will be bound to the input link
#
proc ngs-match-to-create-context-variable { state_id pool_name category_name { input_link_id "" } } {
    return "[ngs-match-top-state $state_id {} $input_link_id]
            [ngs-bind-ctx $state_id $pool_name $category_name]"
}

# Matches a goal and context variable category so you can create a new context variable in that category
# 
# Use this macro to start a production that will create a context variable on a goal
# The category_name will bind to the category pool into which you should place
#  your new context variable. The category pool soar variable will be <category_name>
#  unless you specify a different name using the ngs-bind syntax - category_name:<my-var-name>
#  
# [ngs-match-goal-to-create-context-variable goal_id category_name (input_link_id)]
#
# 
# state_id - A variable bound to the top state
# goal_type - The type of the goal you wish to bind to
# goal_id - A variable bound to the goal on which you will create a context variable
# category_name - Name of the category in whic you wish to place your new context variable. Use
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
#  * Time Sampled Values
#  * Conditionally Sampled Values 
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
    return [ngs-tag $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
}

# Internal procedures to expand the args for ngs-bind-ctx and ngs-bind-goal-ctx 
#
# DO NOT CALL THIS DIRECTLY
#
# See ngs-bind-ctx for a description of the binding syntax/semantics.
#
# pool_ bindings - Soar code binding to the root pool
# pool_id        - Variable bound to the root pool
# category_bindings - A list containing the args list passed to ngs-bind-ctx or
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

          set on_category 0
       } else {

          foreach ctxvar $item {
            # If the user renames the variable, we need to account for that
	        set name_and_var [split $ctxvar ":"]
            set ctxvar_length [llength $name_and_var]
	        
            if { $ctxvar_length == 1 } {
	            set var_name $name_and_var
	            set var_id  [CORE_GenVarName $var_name]
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
	                "~<" { set val_test "-($var_id ^value >= $val_id)" }
	                "~<=" { set val_test "-($var_id ^value > $val_id)" }
	                "~>" { set val_test "-($var_id ^value <= $val_id)" }                        
	                "~>=" { set val_test "-($var_id ^value < $val_id)" }
	              }
              } else {
                set val_test "($var_id ^value $var_compare $val_id)"
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



