# NGS 4.x Developer Guide

## Table of Contents
1. [Introduction](#introduction)
1. [Installation and Configuration](#installation)
1. [The Basic Structure of NGS Code](#structure)
1. [The Structure of Working Memory](#workingmemory)
1. [Production Left Hand Sides](#lhs)
1. [NGS Goals](#goals)

## Introduction <a id="introduction"></a>
### What is NGS 4?
The **N**ew **G**oal **S**ystem (NGS) 4 is a library of macros, written in the TCL language, and default productions simplify and speed up the development of [Soar architecture](http://soar.eecs.umich.edu) models. To a developer, NGS 4 appears as a higher level language that is used to generate Soar productions.

Using NGS 4 provides the following benefits over using Soar's built in programming language:

* It provides support for top-state goals and goal forests. Goal forests in particular are very useful for complex, real-time models such as those used to control robots.
* It provides support for explicit, persistent decisions. The Soar architecture has excellent built in support for decision making. NGS 4.0 provides additional support for decisions that need to remain persistent within a goal forest (i.e. not go away when the operator is complete).
* It makes object creation and removal simple and easy. In particular it eliminates the class of errors related to improper handling of creation conditions (e.g. object already exists v. object does not exist) and layered object creation (e.g. objects with sub-structure). 
* It has direct support for object tagging. Object tagging provides a way to annotate objects with information about how that object is being processed, without polluting the object's attribute name space.
* It supports declaration and usage of named constants. This support uses TCL's variables.
* It provides a compact pattern matching syntax and hides the details of complex logic such as logical "or" and stable continuous value tests.
* It directly supports the use of the Soar architecture's sub-states. NGS provides wrappers for these substates that enable named parameters to the sub-states and all-or-nothing return values.
* It provides some early stage, primitive type declaration and checking capabilities. We intend to expand type declaration and checking in the future.
* It provides debugging aids to help inspect NGS 4 goal hierarchies and objects.

NGS 4 provides a comprehensive wrapper around Soar. While technically possible, it is not typically a good idea to mix NGS 4 code with raw Soar code, unless the raw Soar code is isolated (e.g. in a sub-state). 

### Limitations

Though NGS 4 constructs an abstraction above the level of the Soar architecture, it is a leaky abstraction. To use NGS 4 effectively, you will still need to know how Soar works and know raw Soar syntax. This knowledge is needed to support debugging NGS systems. 

> **Implementation Notes**
>
> Throughout this guide, you will see implementation notes highlighted. 
> These notes are intended to provide the developer with knowledge that can
> help in understanding and debugging an NGS 4 model.> 

Important limitations:
* Currently NGS 4 only supports the *o-supported* construction of new object structures with 4 levels of sub-structure or less. To create deeper substructure, you must construct the object in multiple steps. *I-supported* structures can be arbitrarily deep without breaking up the construction process.
* NGS 4 has a primitive type system. Though you can declare object types, and must declare goals, the library does very little type checking currently and will not prevent you from mis-using an object of a given type.
* NGS 4 does not provide direct support for semantic memory and episodic memory queries, though you can use NGS to build your own support for these.

### Comparing NGS 4 to NGS 3

NGS 4 builds on the NGS 3 library, but differs in many ways from this much older library. NGS 4 and NGS 3 are not compatible.

* NGS 4 provides a *much* broader range of macros than NGS3
* NGS 4 uses a consistent naming convention for macros that do not match NGS3's names in all cases.
* NGS 4 uses a different way to index the goal pool than NGS3 (one of the main reasons why they are incompatible). NGS 3 has a single main goal pool, while NGS 4 indexes goals by type, subtype, and decision name.
* NGS 4 code is made to standalone, without requiring any raw Soar syntax. NGS 3 requires a significant amount of Soar syntax.
* NGS 4 directly supports all-or-nothing substates and no-change operators. NGS 3 does not have any support for these features (though you could build this support yourself using NGS 3).
* NGS 4 does not require the developer to write any operator applications (all operator applications are provided in the library). In NGS 3, you must write operator applications for each operator you propose.
* NGS 4 object structure is different than NGS 3. NGS 4 objects are flat - tags and types are all placed at the root level of an object, while in NGS 3 they sit at a separate sub-level under the object.

There are many other differences, mainly due to the large number of additional macros available in NGS 4, but these are the major differences.


## Installing and Usage <a id="installation"></a>
### Creating an agent that uses NGS 4.0
1. Download the latest NGS 4.0 from [here](https://github.com/soartech/new-goal-system).
2. Unzip and put files into your project. We recommend putting the NGS and _core directories at the top level of your agent (as siblings to the agent's root Soar file).
	* The easiest way to do this is to simply add NGS 4.0 to your project's repository. It's not large and probably won't update often. If an update is released, you can simply replace the entire NGS directory with the new version.
3. Source NGS from your root Soar file before any other commands that use NGS or source files that use NGS (in practice, this typically is at the top of the file):

```
source ngs-4_0_0/load.soar
```
 
### Running the NGS unit tests <a id="unittests"></a>
The NGS unit tests use [SoarUnit](https://github.com/soartech/jsoar/wiki/SoarUnit), which is part of [jsoar](https://github.com/soartech/jsoar). You can add a SoarUnit launch to your favorite editor or run it from the command line. Either way, you will need to point it to NGS's test directory: `/ngs-4.0.0/tests`.

Looking through and running the NGS tests is one way to become familiar with many of the common NGS macros. However, because the NGS test code was written while NGS 4 was in development, many of the productions in the tests do not conform to the most recent standards (e.g. many of the tests mix raw Soar and NGS code, which you should not do in your models).

### Library structure and organization
The library is organized across several files and directories:
* load.soar: This is the root load file for NGS. Sourcing this will source all of NGS.
* macros: This directory contains all of the NGS Tcl macros. These macros are described throughout this document. They are heavily commented, so browsing these files to get more information on how various macros work and which ones are available is encouraged.
* tests: This directory contains the NGS unit tests. You do not need to understand these in order to use NGS, but they may provide useful examples of expected behavior. See [Running the NGS unit tests](#unittests) for more info.
* Other .soar files: These are Soar rules that enable NGS to provide many of its features (e.g., default apply rules).

## The Basic Structure of NGS Code <a id="structure"></a>

When you write NGS code, you are actually writing [TCL code](http://www.tcl.tk) where the NGS library itself is actually a set of [TCL procedures](http://wiki.tcl.tk/463) and [variables](http://wiki.tcl.tk/1368). 

The process is as follows:

```
Developer
   ||
   \/   <-- TCL Code
TCL Interpreter
   ||
   \/   <-- Soar Code (mainly "sp" commands)
Soar Code
   ||
   \/   <-- RETE structures
Soar Virtual Machine
```
The NGS code is nested within Soar's sp command. The TCL interpreter executes the NGS code before it calls the sp command. Each NGS macro returns a string which contains fragments of a Soar production left hand side (LHS) or right hand side (RHS). Thus, when the Soar sp command is called, all it sees is Soar code. 

Here is an example that creates a working memory element on the top state called "text" and sets the value of this "text" to "Hello World."

```
sp "ngs-example*hello-world
   [ngs-match-top-state <s>]
-->
   [ngs-create-attribute-by-operator <s> <s> text "|Hello World|"]"
```

This example is a Soar production in NGS 4 syntax. **sp** is the name of the "Soar Production" command built into the Soar Architecture. **ngs-example*hello-world** is the name of the production. This name is passed directly to the sp command - NGS does not do anything to the name. The NGS portion of the code is the two macros:
* ngs-match-top-state: This macro binds to the top state (it has other optional parameters that we are not using in this simple example).
* ngs-create-attribute-by-operator: This macro uses an operator to construct a working memory element (WME) of the form (\<s\> ^text |Hello World|).

This production will execute, if you load and run it with the NGS 4 library. 

If you are used to writing raw Soar code, you may wonder how this operator gets applied. As with all *atomic* operators in NGS 4, the operator application is handled by a suite of productions in the NGS library itself. 

This production gets expanded by the TCL interpreter as follows:

```
sp {ngs-example*hello-world
   (state <s> ^superstate nil)
-->
   (<s> ^operator <o> + =)
   (<o> ^name     (concat |create-wme--| <s> |--text--| |Hello World|)
        ^type     atomic)
   (<o> ^__tagged*ngs*i-supported *yes* +)
   (<o> ^dest-object    <s>
        ^dest-attribute text
        ^new-obj        |Hello World|
        ^replacement-behavior ngs-replace)
   (<o> ^__tagged*ngs*intelligent-construction *yes* +)
   (<o> ^__tagged*ngs*op-create-primitive *yes* +)
}
```
> **Implementation Note**
>
> The raw Soar code for this example was generated using the SoarIDE's Soar Source Viewer window.
> If you aren't using the SoarIDE you should. It will make development easier. Go to its [github site](https://github.com/soartech/soaride/blob/master/README.md), download and install it.
> It is a plugin to the [Eclipse Editor](eclipse.org), so you will need that too.
> 
 
Notice that the expanded code is:
* Raw soar code (no TCL)
* Larger (more lines of code) than the NGS equivilent
* More difficult to parse and understand what is going on

While some of the complexity of the Soar code is due to the generality of the generated code (it works for more than just this special case), it is also due to the fact that NGS abstracts many low level details of Soar syntax and execution away from the developer, leaving the developer free to focus on the bigger picture issues of the goals, decisions, and procedures that a model should execute.

> **Implementation Note**
>
> Notice that the operator name in this example is constructed at runtime using Soar's (concat)
> function. All *atomic* operators (i.e. those that create objects) in NGS dynamically create
> operator names that describe in detail what that operator is doing. This is one of NGS 4's
> methods of helping the developer trace and debug their system.

The example above is a simple instance of the standard structure of an NGS production:

```
sp "production-name
	[ngs-match-* macro]
	[ngs-bind, ngs-is-*, and test macros]
-->
	[ngs-create-* macro]
	[ngs-add-*-side-effect macro]"
```

The macros on the left hand side (before the "-->") always start with an ngs-match-* macro (which binds to the state) and are followed by other macros that bind to other aspects of the state or test values for logical conditions. The macros on the right hand side (after the "-->") create structure in Soar working memory. Each production should create only ONE object (this object can have sub-structure) and assign its ID to a WME. 

The one exception is operator side-effects. A side-effect is a simple, atomic operation (i.e. creating a WME), that happens in parallel to the construction of the production's main object.

The following is more complex example from a functioning NGS model.

```
sp "achieve-message-handled*propose*remove-message-after-handling
	[ngs-match-goal <s> AchieveMessageHandled <g>]
	[ngs-is-tagged <g> message-copied]
	[ngs-bind <g> message.id]
	[ngs-output-link <s> <ol>]
    [ngs-not [ngs-bind <ol> command!RemoveMessage.id]]
-->
    [ngs-create-output-command-by-operator <s> <ol> RemoveMessage <cmd> { id <id> }]"
```

This production creates an output command to remove a message after it has been copied to Soar internal working memory (from the input link). You don't need to understand this whole production at this point, but you can see the standard pattern - an ngs-match macro (in this case matching a goal), various binding and testing macros, and a RHS that creates a structure -- in this case an output command.

In case you are curious, here is the raw Soar code that these macros generate (reformatted to make it easier to read):

```
sp {achieve-message-handled*propose*remove-message-after-handling
	(state <s>      ^superstate nil 
                    ^goals.AchieveMessageHandled <goal-pool783>)
    (<goal-pool783> ^goal <g>)
	(<g>            ^__tagged*message-copied *yes*)
	(<g>            ^message <message>)
    (<message>      ^id <id>)
	(<s>            ^io.output-link <ol>)
   -{ 
      (<ol> ^command <command>)
      (<command> ^type RemoveMessage)
      (<command> ^id <id>) 
    }
-->
    (<s> ^operator <o> + =)
    (<o> ^name     (concat |create-RemoveMessage--| <ol> |--command--| <cmd>)
         ^type     atomic)
    (<o> ^__tagged*ngs*i-supported *yes* +)
    (<o> ^dest-object    <ol>
         ^dest-attribute command
         ^replacement-behavior ngs-add-to-set)
    (<o> ^__tagged*ngs*intelligent-construction *yes* +)
    (<o> ^__tagged*ngs*op-create-typed-object *yes* +)
    (<o> ^new-obj <cmd> +)
    (<cmd> ^type NGS_OutputCommand 
           ^id <id> 
           ^type RemoveMessage 
           ^my-type RemoveMessage)
    (<o> ^__tagged*ngs*op-output-command *yes* +)
}
```

That's a lot of code that you don't have to write. It's also, a lot harder to parse and understand than the equivalent NGS code.

## The Structure of Working Memory <a id="workingmemory"></a>

NGS macros manipulates and binds Soar's working memory using three abstractions:

1. **Atomic Values**: Atomic values are the values supported by Soar - integers, floats, strings, and ids.
1. **Typed Objects**: Typed objects are collections of WMEs that share the same left-most identifier. They are identical to "plain old data structures" in object oriented programming.
1. **Tags**: Tags are WMEs that follow a standard naming convention for the attribute. All tag names in NGS 4 are prefixed with __tagged*ngs*. NGS provides many macro specializations for working with tags.

Goals (discussed in ###) are a form of typed object.

### Typed Objects
All typed objects share a standard layout. They are "flat" meaning that all of their attributes can be expressed as WMEs with the root-id as the left-most value. For example:

```
# Layout of a typed object, with the root id: o15
(o15 ^__tagged*ngs*constructed *yes*)
(o15 ^type  MyType)
(o15 ^my-type MyType)
(o15 ^attr1 v15) 
(o15 ^attr2 5.0)
(o15 ^attr3 |A String|)
```
Each WME that makes up a typed object can point to either the root of another typed object, or to an atomic value (a number or a string).

```
<root-id>
  ^__tagged*ngs*constructed *yes*   # All typed objects have this flag
  ^__tagged*ngs*i-supported *yes*   # If i-supported only
  ^my-type 							# Most Derived Type (always only one)
  ^type 						    # Most Derived Type
  ^type 							# Base Type(s), if any
  ^<user-defined-attribute-1>       # Any of these you create
```

NGS typed objects are created using NGS macros. Several macros exist to support different use cases.

**Creating I-Supported Typed Objects**

**Creating O-Supported Typed Objects**

**Creating Typed Objects as Substate Return Values**

* ngs-create-typed-object-by-operator: Used to create a new, o-supported, typed object.
* ngs-icreate-typed-object-in-place: Used to create a new i-supported typed object and any sub-structure under that object.
* ngs-ocreate-typed-object-in-place: Used to create sub-structure under objects that you create using ngs-create-typed-object-by-operator.

### Atomic Values and Shallow Links

### Tags

### Removing Objects, Atomic Values, and Tags

### Operator Side Effects

## Production Left Hand Sides <a id="lhs"></a>

NGS provides a number of macros for creating LHS conditions in rules. With these, you should never have to write raw Soar code. The macros generate straightforward code, but do so in a way that tends to be more compact and is easier to read, in part because the macros give a name to the function being performed by the block of conditions they generate. This section will give an overview of the available macros, but for the full set and description, see [macros/lhs-fragments.tcl](macros/lhs-fragments.tcl)
 
### ngs-match-* <a id="ngs-match"></a>
The `ngs-match-*` macros generate productions for matching on specific parts of working memory. Many of them take optional arguments that allow you to specify Soar variables that should be bound to these things. Some examples:

All macros include state testing already; the first argument is always the state. Thus, you probably always want to start a rule with an `ngs-match-*` macro of some kind. For example, `ngs-match-top-state` or `ngs-match-substate`. 

`ngs-match-top-state` matches on the top state, binding it to a specified Soar variable. It can optionally also bind on the input-link, output-link, and other bindings. This kind of pattern (some required parameters, and some optional) is common throughout the NGS macros.

```tcl
sp "example
   [ngs-match-top-state <s>] # bind top-state to <s>
-->
"

sp "example
   [ngs-match-top-state <s> "" <il> <ol>] # bind top state to <s>, input-link to <il>, and output-link to <ol>
-->
" 

sp "example
   [ngs-match-top-state <s> "agent!RobotAgent:<me>.location!Location"] # bind top state and another structure via the ngs-bind macro
-->
"
```

Several macros provide support for matching goals:
* `ngs-match-goalpool`
* `ngs-match-goal`
* `ngs-match-active-goal`
* `ngs-match-goal-to-create-subgoal`
* `ngs-match-selected-goal`
* `ngs-match-top-state-active-goal`

See ??? for more information about how to use NGS goals.

```tcl
sp "example
   [ngs-match-goal <s> MyGoal <g>] # <s> is bound to the top-state, and <g> is bound to the goal
-->
"
```

Macros that match on operators include:
* `ngs-match-proposed-operator`
* `ngs-match-proposed-atomic-operator`
* `ngs-match-proposed-decide-operator`
* `ngs-match-two-proposed-operators`

Note there are macros for matching selected operators, but these are really intended for internal use in NGS. You should be able to use the default apply macros as described in [Common actions](#common actions). Indeed, you may not even need to match on proposed operators in most cases, as the RHS macros often encapsulate the operators for you.

```tcl
sp "example
   # <s> is the state to test for an operator
   # $NGS_OP_ID is a default operator identifier provided by NGS (<o>)
   # You can provide any Soar variable you want to use for the operator if preferred
   [ngs-match-proposed-operator <s> $NGS_OP_ID] 
-->
"
```

Some macros provide LHS conditions in support of RHS actions, including:
* [`ngs-match-to-create-return-goal`](???)
* [`ngs-match-to-make-choice`](???)
* [`ngs-match-to-set-return-val`](???)

These need to be understood in context, and thus are described in the linked sections.

### ngs-bind <a id="ngs-bind"></a>
`ngs-bind` binds arbitrary structures rooted in a specified location in working memory. It provides a more compact syntax than raw Soar code by automatically creating Soar variables for you in many cases. It also provides very basic (optional) type checking. Several other macros take `ngs-bind` strings as parameters (e.g., `ngs-match-top-state`), allowing for easy macro combinations.

The basic syntax is to use dot notation, like standard Soar syntax:

```tcl
sp "example
   [ngs-match-top-state <s> "" <il>]
   [ngs-bind <il> system.time]
-->
"

# Expanded form:
sp "example
   (state <s>  ^superstate nil)
   (<s>        ^io.input-link <il>)
   (<il> ^system <system>)
   (<system> ^time <time>)
-->
"
```

Note how the dot notation is internally broken apart and Soar variables with the same names as the attributes are automatically created. This allows you to maintain the compact dot notation while still being able to refer to intermediate objects like `<system>`.

In many cases, however, the automatic variable names will not be what you want. E.g., you want to use the same variable as another `ngs-bind` statement, but it has a different attribute name (and hence a different automatic variable name). Thus, you can specify a variable name to use:

```tcl
sp "example
   [ngs-match-top-state <s> "" <il>]
   [ngs-bind <il> system:<sys>.time:<my-time>]
-->
"

# Expanded form:
sp "example
   (state <s>  ^superstate nil)
   (<s>        ^io.input-link <il>)
   (<il>      ^system <sys>)
   (<system>  ^time <my-time>)
-->
"
```

Furthermore, you can optionally specify the type of an attribute using the `!`:


```tcl
sp "example
   [ngs-match-top-state <s> "" <il>]
   [ngs-bind <il> agent!RobotAgent:<me>.location!Location]
-->
"

# Expanded form:
sp "example
   (state <s>  ^superstate nil)
   (<s>        ^io.input-link <il>)
   (<il>       ^agent <me>)
   (<me>       ^type RobotAgent)
   (<me>       ^location <location>)
   (<location> ^type Location)
-->
"
```

### ngs-is-\*, ngs-is-not-\* <a id="ngs-is"></a>
NGS includes a family of macros for checking if a specified object meets some condition or not.

Goal tests:
* `ngs-is-achieved`, `ngs-is-not-achieved`
* `ngs-is-active`, `ngs-is-not-active`
* `ngs-is-assigned-decision`, `ngs-is-not-assigned-decision`
* `ngs-is-goal-stack-selected`, `ngs-is-not-goal-stack-selected`
* `ngs-is-subgoal`
* `ngs-is-supergoal`

Object tests (Note: Goals are objects, too, so these can also be used with goals):
* `ngs-is-type`, `ngs-is-not-type`
* `ngs-is-my-type`, `ngs-is-not-my-type`
* `ngs-is-named`, `ngs-is-not-named`
* `ngs-is-tagged`, `ngs-is-not-tagged`

Decision tests:
* `ngs-is-decision-choice`, `ngs-is-not-decision-choice`

```tcl
sp "example
    [ngs-match-goal <s> MyGoal <g>]
    [ngs-is-tagged <g> my-tag <my-tag>]
-->
"
```

### Testing macros (ngs-gt, ngs-stable-gt, etc.) <a id="testing macros"></a>
NGS includes macros for various kinds of tests, including numeric tests, equality tests, existence tests, etc.

Numeric comparison tests. Note that each test has a standard and stable version. The stable version does not rematch if the test result doesn't change, even if the specific values being tested change.
* `ngs-lt`, `ngs-lte`, `ngs-gt`, `ngs-gte`
* `stable-lt`, `stable-lte`, `stable-gt stable-gte`
* `ngs-gte-lt`, `ngs-gte-lte`
* `ngs-stable-gte-lt`, `ngs-stable-gte-lte`
* `ngs-ngt`, `ngs-ngte`, `ngs-nlt`, `ngs-nlte`

Equality tests. These produce standard Soar equality tests, but `ngs-neq` also handles cases where the specified attribute does not exist.
* `ngs-eq`, `ngs-neq`

Existence tests. These are equivalent to basic negations in Soar.
* `ngs-nex`, `ngs-tag-nex`

Miscellaneous:
* `ngs-this-not-that` : produces {<id1> <> <id2>}
* `ngs-cycle`, `ngs-cycle-gt`, `ngs-cycle-lt` : tests the cycle count on the input-link
* `ngs-time`, `ngs-time-range` : tests the time on the input-link

Note the `ngs-cycle*` and `ngs-time*` tests rely on your input system providing the appropriate values, as these are not built into Soar.

```tcl
sp "example
   [ngs-match-top-state <s> "target-value" <il>]
   [ngs-stable-gte <il> current-value <target-value>]
-->
"

# Expanded form:
sp "example
   (state <s> ^superstate nil)
   (<s> ^io.input-link <il>)
   (<s> ^target-value <target-value>)
  -{
     (<il> ^current-value < <target-value>)
   }
-->
"
```

### Logic macros (ngs-and, ngs-or, etc.) <a id="logic macros"></a>
NGS logic macros provide an easy way to construct complex conditions. They can be nested and also work with many other macros. Where necessary, they perform DeMorgan's for you (e.g., `ngs-or`).

* ngs-not (wraps specified arguments in a Soar group negation)
* ngs-or (uses DeMorgan's Law)
* ngs-and (often useful for passing into other macros)
* ngs-anyof (produces standard a Soar disjunction over constant values)

```tcl

# this example checks if value is one of two other values on some objects that are variabilized
sp "example
   [ngs-match-top-state <s>]
   [ngs-bind <s> value]
   [ngs-or [ngs-bind <s> object1.id:<value>] \
           [ngs-bind <s> object2.id:<value>]]
-->
"

# Expanded form:
sp {example
   (state <s> ^superstate nil)
   (<s> ^value <value>)
  -{
    -{
       (<s> ^object1 <object1>)
       (<object1> ^id <value>)
     }
    -{
       (<s> ^object2 <object2>)
       (<object2> ^id <value>)
     }
   }
-->
}
```

### Standard binding macros (e.g. ngs-input-link) <a id="standard binding macros"></a>
NGS includes a couple macros for easily binding to the I/O links. Note that these need to be used in conjunction with an `ngs-match-*` macro, as they do not bind to the state using the `state` keyword. Also note that `ngs-match-top-state` provides a means to match the I/O links directly, so you should not need to use these macros if you are already using `ngs-match-top-state`.

* `ngs-input-link`
* `ngs-output-link`

## NGS Goals <a id="goals"></a>

NGS stands for "New Goal System." Earlier versions of the NGS were primarily libraries for creating and managing goals on the top-state. NGS 4 retains and expands on these goal management capabilities.

NGS 4 supports multiple simultaneous goal trees, or goal forests. This means that a model built using NGS 4 can explicitly represent and pursue multiple goals at the same time; however, only one action can be taken at a time due to Soar's decision bottleneck. When multiple goals and goal forests are pursued at the same time, the actions taken to achieve these goals are interleaved.

### NGS Goal Pools

NGS stores goals in a pool on the top-state. The structure of this pool is as follows:

```
top-state
^ goals
^^ <goal-index>
^^^ goal
```

The <goal-index> is  a sub-pool where goals that share the same index value are stored. Goals are indexed as follows:
* Their most-derived type. When goals are created, they are placed in the pool indexed by their most derived type. 
* Their sub-types. Goals are shallow copied into pools based on their base types (all of them).
* Their declared decisions. When goals are being used to make explicit decisions (see ###), they are also shallow copied into pools based on their requested decisions.

These indices ensure that goal pools stay small (increasing match speed) and for flexibility and generality in how goals can be referenced.

There are several ngs-match productions that are used when creating and/or matching goals in the goal pool. They are as follows:
* **ngs-match-goalpool**: used when creating a goal (you need a reference to the correct goal pool to create the goal and this macro binds to that pool).
* **ngs-match-goal**: use to match to an existing goal in a pool
* **ngs-match-goal-to-create-subgoal**: use to match to an existing goal for which you want to create a subgoal.
* **ngs-match-active-goal**: use to match to a goal that is active in a Soar sub-state (see DECIDE operators ### and Decision Goals ###).

You should *never* try to bind directly to the goal pool (e.g. using ngs-bind), but rather, should always use one of the ngs-match productions to bind to the pool. This restriction ensures that if the goal pool implementation changes in the future, your code will not break.

### NGS Goal Structure and Default Behaviors

NGS Goals are typed objects and share the same basic structure as all other typed objects. Additionally, goals can have the following standard attributes:

```
# Goal specific attributes
<goal-id>
  ^supergoal								# If this is the subgoal of another goal
  ^subgoal									# If this goal has subgoal(s) - multi-valued
  ^type $NGS_GB_ACHIEVE | $NGS_GB_MAINT   	# Specify achievement/maintenance goals
  ^__tagged*ngs*$NGS_GS_ACHIEVED            # If the goal is achieved
  ^__tagged*ngs*$NGS_GS_ACTIVE				# If the goal is active in a sub-state
```

Note that you never directly create or remove these attributes, but rather they are created and removed through NGS macros and/or default productions.

Goals must be declared using the NGS_DeclareGoal macro. If you do not declare your goals, the productions required to process your goals will not exist, and your model will not run correctly.

```
# Declares a goal, creating default productions
NGS_DeclareGoal MyBaseGoalType					

# A goal that inherits from other types
NGS_DeclareGoal MyDerivedGoalType {
   type { MyBaseGoalType }
}

# A goal that inherits from other types and adds some default attributes
# Notice we have to explicitly define all base types (NGS 4 does not look up
#  the base types and automatically do this for you)
NGS_DeclareGoal MyDerivedGoalType2 {
   type { MyBaseGoalType MyDerivedGoalType }
   attribute1 "default-val"
   attribute2 5.0
}
```

This macro expands into several productions that maintain the goal pool associated with goals of this type. These productions also manage the subgoal/supergoal links, propagate achievement flags, remove achieved goals, and maintain goal decision info (see ###).

Goals of type $NGS_GB_ACHIEVE will automatically be removed if they are marked as achieved (see `ngs-tag-goal-achieved`). Your code is responsible for tagging goals as achieved, but the NGS library will clean up these achieved goals automatically, if they are o-supported. When achieved goals form a hierarchy, achievement of a goal higher in the hierarchy will cause all goals lower in the hierarchy to be automatically removed.

Alternatively, you can i-support your goals, in which case the LHS logic of your goal creation productions should include the achievement condition so that the goal will automatically retract when it is achieved.

Goal subgoal/supergoal links are automatically created and maintained by the NGS macros. You do not need to manage these other than to pass the correct parameters to macros such as `ngs-create-goal-by-operator` or `ngs-create-goal-in-place`.

### Creating and Removing Goals

Goals can be created in three different ways depending on how you intend to build and maintain your goal hierarchy

**Creating I-Supported Goal**

**Creating O-Supported Goals**

**Creating and Returning Goals in Substates**

**Removing O-Supported Goals**


### Matching and Binding to Goals

### "Active" Goals
___




* BM (I've started it already): Common actions (atomic operators)
 * Typed Objects
 * Atomic Values and Shallow Links
 * Tags
 * Removing objects
 * Operator side effects
* JC: Goal basics
 * The goal pool and indexing
 * Default goal behaviors (e.g achievement)
 * Goal declaration
 * Creating goals
 * Removing goals
 * Goal matching
 * "Active" goal
 * Common goal tags

* JC: Decide Operators
 * "Calling" a decide operator (parameters, return value definition)
 * Matching the "active" goal
 * Return values generation
 * Return value processing
 * Justifications (for i-supported justifications)
* BM: Annotating operators
* JC: Decision Goals
 * Structure of a decision
 * Requesting a decision
 * Assigning a decision
 * Making a choice
 * Applying the choice
 * Other supporting macros
* BM: Output processing
* JC: Future Additions
 * Robust types and type checking
 * Decision variable pools
 * Logical binning support
 * Support for semantic memory and episodic memory queries


 





 


