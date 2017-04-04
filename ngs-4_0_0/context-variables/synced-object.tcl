##!
# @file
#
# @created jacobcrossman 20170323


# Declare and define the productions for Synced Object
# 
# Use this macro to declare and define the productions for a synced object. A synced object
#  is an object that contains data linked to one or more other objects. A common use for
#  synced objects is in indirecting access to input link. With a synced object, you can
#  create a separate object that have some or all of its attributes synced to the source
#  object. Decision logic then binds to the synced object (which forms an immutable API) while
#  you can change how the data is sourced.
#
# Unlike other context variables, there is no corresponding ngs-create- macro. You can sync any object you like.
#  If you want a synced object to be created when you define the syncing productions, you need to pass
#  a tuple of (variable_name scope_key type_name) in as the variable_name_or_tuple parameter.
#  If you pass these values in, the system will construct a synced objet of the given type_name whenever
#  an object can be bound to the scope_key path.
#
# Following is a use example for Vehicle State syncing
# 
# NGS_DefineSyncedObject my-agent $NGS_CTX_VAR_USER_LOCATION { host my-state VehicleStateContext } "my-state $WM_INPUT_LINK.my-state" {
#   { raw-position-in-lane my-state position-in-lane-m }
#   { position-in-lane     self     raw-position-in-lane }
#   { acceleration         my-state acceleration-mpss }
#   { position             my-state position }
#   { turning-radius       my-state turning-radius-m }
#   { velocity             my-state velocity }
# }
# 
# This macro expansion creates a synced object called "host" at the location my-agent.host (a user defined location).
# It creates a single named scope -- my-state which maps to $WM_INPUT_LINK.my-state. This means that every time
#  my-state is refered to in the parameters, it expands to $WM_INPUT_LINK.my-state.
# It then creates a set of mappings.  
#  - It maps my-state.position-in-lane-m to host.raw-position-in-lane
#  - It maps self.raw-position-in-lane to position-in-lane (i.e. it maps its own attribute to another attribute)
#  - It maps my-state.accleration-mpss to host.acceleration
#  - etc
#
# The system provides a default mapping for the "self" scope. "self" refers to the synced object itself.
# The system also provides a default mapping for "goal" scope, but only if the synced object is created
#  on a goal (i.e. if pool_goal_or_path is a GoalType). "goal" will refer the goal that holds the synced object.
# The source attribute can also itself be a path. This way you can pull values out of context variables.
# For example, if you are time sampling heading values, you might create a context variable to sample it and then
#  map that context value's "value" to a synced object.
#
# Note that you can create more than one scope mapping, just add additional (scope_name scope_path) pairs to the
#  source_defs parameter list. This means that a synced object can sync data from more than one source (it can
#  serve as a collector of data from different sources).
#
# You can add any other data you like to a synced object using other productions
#
# NGS_DefineTimeDelayedValue pool_goal_or_path category_name variable_name_or_tuple source_defs mappings
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name_or_tuple - If you create a synced object in user code, this is just the attribute name that links
#   to the object. If you want this macro to construct the object for you, it should be a 3-tuple with the following
#   values: variable name, source path key, synced object type name. The variable name is just the name of the attribute
#   to link to the newly created synced object (just like all context variables). The source path is a key identifying
#   a source path in the source_defs list. The type name is the type of object to constructe with 
#   ngs-create-typed-object.
# source_defs - A dictionary (just a string with "key1 val1 key2 val2 ...") with named paths to data sources that you
#   wish to reference in the mappings list. The key is a short name you want to give to the path. The path is a
#   path to the data you want to reference. Note -- to link to the input link use $WM_INPUT_LINK.
# mappings - A list of 3-tuples where each 3-tuple defines a mapping of a value from a source object to a value in
#   synced object. The tuple values are as follows: synced object attribute name, source key, source attribute name.
#   The synced object attribute name is the name you want to give to the source value in the synced object.
#   The source key is one of the short names you defined in source_defs. The source attribute name is the name of
#   the source value in source object. Note that this can actually be a path as well, which is useful if you
#   need to reference the "value" in a context variable.
#
proc NGS_DefineSyncedObject { pool_goal_or_path category_name variable_name_or_tuple source_defs mappings } {

   set variable_parameter_size [llength $variable_name_or_tuple]
   if { $variable_parameter_size == 1 } {
      set variable_name $variable_name_or_tuple
   } elseif { $variable_parameter_size == 3 } {
      set variable_name [lindex $variable_name_or_tuple 0]
      set source_key    [lindex $variable_name_or_tuple 1]
      set type_name     [lindex $variable_name_or_tuple 2]
      set path_to_obj_source [ngs-expand-tags [dict get $source_defs $source_key]]
   } else { 
      echo "WARNING: In NGS_DefineSyncedObject expected (variable_name, source_name, type_name_)"
      return ""
   }

   set variable_name [ngs-expand-tags $variable_name]
   set var_id   <variable>
   set scope_id <var-scope>

   # set the suffix for the template's names, removing any '.' charaters that appear (not allowed in production names)
   set production_name_suffix [ngs-ctx-var-gen-production-name-suffix $pool_goal_or_path $category_name $variable_name]
   
   # Production to create the root object if desired
   if { $variable_parameter_size == 3 } {
      sp "ctxvar*synced-object*elaborate*root-pool-object*$production_name_suffix
         [ngs-ctx-var-gen-root-bindings $pool_goal_or_path $category_name {} {} $scope_id]
         [ngs-bind <s> $path_to_obj_source:<source-object>]
      -->
         [ngs-create-typed-object $scope_id $variable_name $type_name <new-obj>]
         [ngs-tag <new-obj> auto-created-from <source-object>]
      "
   }

   # Generate the root bindings shared by all productions in this macro
   set goal_id "<goal>"
   set root_bind [ngs-ctx-var-gen-root-bindings $pool_goal_or_path $category_name $variable_name $var_id $scope_id $goal_id]

   # For each mapping, we construct a production to elaborate the alue
   foreach mapping $mappings {
      set local_name       [lindex $mapping 0]
      set source_path_key  [lindex $mapping 1]
      set source_attr_name [lindex $mapping 2]
      set source_attr_id   [CORE_GenVarName source]

      if { $source_path_key == "self" } {
         set source_binding   [ngs-bind $var_id $source_attr_name:$source_attr_id]
      } elseif { $source_path_key == "goal" } {
         set source_binding   [ngs-bind $goal_id $source_attr_name:$source_attr_id]
      } else {
         set source_path      [dict get $source_defs $source_path_key]
         set source_binding   [ngs-bind <s> $source_path.$source_attr_name:$source_attr_id]   
      }

      sp "ctx-var*synced-object*elaborate*element*$production_name_suffix*$local_name
        $root_bind
        $source_binding
      -->
        [ngs-create-attribute $var_id $local_name $source_attr_id]"
   } 
}
