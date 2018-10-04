-module(geas_release_rebar3).
-behaviour(provider).

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, geas_release).
-define(DEPS, [compile]).

%% ===================================================================
%% Public API
%% ===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([
            {name, ?PROVIDER},
            {module, ?MODULE},
            {bare, true},
            {deps, ?DEPS},
            {example, "rebar geas_release -r 21.1"},
            {opts, opts()},
            {short_desc, "Geas release rebar3 plugin"},
            {desc, "DESC"}
    ]),
    {ok, rebar_state:add_provider(State, Provider)}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    {CommandOpts, _} = rebar_state:command_parsed_args(State),
    Apps = rebar_state:all_deps(State) ++ rebar_state:project_apps(State),
    DepsGeasInfo =
        lists:foldl(
          fun (AppInfo, Acc) ->
                  Name = rebar_app_info:name(AppInfo),
                  AppFileSrc = rebar_app_info:app_file_src(AppInfo),
                  AppFileSrcDir = filename:join(filename:dirname(AppFileSrc), "../"),
                  OutDir = rebar_app_info:out_dir(AppInfo),
                  case geas:info(AppFileSrcDir) of
                      {ok, GeasInfo} ->
                          Compat = proplists:get_value(compat, GeasInfo),
                          maps:put(Name, {OutDir, Compat}, Acc);
                      {error, _Error} ->
                          maps:put(Name, {OutDir, undefined}, Acc)
                  end
          end, #{}, Apps),
    release_window_info(proplists:get_value(release_window, CommandOpts), DepsGeasInfo),
    release_target_info(proplists:get_value(release_target, CommandOpts), DepsGeasInfo),
    offenders_info(proplists:get_value(offenders, CommandOpts), DepsGeasInfo),
    {ok, State}.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

opts() ->
    [{release_target, $r, "release-target", string,
      "Target release info"},
     {release_window, $w, "release-window", {boolean, true},
      "Release window"},
     {offenders, $o, "offenders", string, "Offenders for app"}].

release_window_info(true, AppsInfo) ->
    {MinRel, MaxRel, Unknown} =
        maps:fold(
          fun (App, {_, AppCompatInfo}, {RelMin0, RelMax0, Unknown}) ->
                  case AppCompatInfo of
                      undefined ->
                          {RelMin0, RelMax0, [App | Unknown]};
                      {_, AppRelMin, AppRelMax, _} ->
                          RelMin1 = geas:highest_version(AppRelMin, RelMin0),
                          RelMax1 = geas:lowest_version(AppRelMax, RelMax0),
                          {RelMin1, RelMax1, Unknown}
                  end
          end, {[], [], []}, AppsInfo),
    rebar_log:log(info, "[release_window] Release window, lowest: ~p, highest: ~p, unknown: ~p",
                  [MinRel, MaxRel, Unknown]),
    ok;
release_window_info(_, _) ->
    [].

release_target_info(undefined, _) ->
    [];
release_target_info(Release, AppsInfo) ->
    {Offenders, Unknown} =
        maps:fold(
          fun (App, {_, AppCompatInfo}, {AppsOutOfRange, Unknown}) ->
                  case AppCompatInfo of
                      undefined ->
                          {AppsOutOfRange, [App | Unknown]};
                      {_, AppRelMin, AppRelMax, _} ->
                          case {geas:highest_version(Release, AppRelMin),
                                geas:lowest_version(Release, AppRelMax)} of
                              {Release, Release} ->
                                  {AppsOutOfRange, Unknown};
                              _ ->
                                  {[{App, {AppRelMin, AppRelMax}} | AppsOutOfRange], Unknown}
                          end
                  end
          end, {[], []}, AppsInfo),
    rebar_log:log(
      info, "[release_target] Target release: ~p~n[release_target] Offenders: ~p~n[release_target] Unknown: ~p",
      [Release, Offenders, Unknown]),
    ok.

offenders_info(undefined, _) ->
    [];
offenders_info(AppsStr, AppsInfo) ->
    Apps = string:tokens(AppsStr, [$,]),
    Offenders =
        lists:map(
          fun (App) ->
                  case maps:find(list_to_binary(App), AppsInfo) of
                      error ->
                          {App, {error, not_found}};
                      {ok, undefined} ->
                          {App, {error, unknown}};
                      {ok, {AppDir, _}} ->
                          EbinPath = filename:join(AppDir, "ebin/"),
                      case filelib:is_dir(EbinPath) of
                          true ->
                              {App, filelib:fold_files(
                                      EbinPath, ".beam", false, check_offenders(), []
                                     )};
                          false ->
                              {App, {error, no_beam_files}}
                      end
                  end
          end, Apps),
    rebar_log:log(info, "[offenders] Offending detailed info for apps: ~p~n[offenders] ~p", [Apps, Offenders]),
    ok.

check_offenders() ->
    fun (File, Acc) ->
            case geas:offending(File) of
                {ok, {[], []}} -> Acc;
                {ok, {[{[],[]}],[{[],[]}]}} -> Acc;
                {ok, Offending} ->
                    [{File, Offending} | Acc]
            end
    end.
