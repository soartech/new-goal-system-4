##!
# @file
#
# @created jacobcrossman 20161222

variable WM_CTX_GLOBAL_POOLS

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

# Bind to a global context variable pool with a given name
#
# Use this macro together with ngs-bind to acccess global context variables.
# A typical use might be as follows (bind a variable and test if greater than 42):
#  [ngs-ctx-pool <s> my-pool]
#  [ngs-bind <my-pool> ctx-category.ctx-varname]
#  [ngs-gt <ctx-varname> value 42]
#
# Another common use is as follows (bind a variable and test if it equals 42):
#  [ngs-bind-ctx-pool <s> my-pool]
#  [ngs-bind  <my-pool> ctx-category.ctx-varname.value:42 }]
#
# state_id - variable bound to the top-state
# pool_name - name of the global pool to which you'd like to bind
# pool_id - (Optional) if provided, the variable to which to bind the pool. If it 
#  is not provided, a variable of form <$pool_name> is created and boudn to the pool.
#
proc ngs-ctx-pool { state_id pool_name { pool_id "" } } {

    CORE_SetIfEmpty pool_id "<$pool_name>"

    set mater_pool [CORE_GenVarName master]
    return "($state_id ^$WM_CTX_GLOBAL_POOLS $master_pool)
            ($master_pool ^$pool_name_or_goal_type $pool_id)"

}

