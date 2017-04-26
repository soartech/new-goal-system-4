##!
# @file
#
# @created jacobcrossman 20161227

# Constructs a Computed Value context variable
#
# A computed value is, as its name implies, generally computed from one or more other
#  values using a mathematical or other right hand side function. However, in the
#  degenerate case, a computed value can also simply wrap another value in 
#  a ContextVariable wrapper.
#
# The dynamic aspect of ComputedValue construction involves setting the sources. You 
#  then use NGS_DefineComputedValue to define the computation in terms of these sources.
#
# For example, to compute a distance between a vehicle's position and a destination you
#  might instantiate a variable as follows:
#
# [ngs-create-computed-val <pool> distance-to-destination { 
#           { <my-pos> x } 
#           { <my-pos> y } 
#           { <dest-pos> x dest-x } 
#           { <dest-pos> y dest-y } 
# }]
#
# Here <my-pos> and <dest-pos> are variables that would be bound on the LHS of the production
#  that creates the computed value; x and y are attributes of each of these positions; and
#  dest-x and dest-y are new names for the <dest-pos> x and y attributes so that they don't
#  collide with the <my-pos> x and y attributes.
#
# Another example shows how a computed value can simply pass a value through:
#
# [ngs-create-computed-val <pool> my-speed {{ <my-velocity> speed }}] 
#
# Here the only source we provide is the speed attribute from the <my-velocity> object
#  that must be bound to the LHS of the production that creates the computed value.
#  Now in the NGS_DefineComputedValue macro, this speed can be referenced and used
#  to set the ComputedValue "value" attribute. Note that you can also pass through
#  values with structure (e.g. you could source the velocity object itself instead
#  of the speed attribute).
#
# [ngs-create-computed-val pool_id variable_name sources_list (variable_id)]
#
# pool_id - Variable bound to the identifier for the category pool into which to place the new
#             stable value. Bind to this pool using one of the following macros:
#             ngs-match-to-create-context-variable or ngs-match-goal-to-create-context-variable
# variable_name - Name of the context variable that should be constructed
# sources_list - A list of source tuples. Each source tuple can take one of two forms. 
#                  Form 1: { <src-obj> src-attr } where the given src-attr is used to name this source 
#                  Form 2: { <src-obj> src-attr new-attr-name } when you need/want to rename the
#                          attribute of the source (i.e. if that name is used by another source
#                          as in the distance example above). This name is what is used to
#                          reference the value in the NGS_DefineComputedValue expressions.                                                                             
# variable_id - (Optional) If provided, a variable that is bound to the newly created stable value.
#                You can use this, for exmaple, to tag the variable.
#
proc ngs-create-computed-val { pool_id 
                               variable_name
                               sources_list
                               { variable_id "" } } {

    CORE_GenVarIfEmpty variable_id "variable"
    
    set srcs_id "<sources>"

    set rhs_ret  "[ngs-create-typed-object $pool_id $variable_name ComputedValue $variable_id "name $variable_name"]
                  [ngs-create-typed-object $variable_id sources Set $srcs_id]"

    foreach source $sources_list {
        set first_item [lindex $source 0]
        set second_item [lindex $source 1]

        set src_id  [CORE_GenVarName source]
        set rhs_ret "$rhs_ret
                     [ngs-create-typed-object $srcs_id source SourceDescription $src_id "src $first_item attr $second_item"]"
        
        if { [llength $source] == 2 } {
            set rhs_ret "$rhs_ret
                         [ngs-create-attribute $src_id name $second_item]"
        } else {
            set third_item [lindex $source 2]
            set rhs_ret "$rhs_ret
                         [ngs-create-attribute $src_id name $third_item]"
        }
    }

    return $rhs_ret
}

# Define a Computed Value's expressions
#
# Use this macro to declare and define the productions necessary to implement the computed value
#
# The key items you need to define are as follows:
# 1. a expression to use to set the computed value's "value" attribute. This can be any Soar RHS
#     function (math or otherwise), or it can simply be a variable available in the computed value's
#     local scope.
# 2. (optional) one or more intermediate expressions that can be used to break the function into steps and
#     create intermediate values.
#
# All expressions read from and right to the computed value's local scope. This scope is defined as the 
#  computed value object identifer. All source objects (defined with ngs-create-computed-val) are 
#  elaborated into this scope and can be referenced by the name given them in the call to 
#  ngs-crate-computed-val. All intermediate expressions define exactly one additional local value that
#  can be referenced by the name given to it in its definition. Referencing a local variable is as simple
#  as enclosing the variable's name with angle brackets to make a Soar-style variable.
#
# Here's an example that shows how you could compute the distance value described in the comments for
#  ngs-create-computed-val:
#
# NGS_DefineComputedValue my-agent-pool distances distance-to-destination {sqrt (+ <x-delta-sq> <y-delta-sq>)} {
#    { x-delta    "- <x> <lx>" }
#    { y-delta    "- <y> <ly>" }
#    { x-delta-sq "* <x-delta> <x-delta>" }
#    { y-delta-sq "* <y-delta> <y-delta>" }
# } 
#
# Here four intermediate values are constructed. The first two, x-delta and y-delta, reference
#  the variables bound to sources as defined in ngs-create-computed-val (see that example). 
#  x-delta and y-delta become local variables that can be referenced by other expressions.
#  x-delta-sq and y-delta-sq reference these variables to create squared versions of them.
#  Finally, the "value expression" (i.e. the expression that sets the "value" attribute of
#  the computed value) is computed referencing x-delta-sq and y-delta-sq. Notice that
#  the value expression has a nested expression inside. All expressions can be nested
#  in exactly the same ways they can be nested in Soar.
#
# To show how you would complete the pass through described in the ngs-create-computed-val description
#  we show one more example:
#
# NGS_DefineComputedValue my-agent-pool my-state my-speed {<speed>}
#
# Here we do not define any intermediate values and simply reference the source value "speed"
#  as defined in the call to ngs-create-computed-val. 
#
# NGS_DefineComputedValue pool_goal_or_path category_name variable_name internal_expression_list value_expression
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the variable
# value_expression - An expression, following the rules for expressions described for the parmaeter 
#  internal_expression_list, that will be used to set the computed value's "value" attribute. This value is what 
#  external code references when they use the computed value.
# internal_expression_list - A possibly empty list of variable name, expression pairs. The variables are simply
#  the name you would like to use to reference the result of the expression. The expression is a valid Soar
#  right hand side function call, a numeric constant, a string constant (surrounded by vertical bars - "|"), or
#  a Soar variable. If an expression uses nested function calls, the outermost function does not require parentheses,
#  though you can include them if you desire.
#
proc NGS_DefineComputedValue { pool_goal_or_path category_name variable_name value_expression { internal_expression_list "" } } {

    variable NGS_CTX_ALL_VARIABLES
    lappend NGS_CTX_ALL_VARIABLES [dict create pool $pool_goal_or_path category $category_name name $variable_name]

    set var_id  <variable>

    # Generate the root bindings shared by all productions in this macro
    set root_bind [ngs-ctx-var-gen-root-bindings $pool_goal_or_path $category_name $variable_name $var_id]

    # set the suffix for the template's names, removing any '.' charaters that appear (not allowed in production names)
    set production_name_suffix [ngs-ctx-var-gen-production-name-suffix $pool_goal_or_path $category_name $variable_name]

    # Elaborate values for all sourced values
    sp "ctxvar*computed-value*elaborate*source-vals*$production_name_suffix
        $root_bind
        [ngs-bind $var_id sources.source]
        [ngs-bind <source> name src attr]
        (<src> ^<attr> <src-val>)
    -->
        [ngs-create-attribute $var_id <name> <src-val>]"

    # Compute intermediate values
    foreach expression_pair $internal_expression_list {
        
        set name [lindex $expression_pair 0]
        set expression [lindex $expression_pair 1]

        sp "ctxvar*computed-value*elaborate*internal-vals*$production_name_suffix*$name
            $root_bind
            [ngs-computed-value-bind-expression $var_id $expression]
        -->
            [ngs-create-attribute $var_id $name [ngs-computed-value-wrap-expression $expression]]"
    }


    # Create the computed value (this is an elaboration, it is i-supported)
    variable NGS_CTX_VAR_SUPPRESS_SAMPLING
    sp "ctxvar*computed-value*elaborate*internal-vals*$production_name_suffix*value
        $root_bind
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-computed-value-bind-expression $var_id $value_expression]
    -->
        [ngs-create-attribute $var_id value [ngs-computed-value-wrap-expression $value_expression]]"
}

# A helper function to wrap an expression with parentheses when required.
# 
# An expression is NOT wrapped when it is
# 1. a Soar variable
# 2. a string denoted with vertical bars '|'
# 3. a numeric constant
# 4. already wrapped in parentheses
#
proc ngs-computed-value-wrap-expression { expression } {
    set first_char [string index [string trimleft $expression] 0]
    if { $first_char == "<" || $first_char == "|" || $first_char == "(" || [string is digit $first_char] == 1 } {
        return $expression
    } else {
        return "($expression)"
    }
}

# A helper function to creates a binding string to bind all of the variables in an expression
# 
# This function is used by NGS_DefineComputedValue to bind to the variables that are
#  referenced in an expression.
#
# var_id - A variable bound to the identifier of a ComputedValue object
# expression - An expression as described in the comments for NGS_DefineComputedValue
#
# Returns a set of LHS bindings that bind to the variables in the given expression
#
proc ngs-computed-value-bind-expression { var_id expression } {
    set lhs_tests ""
    set var_dict ""
    set var_start 0
    while { $var_start >= 0 } {
        set var_start [string first "<" $expression $var_start]
        if { $var_start >= 0 } {
            set var_end   [string first ">" $expression $var_start]
            set var_name  [string range $expression [expr $var_start + 1] [expr $var_end - 1]]

            if { [dict exists $var_dict $var_name] == 0 } { 
	            set lhs_tests "$lhs_tests
	                           [ngs-bind $var_id $var_name]"
    
                # The second value is never used but is necessary to use dictionaries
                dict append var_dict $var_name $var_name
            }

            set var_start $var_end
        } 
    }
    return $lhs_tests
}

