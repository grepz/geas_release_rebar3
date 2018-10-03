# geas_release_rebar3

This is rebar3 plugin to use [geas](https://github.com/crownedgrouse/geas) .

Simply add in your global config file `~/.config/rebar3/rebar.config` :

```
{plugins, [
  {geas_release_rebar3, {git, "link", {branch, "master"}}}
]}.

```
then run

```
rebar3 geas -r 21.1 -w -o rabbit_common

...
===> [release_window] Release window, lowest: "20.0", highest: "19.3", unknown: [<<"ranch">>]
===> [release_target] Target release: "21.1"
[release_target] Offenders: [{<<"parse_trans">>,{"R15","20.3"}},
                             {<<"rabbit_common">>,{"18.0","19.3"}},
                             {<<"cowlib">>,{"R15","19.3"}}]
[release_target] Unknown: [<<"ranch">>]
===> [offenders] Offending detailed info for apps: ["rabbit_common"]
[offenders] [{"rabbit_common",
              [{"/Users/grepz/Projects/WG/wgm/_build/default/lib/rabbit_common/ebin/time_compat.beam",
                {[{"18.0",
                   [{erlang,monotonic_time,0},
                    {erlang,monotonic_time,1},
                    {erlang,system_time,0},
                    {erlang,system_time,1},
                    {erlang,time_offset,0},
                    {erlang,time_offset,1},
                    {erlang,timestamp,0},
                    {erlang,unique_integer,0},
                    {erlang,unique_integer,1},
                    {os,system_time,0},
                    {os,system_time,1}]}],
                 []}},
               {"/Users/grepz/Projects/WG/wgm/_build/default/lib/rabbit_common/ebin/ssl_compat.beam",
                {[{"18.0",
                   [{ssl,connection_information,1},
                    {ssl,connection_information,2}]}],
                 [{"19.3",[{ssl,connection_info,1}]}]}},
               {"/Users/grepz/Projects/WG/wgm/_build/default/lib/rabbit_common/ebin/rabbit_reader.beam",
                {[{"R16B",[{application,get_env,3}]}],[]}},
               {"/Users/grepz/Projects/WG/wgm/_build/default/lib/rabbit_common/ebin/rabbit_networking.beam",
                {[{"R16B",[{application,get_env,3}]}],[]}},
               {"/Users/grepz/Projects/WG/wgm/_build/default/lib/rabbit_common/ebin/rabbit_misc.beam",
                {[{"R16B",[{application,get_env,3}]}],[]}}]}]

```
Known options:
```
-r <ErlangReleaseVersion> - Releaase target to get info for
-w - Release window. Get release window for project.
-o app1,app2 - Get offending modules/functions for choosen applications
```
