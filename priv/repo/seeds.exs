alias Todo.Quotes

# Read quotes from the JSON file
quotes_path = "priv/repo/quotes.json"
quotes_path
|> File.read!()
|> Jason.decode!()
|> Enum.each(fn attrs ->
	# Construct a quote struct and attempt to insert it
	quote = %{quote: attrs["quote"], author: attrs["author"], source: attrs["source"]}
	case Quotes.create_quote(quote) do
		{:ok, _quote} -> :ok
		{:error, _changeset} -> :duplicate
	end
end)
