Fluent Refactoring
==================

This repository contains the code used in my "Fluent Refactoring" presentation at <a href="http://www.lonestarruby.org/2013/lsrc">Lone Star Ruby Conf 2013</a>.  My slides are available via <a href="http://www.slideshare.net/geeksam/fluent-refactoring-lone-star-ruby-conf-2013?from=ss_embed">SlideShare</a>.  If you saw the talk, I'd appreciate feedback via email or <a href="http://speakerrate.com/talks/23881-fluent-refactoring">SpeakerRate</a>.

(A note on feedback:  while of course I *always* enjoy hearing "great talk!", I especially want to know if there was any part of the talk that was unclear, confusing or vague&mdash;or if any of my jokes just weren't funny!)

Getting Started
===============

Code is in <a href="./lab/installations_controller.rb">lab/installations_controller.rb</a>.  There is a set of mock-driven characterization tests in <a href="./lab/installations_controller_spec.rb">lab/installations_controller_spec.rb</a>.  (These specs are relatively strict; for example, they will complain if you add a catch-all rescue clause to the request.xhr? branch!)

There are also some convenience scripts:

* `lab/spec` will run the specs
* `lab/autocommit` will run the specs, and if they pass, will automatically commit any changes to Git, using the arguments to the script as the commit message.  For example:  `lab/autocommit do the thing` will create a commit whose message is "do the thing".  (Quotes should work as normal if for some reason you want to include weird spacing in your commit message.)

Other Fun Toys
==============

This repository also contains a script I wrote to dump plain-text and syntax-highlighted RTFs of every commit on a particular branch.  To use this, make sure you are on master and run `go_meta [branch_name]`.  (You'll probably also want to have <a href="http://pygments.org/">Pygments</a> installed to generate the RTFs.)  This will create output in ./metadata/[branch_name] with one subdirectory per commit.

Happy hacking!
-Sam