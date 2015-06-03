
#
# add a tag to the given 'tags' structure.
#
proc NGS_tag {tags_id tag_name {tag_value ""}} {
  CORE_SetIfEmpty tag_value $NGS_YES
  return "($tags_id ^$tag_name $tag_value)"
}