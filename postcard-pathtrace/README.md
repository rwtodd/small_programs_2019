# postcard pathtracer

Here are a couple of ports of [a small pathtracer I found on the internet][1].

At present I wrote similar code in Clojure and Scala.  It turns out, as long as you
use `while`-loops instead of `for`-comprehensions, Scala will give decent performance.
Getting Valhalla into the JVM would be a huge help for this kind of code, as can be
seen in the better performance numbers you can see on the internet for C#/CLR versions
of this code.

[1]: http://fabiensanglard.net/postcard_pathtracer/formatted_full.html

