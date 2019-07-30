##!
# @file
#
# @created jacobcrossman 20161223

# Creates a stable value context variable 
#
# A stable value is a value is a copy of a numeric value that updates only
#  when the source numeric value changes more than a specified amount.
#
# You must define your stable value using NGS_DefineStableValue for the
#  stable value to work.
#
# A stable value is instantiated with a source object and attribute. Do NOT bind to
#  the source attribute on the LHS of the production that creates a stable value. If
#  you do, the stable value will "blink" every time the source value changes, which 
#  defeats the point of the stable value. Just bind to the source object and pass in
#  the name of the attribute.
#
# Three forms are allowed:
#
# Form 1: Single delta (specify a single value for the delta parameter). In this case
#           the stable value will change when the source value changes by more than this
#           delta in either direction (lower or higher).
#         E.g. [ngs-create-stable-value <my-pool> my-variable <src> attr-name 1]
#
# Form 2: Min/Max (specify a list with min and max value for the delta parameter). In this
#           case the stable value will change when the source value is more than min lower
#           than the current stable value or is more than max higher than the current stable
#           value.
#         E.g. [ngs-create-stable-value <my-pool> my-variable <src> attr-name {1 2}]
#
# Form 3: Single delta, dynamic source (specify a list with the delta source object and attribute)
#           In this case the stable value will change when the source value changes by more than the
#           amount bound to the deltal source object/attribute. Use this when the delta changes
#           dynamimcally throughout the model's execution time.
#         E.g. [ngs-create-stable-value <my-pool> my-variable <src> attr-name {<delta-src> delta-value}]
#
# All delta values (in all forms) can be absolute values or percentages. If they are percentages
#  the delta values will be computed by multiplying the percentage values by the current
#  stable value.
#
# See the stable-value tests in the ngs test directory
#
# [ngs-create-stable-value pool_id variable_name src_obj src_attr delta (delta_type) (variable_id)]
#
# pool_id - Variable bound to the identifier for the category pool into which to place the new
#             stable value. Bind to this pool using one of the following macros:
#             ngs-match-to-create-context-variable or ngs-match-goal-to-create-context-variable
# variable_name - Name of the context variable that should be constructed
# src_obj - Variable bound to the object containing the value to be sampled
# src_attribute - Name of the attribute to sample (do NOT bind to this in the LHS)
# delta - Either a constant/variable (Form 1), a list with a min/max (Form 2), or
#          a list with a delta source obj/attr (Form 3). All forms specify the bounds
#          on the stable-value, indicating when it will be resampled from the source value.
# delta_type - (Optional). The type of delta being used. Either NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE (default),
#                or NGS_CTX_VAR_DELTA_TYPE_PERCENT.
# variable_id - (Optional) If provided, a variable that is bound to the newly created stable value.
#                You can use this, for exmaple, to tag the variable.
#
proc ngs-create-stable-value { pool_id variable_name src_obj src_attr delta { delta_type "" } { variable_id "" } } {

    CORE_GenVarIfEmpty variable_id "variable"

    variable NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE
    CORE_SetIfEmpty delta_type $NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE ;# could also be NGS_CTX_VAR_DELTA_TYPE_PERCENT

    set root_obj "[ngs-create-typed-object $pool_id $variable_name StableValue $variable_id \
        "name $variable_name src-obj $src_obj src-attr $src_attr delta-type $delta_type"]"
    
    return "$root_obj
            [ngs-ctx-var-create-deltas $delta $variable_id]"
}

# Declare and define a stable value
#
# Use this macro to declare and define the productions for a stable value.
#
# This macro instantiates productions that elaborate the min and max bounds on a stable
#  value and that execute the sampling behavior whenever the source value changes
#  beyond the min and max bounds
#
# You must call this macro for every stable value you wish to use in your program or
#  that value will not properly update.
#
# NGS_DefineStableValue pool_goal_or_path category_name variable_name
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the variable
# batch_op_cat_and_name - If provided a pair (TCL list) consisting of a batch operator category and name to use when
#  setting this context variable's value.  If not provides, the value will be set by a stand-alone operator.
#
proc NGS_DefineStableValue { pool_goal_or_path category_name variable_name { batch_op_cat_and_name "" } } {

    variable NGS_CTX_ALL_VARIABLES
    lappend NGS_CTX_ALL_VARIABLES [dict create pool $pool_goal_or_path category $category_name name $variable_name]

    set var_id  <variable>

    # Generate the root bindings shared by all productions in this macro
    set root_bind [ngs-ctx-var-gen-root-bindings $pool_goal_or_path $category_name $variable_name $var_id]

    # set the suffix for the template's names, removing any '.' charaters that appear (not allowed in production names)
    set production_name_suffix [ngs-ctx-var-gen-production-name-suffix $pool_goal_or_path $category_name $variable_name]

    variable NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE
    variable NGS_CTX_VAR_DELTA_TYPE_PERCENT

    #################################################################################################################
    # Productions that maintain the min and max bounds under different conditions

    # Production for when only a single delta is provided
    sp "ctxvar*elaborate*stable-value*min-max-bounds*$production_name_suffix*absolute*delta-only
        $root_bind
        [ngs-bind $var_id value delta delta-type:$NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE]
    -->
        [ngs-create-attribute $var_id min-bound "(- <value> <delta>)"]
        [ngs-create-attribute $var_id max-bound "(+ <value> <delta>)"]"

    # Production for when a separate min and max delta are set
    sp "ctxvar*elaborate*stable-value*min-max-bounds*$production_name_suffix*absolute*min-max-delta
        $root_bind
        [ngs-nex $var_id delta]
        [ngs-bind $var_id value min-delta max-delta delta-type:$NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE]
    -->
        [ngs-create-attribute $var_id min-bound "(- <value> <min-delta>)"]
        [ngs-create-attribute $var_id max-bound "(+ <value> <max-delta>)"]"

    sp "ctxvar*elaborate*stable-value*min-max-bounds*$production_name_suffix*absolute*dynamic-delta
        $root_bind
        [ngs-nex $var_id delta]
        [ngs-nex $var_id min-delta]
        [ngs-bind $var_id value delta-src-obj delta-src-attr delta-type:$NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE]
        (<delta-src-obj> ^<delta-src-attr> <delta-src-val>)
    -->
        [ngs-create-attribute $var_id min-bound "(- <value> <delta-src-val>)"]
        [ngs-create-attribute $var_id max-bound "(+ <value> <delta-src-val>)"]"

    # Production for when only a single delta is provided
    sp "ctxvar*elaborate*stable-value*min-max-bounds*$production_name_suffix*percent*delta-only
        $root_bind
        [ngs-bind $var_id value delta delta-type:$NGS_CTX_VAR_DELTA_TYPE_PERCENT]
    -->
        [ngs-create-attribute $var_id min-bound "(- <value> (* <delta> <value>))"]
        [ngs-create-attribute $var_id max-bound "(+ <value> (* <delta> <value>))"]"

    # Production for when a separate min and max delta are set
    sp "ctxvar*elaborate*stable-value*min-max-bounds*$production_name_suffix*percent*min-max-delta
        $root_bind
        [ngs-nex $var_id delta]
        [ngs-bind $var_id value min-delta max-delta delta-type:$NGS_CTX_VAR_DELTA_TYPE_PERCENT]
    -->
        [ngs-create-attribute $var_id min-bound "(- <value> (* <min-delta> <value>))"]
        [ngs-create-attribute $var_id max-bound "(+ <value> (* <max-delta> <value>))"]"

    sp "ctxvar*elaborate*stable-value*min-max-bounds*$production_name_suffix*percent*dynamic-delta
        $root_bind
        [ngs-nex $var_id delta]
        [ngs-nex $var_id min-delta]
        [ngs-bind $var_id value delta-src-obj delta-src-attr delta-type:$NGS_CTX_VAR_DELTA_TYPE_PERCENT]
        (<delta-src-obj> ^<delta-src-attr> <delta-src-val>)
    -->
        [ngs-create-attribute $var_id min-bound "(- <value> (* <delta-src-val> <value>))"]
        [ngs-create-attribute $var_id max-bound "(+ <value> (* <delta-src-val> <value>))"]"

    #################################################################################################################
    # Propose to change the stable-value when it goes out of bounds. This will trigger
    # elaboration of new bounds

    if { $batch_op_cat_and_name != "" } {

        set batch_category [lindex $batch_op_cat_and_name 0]
        set batch_name     [lindex $batch_op_cat_and_name 1]
        set root_bind "$root_bind
                       [ngs-bind-bop <s> <bo> $batch_category $batch_name]"

        set set_line  "[ngs-set-context-variable-by-batch-operator <bo> $var_id <src-val>]"
    } else {
        set set_line  "[ngs-create-attribute-by-operator <s> $var_id value <src-val>]"
    }

    variable NGS_CTX_VAR_SUPPRESS_SAMPLING
    sp "ctxvar*propose*stable-value*init-value*$production_name_suffix
        $root_bind
        [ngs-nex $var_id value]
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-ctx-var-source-val $var_id <src-val>]
     -->
        $set_line"

    sp "ctxvar*propose*stable-value*update-value*$production_name_suffix
        $root_bind
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-bind $var_id min-bound max-bound src-obj src-attr]
        [ngs-or [ngs-nex $var_id value] \
                [ngs-lt <src-obj> <src-attr> <min-bound>] \
                [ngs-gt <src-obj> <src-attr> <max-bound>]]
        [ngs-bind <src-obj> <src-attr>:<src-val>]
     -->
        $set_line"
}
