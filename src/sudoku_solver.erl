-module (sudoku_solver).

-export ([execute/2]).
-export ([main/1]).
-export ([print/3]).

main([Filename | _]) ->
	{ok, IoDevice} = file:open(Filename, [read]),
	{L0, _C0} = execute({create}, {[], []}),
	{true, L1} = parse(IoDevice, 1, 1, L0),
	print(1, 1, L1),
	{true, L2} = execute({solve}, {L1, []}),
	io:format("~n", []),
	print(1, 1, L2),
	ok = file:close(IoDevice),
true.

parse(_, 1, 10, L0) ->
	{true, L0};
parse(IoDevice, X, Y, L0) ->
	N = io:get_chars(IoDevice, false, 1),
	%io:format("parsed ~p at ~p / ~p~n", [N, X, Y]),
	{X1, Y1, L1} = case N of
		"1" -> {T, _} = execute({put, X, Y, 1}, {L0, []}),
			   {X + 1, Y, T};
		"2" -> {T, _} = execute({put, X, Y, 2}, {L0, []}),
			   {X + 1, Y, T};
		"3" -> {T, _} = execute({put, X, Y, 3}, {L0, []}),
			   {X + 1, Y, T};
		"4" -> {T, _} = execute({put, X, Y, 4}, {L0, []}),
			   {X + 1, Y, T};
		"5" -> {T, _} = execute({put, X, Y, 5}, {L0, []}),
			   {X + 1, Y, T};
		"6" -> {T, _} = execute({put, X, Y, 6}, {L0, []}),
			   {X + 1, Y, T};
		"7" -> {T, _} = execute({put, X, Y, 7}, {L0, []}),
			   {X + 1, Y, T};
		"8" -> {T, _} = execute({put, X, Y, 8}, {L0, []}),
			   {X + 1, Y, T};
		"9" -> {T, _} = execute({put, X, Y, 9}, {L0, []}),
			   {X + 1, Y, T};
		"\n" when X >= 9 -> {1, Y + 1, L0};
		"_" -> {X + 1, Y, L0};
		_ -> {X, Y, L0}
	end,
	parse(IoDevice, X1, Y1, L1).

put(X, Y, N, L) ->
	{A, [_ | B]} = lists:split((Y - 1) * 9 + X - 1, L),
	A ++ [N | B].

get(X, Y, L) when is_integer(X), is_integer(Y), is_list(L), X > 0, X < 10, Y > 0, Y < 10 ->
	lists:nth((Y - 1) * 9 + X, L).

row(N, L) when is_integer(N), is_list(L), N > 0, N < 10 ->
	[get(X, N, L) || X <- lists:seq(1,9)].

col(N, L) when is_integer(N), is_list(L), N > 0, N < 10 ->
	[get(N, Y, L) || Y <- lists:seq(1,9)].

seg(X, Y, L) when is_integer(X), is_integer(Y), is_list(L), X > 0, X < 4, Y > 0, Y < 4 ->
	[get((X - 1) * 3 + A, (Y - 1) * 3 + B, L) || B <- lists:seq(1,3), A <- lists:seq(1,3)].

duplicates(L) when is_list(L) ->
	K = [X || X <- L, X > 0],
	length(K) =:= length(lists:usort(K)).

validate(L) when is_list(L) ->
	Rows = [row(N, L) || N <- lists:seq(1,9)],
	Cols = [col(N, L) || N <- lists:seq(1,9)],
	Segs = [seg(X, Y, L) || X <- lists:seq(1,3), Y <- lists:seq(1,3)],
	lists:foldl(fun(X, Acc) -> Acc and duplicates(X) end, true, Rows ++ Cols ++ Segs).

execute(C = {create}, {[], []}) ->
	{lists:duplicate(81, 0), [C]};
execute(C = {put, X, Y, N}, {L, Cs}) ->
	{put(X, Y, N, L), [C | Cs]};
execute(C = {solve}, {L0, Cs}) ->
	{true, X, Y} = find(1, 1, 0, L0),
	L1 = put(X, Y, 1, L0),
	solve(validate(L1), [{put, X, Y, 1}, C | Cs], L1).

find(9, 9, N, L) ->
	case get(9, 9, L) =:= N of
		true -> {true, 9, 9};
		_ -> {false, 9, 9}
	end;
find(X0, Y0, N, L) ->
	{X1, Y1} = case X0 =:= 9 of
			   true -> {1, Y0 + 1};
			   _ -> {X0 + 1, Y0}
		   end,
	case get(X0, Y0, L) =:= N of
		true -> {true, X0, Y0};
		_ -> find(X1, Y1, N, L)
	end.

solve(false, [{solve} | _], L0) ->
	{false, L0};
solve(false, [{put, X, Y, 9} | Cs], L0) ->
	io:format("b", []),
	L1 = put(X, Y, 0, L0),
	solve(false, Cs, L1);
solve(false, [{put, X, Y, N} | Cs], L0) ->
	%io:format("put(~B, ~B, ~B)~n", [X, Y, N + 1]),
	io:format("p", []),
	L1 = put(X, Y, N + 1, L0),
	solve(validate(L1), [{put, X, Y, N + 1} | Cs], L1);
solve(true, Cs, L0) ->
	case find(1, 1, 0, L0) of
		{false, _, _} -> {true, L0};
		{true, X, Y} -> io:format("p", []),
				L1 = put(X, Y, 1, L0),
				solve(validate(L1), [{put, X, Y, 1} | Cs], L1)
	end.

print(9, 9, L) ->
	S = get(9, 9, L),
	case S of
		0 -> io:format("|   |~n", []);
		_ -> io:format("| ~B |~n", [S])
	end;
print(9, Y, L) ->
	S = get(9, Y, L),
	case S of
		0 -> io:format("|   |~n", []);
		_ -> io:format("| ~B |~n", [S])
	end,
	io:format("-------------------------------------~n", []),
	print(1, Y + 1, L);
print(X, Y, L) ->
	S = get(X, Y, L),
	case S of
		0 -> io:format("|   ", []);
		_ -> io:format("| ~B ", [S])
	end,
	print(X + 1, Y, L).
