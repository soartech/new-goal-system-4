

# At minimum, reward must have a value.  It can have
#  other attributes, which are ignored by the Soar architecture
NGS_DeclareType NGSRewardValueStructure { 
   name  ""
   value ""
}

NGS_DeclareType NGSUserReward {
    type { NGSRewardValueStructure }
}

# Binds to a reinforcement learning reward structure
#
# Use on the LHS of productions that set the reward for a given reward type.
#
#    [ngs-bind-reward-structure state_id reward_name reward_structure_id reward_source_id* source_bindings*]
# 
# On the RHS the reward should be set using ngs-create-attribute or ngs-create-attribute-by-operator
#  as follows:
#   - [ngs-create-attribute <reward_structure_id> value <YOUR VALUE>] 
#   - [ngs-create-attribute-by-operator <s> <reward_structure_id> value <YOUR VALUE>]
#
# state_id - Variable bound to the state where the reward structure should be bound
# reward_name - Name of the reward as specified when the reward was defined with NGS_DefineXReward
# reward_structure_id - Variable that will be bound to the id of the reward structure for the given named reward
# reward_source_id - (Optional) If specified, a variable that will be bound to the source tag in the given reward structure.
#    This source tag will be the object that can be found at the reward_path as specified in NGS_DefineXReward
# source_bindings - (Optioal) If specified, this macro will expand [ngs-bind $reward_source_id $source_bindings]
#
proc ngs-bind-reward-structure { state_id reward_name reward_structure_id { reward_source_id "" } { source_bindings "" } } {

    variable NGS_TAG_REWARD_SOURCE

    set source_line ""
    if { $reward_source_id != "" } {
        set source_line "[ngs-is-tagged $reward_structure_id $NGS_TAG_REWARD_SOURCE $reward_source_id]"

        if { $source_bindings != "" } {
            set source_line "$source_line
                             [ngs-bind $reward_source_id $source_bindings]"
        }
    }

    set reward_link_id [CORE_GenVarName reward-link]
    return "($state_id            ^reward-link $reward_link_id)
            ($reward_link_id      ^reward      $reward_structure_id)
            ($reward_structure_id ^name        $reward_name)
            $source_line"
}


# Creates productions to generate a reward structure of the given type, path, and name
#
# Use to define a user-managed reward structure to be elaborated onto the reward link.
# In separate productions, set the reward value per Soar's reinforcement learning architecture.
#
# NGS_DefineUserReward reward_name reward_type* source_path* which_state* state_name*]
#
# reward_name - A Soar symbol (typically a string) identifying the reward.  It is recommended that your model not
#                create multiple reward structures with the same name or the reward value-setting productions might
#                fire more than once setting multiple values for a single reward.
# source_path - (Optional) If specified, a path rooted at the state (see the which_state and state_name 
#                 paramter descriptions) at which to find a source object. Source objects typically contain
#                 one or more attributes that are used to set the reward value.  Other productions can bind this
#                 source object using the reward_source_id parameter to ngs-bind-reward-structure and then
#                 read from it to set the reward.
# which_state - (Optional) One of the following values specifying the state one which the reward structure should be created:
#                $NGS_REWARD_LOCATION_TOP_STATE, $NGS_REWARD_LOCATION_ANY_STATE, or $NGS_REWARD_LOCATION_SUB_STATE
# state_name  - (Optional) If specified, the reward structure will only be put on states with the given name (mainly applies
#                to rewards on substates)              
# 
proc NGS_DefineUserReward { reward_name { source_path "" } { which_state "" } { state_name "" } } {

    variable NGS_TAG_REWARD_SOURCE
	variable NGS_REWARD_LOCATION_TOP_STATE
	variable NGS_REWARD_LOCATION_ANY_STATE
	variable NGS_REWARD_LOCATION_SUB_STATE

    CORE_SetIfEmpty which_state $NGS_REWARD_LOCATION_TOP_STATE

    if { $which_state == $NGS_REWARD_LOCATION_TOP_STATE } {
        set top_binding [ngs-match-top-state <s> reward-link]
    } elseif { $which_state == $NGS_REWARD_LOCATION_ANY_STATE } {
        set top_binding [ngs-match-any-state <s> reward-link]
    } elseif { $which_state == $NGS_REWARD_LOCATION_SUB_STATE } {
        set top_binding [ngs-match-sub-state <s> reward-link]
    }
    
    if { $state_name != "" } {
        set top_binding "$top_binding
                         [ngs-is-named <s> $state_name]"
    }

    sp "rl*create-reward-structure*NGSUserReward*$reward_name
        $top_binding
    -->
        [ngs-create-typed-object <reward-link> reward NGSUserReward <reward-struct> "name $reward_name"]"

    set reward_source_id [CORE_GenVarName reward-source]
    if { $source_path != "" } {
	    sp "rl*create-reward-structure*NGSUserReward*$reward_name*source
	        $top_binding
            [ngs-bind <s> $source_path:$reward_source_id]
            [ngs-bind <reward-link> reward.name:$reward_name]
	    -->
	        [ngs-tag <reward> $NGS_TAG_REWARD_SOURCE $reward_source_id]"
    }

}

## I'd like to create the ability to easily create:
## Rewards that can be expressed as computed values
## Rewards that are look-up tables
## Rewards that are instantaneous (one cycle)

