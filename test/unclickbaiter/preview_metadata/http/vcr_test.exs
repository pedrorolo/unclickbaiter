defmodule Unclickbaiter.PreviewMetadata.HTTP.VCRTest do
  use ExUnit.Case, async: false

  use ExVCR.Mock, adapter: ExVCR.Adapter.Httpc

  alias Unclickbaiter.PreviewMetadata.HTTP
  alias Unclickbaiter.PreviewMetadata.HTTP.HttpcAdapter
  alias Unclickbaiter.PreviewMetadata.HTTP.ProviderCache
  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

  setup_all do
    ProviderCache.clear()

    :ok
  end

  setup do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    ExVCR.Config.cassette_library_dir("test/fixtures/vcr_cassettes")
    ExVCR.Config.filter_url_params(true)
    ExVCR.Config.filter_sensitive_data("app_id=[a-z0-9-]+", "app_id=REDACTED")
    ExVCR.Config.filter_sensitive_data("api_key=[a-z0-9]+", "api_key=REDACTED")

    original_req_options = Application.get_env(:unclickbaiter, :req_options, [])

    Application.put_env(
      :unclickbaiter,
      :req_options,
      original_req_options
      |> Keyword.drop([:plug])
      |> Keyword.put(:adapter, HttpcAdapter)
    )

    on_exit(fn ->
      Application.put_env(:unclickbaiter, :req_options, original_req_options)
      ExVCR.Config.filter_url_params(false)
    end)

    :ok
  end

  test "fetches preview metadata for theguardian using exvcr" do
    use_cassette "preview_metadata_theguardian" do
      assert {:ok, %PreviewMetadata{title: title, description: description}} =
               HTTP.fetch(
                 "https://www.theguardian.com/food/2025/may/14/how-to-turn-old-bread-into-a-classic-portuguese-soup-acorda-recipe-zero-waste-cooking"
               )

      refute is_nil(title) or is_nil(description)
    end
  end

  test "fetches preview metadata for observador_pt using exvcr" do
    use_cassette "preview_metadata_observador_pt" do
      assert {:ok, %PreviewMetadata{title: title, description: description}} =
               HTTP.fetch(
                 "https://observador.pt/2026/08/18/vendeu-os-lakers-quer-sair-do-chelsea-quem-e-mark-walter-e-por-que-e-que-esta-a-desfazer-se-de-tudo-o-que-tem-no-desporto/"
               )

      refute is_nil(title) or is_nil(description)
    end
  end

  test "fetches preview metadata for the nytimes articles using exvcr" do
    use_cassette "preview_metadata_nytimes" do
      assert {:ok, %PreviewMetadata{title: title, description: description}} =
               HTTP.fetch(
                 "https://www.nytimes.com/2026/08/20/business/evergrande-founder-life-prison.html"
               )

      refute is_nil(title) or is_nil(description)
    end

    use_cassette "preview_metadata_nytimes_tech_trends" do
      assert {:ok, %PreviewMetadata{title: title, description: description}} =
               HTTP.fetch(
                 "https://www.nytimes.com/2026/01/08/technology/personaltech/2026-tech-trends.html"
               )

      refute is_nil(title) or is_nil(description)
    end
  end

  test "fetches preview metadata for the publico articles using exvcr" do
    use_cassette "preview_metadata_publico_pt" do
      assert {:ok, %PreviewMetadata{title: title, description: description}} =
               HTTP.fetch(
                 "https://www.publico.pt/2026/08/20/sociedade/noticia/nomeacao-medicos-inem-servicos-regionais-considerada-ilegal-2185525"
               )

      refute is_nil(title) or is_nil(description)
    end

    use_cassette "preview_metadata_publico_setubal" do
      assert {:ok, %PreviewMetadata{title: title, description: description}} =
               HTTP.fetch(
                 "https://www.publico.pt/2026/07/14/local/noticia/presidente-camara-setubal-suspende-mandato-durante-tres-meses-2181701"
               )

      refute is_nil(title) or is_nil(description)
    end
  end
end
