##!
# @file
#
# @created jcrossman 20160505

# The Soar Typed Object Representation (STOR) is structured as follows:
#
# Object = { TypeName { AttributeList } }
# AttributeList = { AttributeName AttributeAtomicValue } |
#                 { AttributeName Object }
#
# You can use ngs-create-typed-object-from-stor to create the Soar code for constructing
#  an i-supported (or :o-support) version of the object in the STOR
#
# This representation is primarily used to pass Soar data that is used in testing or setting up the agent

# Returns the type from a Soar Typed Object Representation (STOR)
proc ngs-type-from-stor { stor } {
    return [lindex $stor 0]
}

# Returns the attribute lise from a Soar Typed Object Representation (STOR)
proc ngs-attr-list-from-stor { stor } {
    return [lindex $stor 1]
}

# Creates code to construct an NGS 4 typed object from a STOR, assigning the object to
#  the given parent_id and parent_attr
#
proc ngs-create-typed-object-from-stor { parent_id parent_attr stor } {
    set stor [strip_comments $stor]

    set obj_type   [ngs-type-from-stor $stor]
    set obj_attrs  [ngs-attr-list-from-stor $stor]
    set new_obj_id [CORE_GenVarName "new-obj"]
    set key ""
    set val ""

    set create_line "[ngs-create-typed-object $parent_id [ngs-expand-tags $parent_attr] $obj_type $new_obj_id]"

    # For each attribute of an object, create it
    # We can't iterate using "dict for" because it eliminates multi-valued attributes
    foreach element $obj_attrs {
        
        if { $key == "" } { 
            # read the key, and wait for next iteration to grab the value
            set key $element 
        } else {
            set val $element
            if { [llength $val] == 1 } {
                # create an atomic attribute
                set create_line "$create_line
                                 [ngs-create-attribute $new_obj_id [ngs-expand-tags $key] $val]"
            } else {
                # recursive call to create sub-object
                set create_line "$create_line
                                 [ngs-create-typed-object-from-stor $new_obj_id [ngs-expand-tags $key] $val]"
            }

            # prepare for next key
            set key ""
            set val ""
        }

    }

    return $create_line
}
