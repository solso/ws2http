-module(ws2http_handler).
-behaviour(cowboy_http_handler).
-behaviour(cowboy_http_websocket_handler).
-export([init/3, handle/2, terminate/2]).
-export([
    websocket_init/3, websocket_handle/3,
    websocket_info/3, websocket_terminate/3]).
-export([call_to_backend/4]).


init({tcp, http}, Req, _Opts) ->
    lager:debug("Request: ~p", [Req]),
    %inets:start(),
    {upgrade, protocol, cowboy_http_websocket}.

handle(Req, State) ->
    lager:debug("Request not expected: ~p", [Req]),
    {ok, Req2} = cowboy_http_req:reply(404, [{'Content-Type', <<"text/html">>}]),
    {ok, Req2, State}.

terminate(_Req, _State) ->
    ok.

call_to_backend(Msg, Req, State, PidParent) ->
    inets:start(),
    Q = string:concat("REPLACE WITH YOUR BACKEND ENDPOINT HERE",binary_to_list(Msg)),
    lager:debug(">>>> Got Data!: ~p", [Q]),
    {ok, {{Version, _, ReasonPhrase}, Headers, Body}} = httpc:request(Q),
    PidParent ! {{bleh, Body}, Req, State}.


websocket_init(_Any, Req, []) ->
    lager:debug("New client"),
    Req2 = cowboy_http_req:compact(Req),
    {ok, Req2, undefined, hibernate}.

websocket_handle({text, Msg}, Req, State) ->
    lager:debug("Got Data!: ~p ~p", [Msg, State]),
    spawn_link(?MODULE, call_to_backend, [Msg, Req, State, self()]),
    {ok, Req, State, hibernate};
        
websocket_handle(Any, Req, State) ->
    lager:debug("Any ~p", [Any]),
    {ok, Req, State}.

websocket_info(Info, Req, State) ->
    case Info of
      {{bleh, Body}, _, _} -> {reply, {text, Body}, Req, State, hibernate};
      _ -> {ok, Req, State, hibernate}
    end.
      
websocket_terminate(_Reason, _Req, _State) ->
    ok.