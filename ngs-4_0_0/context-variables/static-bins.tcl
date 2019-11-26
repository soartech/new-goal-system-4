##!
# @file
#
# @created jacobcrossman 20190924


CORE_CreateMacroVar NGS_CTX_VAR_OP_STANDARD basic-operator


# Create a statically binned value
#
# Use this macro when you want to bin a numeric value (i.e. convert it
#  to a sybolic form) but you aren't worried about boundary effects (e.g the value
#   oscillating across the boundaries).  Declare your variable using 
#   NGS_DefineStaticBinValue.  For efficiency, the bin boundaries are 
#   created when declaring the variable.
#
# Statically binned variables are more efficient than dynamically binned values because they
#  create fewer WMEs and directly test the source value to set the bin value.  
#
# A binned value is a symbolic value derived from "binning" a numeric value. Bins are simply
#  ranges of values associated with a label. For example, a temperature might be considered
#  COLD (the label) if the thermometer reads 20 to 32 degrees Fahrenheit (the range).
#
# If youre system is oscillating around a bin boundary causing excessive changes to the
#  binned value, use a DynamicBinValue instead.
#
# Statically binned values map a numeric value range onto a symbolic value, where the
#  range is fixed at the time the variable is declared. Note that binned values
#  are not sampled values -- i.e. they change the form of a value from numeric to symbolic.
#  To specify a statically binned value you need to define the following:
#
# * A source object/attribute pair -- the numeric value that will be mapped
# * A set of bin definitions -- Use NGS_DefineStaticBinValue's last parameter to define your bins.
#           If you plan to reuse bins in many places, declare a macro variable with
#           your bin definitions making it easy to create several statically binned
#           variables that use the same bin definitions.
#
# pool_id - Variable bound to the identifier for the category pool into which to place the new
#             dynamically binned value. Bind to this pool using one of the following macros:
#             ngs-match-to-create-context-variable or ngs-match-goal-to-create-context-variable
# variable_name - Name of the context variable that should be constructed
# src_obj - Variable bound to the object containing the value to be sampled
# src_attribute - Name of the attribute to sample (do NOT bind to this in the LHS)
# variable_id - (Optional) If provided, a variable that is bound to the newly created statically binned value.
#                You can use this, for exmaple, to tag the variable.
#
proc ngs-create-static-bin-value { pool_id 
                                   variable_name 
                                   src_obj 
                                   src_attr                            
                                   { variable_id "" } } {

    CORE_GenVarIfEmpty variable_id "variable"

    set root_obj "[ngs-create-typed-object $pool_id $variable_name StaticBinnedValue $variable_id \
                    "name $variable_name src-obj $src_obj src-attr $src_attr"]"

    return $root_obj
}


# Define a Statically Binned Value
#
# This macro declares and defines the helper productions to support a specific statically binned
#  value. To actually construct the variable, us ngs-create-static-bin-value and its supporting
#  macro ngs-add-dyn-bin.
#
# An example of bin_definitions follows (the source value is water temperature in degrees celsius):
#   { { $ICE 0.0 } { $WATER 100.0 } { $STEAM {} } }
#
# Note how the final bin uses an empty list for its max value.
#
# NGS_DefineStaticBinValue pool_goal_or_path category_name variable_name bin_definitions { ngs set-ctx-var-values }
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the variable
# bin_definitions - A list of {bin-name bin-max} pairs.  This list should be in ascending order sorted by
#   bin-max values.  The last bin should have an empty max (i.e. {bin-name {}}).
# operator_info - (Optional) By default this is an empty string indicating that values should be binned using
#  elaboration productions (i-support).  If you prefer to bin using a standard operator pass in the value 
#  NGS_CTX_VAR_OP_STANDARD - the bin value will be set via an operator.  To use a batch operator to set the bin
#  value provide a pair (TCL list) consisting of a batch operator category and name.
#
proc NGS_DefineStaticBinValue { pool_goal_or_path category_name variable_name bin_definitions { use_operator "" } } {

    variable NGS_CTX_ALL_VARIABLES
    lappend NGS_CTX_ALL_VARIABLES [dict create pool $pool_goal_or_path category $category_name name $variable_name]

    set var_id  <variable>

    # Generate the root bindings shared by all productions in this macro
    set root_bind "[ngs-ctx-var-gen-root-bindings $pool_goal_or_path $category_name $variable_name $var_id]"

    # set the suffix for the template's names, removing any '.' charaters that appear (not allowed in production names)
    set production_name_suffix [ngs-ctx-var-gen-production-name-suffix $pool_goal_or_path $category_name $variable_name]

    if { [llength $use_operator] > 1 } {
        set batch_category [lindex $use_operator 0]
        set batch_name     [lindex $use_operator 1]
        set root_bind "$root_bind
                       [ngs-bind-bop <s> <bo> $batch_category $batch_name]"
    }

    ############### Setting values ####################################
    
    # This assumes that the maxes are presented in order, lowest to highest
    variable NGS_CTX_VAR_SUPPRESS_SAMPLING
    variable NGS_CTX_VAR_OP_STANDARD

    set bin_min ""
    set bin_max ""
    set bin_val ""
    
    set first_bin_val [lindex [lindex $bin_definitions 0] 1]
    set last_bin_val  [lindex [lindex $bin_definitions end-1] 1]
    set avg_bin_size [expr ($last_bin_val - $first_bin_val) / [llength $bin_definitions]]

    foreach bin_max_pair $bin_definitions {

        set cur_bin_size ""
        set bin_name [lindex $bin_max_pair 0]
        set bin_max  [lindex $bin_max_pair 1]
        set the_test ""

        if { $bin_min == "" } {
            set the_test "[ngs-stable-lt <src-obj> <src-attr> $bin_max]"
            set cur_bin_size "$avg_bin_size"
        } elseif { $bin_max == "" } {
            set the_test "[ngs-stable-gt <src-obj> <src-attr> $bin_min]"
            set cur_bin_size "$avg_bin_size"
        } else {
            set the_test "[ngs-stable-gte-lt <src-obj> <src-attr> $bin_min $bin_max]"
            set cur_bin_size [expr $bin_max - $bin_min]
       }

        set retract_cond ""
        if { $use_operator == ""  } {
            set set_line "[ngs-create-attribute $var_id value $bin_name]"
        } elseif { $use_operator == $NGS_CTX_VAR_OP_STANDARD } {
            set retract_cond "[ngs-neq $var_id value $bin_name]"
            set set_line  "[ngs-create-attribute-by-operator <s> $var_id value $bin_name]"
        } else {
            set retract_cond "[ngs-neq $var_id value $bin_name]"
            set set_line  "[ngs-set-context-variable-by-batch-operator <bo> $var_id $bin_name]"
        }
        
        sp "ctxvar*static-bins*elaborate*cur-bin-size*$production_name_suffix*$bin_name
            $root_bind
            [ngs-eq $var_id value $bin_name]
        -->
            [ngs-create-attribute $var_id cur-bin-size $cur_bin_size]"

        sp "ctxvar*static-bins*propose*set-value*$production_name_suffix*$bin_name
            $root_bind
            [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
            [ngs-bind $var_id src-obj src-attr]
            $the_test
            $retract_cond
        -->
            $set_line"

        # The prior bin's max becomes the next bin's min
        set bin_min $bin_max
    }
                        
}

