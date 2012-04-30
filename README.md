catenary
========

A bare-bones Processing program to draw a catenary between two points.

To use, open and run the .pde in Processing or download one of the executables (I haven't tried any of them). Drag a line in the window with the mouse and behold the resulting catenary. Don't think for a second that it's actually a parabola. See the Wikipedia entry on catenaries (referenced extensively in the code) for the difference.

The default chain length between the endpoints of the line segment you trace is twice the straight-line distance between same. Press -/= to decrease/increase the chain length; hold Shift (i.e. _/+) to decrease/increase by larger intervals.

This code will fail unspectacularly if the line you trace is too steep.

TODO: Make it possible to trace over an existing image. Making the app window transparent in a cross-platform way looks like a huge pain in the ass so I'll probably implement this by making you load an image from disk.
