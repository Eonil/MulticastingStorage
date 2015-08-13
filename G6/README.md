
Multicasting Storages
=====================
Interfaces are co-designed by Kangsan Lee and Hoon H..
This implementation is done soley by Hoon H.





Design Intentions
-----------------

-	Simplicity. No complex concepts. 
-	Shallower stack.
-	Intuitivity. (no implicit data transfer, notification only)
-	Thread safety. (limit execution into single thread)
-	Mutation safety. You cannot perform mutation from a mutation observer.
-	Only for scalar and vector storages. No set, map or anything else.

Longer code with simple concept is easier to write, read and maintain
then shorter code with complex concept. Also, no set or dictionary data-type
support. Because I couldn't imagine any other cases that I need more than 
scale and vector type. Of course there're so many data typs, but I cannot 
pre-make everything.

Minimised stack depth for easier debugging.

All notifications are just timing notifications for each mutation events. It 
does not represents a kind of "state" or implicate any conceptual stuffs.

You can access **ALL** methods of each storage from only one thread. Allowing
access from multiple thread causes complex locking issue, and that brings
extra complexity -- that is invisible -- and performance degrade. If you need
access from another thread, you always have to use a sort of asynchronous 
data transferring mechanism.

Mutations are notified, and you cannot perform mutation while inside of this
notification. Because that break assumption of "current state" and result
becomes undeterministic.

This sort of safety is guaranteed by assertions. Program will crash if 
something goes wrong in an unoptimised build.

This provides only scalar and vector (value / array) storages. That because 
this storage is designed soley for UI presentation. In most cases, collection 
data always must be sorted before it to be rendered. Also, another type of
storages cannot be implemented in this type of interfaces.










"No" for Complex and Automatic Data Binding
-------------------------------------------
Data binding is a 




















