#
# There are three fundamental semantic memory actions
# 1. Retrieve a fact from memory
# 2. Store one or more facts in memory
# 3. Try to retrieve a fact, but store one if a fact can't be retrieved
#
# Retrieve or Store is a core function when developing a model at runtime as often
#  you will need to try to retrieve a fact that might not have been observed yet and
#  then will need to store that fact when you find it hasn't been recorded yet.
#
# NOTE: When usings semantic memory, the term LTI (for Long Term Identifier) is often used
#  to refer to (1) the id of facts stored in semantic memory and (2) as shorthand to refer
#  to a fact stored or retrieved from semantic memory.  Internally, LTIs are Soar ids (i.e.
#  object references in object oriented terms) that are permanently stored in the semantic
#  memory database.  They are invariant with respect to a given fact and uniquely identify
#  that fact.  Storing and/or changing attributes associated with an LTI will change
#  that fact in semantic memory permanently.  LTIs cannot be directly compared to normal
#  Soar working memory identifiers (the test will fail). Instead use one of the ngs-eq-lti
#  or ngs-neq-lti macros to compare identifiers that might be LTIs.  You can use the macros
#  ngs-is-lti and ngs-is-not-lti to test an identerfier and determine whether it is an LTI
#  (i.e. is stored in semantic memory).
#
# SETTINGS
#
# To use semantic memory, you'll need to turn it on and set it up.  Details on how to do this are in the
#  Soar Manual.  One way to do this is to create an smem-settings.soar file and load this.  I have had
#  problems with this approach though as some settings seem to not work correctly when loaded from the same
#  file.  This is especially true for activation.
#
# Settings to use a file for storage
# smem --set database file
# smem --set append on
# smem --set path "smem.sqlite"
#
# Need to enable smem
# smem --enable
#
# Activation oriented settings (see the help for smem and the wm commands)
# wm activation --set activation on
# smem --set activation-mode base-level
# smem --set base-decay 0.5
# smem --set base-update-policy stable
# smem --set base-incremental-threshes 10
# smem --set thresh 100
# smem --set base-inhibition on
# smem --set activate-on-query on
# smem --set spreading-edge-updating on
# smem --set spreading-wma-source on
# smem --set spreading-edge-update-factor 0.99
# smem --set spreading-loop-avoidance on
#
# I've had problems turning these on in this file
# smem --set spreading-limit 300
# smem --set spreading-depth-limit 10
# smem --set spreading-baseline 0.00001
# smem --set spreading-continue-probability 0.9
# 
# Here's one I've had a probelm with, seems to need to be turned on in another file that is loaded later
# smem --set spreading on

# All smem actions are done in substates using NGS function operators. The code to execute the queries is in retrieve-and-store.soar
#  They execute as all or nothing actions



#####################################################################################################################################

# TODO: I need to add a direct retrieval macro ...
# 


# Retrieve a fact by fact content (not a direct retrieval)
#
# Use this macro to retrieve a fact using content of that fact as the query conditions.  This macro supports
#  all of the Soar semantic memory condition types including negated, math, and prohibits.
#
# Almost all of the parameters to this macro are optional. This is because (1) you generally only need to specify
#  some of the query conditions (though you must have at least one valid query) and (2) you can add to the query
#  using other productions.  Because queries follow the one-to-many pattern (one operator but potentially many conditions) it is often
#  necessary to split up retrieval operator proposals into multiple steps. The first proposes the operator, the second tests for the
#  operator proposal using ngs-match-proposed-smem-* macros and then sets query conditions using one of the ngs-create-*-query macros below.
#
# ngs-smem-retrieve-by-substate-operator state_id return_description match_query_id* query_depth* math_query_id* negated_query_id* prohibits_set_id* goal_id* op_id* add_prefs*
#
# state_id - Variable bound to the state in which to propose an operator to do a retrieval
# return_description - A tuple of values defining the destination object (a variable bound to an id), a destination attribute (typically a string), 
#                        and an optional replacement behavior.  Example: { <obj> my-attr $NGS_REPLACE_IF_EXISTS }.  If the replacement behavior is
#                        not specified, the default of NGS_REPLACE_IF_EXISTS is used.  The retrieved fact will be bound as the value to the following
#                        WME: (<obj> ^my-attr <returned-fact-id>).
# match_query_id - (Optional) If provided, a variable bound to an identifier representing the main match part of the query.  Use this identifier in 
#                   a subsequent call to ngs-create-smem-match-query to set the match conditions for the query.
# query_depth - (Optional) If provided, a number indicating how deep the retrieval should be (i.e. how much of the fact's substructure should be retrieved).
#                The default depth is 1, which only retrieves the fact's direct attributes (i.e. not attributes of the attributes)
# math_query_id - (Optional) If provided, a variable bound to an identifier representing the mathematics test part of the query.  Use this identifier in 
#                   a subsequent call to ngs-create-smem-math-query to set the math conditions for the query.
# math_query_id - (Optional) If provided, a variable bound to an identifier representing the negated test (i.e. must NOT match) part of the query.  Use this 
#                   identifier in a subsequent call to ngs-create-smem-negated-query to set the negated conditions for the query.
# prohibits_set_id - (Optional) If provided, a variable bound to the set of identifiers (LTIs) that should not be retrieved, even if they match.  Use this
#                   identifier in a subsequent call to ngs-create-smem-prohibit to set the prohibited retrievals for the query.
# goal_id - (Optional) If provided, a variable bound to the goal that should be activated (in NGS terms) when the query substate is created.
# op_id - (Optional) If provided, an id bound to the operator this macro proposes.  It is good practice to use $NGS_OP_ID as the operator variable.
# add_prefs - (Optional) If provided, preferences other than '+' that should be applied to the proposed operator.  The default is '='
#
proc ngs-smem-retrieve-by-substate-operator { state_id return_description { match_query_id "" } { query_depth 1 } { math_query_id "" } { negated_query_id "" } { prohibits_set_id "" } { goal_id "" } { op_id "" } { add_prefs "=" } } {

   variable NGS_TYPE_STATE_RETURN_VALUE 
   variable NGS_REPLACE_IF_EXISTS
   variable NGS_OP_SMEM_ACTION
   variable NGS_OP_ID

   CORE_SetIfEmpty op_id $NGS_OP_ID 
   set smem_query_desc_id [CORE_GenVarName "query-description"]

   set rhs_ret "[ngs-create-substate-operator $state_id $NGS_OP_SMEM_ACTION $op_id $goal_id $add_prefs]
                [ngs-create-typed-object $op_id query-description FilteredSet $smem_query_desc_id "query-depth $query_depth"]"

   if { $match_query_id != "" } {
      set rhs_ret "$rhs_ret
                   [ngs-create-attribute $smem_query_desc_id match-query $match_query_id]"
   }
   if { $math_query_id != "" } {
      set rhs_ret "$rhs_ret
                   [ngs-create-attribute $smem_query_desc_id math-query $math_query_id]"
   }
   if { $negated_query_id != "" } {
      set rhs_ret "$rhs_ret
                   [ngs-create-attribute $smem_query_desc_id negated-query $negated_query_id]"
   }
   if { $prohibits_set_id != "" } {
      set rhs_ret "$rhs_ret
                   [ngs-create-attribute $smem_query_desc_id prohibits-set $prohibits_set_id]"
   }

   set dest_obj             [lindex $return_description 0]
   set dest_attr            [ngs-expand-tags [lindex $return_description 1]]
   set replacement_behavior [lindex $return_description 2]
   CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

   set ret_desc_id [CORE_GenVarName "return-description"]
   set ret_desc_info "destination-object $dest_obj destination-attribute $dest_attr replacement-behavior $replacement_behavior"
   set rhs_ret "$rhs_ret
                [ngs-create-typed-object $op_id return-description $NGS_TYPE_STATE_RETURN_VALUE $ret_desc_id $ret_desc_info]"

   return $rhs_ret
}

# Retrieve a fact by fact content (not a direct retrieval) and if the retrieval fails, store a provided fact instead.
#
# Use this macro to retrieve a fact using content of that fact as the query conditions.  This macro supports
#  all of the Soar semantic memory condition types including negated, math, and prohibits.
#
# Almost all of the parameters to this macro are optional. This is because (1) you generally only need to specify
#  some of the query conditions (though you must have at least one valid query) and (2) you can add to the query
#  using other productions.  Because queries follow the one-to-many pattern (one operator but potentially many conditions) it is often
#  necessary to split up retrieval operator proposals into multiple steps. The first proposes the operator, the second tests for the
#  operator proposal using ngs-match-proposed-smem-* macros and then sets query conditions using one of the ngs-create-*-query macros below.
#
# ngs-smem-retrieve-by-substate-operator state_id return_description match_query_id* query_depth* math_query_id* negated_query_id* prohibits_set_id* goal_id* op_id* add_prefs*
#
# state_id - Variable bound to the state in which to propose an operator to do a retrieval
# return_description - A tuple of values defining the destination object (a variable bound to an id), a destination attribute (typically a string), 
#                        and an optional replacement behavior.  Example: { <obj> my-attr $NGS_REPLACE_IF_EXISTS }.  If the replacement behavior is
#                        not specified, the default of NGS_REPLACE_IF_EXISTS is used.  The retrieved fact will be bound as the value to the following
#                        WME: (<obj> ^my-attr <returned-fact-id>).
# match_query_id - (Optional) If provided, a variable bound to an identifier representing the main match part of the query.  Use this identifier in 
#                   a subsequent call to ngs-create-smem-match-query to set the match conditions for the query.
# query_depth - (Optional) If provided, a number indicating how deep the retrieval should be (i.e. how much of the fact's substructure should be retrieved).
#                The default depth is 1, which only retrieves the fact's direct attributes (i.e. not attributes of the attributes)
# math_query_id - (Optional) If provided, a variable bound to an identifier representing the mathematics test part of the query.  Use this identifier in 
#                   a subsequent call to ngs-create-smem-math-query to set the math conditions for the query.
# math_query_id - (Optional) If provided, a variable bound to an identifier representing the negated test (i.e. must NOT match) part of the query.  Use this 
#                   identifier in a subsequent call to ngs-create-smem-negated-query to set the negated conditions for the query.
# prohibits_set_id - (Optional) If provided, a variable bound to the set of identifiers (LTIs) that should not be retrieved, even if they match.  Use this
#                   identifier in a subsequent call to ngs-create-smem-prohibit to set the prohibited retrievals for the query.
# goal_id - (Optional) If provided, a variable bound to the goal that should be activated (in NGS terms) when the query substate is created.
# op_id - (Optional) If provided, an id bound to the operator this macro proposes.  It is good practice to use $NGS_OP_ID as the operator variable.
# add_prefs - (Optional) If provided, preferences other than '+' that should be applied to the proposed operator.  The default is '='
#
proc ngs-smem-retrieve-or-store-by-substate-operator { state_id return_description store_id { match_query_id "" } { query_depth 1 } { math_query_id "" } { negated_query_id "" } { prohibits_id "" } { goal_id "" } { op_id "" } { add_prefs "=" } } {

   variable NGS_OP_ID

   CORE_SetIfEmpty op_id $NGS_OP_ID
   set store_set_id [CORE_GenVarName "store-set"]

   return "[ngs-smem-retrieve-by-substate-operator $state_id $return_description $match_query_id $query_depth $math_query_id \
                                                   $negated_query_id $prohibits_id $goal_id $op_id $add_prefs]
           [ngs-create-typed-object $op_id store-set Set $store_set_id "item $store_id"]"
}

# Will return a flag, not an LTI
proc ngs-smem-store-by-substate-operator { state_id  return_description { store_id "" }  { store_set_id "" }  { goal_id "" } { op_id "" } { add_prefs "=" } } {

   variable NGS_TYPE_STATE_RETURN_VALUE 
   variable NGS_REPLACE_IF_EXISTS
   variable NGS_OP_SMEM_ACTION
   variable NGS_OP_ID

   CORE_SetIfEmpty op_id $NGS_OP_ID 
   CORE_GenVarIfEmpty store_set_id "store-set"

   set rhs_ret "[ngs-create-substate-operator $state_id $NGS_OP_SMEM_ACTION $op_id $goal_id $add_prefs]
                [ngs-create-typed-object $op_id store-set Set $store_set_id]"

   if { $store_id != "" } {
      set rhs_ret "$rhs_ret
                   [ngs-create-attribute $store_set_id item $store_id]"
   }

   set dest_obj             [lindex $return_description 0]
   set dest_attr            [lindex $return_description 1]
   set replacement_behavior [lindex $return_description 2]
   CORE_SetIfEmpty replacement_behavior $NGS_REPLACE_IF_EXISTS

   set ret_desc_id [CORE_GenVarName "return-description"]
   set ret_desc_info "destination-object $dest_obj destination-attribute $dest_attr replacement-behavior $replacement_behavior"
   set rhs_ret "$rhs_ret
                  [ngs-create-typed-object $op_id return-description $NGS_TYPE_STATE_RETURN_VALUE $ret_desc_id $ret_desc_info]"

   return $rhs_ret
}

proc ngs-add-store-item { store_set_id store_id } {
   return [ngs-create-attribute $store_set_id item $store_id]
}

proc ngs-create-smem-match-query { match_query_id attr_val_pairs } {
   set rhs_ret ""

   # Put all of the elements in the query
   dict for { attr val } $attr_val_pairs {
      set rhs_ret "$rhs_ret
                   ($match_query_id ^$attr $val)"
   }

   return $rhs_ret
}

proc ngs-create-smem-negated-query { negated_query_id attr_val_pairs } {
   set rhs_ret ""

   # Put all of the elements in the query
   dict for { attr val } $attr_val_pairs {
      set rhs_ret "$rhs_ret
                   ($negated_query_id ^$attr $val)"
   }   

   return $rhs_ret
}

proc ngs-create-smem-math-query { math_query_id attr_cond_val_triples } {
   set mappings { ">" "greater" "<" "less" ">=" "greater-or-equal" "<=" "less-or-equal" "max" "max" "min" "min"}
   set rhs_ret ""

   # Put all of the elements in the query
   for triple $attr_cond_val_triples {
      set attr      [lindex $triple 0]
      set math_test [dict get $mappings [lindex $triple 1]]
      set val       [lindex $triple 2]

      set rhs_ret "$rhs_ret
                   ($math_query_id ^$attr.$math_test $val)"
   }   

   return $rhs_ret
}

proc ngs-create-smem-prohibit { prohibits_set_id prohibited_lti } {
   # This is a little awkward, but I don't want to carry around the variable
   return "($prohibits_set_id ^prohibit $prohibited_li)"   
}