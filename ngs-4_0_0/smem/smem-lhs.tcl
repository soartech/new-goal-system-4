

proc ngs-match-proposed-smem-retrieve-or-store-operator { state_id smem_query_desc_id { smem_store_id "" } { goal_id "" } { op_id "" } } {
   
   variable NGS_OP_SMEM_ACTION
   variable NGS_OP_ID

   CORE_SetIfEmpty op_id $NGS_OP_ID 

   set lhs_ret "[ngs-match-proposed-substate-operator $state_id $op_id $NGS_OP_SMEM_ACTION $goal_id]
                ($op_id ^query-description $smem_query_desc_id)"

   if { $smem_store_id != "" } {
      set smem_store_set_id [CORE_GenVarName "store-set"]
      set lhs_ret "$lhs_ret
                   ($op_id ^store-set $smem_store_set_id)
                   ($smem_store_set_id ^item $smem_store_id)"
   }

   return $lhs_ret
}

proc ngs-match-proposed-smem-retrieve-operator { state_id smem_query_desc_id  { goal_id "" } { op_id "" } } {
   
   variable NGS_OP_SMEM_ACTION
   variable NGS_OP_ID

   CORE_SetIfEmpty op_id $NGS_OP_ID 

   set lhs_ret "[ngs-match-proposed-substate-operator $state_id $op_id $NGS_OP_SMEM_ACTION $goal_id]
                ($op_id ^query-description $smem_query_desc_id)"

   return $lhs_ret
}

proc ngs-match-proposed-smem-store-operator { state_id  { smem_store_set_id "" } { smem_store_id "" } { goal_id "" } { op_id "" } } {
   
   variable NGS_OP_SMEM_ACTION
   variable NGS_OP_ID

   CORE_SetIfEmpty op_id $NGS_OP_ID 
   CORE_SetIfEmpty smem_store_set_id "store-set"

   set lhs_ret "[ngs-match-proposed-substate-operator $state_id $op_id $NGS_OP_SMEM_ACTION $goal_id]
                ($op_id ^store-set $smem_store_set_id)"

   if { $smem_store_id != "" } {
      set lhs_ret "$lhs_ret
                   ($smem_store_set_id ^item $smem_store_id)"
   }

   return $lhs_ret
}

proc ngs-bind-smem-match-query-set { smem_query_desc_id query_id } {
   return "($smem_query_desc_id ^match-query $query_id)"
}

proc ngs-bind-smem-math-query-set { smem_query_desc_id op_id query_id } {
   return "($smem_query_desc_id ^math-query $query_id)"   
}

proc ngs-bind-smem-negated-query-set { smem_query_desc_id query_id } {
   return "($smem_query_desc_id ^negated-query $query_id)"   
}

proc ngs-bind-smem-prohibits-set { smem_query_desc_id prohibits_set_id } {
   return "($smem_query_desc_id ^prohibits_set $prohibits_set_id)"
}

########## New equal and not equal to support LTIs

# Test and id to determine whether it is a fact currently stored in semantic memory
#
# ngs-is-lti: Will match if the id bound to id_to_test is a fact currently stored in semantic memory
# ngs-is-not-lti: Will match if the id bound to id_to_test is NOT a fact currently stored in semantic memory
#
# These methods (1) expand ngs tags for the attribute and (2) use Soar's LTI testing operators '@+/-"
#
# [ngs-is-lti obj attr id_to_test]
# [ngs-is-not-lti obj attr id_to_test]
#
# obj: variable bound to object linked to the id being tested (the WME's "id")
# attr: the attribute bound to the id to test (the WME's attribute)
# id_to_test: variable bound to the id to be tested for a link to semnatic memory
#
proc ngs-is-lti     { obj attr id_to_test } { return "($obj ^[ngs-expand-tags $attr] { @+ $id_to_test })" }
proc ngs-is-not-lti { obj attr id_to_test } { return "($obj ^[ngs-expand-tags $attr] { @- $id_to_test })" }

# Test whether two Soar working meory ids are linked to the same fact in semantic memory.
#
# Soar's semantic memory ids are not used directly in Soar's working memory.  Each time a semantic memory
#  fact (represented by a long-term identifier, LTI) is retrieved, it is bound to a working memory id.
#  If and LTI is retrieved twice (once each for two different queries) it will be bound to two different
#  working memory identifier values. Equality tests on these two working memory identifiers will fail
#  if you use ngs-eq (or equivilent tests in ngs-bind).  Instead, use these two macros which use
#  Soar's built in LTI equality/inequality comparison operators to test for LTI equality/inequality.
#
# ALWAYS use these macros to test for equality/inequality of working memory elements bound to LTIs
#
# ngs-eq-lti:  Will match if the compare_to_id and bind_to_id are both linked to the same LTI
# ngs-neq-lti:  Will match if the compare_to_id and bind_to_id are NOT linked to the same LTI
#
# These methods (1) expand ngs tags for the attribute and (2) use Soar's LTI testing operators '@/!@"
#
# [ngs-eq-lti obj attr compare_to_id (bind_to_id)]
# [ngs-neq-lti obj attr compare_to_id (bind_to_id)]
#
# obj: variable bound to object linked to the id being tested (the WME's "id")
# attr: the attribute bound to the id to test (the WME's attribute)
# compare_to_id: variable bound to an object that is linked to an LTI
# bind_to_id: (Optional) If provided, this variable will be boudn to the value slot of (obj ^attr bind_to_id)
#
proc ngs-eq-lti  { obj attr compare_to_id { bind_to_id "" } } { return "($obj ^[ngs-expand-tags $attr] { @ $compare_to_id $bind_to_id })" }
proc ngs-neq-lti { obj attr compare_to_id { bind_to_id "" } } { return [ngs-not [ngs-eq-lti $obj $attr $compare_to_id $bind_to_id]] }

########## These all simplify  access to Soar's built in smem capabilities
proc ngs-bind-smem-command-set { state_id command_set_id } {
   set smem_id [CORE_GenVarName smem]
   return "($state_id ^smem $smem_id)
           ($smem_id  ^command $command_set_id)"
}

proc ngs-bind-smem-query-command { state_id query_id {command_set_id ""}} {
   set smem_id [CORE_GenVarName smem]
   CORE_GenVarIfEmpty command_set_id "command"
   return "($state_id ^smem $smem_id)
           ($smem_id  ^command $command_set_id)
           ($command_set_id ^query $query_id)"
}
proc ngs-bind-smem-neg-query-command { state_id query_id {command_set_id ""}} {
   set smem_id [CORE_GenVarName smem]
   CORE_GenVarIfEmpty command_set_id "command"
   return "($state_id ^smem $smem_id)
           ($smem_id  ^command $command_set_id)
           ($command_set_id ^neg-query $query_id)"
}
proc ngs-bind-smem-math-query-command { state_id query_id {command_set_id ""}} {
   set smem_id [CORE_GenVarName smem]
   CORE_GenVarIfEmpty command_set_id "command"
   return "($state_id ^smem $smem_id)
           ($smem_id  ^command $command_set_id)
           ($command_set_id ^math-query $query_id)"
}
proc ngs-bind-smem-store-command { state_id store_id {command_set_id ""}} {
   set smem_id [CORE_GenVarName smem]
   CORE_GenVarIfEmpty command_set_id "command"
   return "($state_id ^smem $smem_id)
           ($smem_id  ^command $command_set_id)
           ($command_set_id ^store $store_id)"
}
proc ngs-bind-smem-failure { state_id { command "" } } {
   set smem_id [CORE_GenVarName smem]
   set result_id [CORE_GenVarName result]
   CORE_GenVarIfEmpty command "command"

   return "($state_id ^smem $smem_id)
           ($smem_id  ^result $result_id)
           ($result_id ^failure $command)"
}
proc ngs-bind-smem-success-query { state_id result_lti { command "" } } {
   set smem_id [CORE_GenVarName smem]
   set result_id [CORE_GenVarName result]
   CORE_GenVarIfEmpty command "command"
   
   return "($state_id ^smem $smem_id)
           ($smem_id  ^result $result_id)
           ($result_id ^success $command
                       ^retrieved $result_lti)"
}

proc ngs-bind-smem-success-store { state_id result_lti } {
   set smem_id [CORE_GenVarName smem]
   set result_id [CORE_GenVarName result]
   
   return "($state_id ^smem $smem_id)
           ($smem_id  ^result $result_id)
           ($result_id ^success $result_lti)"
}