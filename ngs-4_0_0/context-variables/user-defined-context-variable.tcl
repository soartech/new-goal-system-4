##!
# @file
#
# @created jacobcrossman 20161229



# Creates an empty, i-supported context variable at the given location
#
# NOTE: Right now, you can't create o-supported context variables (though the actual values of
#  these variables are often o-supported) -- the outer variable shell is i-supported.
#
# There is an optional NGS_DefineUserContextVariable because the system doesn't create any default
#  productions for user defined context variables ... all management of the context variable
#  is left to you. However, this procedure is required in order for behavior explanation to be aware of the variable.
#
# Use this macro when you want to create a context variable for which you control the values.
# For this type of variable you are responsible for updating the value. You can use the following
#  macros to update the value:
#
# * ngs-ctx-var-set-val-by-operator: for o-supported updates
# * ngs-ctx-var-set-val: for i-supported updates
#
# If your variable will be single-sourced, you can provide the source object (src-obj) and attribute 
#  (src-attr) in the attribute_list. Given these attributes you can use the macro ngs-ctx-var-source-val 
#  to bind to the value of the source.
#
# You can provide your own typename for the context variable using the typename parameter. If you don't
#  the system will use UserContextValue.
#
# pool_id - Variable bound to the identifier for the category pool into which to place the new
#             stable value. Bind to this pool using one of the following macros:
#             ngs-match-to-create-context-variable or ngs-match-goal-to-create-context-variable
# variable_name - Name of the context variable that should be constructed
# variable_id - A variable that is bound to the newly created stable value. Use this to create 
#                substructure on the variable.
# typename - (Optional) If provided, this will be the type of the context variable that is created
# attribute_list - (Optional) List of attribute, value pairs for the new context variable. If attributes is a set
#                  (i.e. a multi-valued attribute), put the set values in a list.
#
proc ngs-create-user-defined-context-variable { pool_id variable_name variable_id { typename "" } { attribute_list "" } } {

    CORE_SetIfEmpty typename "UserContextValue"
    set attribute_list "name $variable_name $attribute_list"
    return "[ngs-create-typed-object $pool_id $variable_name $typename $variable_id $attribute_list]"

}


# Declare a user context variable.
#
# This is not strictly required for the variable to work, but it is required in order
# for behavior explanation to be aware of the variable.
#
# NGS_DefineUserContextVariable pool_goal_or_path category_name variable_name
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the variable
proc NGS_DefineUserContextVariable { pool_goal_or_path category_name variable_name } {
    variable NGS_CTX_ALL_VARIABLES
    lappend NGS_CTX_ALL_VARIABLES [dict create pool $pool_goal_or_path category $category_name name $variable_name]
}
