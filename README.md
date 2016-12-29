# NGS 4.x Developer Guide

## Table of Contents
1. [Introduction](#introduction)
1. [Installation and Configuration](#installation)
1. [The Basic Structure of NGS Code](#structure)
1. [The Structure of Working Memory](#workingmemory)
1. [Production Left Hand Sides](#lhs)
1. [Common actions](#actions)
1. [NGS Goals](#goals)
1. [Decide Operators](#decide)

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
2. Unzip and put files into your project. We recommend putting the NGS directory at the top level of your agent (as siblings to the agent's root Soar file).
	* The easiest way to do this is to simply add NGS 4.0 to your project's repository. It's not large and probably won't update often. If an update is released, you can simply replace the entire NGS directory with the new version.
3. Source NGS from your root Soar file before any other commands that use NGS or source files that use NGS (in practice, this typically is at the top of the file):

```tcl
source "ngs-4_0_0/load.soar"
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
1. **Tags**: Tags are WMEs that follow a standard naming convention for the attribute. All tag names in NGS 4 are prefixed with __tagged\*ngs\*. NGS provides many macro specializations for working with tags.

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
* ngs-create-typed-object: Used to create a new i-supported typed object and any sub-structure under that object.
* ngs-create-typed-sub-object-by-operator: Used to create sub-structure under objects that you create using ngs-create-typed-object-by-operator.

### Atomic Values and Shallow Links

### Tags

### Removing Objects, Atomic Values, and Tags

### Operator Side Effects

## Production Left Hand Sides <a id="lhs"></a>

NGS provides a number of macros for creating LHS conditions in rules. With these, you should never have to write raw Soar code. The macros generate straightforward code, but do so in a way that tends to be more compact and is easier to read, in part because the macros give a name to the function being performed by the block of conditions they generate. This section will give an overview of the available macros, but for the full set and description, see [macros/lhs-fragments.tcl](macros/lhs-fragments.tcl)
 
### ngs-match-* <a id="ngs-match"></a>
The `ngs-match-*` macros generate productions for matching on specific parts of working memory. All macros include state testing already; the first argument is always the state. Thus, you probably always want to start a rule with an `ngs-match-*` macro of some kind. For example, `ngs-match-top-state` or `ngs-match-substate`. 

`ngs-match-top-state` matches on the top state, binding it to a specified Soar variable. It can optionally also bind on the input-link, output-link, and other bindings. This kind of pattern (some required parameters, and some optional) is common throughout the NGS macros. Some examples:

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

See [here](#goals) for more information about how to use NGS goals.

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
   (state <s> ^superstate nil)
   (<s>       ^io.input-link <il>)
   (<il>      ^system <system>)
   (<system>  ^time <time>)
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
   (state <s> ^superstate nil)
   (<s>       ^io.input-link <il>)
   (<il>      ^system <sys>)
   (<sys>     ^time <my-time>)
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

You can also specify multiple paths from the same root in one line by separating them with whitespace, like this:

```tcl
sp "example
   [ngs-match-top-state <s> "" <il>]
   [ngs-bind <il> a.b c.d]
-->
"

# Expanded form:
sp {example
   (state <s> ^superstate nil
              ^io.input-link <il>)
   (<il> ^a <a>
         ^c <c>)
   (<a> ^b <b>)
   (<c> ^d <d>)
-->
}
```

Note you can also use `ngs-bind` syntax in some other macros; for example, the optional second parameter to `ngs-match-top-state`:

```tcl
sp "example
   [ngs-match-top-state <s> "a.b c.d"]
-->
"

Expanded form:
sp {example
   (state <s> ^superstate nil
              ^a <a>
              ^c <c>)
   (<a> ^b <b>)
   (<c> ^d <d>)
-->
}
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

Here's an example showing how you can use `ngs-and` and `ngs-not` nested inside an `ngs-or`:

```tcl
sp "example
   [ngs-match-top-state <s>]
   [ngs-bind <s> value]
   [ngs-or [ngs-and [ngs-bind <s> object1.id:<value>]  \
                    [ngs-bind <s> object2.id:<value>]] \
           [ngs-not [ngs-bind <s> object3.id:<value>]  \
                    [ngs-bind <s> object4.id:<value>]]]
                 
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
       (<s> ^object2 <object2>)
       (<object2> ^id <value>)
     }
    -{
      -{ 
         (<s> ^object3 <object3>)
         (<object3> ^id <value>)
         (<s> ^object4 <object4>)
         (<object4> ^id <value>)
       }
     }
   }              
-->
}
```

### Standard binding macros (e.g. ngs-input-link) <a id="standard binding macros"></a>
NGS includes a couple macros for easily binding to the I/O links. Note that these need to be used in conjunction with an `ngs-match-*` macro, as they do not bind to the state using the `state` keyword. Also note that `ngs-match-top-state` provides a means to match the I/O links directly, so you should not need to use these macros if you are already using `ngs-match-top-state`.

* `ngs-input-link`
* `ngs-output-link`

## Common actions <a id="actions"></a>

An NGS typed object is a set of WMEs that share the same root id (i.e. left hand id in the WME structure). They are conceptually identical to plain old data structures in object-oriented languages. Each WME can point to either the root of another typed object, or to an atomic value (a number or a string).

```
<root-id>
  ^__tagged*ngs*constructed *yes*
  ^__tagged*ngs*i-supported *yes*   # If i-supported only
  ^my-type 							# Most Derived Type (always only one)
  ^type 						    # Most Derived Type
  ^type 							# Base Type(s), if any
  ^<user-defined-attribute-1>       # Any of these you create
```

### Typed Objects

Typed objects are collections of WMEs that share the same left-most identifier. They are identical to "plain old data structures" in object oriented programming. NGS typed objects are created using one of the following macros:
* `ngs-create-typed-object-by-operator`: Used to create a new, o-supported, typed object.
* `ngs-create-typed-object`: Used to create a new i-supported typed object and any sub-structure under that object.
* `ngs-create-typed-sub-object-by-operator`: Used to create sub-structure under objects that you create using ngs-create-typed-object-by-operator.

Here's an example of creating an o-supported typed object. Note you don't have to write the apply rule (application is handled for you internally). Note that by default, this will replace any existing object. If you wish to add to a multi-attribute set, pass `NGS_ADD_TO_SET` as the last parameter to `ngs-create-typed-object-by-operator`. By default the operator preferences are `+ =`, but this can also be overridden.
```tcl
# When creating a typed object, you must first declare the object type
# This specifies an (optional) list of attribute/values to create by default when creating an object of this type
# The specific values can be overridden in ngs-create-typed-object-by-operator if desired 
NGS_DeclareType MyObjectType {my-string foo my-number 12}

# This is an operator proposal for creating a typed object
# Here we use the default attribute/values specified by the object declaration, and add another attribute value
sp "example
   [ngs-match-top-state <s>]
   [ngs-nex <s> my-object] # so the operator proposal goes away after the object is created
-->
   # note the first <s> is the state to propose the operator on, and the second is the parent id of the object
   # in this simple example, they just happen to be the same thing
   [ngs-create-typed-object-by-operator <s> <s> my-object MyObjectType <myobj> { another-attr another-val }]
"

# In the Soar debugger trace, you will see something like this when the operator is selected:
#     1:    O: O1 (create-MyObjectType--S1--my-object--M1)

# This will create an object in working memory that looks like this:

(S1 ^__tagged*ngs*constructed *yes*
    ^my-object T1)
  (T1 ^__tagged*ngs*constructed *yes*
      ^another-attr another-val
      ^my-number 12
      ^my-string foo
      ^my-type MyObjectType
      ^type MyObjectType)
```

If you wish to create deeper objects, you can combine `ngs-create-typed-object-by-operator` with `ngs-create-typed-sub-object-by-operator`. However, note that currently this is limited to 5 levels deep (you will get a warning if you try to go deeper):
```tcl
NGS_DeclareType MyObjectType {my-string foo my-number 12}
NGS_DeclareType MyObjectType2 {}
sp "example
   [ngs-match-top-state <s>]
   [ngs-nex <s> my-object] # so the operator proposal goes away after the object is created
-->
   [ngs-create-typed-object-by-operator <s> <s> my-object MyObjectType <myobj> { another-attr another-val }]
   [ngs-create-typed-sub-object-by-operator <myobj> next-level MyObjectType2 <myobj2> { deeper-attr deeper-val }]
"

# This will create an object in working memory that looks like this:
(S1 ^__tagged*ngs*constructed *yes*
    ^my-object T1)
  (T1 ^__tagged*ngs*constructed *yes*
      ^another-attr another-val
      ^my-number 12
      ^my-string foo
      ^my-type MyObjectType
      ^type MyObjectType
      ^next-level N1)
    (N1 ^__tagged*ngs*constructed *yes*
        ^deeper-attr deeper-val
        ^my-type MyObjectType2
        ^type MyObjectType2
  
```

If you wish to create an i-supported typed object, the process is similar:
```tcl
NGS_DeclareType MyObjectType {my-string foo my-number 12}

# This is an elaboration rule
# Here we use the default attribute/values specified by the object declaration, and add another attribute value
sp "example
   [ngs-match-top-state <s>]
-->
   [ngs-create-typed-object <s> my-object MyObjectType <myobj> { another-attr another-val }]
"

# This will create an object in working memory that looks like this:
(S1 ^__tagged*ngs*constructed *yes*
    ^my-object M1)
  (M1 ^__tagged*ngs*constructed *yes*
      ^__tagged*ngs*i-supported *yes*
      ^another-attr another-val
      ^my-number 12
      ^my-string foo
      ^my-type MyObjectType
      ^type MyObjectType)
```

### Atomic Values and Shallow Links

Atomic values are the values supported by Soar - integers, floats, strings, and ids. These are created via `ngs-create-attribute-by-operator`. This can be used to add simple attribute/values to existing objects, and also to create a shallow link from one object to another. Note there is a `ngs-create-attribute` macro, but users should rarely need to use it.

As with object creation, optional arguments allow the creation of multi-valued attributes and control over the operator preferences.
```tcl
sp "example
   [ngs-match-top-state <s>]
   [ngs-nex <s> foo]
-->
   [ngs-create-attribute-by-operator <s> <s> foo bar]
"

# Working memory will then look like this:
(S1 ^__tagged*ngs*constructed *yes*
    ^foo bar)
```

## Deep copy
If you wish to create a complete o-supported copy of an object (typically something off the input-link), you must use `ngs-deep-copy-by-operator`. Any other method will result in i-supported objects.

```tcl
sp "example
   [ngs-match-top-state <s> "" <il>]
   [ngs-bind <il> some.object]
-->
   [ngs-deep-copy-by-operator <s> <s> my-copy <object> ]
"
```

### Tags

Object tagging provides a way to annotate objects with information about how that object is being processed, without polluting the object's attribute name space. Tags are WMEs that follow a standard naming convention for the attribute; namely, they are prefixed with `__tagged*ngs*`. Internally, NGS uses them to track the state of goals and objects, but you can also use your own tags for tracking whatever you like. By default, tags get the value `$NGS_YES`, but you can override this if desired. Available macros include:

* `ngs-tag`: Creates an i-supported tag.
* `ngs-create-tag-by-operator`: Creates an i-supported tag.
* `ngs-remove-tag-by-operator`: Removes an o-supported tag.

Example:
```tcl
sp "example
   [ngs-match-top-state <s> "some-object"]
   [ngs-lt <some-object> number 0]
-->
   [ngs-tag <some-object> is-negative]
"

# This expands to:
sp {example
   (state <s> ^superstate nil)
                  (<s> ^some-object <some-object>)
   (<some-object> ^number < 0)
-->
   (<some-object> ^__tagged*is-negative *yes* +)
}
```
 
### Removing attributes and objects
If you wish to remove an attribute or object, you can use one of these macros:
* `ngs-remove-attribute`: i-supported attribute removal.
* `ngs-remove-attribute-by-operator`: o-supported attribute removal.

Note: if you wish to remove a tag, do not use these; use `ngs-remove-tag-by-operator`.
Note: if you wish to remove a goal, do not use these; see [NGS Goals](#goals).

At the moment, `ngs-remove-attribute` is actually more verbose than raw Soar code. However, in the future, it may perform type-checking or other processing, so using it over raw Soar code is still recommended.

Example:
```tcl
sp "example
   [ngs-match-top-state <s> my-object]
-->
   [ngs-remove-attribute-by-operator <s> <s> my-object <my-object>]
"
```

You can actually combine this with the example of typed object creation above to create an agent that just adds and removes this object forever (this probably isn't directly, but just demonstrates how easy it is):

```tcl
NGS_DeclareType MyObjectType {my-string foo my-number 12}

sp "example
   [ngs-match-top-state <s>]
   [ngs-nex <s> my-object] # so the operator proposal goes away after the object is created
-->
   [ngs-create-typed-object-by-operator <s> <s> my-object MyObjectType <myobj> { another-attr another-val }]
"

sp "example2
   [ngs-match-top-state <s> my-object]
-->
   [ngs-remove-attribute-by-operator <s> <s> my-object <my-object>]
"
```

### Operator side effects
A side effect is an additional primitive action that can be taken for most operators (i.e., creation or removal of a wme). They are typically used to set tags, add an attribute, or create links to objects. Note there is a separate macro for creating tag side effects:

* `ngs-add-primitive-side-effect`
* `ngs-add-tag-side-effect`

Side effects can be difficult to debug, so use wisely.

Side effects can be combined with the following other macros:
* `ngs-create-typed-object-by-operator`
* `ngs-create-goal-by-operator`
* `ngs-create-goal-as-return-value`
* `ngs-create-attribute-by-operator`
* `ngs-create-tag-by-operator`
* `ngs-create-typed-object-for-ret-val`
* `ngs-set-ret-val-by-operator`
* `ngs-make-choice-by-operator`
* `ngs-deep-copy-by-operator`
* `ngs-create-output-command-by-operator`
* `ngs-remove-attribute-by-operator`
* `ngs-remove-tag-by-operator`

Example:
```tcl
NGS_DeclareType MyObjectType {my-string foo my-number 12}

sp "example
   [ngs-match-top-state <s>]
   [ngs-nex <s> my-object]
-->
   [ngs-create-typed-object-by-operator <s> <s> my-object MyObjectType <myobj> { another-attr another-val }]
   [ngs-add-tag-side-effect $NGS_SIDE_EFFECT_ADD <s> created-my-object]
"

# Assuming there was already a "links" object on the top-state, working memory would look like this:
(S1 ^__tagged*ngs*constructed *yes*
    ^__tagged*created-my-object *yes*
    ^my-object T1)
  (T1 ^__tagged*ngs*constructed *yes*
      ^another-attr another-val
      ^my-number 12
      ^my-string foo
      ^my-type MyObjectType
      ^type MyObjectType)
```

Note that you cannot reference an object that you're creating in the side effect action. If you want to do something like create another link to the object you are creating, you'll need to write a separate rule.

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
* Their declared decisions. When goals are being used to make explicit decisions (see [Decide Operators](#decide)), they are also shallow copied into pools based on their requested decisions.

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
  ^__tagged*ngs*$NGS_GS_ACHIEVED			# If the goal is achieved
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

This macro expands into several productions that maintain the goal pool associated with goals of this type. These productions also manage the subgoal/supergoal links, propagate achievement flags, remove achieved goals, and maintain goal decision info (see [Decide Operators](#decide)).

Goals of type `$NGS_GB_ACHIEVE` will automatically be removed if they are marked as achieved (see `ngs-tag-goal-achieved`). Your code is responsible for tagging goals as achieved, but the NGS library will clean up these achieved goals automatically, if they are o-supported. When achieved goals form a hierarchy, achievement of a goal higher in the hierarchy will cause all goals lower in the hierarchy to be automatically removed.

Alternatively, you can i-support your goals, in which case the LHS logic of your goal creation productions should include the achievement condition such that the goal will automatically retract when it is achieved.

Goal subgoal/supergoal links are automatically created and maintained by the NGS macros. You do not need to manage these other than to pass the correct parameters to macros such as `ngs-create-goal-by-operator` or `ngs-create-goal-in-place`.

### Creating and Removing Goals

Goals can be created in three different ways depending on how you intend to build and maintain your goal hierarchy.

* **I-Supported Goals**: I-Supported goals use Soar's truth maintenance to instantiate and retract goals when the are applicable. I-Supported goal hierarchies are great for enabling reactivity and for ensuring logical consistency among goals. I-Supported goals mimic some of the support structure of the traditional Soar state stack where the state stack is supported by a hierarchy of operator proposals which, by Soar's architecture constraints, are always i-supported.
* **O-Supported Goals**: O-Supported goals are constructed and removed through operator applications. O-Supported goals can be used as a way to avoid some types of oscillations that can occur when input values change rapidly. O-Supported goals could also be used to generate plans in a planning system.
* **O-Supported Goals as Return Values**: A special case of o-supported goal is a goal that is created in a sub-state. These goals are best as o-supported structures due to the fact that they will depend on values available in the sub-state (which goes away after processing). To support the process of return goals from sub-states, NGS provides special macros to create goals as return values.

**Limitation**: There is currently no way to construct a goal in a "latent" state (i.e. a state where it isn't in a goal pool) and then activate it (i.e. move it to the goal pool) later. This type of creation/activation process could be helpful for planning process that might create goals and later activate them.

(**NOTE**: The actual support of a value returned from a sub-state is determined by the _justification_ that Soar creates to support the value that is created. The vast majority of cases will likely get O-Support, even if you use an I-Supported rule to create the result. See the Soar Manual for more details.).

**Creating I-Supported Goal**

An I-supported goal is instantiated when the goal is not achieved and retracts (using Soar's i-support mechanism) when the goal is achieved. I-supported goals provide a very powerful way to maintain a reactive behavior model with relatively little code. 

To create an i-supported goal, using the following macro on the right hand side of an i-supported production:

```
[ngs-create-goal-in-place <goal-pool> MyGoalType $NGS_GB_ACHIEVE <new-goal> <supergoal> { goal-attr-1 val1 goal-attr-2 val2 ... }]
```
Goal creation macros require a variable bound to the goal pool (here shown as <goal-pool>). This variable can be bound using the following match macros:

* ngs-match-goalpool
* ngs-match-goal-to-create-subgoal

The version you use depends on whether you are creating a stand-alone goal (`ngs-match-goalpool`) or a sub-goal of another goal (`ngs-match-goal-to-create-subgoal`). The following is an example of each case:

```
# Standalone goal construction
sp "achieve-message-handled*trigger*any-message
	[ngs-match-goalpool <s> <goals> AchieveMessageHandled]
	[ngs-input-link <s> <il> message-queue.message]
-->
	[ngs-create-goal-in-place <goals> AchieveMessageHandled $NGS_GB_ACHIEVE <goal> {} { message <message> }]"

# Subgoal construction example
sp "achieve-modified-wedge-formation*trigger*for-maneuver-task
	[ngs-match-goal-to-create-subgoal <s> AchieveManeuverTask <sg> AchieveModifiedWedgeFormation <goals>]
	... (additional bindings)
-->
	[ngs-create-goal-in-place <goals> AchieveModifiedWedgeFormation $NGS_GB_ACHIEVE <g> <sg>]
	... (additional construction code)"
``` 

Notice in the second example that two goal types are provided. The first goal type is the type of the _supergoal_ while the second goal type is the type of the goal you want to create. Because the production itself is constructing the goal, the last parameter of ngs-match-goal-to-create-subgoal is an identifier to the goalpool for this second goal type. This goal pool identifier (here, `<goals>`) is used in the right hand side to construct the goal.

**Creating and Removing O-Supported Goals**

To create an o-supported goal use the following macro on the right hand side of a production.

```
[ngs-create-goal-by-operator <state> MyGoalType $NGS_GB_ACHIEVE <new-goal> <supergoal> { goal-attr-1 val1 goal-attr-2 val2 ... } preferences]
```

Because the production creates an operator, its right-hand side changes will be o-supported (more accurately, NGS creates the goal via an operator apply behind the scenes). Unlike with the i-supported version, you do not have to bind to the goal pool on the left hand side. The operator application productions in the NGS library do that for you.  Here is how the two i-supported productions above might look if they used o-supported goals:

```
# Standalone goal construction
sp "achieve-message-handled*trigger*any-message*o-supported
	[ngs-match-top-state <s> {} <il>]
	[ngs-bind <il> message-queue.message]
-->
	[ngs-create-goal-by-operator AchieveMessageHandled $NGS_GB_ACHIEVE <goal> {} { message <message> }]"

# Subgoal construction example
sp "achieve-modified-wedge-formation*trigger*for-maneuver-task*o-supported
	[ngs-match-goal <s> AchieveManeuverTask <sg>]
	... (additional bindings)
-->
	[ngs-create-goal-by-operator AchieveModifiedWedgeFormation $NGS_GB_ACHIEVE <g> <sg>]
	... (additional construction code)"

```

Notice the different match macros used when creating o-supported v. i-supported goals. In the first case, there is no need to bind to a goal pool. Instead the more general `ngs-match-top-state` is used (though other match macros can be used, if desired).  In the second case, we only need to bind to the goal that will be the new goal's supergoal (not to the new goal's pool). So we use `ngs-match-goal` to bind the supergoal instead of `ngs-match-goal-to-create-subgoal`.

_O-supported Goal Removal_

O-supported goals must be removed deliberately (i.e. by operators) when they are no longer applicable. There are two ways to do this, depending on the type of goal that is created.

To remove an **achievement goal** (i.e. one that should only exist while it is not met) use the `ngs-tag-goal-achieved` macro on the right hand side of any production (i-supported or o-supported). The NGS library will automatically propose an operator to remove the achieved goal, and will remove all sub-goals of the achieved goal.

Maintenance goals are not necessarily supposed to go away when they are achieved and the NGS does NOT automatically remove them. To remove a **maintenance goal**, use the macro `ngs-remove-goal-by-operator` on the right hand side of a production. This macro will create an operator to remove the goal. Just as is the case for operator-based goal creation, you do not need to bind to or pass the goal pool in which the goal resides.

**Creating and Returning Goals in Substates**

There are two ways to create goals in substates. First, the standard o-supported process (discussed above) can be used. In this case, a goal is immediately placed in the goal pool and is available for matching using the ngs goal match macros (e.g. `ngs-match-goal`). The potential issue with this approach is that goal creation is likely to trigger other actions which might interrupt the execution of the sub-state. If this type of behavior is desired, then it can be achieved using NGS.

However, in most cases it is better for agent robustness to delay the construction of the goal until the sub-state completes processing (i.e. it returns). NGS provides macros to make this process simple.

To create a goal that will be placed in the goal pool after a substate completes execution, simply construct the goal using the following macro:

```
[ngs-create-goal-as-return-value <state> MyGoalType $NGS_GB_ACHIEVE <new-goal> <supergoal> { goal-attr-1 val1 goal-attr-2 val2 ... } preferences]
```

The parameters are identical to `ngs-create-goal-by-operator` with the only difference being the behavior of the operator that it creates. Rather than placing the goal immediately into the goal pool, it will place in the sub-state's return value set. Then, when the sub-state completes and its values are returned, NGS library productions will copy the goal into the goal pool at the same time the rest of the return values are set.

Because goals returned from sub-state using this method are o-supported, you will need to ensure these goals get removed through one of the removal methods discussed for o-supported goals above.

### Matching and Binding to Goals

Goals define the context for agent behavior and, as such, often are the trigger and key matching object in a production. NGS has several macros to support matching goals in common contexts.  We divide our discussion of these macros across three common use cases:

* Matching goals in the top state. Typically this is done to trigger actions and to create sub-goals.
* Matching goals in sub-states. Typically this is done to trigger a multi-step process when using Decide Operators (see [Decide Operators](#decide) below).
* Matching a special category of goal call "Decision Goals." These goals are discussed in a separate section ([Decide Operators](#decide)).

#### Top-state Goal Matching

When creating an isolated, i-supported goal on the top state, you should start your production with the following macro:

```
[ngs-match-goalpool <s> <goal-pool> MyGoalType]
```

This macro will bind to the goal pool of the given type (here MyGoalType). You can then pass the `<goal-pool>` variable to `ngs-created-goal-in-place` to create the goal. 

Two other macros can be used for productions that need to bind to existing goals. First is `ngs-match-goal`:

```
[ngs-match-goal <s> MyGoalType <g>]
```

This macro is used frequently as the primary way to create productions to only fire in support of a goal.

To create an i-supported sub-goal, use the `ngs-match-goal-to-create-subgoal` macro, which provides a convenient way to bind both to the supergoal instances and to the subgoal pool.

```
[ngs-match-goal-to-create-subgoal <s> SuperGoalType <supergoal> SubGoalType <subgoal-pool>]
```

The `<subgoal-pool>` variable should be passed as the goal pool identifier to the `ngs-create-goal-in-place` macro on the right hand side of the production that creates the sub-goal.  The `<supergoal>` variable is passed as the supergoal identifier.

## Decide Operators, Active Goals and Decision Goals <a id="decide"></a>

For most behavior models, the decision they make are the centerpiece of the model. Because decisions are so important and central, NGS provides some support to make the decision making process simpler, less error prone, and most consistent. The key elements NGS defines to support decision making are as follows:

* **Decide Operators**: Decide operators are operators that are not applied. They result in an operator no-change and the creation of a sub-state. These operators are called "decide" operators because typically the purpose of a sub-state is to make a decision after considering options. However, sub-states can also be used to implement more traditional software sub-routines and functions and decide operators can be used for this purpose as well.
* **Active Goals**: An "active" goal is one that is attached to a decide operator. Essentially, an active goal is one that is being pursued through processes executing in the sub-state.
* **Decision Goals**: "Decision goals" is a term used to describe a specific way of organizing goal hierarchies to support decision making. Decision goals are just regular goals but with some additional data and processes associated with them to support making and maintaining a decision.  They are similar to operators, but persist even after the decision is made (unlike operators).
 
### Decide Operators

Decide operators are typically used in two ways:

1. To execute a connected process that should complete in "one step" (all or nothing)
1. To decide between multiple options. If this is your use case, consider using Decision Goals rather than decide operators directly. Decision goals use decide operators, but wrap them in a higher level abstraction which can make managing the decision easier.

A decide operator is simply an operator that is not intended to be applied directly.  It is intended to operator no-change, producing a Soar sub-state. Decide operators and the sub-states they produce contain some common structures which can be used by other productions that execute the process that the decide operator represents. 

The structure of a decide operator is as follows:

```
^ operator
^^ type            # NGS_OP_DECIDE
^^ name            # your name for the operator (the action/decision)
^^ goal            # becomes the "active" goal if this operator is selected
^^ return-values   # stores meta-information about the return values
```

Whether a sub-state makes a decision or executes a process, it must produce a result in order to be useful (with the exception of, perhaps, a sub-state used to print something to the console). A _result_ is any change to working memory that is reachable through a `superstate` WME. So for example, if a production adds the WME: `(S54 ^my-value 5)` to the sub-state S54, it is NOT creating a return value. However, if it adds the WME: `(G15 ^my-value *yes*)` to the goal G15 that is stored in the global NGS goal pool, the production IS creating a return value. 

Soar treats return values specially. All return values are associated with a _justification_ -- a production automatically created by the architecture based on the chain of WMEs that were tested in order to create the new value. The vast majority of cases will likely get O-Support, even if you use an I-Supported rule to create the result. Detailed discussion of justifications and how they impact the lifetime of return values is beyond the scope of this reference and the reader is referred to the Soar Manual for more information.

One potential issue with sub-states is that they can create return values at any time. These return values can, in turn, trigger other actions (e.g. operator proposals/retractions) that can interrupt the execution of the sub-state. Furthermore, even if these return values don't cause the sub-state to interrupt, updates to the input link could do the same thing. 

The former problem, i.e. one return value triggering an interruption, is typically a design flaw, but can be a pain to debug and fix.  The second problem, i.e. an input process triggering an interruption, is a fundamental characteristic and expected behavior in an asynchronous, real-time model.

This behavior is not a flaw in the Soar architecture, but rather a fundamental characteristic that can be very powerful if used correctly, but using it correctly can be challenging, even for experienced model builders.

NGS provides an abstraction and support macros to make sub-states easier to manage and use this type of reactivity correctly.

The core idea is that all return values should be executed _at the same time_ (or technically, during the same operator application wave). If consistently enforced, this constraint guarantees that if a sub-state is interrupted no partially implemented changes will be left dangling. In fact, if a sub-state is interrupted, it is as if that sub-state was never instantiated. If the cause of the interruption makes it unnecessary to execute that sub-state, then model continues executing without it. If it is still required, it begins executed from scratch again at some future decision cycle.

To help maintain this constraint, NGS creates the "return value" abstraction. Sub-states can return more than one value (which is why each requires a name) and can even return values that are generated in the code that creates the operator (this is useful mainly for process tagging). 

A return value is a 4-tuple consisting of the following:
* A name. Return value names form a sort of "definition" or "contract" between the code that creates (or calls) the decide operator and the code that executes the decide operator.
* A parent object (an object that will receive the return value)
* A parent attribute (the attribute that will receive the return value)
* A value (the return value itself - either an atomic value or the id of an object)

To make sub-states independent and modular, the production that creates a decide operator must specify the first three items -- the name, parent object, and parent attribute. These values are stored on the operator under the "return-values" attribute.

The "value" attribute is typically (though not always) created by the sub-state. Code that executes the sub-state creates the return value(s) and places them in a temporary holding location in the sub-state. In some cases, it is desirable to have a "fixed" return value - i.e., a return value that is decided on before the sub-state is executed but should only be set after the sub-state completes. The most common example of this is a flag that indicates the sub-state executed. In these cases, the code that creates the decide operator can provide a caller-defined return value (name, parent object, parent attribute, and value) that will be put in the return value storage area and copied to the destination (the parent object) when the sub-state returns.

NGS library code actually implements the return process as follows:
* Upon entering the sub-state, the NGS library proposes an operator named: `ngs-op-copy-return-values-to-destination`. 
* This operator is given least (<) preference such that as long other operators are proposed, it will not be selected. 
* Once other operators execute (presumably setting the return values), this operator is selected and its single apply production copies all return values to their associated parent objects/attributes in one step.

The one weakness of this approach is that it is possible for the sub-state to fail, the `ngs-op-copy-return-values-to-destination` to execute, and the sub-state to return after not actually doing what was intended. A later version of NGS may incorporate better handling (or at least error reporting) when this occurs. Currently, this is likely to cause a state no change in the sub-state because a failure in the sub-state will often prevent the retraction condition for the decide operator's proposal production from matching.

#### Creating a Decide Operator

Creating a decide operator is straightforward. Use the `ngs-create-decide-operator` macro as follows:

```
# Minimal decide operator creation example (no return values)
sp "sample*create-decide-operator
  [ngs-match-goal <s> MyGoalType <g>]
  [ngs-is-not-tagged <g> i-am-done-flag]
  ... (test some other things that trigger the decide operator)
-->
  [ngs-create-decide-operator <s> decide-operator-name <o> <return-values> <g> i-am-done-flag]"

```

This example shows a minimal construction for creating a decide operator.  

Decide operators have user-defined names (unlike atomic operators, which are named using an NGS-defined naming pattern). You can use this name to give the process and simple, human understandable label for the action being performed by the operator. This name is not used by NGS, but is likely to be used by your code that implements the sub-state.

Since sub-states almost always create at least one return values, the `ngs-create-decide-operator` macro constructs a return value set on the operator and provides a convenient binding to that set in the macro. In the next example, we will show how to use the variable bound to this set.

The next parameter is the decide operator's goal. _All_ decide operators are associated with a goal, which becomes the "active" goal when the operator is selected. The active goal is made directly available in the sub-state when the operator no changes. Because of this, almost all decide operator proposal productions will begin with `ngs-match-goal` or one of the other goal matching macros.

Finally, the `ngs-create-decide-operator` macro provides an optional parameter -- the name of a boolean tag that should be created on the active goal (`<g>` in this case) upon returning from the sub-state generated by the decide operator. This tag is typically used to force retraction of the operator that proposes the decide operator, after the operator execute (i.e. it signals that the system is done executing the sub-state).  Behind the scenes, NGS  creates a return value that creates this tag in the operators return value set. Since this action is so common, the steps to do it are abstracted.

Because most decide operators generate sub-states with at least one return value, most decide operator proposals a a bit more complex. Here, for example, is a production from a real model that proposes to handle a message that tells a vehicle to change formation.

```
sp "achieve-message-handled*propose*handle-change-formation-message
	[ngs-match-goal <s> AchieveMessageHandled <g>]
	[ngs-bind <s> robo-agent.current-commands]
	[ngs-bind <g> message!ChangeFormationMessage.payload]
	[ngs-is-not-tagged <g> message-copied]
-->
	[ngs-create-decide-operator <s> handle-formation-change-message <o> <ret-vals> <g> message-copied]
	[ngs-create-ret-val-in-place payload <ret-vals> <current-commands> change-formation]
	[ngs-tag <o> $RS_DEEP_COPY_MESSAGE]"
```

The first line and the last line of the left hand side follow the same pattern expressed in the first example. The `[ngs-bind <s> robo-agent.current-commands]` binds to the location where the return value (the message payload) should be placed after it is handled.  The `[ngs-bind <g> message!ChangeFormationMessage.payload]` defines the condition under which this should happen; i.e. when a message of type ChangeFormationMessage is received.

The key addition to the right hand side is the line:

```
[ngs-create-ret-val-in-place payload <ret-vals> <current-commands> change-formation]
```

The `ngs-create-ret-val-in-place` macro constructs a return value description on the operator. This description tells the sub-state code where to put the return value, which in this case is named `payload` (the first parameter to the macro). In English, this macro says to do the following:

Link the return value called "payload" to the object bound to `<current-commands>` under the attribute "change-formation".  The `<ret-vals>` variable is the same variable that is bound to the return value set in the `ngs-create-decide-operator` macro.

The `ngs-tag` statement is an additional parameter that the sub-state code will use to control the processing of the message.  Decide operators can have any number and type of parameters. These parameters are automatically copied to to the sub-state under the "params" attribute.


### "Active" Goals

NGS defines an "active" goal as one for which action is being taken in a substate. 

### Decision Goals

To be completed
___



* JC: Goal basics
 * The goal pool and indexing
 * Default goal behaviors (e.g achievement)
 * Goal declaration
 * Creating goals
 * Removing goals
 * Goal matchinge * "Active" goal
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


 





 



