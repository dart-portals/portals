# Relation to magic wormhole

This package is heavily inspired by Magic Wormhole and is compatible with it in most of the lower layers of the architecure.

The magic wormhole's mailbox server acts as the control connection. All the commands relating setup and meta-information go through this one.
All actual data transfers go through data connections.


