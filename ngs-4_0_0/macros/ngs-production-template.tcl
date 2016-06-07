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
#                    curly brackets work as well for production bodis that don't
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
# In this example there is only one template parameters. If there is
#  more than one, the other parameters follow the first parameter in pairs
#  within the inner lists. For example: { %template_var1 value1 %template_var2 value2 ... }
#
# template_name: Name of the template as specified in the call to ngs-declare-tsp
# expansion_lists: A list of lists, where the inner lists each hold the values for a single
#                   template instantiation. The format of the inner lists is sequential pairs of
#                   tempmlate variable name, template variable value.
#
proc ngs-expand-tsp { template_name expansion_lists } {
    
    CORE_RefMacroVars

    set template_string [subst \$\{$template_name\}]

    foreach elist $expansion_lists {
        set production_body [string map $elist $template_string]
        
        set production_name $template_name
        foreach { key val } $elist {
            set production_name "$production_name*$val"
        }

        echo "Expanding template: $production_name"
        sp "$production_name
            $production_body"
    }
}
