defmodule Icaecrawler do
  @moduledoc """
  Little crawler to find all the people working at ICAE and store them as JSON
  """

  alias NimbleCSV.RFC4180, as: CSV

  def titles do
    ["Dr.", "Mag.", "BSc", "MSc", "PD", "Prof.", "MA", "MPhil", "BA"]
  end

  defp get_body(url) do
    Req.get!(url).body
  end

  defp parse_table_content(table) do
    # fitler out the table header
    # get each person
    [_ | contents] =
      Floki.find(table, "tr")
      # extract name,link and email
      |> Enum.map(fn x ->
        %{
          email:
            Floki.find(x, "td")
            |> List.last()
            |> Floki.text()
            |> String.split(",")
            |> hd(),
          name: Floki.find(x, "td") |> hd() |> Floki.text(),
          href:
            Floki.find(x, "a")
            |> Floki.attribute("href")
            |> Enum.filter(fn link ->
              String.contains?(link, "/team") or String.contains?(link, "http")
            end)
        }
      end)

    contents
  end

  defp parse_response(response) do
    {:ok, document} = Floki.parse_document(response)

    Floki.find(document, "#offCanvas")
    |> Floki.find(".text")
    |> Enum.filter(fn x ->
      not Enum.empty?(Floki.find(x, ".lead")) and not Enum.empty?(Floki.find(x, ".body"))
    end)
    |> Enum.map(fn x ->
      %{
        role: Floki.find(x, ".lead") |> Floki.find("p") |> Floki.text(),
        people: Floki.find(x, ".body") |> parse_table_content
      }
    end)
  end

  defp unravel(persons) do
    persons
    |> Enum.map(fn outer ->
      Enum.map(outer.people, fn person -> Map.put(person, :role, outer.role) end)
    end)
  end

  defp extract_titles_from_map(persons) do
    Enum.map(persons, fn person ->
      {name, titles} =
        extract_title(
          person.name
          |> String.replace("öffnet eine externe URL in einem neuen Fenster", "")
        )

      Map.update(person, :name, "", fn _ -> name end) |> Map.put(:titles, titles)
    end)
  end

  defp extract_title(person) do
    titles = extract_titles_from_list(person, Icaecrawler.titles(), [])

    {remove_titles_from_name(person, titles) |> String.replace(",", "") |> String.trim(),
     titles |> Enum.join(" ")}
  end

  defp extract_titles_from_list(_, [], extracted_titles), do: extracted_titles

  defp extract_titles_from_list(name, [title | rest], extracted_titles) do
    if String.contains?(name, title) do
      extract_titles_from_list(name, rest, [title | extracted_titles])
    else
      extract_titles_from_list(name, rest, extracted_titles)
    end
  end

  defp remove_titles_from_name(name, []), do: name

  defp remove_titles_from_name(name, [title | rest]) do
    remove_titles_from_name(String.replace(name, title, ""), rest)
  end

  def save_to_csv(persons) do
    csv_data =
      [
        ["Name", "Stelle", "Email", "Link", "Titel"]
        | Enum.map(persons, &Map.values/1)
      ]
      |> CSV.dump_to_iodata()
      |> IO.iodata_to_binary()

    File.write(
      "people.csv",
      csv_data
    )
  end

  def crawl do
    get_body("https://www.jku.at/institut-fuer-die-gesamtanalyse-der-wirtschaft/ueber-uns/team/")
    |> parse_response()
    |> unravel()
    |> List.flatten()
    |> extract_titles_from_map()
  end
end
