##!
# @file
#
# @created soartech 20160606


# Declare a production template
#
# A production template is a production that has one or more elements
#  that are variabilized such that it can expand into multiple productions.
#
# Production templates look exactly like regular productions generated using
#  sp with the following minor differences:
#
# * You start the production with ngs-declare-tsp
# * Within the production you specify template variables, prefixing with %
#
# Example (the %item is the template parameter, you can specify more than one):
#
# ngs-declare-tsp achieve-task-complete*elaborate "
#    [ngs-match-goal <s> AchieveTaskComplete <g>]
#    [ngs-bind <g> task]
#    [ngs-is-tagged <g> $RS_TASK_INFERRED]
#    [ngs-is-supergoal <g> <sg>]
#    [ngs-bind <sg> task:<sg-task>.%item]
# -->
#    [ngs-create-attribute <task> %item <%item>]"
#
# production_name: Root name of the production the template defines. This name
#        will be augmented with the template parameters to give each template
#        expansion a unique name.
# production_body: The body of the production (typically surrounded in quotes, but
#                    curly brackets work as well for production bodies that don't
#                    use TCL variables). 
#
proc ngs-declare-tsp { production_name production_body } {
    #set template_name [string map { "-" "_" "*" "_" } $production_name]
    set template_name $production_name
    CORE_CreateMacroVar $template_name $production_body
}

# Expand a production template
#
# Use this macro to instantiate one or more instances of a production template
#  that was defined using ngs-declare-tsp.
#
# You can instantiate more than one instance using one call to ngs-expand-tsp
#
# Example:
#
# ngs-expand-tsp achieve-task-complete*elaborate { 
#    { %item route } 
#    { %item destination } 
#    { %item desired-formation } 
#    { %item desired-formation-position } 
# }
#
# You can also use ngs macros in the values:
#
# ngs-expand-tsp elaborate*context*subsurface-contact*buoy-readings { 
#    { %groupName all %additionalConditions "" }
#    { %groupName difar %additionalConditions "[ngs-bind <buoy> type:difar]" }
#    { %groupName dicass %additionalConditions "[ngs-bind <buoy> type:dicass]" }
#    { %groupName dicass-down %additionalConditions "[ngs-bind <buoy> type:dicass] [ngs-bind <reading> doppler:down]" }
# }
#
# In this example there is only one template parameters. If there is
#  more than one, the other parameters follow the first parameter in pairs
#  within the inner lists. For example: { %template_var1 value1 %template_var2 value2 ... }
#
# The expanded production's name is derived from the concatenation of the template arguments.
#  If you do not want an argument to be included in the production name, use two "%"
#  characters instead of one. This is useful if the template argument is a string containing
#  spaces or other characters that are invalid in a production name.
#
# template_name: Name of the template as specified in the call to ngs-declare-tsp
# expansion_lists: A list of lists, where the inner lists each hold the values for a single
#                   template instantiation. The format of the inner lists is sequential pairs of
#                   tempmlate variable name, template variable value. The value may be a constant
#                   or Soar code (i.e., calls to other ngs macros)
#
proc ngs-expand-tsp { template_name expansion_lists } {
    
    variable $template_name

    set template_string [subst \$\{$template_name\}]

    foreach elist $expansion_lists {
        # expand any tcl content in the list
        set elist [subst $elist]
        
        set production_body [string map $elist $template_string]
        
        set production_name $template_name
        foreach { key val } $elist {
            if { [string range $key 0 1] != "%%" } {
                # since the value may consist of arbitrary soar code and float values, we need to convert any characters
                # that don't work for a production name into characters that do work for a production name
                set name_val [regsub -all {\s+} $val _]
                set name_val [string map {( "" ) "" . - < "" > "" ^ ""} $name_val]

                set production_name "$production_name*$name_val"
            }
        }

        echo "Expanding template: $production_name"
        sp "$production_name
            $production_body"
    }
}
