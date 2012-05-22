Worklog
=======

TODO: Add info about todo feature.

This is a small script/tool I've created to make it easy to register what I spend my time on. I hate most existing tools I'm forced to use you see, but this script stays out of the way, but still prompts me for info twice a day in a friendly way. When I then need to update the company tracking tool my script has created a nice file which I manually transfer (like once a month).

Personally I'm running the tool (with the ADDN option - see below) as a scheduled task twice a day - at lunch and before I go home. It pops up a command line where I enter my stuff, and the forget about it until the next time.

This is the default message you get when you run the script:

> ~~~ T-MANs SIMPLE WORK LOG TOOL ~~~
>
> Usage: worklog.rb COMMAND
>
> Available commands:
>
>          ADD    Adds an entry to the current work log
>         ADDN    Add one or more entries to the current work log
>      ARCHIVE    Dump current work log to archive file
>        CLEAR    Clear the current work log
>         TAIL    Display the current work log

Internals
---------

The tool consists of two files:

+ **worklog.rb**: The file you run. Defines all the commands. You'll see some file handling code as well.
+ **workloglib.rb**: The inner workings of the script. Contains the interface to define commands, logic to handle the commands, a class representing a worklog entry, and helper functionality for prompting.

License
-------
Free to use however you like, but it's nice if you tell me about it, and also if you attribute me. I can not promice that it'll work as expected, and take absolutely no responsibility for what might happen when you use it.

If you fork it and does something nice with it, please send me a pull request!
