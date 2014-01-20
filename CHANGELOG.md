### Changelog ###

This file contains highlights of what changes on each version of the force package.

#### Pub version 0.3.1 ####

Extract webServer code and put it into forcemvc package 

#### Pub version 0.3.0+5 & 0.3.0+6 ####

Some small changes in logging and an update to the documentation.

#### Pub version 0.3.0+4 ####

Adding a generateId method to the forceclient class. So you can use this unique id in the client to start something, for example a gamesession!

#### Pub version 0.3.0+3 ####

Added an optional parameter url to forceclient so you can set the url to another hosted force server endpoint.
Added an optional parameter heartbeat, to specify in milliseconds the heartbeat duration.

#### Pub version 0.3.0+2 ####

Refactor the code so it uses a factory instead of a static method to choose the socket implementation clientside.
Fixed an small issue when sending characters through polling and receiving it again.

#### Pub version 0.3.0+1 ####

Sending the old property values in the profile changed event. So you can use the old value and look at the new value in profileInfo field.

#### Pub version 0.3.0 ####

Adding socket abstraction to the dart force framework and add also the long polling mechanism as an alternative for websockets.