Interface := Object clone do(

  # define messages accepted by objects implementing this interface
  define := method(
    # TODO: defer evaluation of argument types until required
    # This way, we can have cross references
    arg := call message argAt(0)
    while(arg != nil,
      arg name print
      arg argsEvaluatedIn(call sender) foreach(a,
        " " print
        a type print
      )
      "" println
      arg := arg nextIgnoreEndOfLines
    )
    self
  )
  
  # When true, any message can be sent to objects implementing this interface
  setAllowAnyCall := method(bool,
    self
  )

)

Object cast := method(interface,
  # cast the object to another interface
  self
)

#
# Declare interfaces
#

iAny := Interface clone setAllowAnyCall(true)

iString := Interface clone define(
)

iCanBeDebugged := Interface clone define(
  tostring(iString)
  print()
  println()
)

#
# Declare objects implementing interfaces
#
# (Runtime check of interface compliance, raise errors such as missing methods.
#  Check that the calls in the method's body respect the interfaces.)

# String implements(iString)


