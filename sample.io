Interface := Object clone do(

  init := method(
    self acceptedMessages := self acceptedMessages clone
  )

  interfaceName ::= "i"

  # List of accepted messages
  acceptedMessages := list()

  # define messages accepted by objects implementing this interface
  define := method(name,
    setInterfaceName(name)
    # TODO: defer evaluation of argument types until required
    # This way, we can have cross references
    arg := call message argAt(1)
    while(arg != nil,
      msg := list(arg name)
      arg argsEvaluatedIn(call sender) foreach(a, msg append(a))
      acceptedMessages append(msg)
      arg := arg nextIgnoreEndOfLines
    )
    self
  )
  
  # When non nil, any message can be sent to objects implementing this interface
  # This contains the default result interface for the default calls
  allowAnyCall ::= nil
  
  # When true, this interface should never be implemented
  neverFound ::= false
  
  # Does the interface understand the message
  # name: the name of the message
  # args: the input argument interfaces
  # Return the interface of the return value, or nil
  hasMessage := method(name, args,
    if(allowAnyCall) then(
      return(anyCallResult(name, args))
    ) else(
      acceptedMessages foreach(msg,
        if((msg first == name) && (msg slice(2) == args)) then(
          return(msg at(1))
        )
      )
    )
    return nil
  )
  
  anyCallResult := method(name, args, allowAnyCall)
  
  # Check object obj according to this interface
  checkObject := method(obj,
    acceptedMessages foreach(msg,
      checkObjectMessage(obj, msg at(0), msg at(1), msg slice(2))
    )
    self
  )
  
  # Check an object obj respond to the message named name, returning
  # returnInterface and taking args (a list of interfaces)
  # Raise an exception on failure
  checkObjectMessage := method(obj, slotname, returnInterface, args,
    # Find the message implementation
    code := obj getSlot(slotname) message
    obj getSlot(slotname) println
    # Iterate over all instructions, and check each instruction is legal
    checkMessage(code, obj interfaces)
    self
  )
  
  # Check a message object given the receiver implements a list of interfaces
  checkMessage := method(code, interfaces
    while(code != nil,
      if(code isEndOfLine) then(
        "" println
      ) else(
        (" " .. code name .. "(" .. code arguments map(i, i asString) join(", ") .. ")") print
      )
      code := code next
    )
  )
  
  asString := method(
    interfaceName .. "(" .. acceptedMessages map(i, i first) join(", ")  .. ")"
  )

)

Object do(

  localInterfaces := list()

  # List of implemented interfaces
  interfaces := method(
    l := localInterfaces clone
    protos foreach(p,
      iflist := p interfaces
      if(iflist != nil) then(
        iflist foreach(i,
          l contains(i) ifFalse(l append(i))
        )
      )
    )
    return l
  )

  # Declare the current object implements interface
  # TODO: accept vararg to append all interfaces first, check all afterwards
  implements := method(interface,
    interfaces contains(interface) ifFalse(
      localInterfaces append(interface)
      interface checkObject(self)
    )
  )

  cast := method(interface,
    interfaces contains(interface) ifFalse(
      Exception raise("Casting to unsupported interface " .. interface)
    )
    self
  )
  
  force_cast := method(interface,
    self
  )

)

#
# Declare interfaces
#
#
# iNone:  always return an object which doesn't accept any call (return iError)
# iAny:   always return an object accepting any call (calls returns iNone)
# iNever: never returning interface, normal programming flow
# iError: never returning interface because of a programming error
#
# iExact(o):    interface for the object o (identity check)
# iMaybe(i):    may return at most once with i
# iMultiple(i): may never return or return multiple times with i
# iSymbol():    non evaluated code
# iParam():     new parametric interface
# iCode(i):     code evaluated in context of i
#

iNone  := Interface clone setInterfaceName("iNone")
iAny   := Interface clone setInterfaceName("iAny")   setAllowAnyCall(iNone)
iNever := Interface clone setInterfaceName("iNever") setNeverFound(true)

iString := Interface clone define("iString"
)

iCanBeDebugged := Interface clone define("iCanBeDebugged",
  asString(iString)
  print()
  println()
)

#
# Declare objects implementing interfaces
#
# (Runtime check of interface compliance, raise errors such as missing methods.
#  Check that the calls in the method's body respect the interfaces.)

Object implements(iCanBeDebugged)
String implements(iString)

# Checks are done by evaluating all slots of all managed objects. Interface are
# matched with each other and compatibility is checked. Parametric interfaces
# are bound to producer and consumer interfaces. The graph of parametric
# interfaces is then reduced until all producers and consumers are non
# parametric. Then compatibility is checked between producers and consumers.

# Flow control with return is checked using parametric interfaces. return is a
# continuation having a parametric type.

# call-with-current-continuation is implemented as:
#
# A := iParam
# CodeInterface := Interface clone do(
#   parent(iObject)
#   slot("continuation", iNever, A)
# )
# slot("call-cc", iMultiple(A), iCode(CodeInterface))
#
# call-cc takes a code block and returns a parameter A. The code block takes
# code evaluated in an object having the "continuation" slot. This slot takes
# a parameter A identical to the one returned by call-cc and never returns.
# 
#


