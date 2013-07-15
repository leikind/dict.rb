RFC 2229 client for ruby.
================================

The Dictionary Server Protocol (DICT) is a TCP transaction based query/response protocol that allows a client to access dictionary
definitions from a set of natural language dictionary databases.

See RFC 2229 for details. http://tools.ietf.org/html/rfc2229

Authors
-------------------------
Copyright 2002,2003 by Dave Pearson <davep@davep.org> (initial version)

Copyright 2013 by Yuri Leikind (modifications, refactoring, gemification, etc)

Copying
-------------------------
dict_client is free software distributed under the terms of the GNU General
Public Licence, version 2. For details see the file COPYING.


## Usage
<pre>
  $ dictd_client --help
  Copyright 2002,2003 by Dave Pearson <davep@davep.org>
  Copyright 2013 by Yuri Leikind

  Supported command line options:

  -h --host <host>         Specify the host to be contacted
                           (default is "localhost").
  -p --port <port>         Specify the port to be connected
                           (default is 2628).
  -d --database <db>       Specity the database to be searched
                           (default is "*").
  -m --match               Perform a match instead of a define.
  -s --strategy <strat>    Specity the strategy to use for the match/define
                           (default is ".").
  -D --dbs                 List databases available on the server.
  -S --strats              List stratagies available on the server.
  -H --serverhelp          Display the server's help.
  -i --info <db>           Display information about a database.
  -I --serverinfo          Display information about the server.
     --help                Display this help.
  -L --licence             Display the licence for this program.

  Supported environment variables:

  DICT_HOST                Specify the host to be contacted.
  DICT_PORT                Specify the port to be connected.
  DICT_DB                  Specify the database to be searched.
  DICT_STRAT               Specify the strategy to use for the match/define.
</pre>