# How it works

While portals are marketed as peer-to-peer connections, of course it's virtually impossible for two devices on the internet to find each other without some information about the other (like, an ip address or something similar).

That's why applications are usually architected around a server-client paradigm, where all clients connect to a server with a static ip or url.
This server acts as a man-in-the-middle, intercepting all the data that's sent.

Portals also connect to a central server, but the server merely forwards messages - portals use the code to establish an encrypted connection over the server.
Also, they don't send any actual data over the server. Rather, they exchange their internet (ip) addresses and then try to connect to each other directly.

Connecting devices peer-to-peer has some nice side-effects:
There's less latency, especially when devices are in the same region.
If they are in the same wifi network, data messages don't even have to leave the network.

# Architecture

There's

- control connections
- data connections.
