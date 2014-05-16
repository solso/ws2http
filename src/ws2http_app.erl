-module(ws2http_app).
-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    %% {Host, list({Path, Handler, Opts})}
    Dispatch = [{'_', [
        {'_', ws2http_handler, []}
    ]}],
    %% Name, NbAcceptors, Transport, TransOpts, Protocol, ProtoOpts
    cowboy:start_listener(ami_ws_dispatcher, 100,
        cowboy_tcp_transport, [{port, 8090}],
        cowboy_http_protocol, [{dispatch, Dispatch}]
    ),
    ws2http_sup:start_link().

stop(_State) ->
    ok.
