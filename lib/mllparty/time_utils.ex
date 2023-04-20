defmodule TimeUtils do
  def format_seconds(seconds) do
    case seconds do
      s when s < 60 ->
        "#{s} second#{pluralize(s)}"

      s when s < 3600 ->
        minutes = div(s, 60)
        seconds = rem(s, 60)
        "#{minutes} minute#{pluralize(minutes)}, #{seconds} second#{pluralize(seconds)}"

      s when s < 86400 ->
        hours = div(s, 3600)
        minutes = rem(div(s, 60), 60)
        seconds = rem(s, 60)

        "#{hours} hour#{pluralize(hours)}, #{minutes} minute#{pluralize(minutes)}, #{seconds} second#{pluralize(seconds)}"

      s ->
        days = div(s, 86400)
        hours = rem(div(s, 3600), 24)
        minutes = rem(div(s, 60), 60)
        seconds = rem(s, 60)

        "#{days} day#{pluralize(days)}, #{hours} hour#{pluralize(hours)}, #{minutes} minute#{pluralize(minutes)}, #{seconds} second#{pluralize(seconds)}"
    end
  end

  defp pluralize(1), do: ""
  defp pluralize(_), do: "s"
end
