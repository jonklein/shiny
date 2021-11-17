defmodule Mix.Tasks.Options do
  def parse(argv) do
    {options, [config_file | params], errors} =
      OptionParser.parse(argv, strict: [logger: :string])

    if errors != [] do
      IO.puts("Invalid options: #{Enum.map(errors, fn {o, _} -> o end)}")
      exit(:shutdown)
    end

    Logger.configure(level: String.to_atom(options[:logger] || "info"))

    {config_file, params}
  end
end
