##!
# @file
#
# @created jacobcrossman 20161230

# Get the version information.  We also place a tag on the top state with the version.
#  You could test this version number in productions if it is important

# I use git rev-list --count --first-parent HEAD to get the build number

CORE_CreateMacroVar NGS_VERSION_TAG_NAME ngs-version-text
CORE_CreateMacroVar NGS_MAJOR_VERSION 4
CORE_CreateMacroVar NGS_MINOR_VERSION 1
CORE_CreateMacroVar NGS_BUILD_NUMBER  156

CORE_CreateMacroVar NGS_VERSION_TEXT "|$NGS_MAJOR_VERSION.$NGS_MINOR_VERSION.$NGS_BUILD_NUMBER|"

NGS_DeclareType NGSVersionNumber {
    major-number $NGS_MAJOR_VERSION
    minor-number $NGS_MINOR_VERSION
    build-number $NGS_BUILD_NUMBER
}

proc ngs-version {} {
    echo $NGS_VERSION_TEXT
}

sp "ngs*version*set-tag
    [ngs-match-top-state <s>]
-->
    [ngs-tag <s> $NGS_VERSION_TAG_NAME $NGS_VERSION_TEXT]
    [ngs-create-typed-object <s> @ngs-version-details NGSVersionNumber <version>]"