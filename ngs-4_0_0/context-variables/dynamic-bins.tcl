##!
# @file
#
# @created jacobcrossman 20161226

# Create a dynamically binned value
#
# # Use this macro when you want to bin a numeric value (i.e. convert it
#  to a sybolic form). Be sure to define your binned value using NGS_DefineDynamicBinValue
#
# NOTE: Dynamically Binned Values can also be used to statically bin values (see discussion of the 
#        "delta" parameter below.
#
# A binned value is a symbolic value derived from "binning" a numeric value. Bins are simply
#  ranges of values associated with a label. For example, a temperature might be considered
#  COLD (the label) if the thermometer reads 20 to 32 degrees Fahrenheit (the range).
#
# A "dynamically binned" value is one where the range can change when the value changes. For example,
#  you might normally consider it COLD when it is between 20 and 32 degrees Fahrenheit, but after 
#  the temperature actually changes to COLD, you get used to it and start considering COLD to be
#  anything between 0 and 32. Thus, the state of the variable (the temperature) changes the 
#  the bin range. If a binned value is being used for real-time control, it almost certainly
#  should be dynamically binned or the behavior will oscillate about the boundary conditions.
#
# Dynamically binned values map a numeric value range onto a symbolic value, where the
#  range is allowed to change based on the current symbolic value. Note that binned values
#  are not sampled values -- i.e. they change the form of a value from numeric to symbolic.
#  To specify a dynamically binned value you need to define the following:
#
# * A source object/attribute pair -- the numeric value that will be mapped
# * A set of bin definitions -- Use [ngs-add-dyn-bin ...] to define your bins in the 
#           same production RHS that creates the DynamicallyBinnedValue
# * Optionally, one or more "expansion factors," called "deltas." These factors define
#           how the bin ranges will change when a given bin is mapped (or "active"). You
#           can specify (a) no delta value in which case the bins are STATIC (their
#           bounds do not change), (b) global delta values (using this macro) in which
#           case all bins expand by the same amount when mapped, and (c) bin-specific
#           delta values (using ngs-add-dyn-bin) in which case the given bin expands
#           by that bin-specific value when it is mapped. The bin-specific delta values
#           override the global delta values (if both are specified). Furthermore, 
#           if no global delta is provided, individual bins may use bin-specific 
#           delta values or none (making them static).
#
# Just like with stable values, there are three forms for the delta values:
# 
# Form 1: Single  (specify a single value for the delta parameter). In this case
#           the bin range will expand by the given amount in both directions when it is mapped.
#         E.g. range --> 5, will expand a bin by 5 making its (min, max) become (min-5,max+5)
#                            when the bin is mapped (i.e. active)
#
# Form 2: Min/Max (specify a list with min and max value for the delta parameter). In this
#           case the bin range will expand differently in the minimum and maximum directions
#           using the two provided values.
#         E.g. range --> {1 2}, will reduce a bin's minimum by 1 and increase its maximum by 2
#                            making the range (min-1,max+2) when the bin is mapped (i.e. active)
#
# Form 3: Single delta, dynamic source (specify a list with the delta source object and attribute)
#           In this case the bin range will expand by the amount given by a value linked to
#           given object and attribute. This expansion is uniform in the minimum and maximum
#           direction.
#         E.g. range --> {<my-state> velocity-bin}, will expand a bin by the amount stored in
#                        the working memory location (<my-state> velocity-bin <delta>).
#                        Thus the bin bounds are (min-<delta>,max+<delta>) when the bin is 
#                        mapped (i.e. active)
#
# pool_id - Variable bound to the identifier for the category pool into which to place the new
#             dynamically binned value. Bind to this pool using one of the following macros:
#             ngs-match-to-create-context-variable or ngs-match-goal-to-create-context-variable
# variable_name - Name of the context variable that should be constructed
# src_obj - Variable bound to the object containing the value to be sampled
# src_attribute - Name of the attribute to sample (do NOT bind to this in the LHS)
# delta - (Optional) If specified, this is the default expansion factor for all of the bins.
#          If any bin has its own expansion factor, the bin's expansion factor will overide
#          the defaults. Delta values take one of the 3 forms desribed above. I.e. either a 
#          constant/variable (Form 1), a list with a min/max (Form 2), or a list with a delta 
#          source obj/attr (Form 3). 
# delta_type - (Optional). The type of delta being used. Either NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE (default),
#                or NGS_CTX_VAR_DELTA_TYPE_PERCENT if the delta should be interpreted as a percentage
#                of the maximum value.
# variable_id - (Optional) If provided, a variable that is bound to the newly created stable value.
#                You can use this, for exmaple, to tag the variable.
#
proc ngs-create-dyn-bin-value { pool_id 
                                variable_name 
                                src_obj 
                                src_attr                            
                                bin_set_id 
                                { delta "" }
                                { delta_type "" }
                                { variable_id "" } } {

    CORE_GenVarIfEmpty variable_id "variable"

    set root_obj "[ngs-create-typed-object $pool_id $variable_name DynamicBinnedValue $variable_id \
                    "name $variable_name src-obj $src_obj src-attr $src_attr"]
                  [ngs-create-typed-object $variable_id bins Set $bin_set_id]"

    if { $delta != "" } {

        variable NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE
        CORE_SetIfEmpty delta_type $NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE ;# could also be NGS_CTX_VAR_DELTA_TYPE_PERCENT
        
        return  "$root_obj
                 [ngs-ctx-var-create-deltas $delta $variable_id]
                 [ngs-create-attribute $variable_id delta-type $delta_type]"
    }

    return $root_obj
}

# Add a bin to a dynamic binned value
#
# Use this method on the RHS of productions that create Dynamically Binned Values
#  using ngs-create-dyn-bin-value. 
#
# A bin requires the following items:
#  * a name -- this will become the _value_ of the binned value when the bin is selected
#  * a maximum value -- this defines the upper bound of the bin (before any expansion)
#  * the name of the bin previous to this one
#  * (Optional) a bin-specific delta value (see discussion of delta values in ngs-create-dyn-bin-value)                                                   
# 
# [ngs-add-dyn-bin bin_set_id bin_name max_val prev_bin (delta)]
#
# bin_set_id - Variable bound to the bin set of the parent dynamically binned value. This variable
#               should be the one bound to the bin_set_id parameter of ngs-create-dyn-bin-value.
# bin_name - Name of the bin. Names do not necessarily have to be unique, but if they aren't all
#               bins with a given name are considered active when one of them is active.
# max_val - Max bound of the bin. This can be a constant, a variable, or a { source attribute } pair.
#             This last form will pull the maximum value from the given location in Soar's working
#             memory, allowing you to change the maximum value over time.
# prev_bin - Name of the bin previous to this one. 
# delta - (Optional) If provided, specifies the expansion factor for this specific bin. The bin's delta
#            overrides the parent variable's delta if both are present. See ngs-create-dyn-bin-value for
#            a detailed discussion on the forms of delta values.
#
proc ngs-add-dyn-bin { bin_set_id 
                       bin_name 
                       max_val 
                       prev_bin
                       { delta "" } } {

    set new_bin_id [CORE_GenVarName bin]
 
    set lhs_ret "[ngs-create-typed-object $bin_set_id bin DynamicBin $new_bin_id "name $bin_name"]"

    if { $prev_bin != "" } {
        set lhs_ret "$lhs_ret
                     [ngs-create-attribute $new_bin_id prev-bin $prev_bin]"
    }

    # Handle the different forms of max values
    if { $max_val != "" } {
    
        if { [llength $max_val] == 1 } {
            if { $max_val != "" } {
                # We have a simple constant value (or variable)
                set lhs_ret "$lhs_ret
                             [ngs-create-attribute $new_bin_id max-val $max_val]"
            }
        } else { 
            # We have a source and attribute
            set max_src_obj  [lindex $max_val 0]
            set max_src_attr [lindex $max_val 1]
    
            set lhs_ret "$lhs_ret
                         [ngs-create-attribute $new_bin_id max-src-obj $max_src_obj]
                         [ngs-create-attribute $new_bin_id max-src-attr $max_src_attr]"
        }
    }

    # This needs to be a shared function, it's repeated in three places
    variable NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA
    if { $delta != "" } {

        # Tag the structure so we know it has its own delta value and shouldn't use the
        #  global delta value
        set lhs_ret "$lhs_ret
                     [ngs-ctx-var-create-deltas $delta $new_bin_id]
                     [ngs-tag $new_bin_id $NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA]"
    } 

    return $lhs_ret

}

# Define a Dynamically Binned Value
#
# This macro declares and defines the helper productions to support a specific dynamically binned
#  value. To actually construct the variable, us ngs-create-dyn-bin-value and its supporting
#  macro ngs-add-dyn-bin.
#
# NGS_DefineDynamicBinValue pool_goal_or_path category_name variable_name { ngs set-ctx-var-values }
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the variable
# batch_op_cat_and_name - If provided a pair (TCL list) consisting of a batch operator category and name to use when
#  setting this context variable's value.  If not provides, the value will be set by a stand-alone operator.
#
proc NGS_DefineDynamicBinValue { pool_goal_or_path category_name variable_name { batch_op_cat_and_name "" } } {

    variable NGS_CTX_ALL_VARIABLES
    lappend NGS_CTX_ALL_VARIABLES [dict create pool $pool_goal_or_path category $category_name name $variable_name]

    set var_id  <variable>
    set bin_set_id <bins>
    set bin_attr "bin"
    set bin_id  <bin>

    set var_id  <variable>

    # Generate the root bindings shared by all productions in this macro
    set root_bind "[ngs-ctx-var-gen-root-bindings $pool_goal_or_path $category_name $variable_name $var_id]
                   [ngs-bind $var_id bins:$bin_set_id.$bin_attr:$bin_id]"

    # set the suffix for the template's names, removing any '.' charaters that appear (not allowed in production names)
    set production_name_suffix [ngs-ctx-var-gen-production-name-suffix $pool_goal_or_path $category_name $variable_name]

    variable NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE
    variable NGS_CTX_VAR_DELTA_TYPE_PERCENT

    # Elaborate max-val from src
    sp "ctxvar*dyn-bins*elaborate*max-val*from-source*$production_name_suffix
        $root_bind
        [ngs-bind $bin_id max-src-obj max-src-attr]
        (<max-src-obj> ^<max-src-attr> <max-src-val>)
    -->
        [ngs-create-attribute $bin_id max-val <max-src-val>]"

    #############################################################################################
    # min-max delta productions (all different ways it can be set)  

    variable NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA
    variable NGS_TAG_DYN_BINS_IS_STATIC

    # Elaborate min-delta and max-delta from single delta at variable level
    sp "ctxvar*dyn-bins*elaborate*min-max-delta*from-parent-delta*$production_name_suffix
        $root_bind
        [ngs-is-not-tagged $bin_id $NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA]
        [ngs-bind $var_id delta]
    -->
        [ngs-create-attribute $bin_id min-delta <delta>]
        [ngs-create-attribute $bin_id max-delta <delta>]"

    # Elaborate min-delta and max-delta from parent
    sp "ctxvar*dyn-bins*elaborate*min-max-delta*from-parent-min-max*$production_name_suffix
        $root_bind
        [ngs-is-not-tagged $bin_id $NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA]
        [ngs-bind $var_id min-delta max-delta]
    -->
        [ngs-create-attribute $bin_id min-delta <min-delta>]
        [ngs-create-attribute $bin_id max-delta <max-delta>]"

    # Elaborate min-delta and max-delta from source delta
    sp "ctxvar*dyn-bins*elaborate*min-max-delta*from-parent-src-delta*$production_name_suffix
        $root_bind
        [ngs-is-not-tagged $bin_id $NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA]
        [ngs-bind $var_id delta-src-obj delta-src-attr]
        (<delta-src-obj> ^<delta-src-attr> <delta>)
    -->
        [ngs-create-attribute $bin_id min-delta <delta>]
        [ngs-create-attribute $bin_id max-delta <delta>]"

    # Elaborate min-delta and max-delta from single delta
    sp "ctxvar*dyn-bins*elaborate*min-max-delta*from-single-delta*$production_name_suffix
        $root_bind
        [ngs-is-tagged $bin_id $NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA]
        [ngs-bind $bin_id delta]
    -->
        [ngs-create-attribute $bin_id min-delta <delta>]
        [ngs-create-attribute $bin_id max-delta <delta>]"

    # Elaborate min-delta and max-delta from source delta
    sp "ctxvar*dyn-bins*elaborate*min-max-delta*from-src-delta*$production_name_suffix
        $root_bind
        [ngs-is-tagged $bin_id $NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA]
        [ngs-bind $bin_id delta-src-obj delta-src-attr]
        (<delta-src-obj> ^<delta-src-attr> <delta>)
    -->
        [ngs-create-attribute $bin_id min-delta <delta>]
        [ngs-create-attribute $bin_id max-delta <delta>]"

    sp "ctxvar*dyn-bins*elaborate*min-max-delta*no-delta-values*$production_name_suffix
        $root_bind
        [ngs-nex $var_id delta]
        [ngs-nex $var_id delta-min]
        [ngs-nex $var_id delta-src-obj]
        [ngs-nex $bin_id delta]
        [ngs-nex $bin_id delta-min]
        [ngs-nex $bin_id delta-src-obj]
    -->
        [ngs-tag $bin_id $NGS_TAG_DYN_BINS_IS_STATIC]"

    ####################################

    variable NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE
    variable NGS_CTX_VAR_DELTA_TYPE_PERCENT

    # Elaborate current-minimum
    #  OR Not selected now, my prev's current-maximum
    #     Selected now, my prev's max-val - min-delta
    sp "ctxvar*dyn-bins*elaborate*cur-min*$production_name_suffix
        $root_bind
        [ngs-bind $bin_id prev-bin:<prev-name>]
        [ngs-bind $bin_set_id $bin_attr:<prev>.name:<prev-name>]
        [ngs-bind <prev> cur-max:<prev-max>]
    -->
        [ngs-create-attribute $bin_id cur-min <prev-max>]"

    # The case where no delta is supplied (now it's not dynamic, it's just a static bin)
    sp "ctxvar*dyn-bins*elaborate*cur-max*no-deltas*$production_name_suffix
        $root_bind
        [ngs-is-tagged $bin_id $NGS_TAG_DYN_BINS_IS_STATIC]
        [ngs-bind $bin_id max-val]
    -->
        [ngs-create-attribute $bin_id cur-max <max-val>]"         
         
    # Easy case, when this bin is currently selected
    sp "ctxvar*dyn-bins*elaborate*cur-max*this-bin-selected*$production_name_suffix*absolute
        $root_bind
        [ngs-is-not-tagged $bin_id $NGS_TAG_DYN_BINS_IS_STATIC]
        [ngs-eq $var_id delta-type $NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE]
        [ngs-bind $bin_id name max-val max-delta]
        [ngs-eq $var_id value <name>]
    -->
        [ngs-create-attribute $bin_id cur-max "(+ <max-val> <max-delta>)"]"

    # Case when neither this bin, nor the next bin is selected. Binds to the next bin as well
    #  by checking to see if it is the previous bin of that bin
    sp "ctxvar*dyn-bins*elaborate*cur-max*this-and-next-not-selected*$production_name_suffix*any-case
        $root_bind
        [ngs-is-not-tagged $bin_id $NGS_TAG_DYN_BINS_IS_STATIC]
        [ngs-bind $bin_id name max-val]
        
        [ngs-bind $bin_set_id $bin_attr:<next>.prev-bin:<name>]
        [ngs-bind <next> name:<next-name>]
        
        [ngs-neq  $var_id value <name>]
        [ngs-neq  $var_id value <next-name>]
    -->
        [ngs-create-attribute $bin_id cur-max <max-val>]"

    # Case when the next bin is selected (need to use it's min-delta)
    sp "ctxvar*dyn-bins*elaborate*cur-max*next-bin-selected*$production_name_suffix*absolute
        $root_bind
        [ngs-is-not-tagged $bin_id $NGS_TAG_DYN_BINS_IS_STATIC]
        [ngs-eq $var_id delta-type $NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE]
        [ngs-bind $bin_id name max-val]
        
        [ngs-bind $bin_set_id $bin_attr:<next>.prev-bin:<name>]
        [ngs-bind <next> name:<next-name> min-delta:<next-min-delta>]
        
        [ngs-eq  $var_id value <next-name>]
    -->
        [ngs-create-attribute $bin_id cur-max "(- <max-val> <next-min-delta>)"]"
        
    # Easy case, when this bin is currently selected
    sp "ctxvar*dyn-bins*elaborate*cur-max*this-bin-selected*$production_name_suffix*percent
        $root_bind
        [ngs-is-not-tagged $bin_id $NGS_TAG_DYN_BINS_IS_STATIC]
        [ngs-eq $var_id delta-type $NGS_CTX_VAR_DELTA_TYPE_PERCENT]
        [ngs-bind $bin_id name max-val max-delta]
        [ngs-eq $var_id value <name>]
    -->
        [ngs-create-attribute $bin_id cur-max "(+ <max-val> (* <max-delta> <max-val>))"]"

    # Case when the next bin is selected (need to use it's min-delta)
    sp "ctxvar*dyn-bins*elaborate*cur-max*next-bin-selected*$production_name_suffix*percent
        $root_bind
        [ngs-is-not-tagged $bin_id $NGS_TAG_DYN_BINS_IS_STATIC]
        [ngs-eq $var_id delta-type $NGS_CTX_VAR_DELTA_TYPE_PERCENT]
        [ngs-bind $bin_id name max-val]
        
        [ngs-bind $bin_set_id $bin_attr:<next>.prev-bin:<name>]
        [ngs-bind <next> name:<next-name> min-delta:<next-min-delta>]
        
        [ngs-eq  $var_id value <next-name>]
    -->
        [ngs-create-attribute $bin_id cur-max "(- <max-val> (* <next-min-delta> <max-val>))"]"

    if { $batch_op_cat_and_name != "" } {

        set batch_category [lindex $batch_op_cat_and_name 0]
        set batch_name     [lindex $batch_op_cat_and_name 1]
        set root_bind "$root_bind
                       [ngs-bind-bop <s> <bo> $batch_category $batch_name]"

        set set_line  "[ngs-set-context-variable-by-batch-operator <bo> $var_id <name>]"
    } else {
        set set_line  "[ngs-create-attribute-by-operator <s> $var_id value <name>]"
    }

    ############### PROPOSALS ####################################
    # When in bounds, propose operator to change the value
    variable NGS_CTX_VAR_SUPPRESS_SAMPLING
    sp "ctxvar*dyn-bins*propose*set-value*$production_name_suffix*min-and-max
        $root_bind
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-bind $bin_id name cur-min cur-max]
        [ngs-bind $var_id src-obj src-attr]
        [ngs-neq  $var_id value <name>]
        [ngs-stable-gte-lt <src-obj> <src-attr> <cur-min> <cur-max>]
        [ngs-ex <src-obj> <src-attr>]
    -->
        $set_line"

    sp "ctxvar*dyn-bins*propose*set-value*$production_name_suffix*min-only
        $root_bind
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-bind $bin_id name cur-min]
        [ngs-nex $bin_id cur-max]
        [ngs-bind $var_id src-obj src-attr]
        [ngs-neq  $var_id value <name>]
        [ngs-stable-gte <src-obj> <src-attr> <cur-min>]
        [ngs-ex <src-obj> <src-attr>]
     -->
        $set_line"

    sp "ctxvar*dyn-bins*propose*set-value*$production_name_suffix*max-only
        $root_bind
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-bind $bin_id name cur-max]
        [ngs-nex $bin_id cur-min]
        [ngs-bind $var_id src-obj src-attr]
        [ngs-neq  $var_id value <name>]
        [ngs-stable-lt <src-obj> <src-attr> <cur-max>]
        [ngs-ex <src-obj> <src-attr>]
    -->
        $set_line"
                        
}

