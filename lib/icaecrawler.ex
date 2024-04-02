defmodule Icaecrawler do
  @moduledoc """
  Little crawler to find all the people working at ICAE and store them as JSON
  """

  @doc """
  Get's the body of a website

  Returns: website body

  ## Examples

      iex> Icaecrawler.get_body()
      "<html>...</html>"

  """
  def get_body(url) do
    Req.get!(url).body
  end

  def parse_table_content(table) do
    # fitler out the table header
    # get each person
    [_ | contents] =
      Floki.find(table, "tr")
      # divide person into key characteristics
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

  def parse_item(response) do
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

  def save_to_json(people) do
    {:ok, p} = Poison.encode(people)
    File.write!("people.json", p)
  end

  def crawl do
    Icaecrawler.get_body(
      "https://www.jku.at/institut-fuer-die-gesamtanalyse-der-wirtschaft/ueber-uns/team/"
    )
    |> Icaecrawler.parse_item()
    |> save_to_json()
  end
end
