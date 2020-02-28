
##!
# @file
#
# @created jacobcrossman 20200228


# Create a piecewise function value value
#
# Use this macro when you want to create a numeric scoring function on a variable or
#  simply need a piecewise linear mapping of one value to another.
#
# Piecewise function values are like static bins in that they map a continuous source value to a set of
#  discrete segments.  However, within each segment or "bin" the output value is computed as a linear
#  function.  Therefore, the output of a piecewise function variable is also a continuous value.
#
# Piecewise function values map a numeric value domain onto another numeric value, where the
#  input domain is fixed at the time the variable is declared. Note that piecewise function values
#  are not sampled values -- i.e. they change the form of a value from an input domain to a
#  distinct, user-specified numer range.
#
#  To specify a piecewise function value you need to define the following:
#
# * A source object/attribute pair -- the numeric value that will be mapped
# * A set of linear function definitions -- Use NGS_DefinePiecewiseFunctionValue's last 
#           parameter to define your bins. If you plan to reuse bins in many places, 
#           declare a macro variable with your bin definitions making it easy to 
#           create several statically binned variables that use the same bin definitions.
#
# pool_id - Variable bound to the identifier for the category pool into which to place the new
#             dynamically binned value. Bind to this pool using one of the following macros:
#             ngs-match-to-create-context-variable or ngs-match-goal-to-create-context-variable
# variable_name - Name of the context variable that should be constructed
# src_obj - Variable bound to the object containing the value to be mapped
# src_attribute - Name of the attribute to sample for the mapping (do NOT bind to this in the LHS)
# variable_id - (Optional) If provided, a variable that is bound to the newly created statically binned value.
#                You can use this, for exmaple, to tag the variable.
#
proc ngs-create-piecewise-function-value { pool_id 
                                   variable_name 
                                   src_obj 
                                   src_attr                            
                                   { variable_id "" } } {

    CORE_GenVarIfEmpty variable_id "variable"

    set root_obj "[ngs-create-typed-object $pool_id $variable_name PiecewiseFunctionValue $variable_id \
                    "name $variable_name src-obj $src_obj src-attr $src_attr"]"

    return $root_obj
}


# Define a Piecwise Function variable
#
# This macro declares and defines the helper productions to support a specific piecewise function value. 
#  To actually construct the variable, us ngs-create-piecewise-function-value.
#
# Piecewise function values are like static bins in that they map a continuous source value to a set of
#  discrete segments.  However, within each segment or "bin" the output value is computed as a linear
#  function.  Therefore, the output of a piecewise function variable is also a continuous value.
#
# This variable was designed to be used for scoring functions where the source value represents a
#  portion of a situation and the output value is the "goodness" or "badness" of that situation.
#
# An example of bin_definitions follows (the source could be the tempurature of beef roast and
#   the values represent a person's assessment of the "goodness" with 1.0 being best). Notice
#   the two extremes only list a single value and the last bin uses the empty list for its max value.
#   { { 120.0 { 0.0 } } { 130.0 { 0.0 1.0 } } { 135 { 1.0 1.0 } } { 145.0 { 1.0 0.6 } } } { 155.0 { 0.6 0.25 } } 
#     { 200.0 { 0.6 0.0 } } { {} { 0.0 } } }
#
# NGS_DefinePiecewiseFunctionValue pool_goal_or_path category_name variable_name bin_definitions operator_info
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the variable
# bin_definitions - A list of {bin-name bin-max} pairs.  This list should be in ascending order sorted by
#   bin-max values.  The last bin should have an empty max (i.e. {bin-name {}}). See example in the
#   detailed comments above.
# operator_info - (Optional) By default this is an empty string indicating that values should be binned using
#  elaboration productions (i-support).  If you prefer to bin using a standard operator pass in the value 
#  NGS_CTX_VAR_OP_STANDARD - the bin value will be set via an operator.  To use a batch operator to set the bin
#  value provide a pair (TCL list) consisting of a batch operator category and name.
#
proc NGS_DefinePiecewiseFunctionValue { pool_goal_or_path category_name variable_name bin_definitions { operator_info "" } } {

    variable NGS_CTX_ALL_VARIABLES
    lappend NGS_CTX_ALL_VARIABLES [dict create pool $pool_goal_or_path category $category_name name $variable_name]

    set var_id  <variable>

    # Generate the root bindings shared by all productions in this macro
    set root_bind "[ngs-ctx-var-gen-root-bindings $pool_goal_or_path $category_name $variable_name $var_id]"

    # set the suffix for the template's names, removing any '.' charaters that appear (not allowed in production names)
    set production_name_suffix [ngs-ctx-var-gen-production-name-suffix $pool_goal_or_path $category_name $variable_name]

    ############### Setting values ####################################
    
    # This assumes that the maxes are presented in order, lowest to highest
    variable NGS_CTX_VAR_SUPPRESS_SAMPLING
    variable NGS_CTX_VAR_OP_STANDARD

    set bin_min ""
    set cur_source_val [CORE_GenVarName "source-value"]

    set bin_count 0
    foreach bin_max_pair $bin_definitions {

        set bin_max   [lindex $bin_max_pair 0]
        set func_pair [lindex $bin_max_pair 1]
        set the_test ""
        set func_expr ""

        if { $bin_min == "" } {
            set the_test "[ngs-stable-lt <src-obj> <src-attr> $bin_max]"
            set func_expr [lindex $func_pair 0]
        } elseif { $bin_max == "" } {
            set the_test "[ngs-stable-gt <src-obj> <src-attr> $bin_min]"
            set func_expr [lindex $func_pair 0]
        } else {
            set the_test "[ngs-gte-lt <src-obj> <src-attr> $bin_min $bin_max $cur_source_val]"

            set func_min [lindex $func_pair 0]
            set func_max [lindex $func_pair 1]
            set func_delta [expr $func_max - $func_min]
            set cur_bin_size [expr $bin_max - $bin_min]

            set func_expr "(+ $func_min (* $func_delta (/ (- $cur_source_val $bin_min) $cur_bin_size)))"
        }

        if { $operator_info == ""  } {
            set set_line "[ngs-create-attribute $var_id value $func_expr]"
        } else {
            # Elaborate the value to a tag first if we are using an operator
            set set_line "[ngs-create-attribute $var_id @val-to-set $func_expr]"
        }
        
        # Using i-support, this is straightforward. Just set the value. But this will
        #  elaborate the value to a tag when using operators
        sp "ctxvar*static-bins*propose*elaborate-value*$production_name_suffix*$bin_count
            $root_bind
            [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
            [ngs-bind $var_id src-obj src-attr]
            $the_test
        -->
            $set_line"

        # The prior bin's max becomes the next bin's min
        set bin_min $bin_max
        incr bin_count
    }

    set batch_category ""
    set batch_name ""
    if { [llength $operator_info] > 1 } {
        set batch_category [lindex $operator_info 0]
        set batch_name     [lindex $operator_info 1]
    }
    
    if { $operator_info != ""  } {      
        # For an operator, we need two steps because of the required retraction condition.
        # 1. Elaborate the value elsewhere (production above)
        # 2. Use an operator to set the value (following productions)

        if { $operator_info == $NGS_CTX_VAR_OP_STANDARD } {
            sp "ctxvar*static-bins*propose*set-value*$production_name_suffix
                $root_bind
                [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
                [ngs-bind $var_id @val-to-set]
                [ngs-neq  $var_id value <val-to-set>]
            -->
                [ngs-create-attribute-by-operator <s> $var_id value <val-to-set>]"
        } else {
            sp "ctxvar*static-bins*propose*set-value*$production_name_suffix
                $root_bind
                [ngs-bind-bop <s> <bo> $batch_category $batch_name]
                [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
                [ngs-bind $var_id @val-to-set]
                [ngs-neq  $var_id value <val-to-set>]
            -->
                [ngs-set-context-variable-by-batch-operator <bo> $var_id <val-to-set>]"
        }
    }

}

