defmodule Uptom.SiteController do
  use Uptom.Web, :controller

  alias Uptom.Site

  def index(conn, _params, user) do
    sites = Repo.all(from s in assoc(user, :sites), order_by: s.inserted_at)
    render(conn, "index.html", sites: sites)
  end

  def new(conn, _params, user) do
    changeset =
      user
      |> build_assoc(:sites, enabled: true)
      |> Site.changeset()
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"site" => site_params}, user) do
    changeset =
      user
      |> build_assoc(:sites)
      |> Site.changeset(site_params)

    case Repo.insert(changeset) do
      {:ok, site} ->
        update_site_in_monitoring(site)

        conn
        |> put_flash(:info, "Site created successfully.")
        |> redirect(to: site_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, user) do
    site = Repo.get!(assoc(user, :sites), id)
    render(conn, "show.html", site: site)
  end

  def edit(conn, %{"id" => id}, user) do
    site = Repo.get!(assoc(user, :sites), id)
    changeset = Site.changeset(site)
    render(conn, "edit.html", site: site, changeset: changeset)
  end

  def update(conn, %{"id" => id, "site" => site_params}, user) do
    site = Repo.get!(assoc(user, :sites), id)
    changeset = Site.changeset(site, site_params)

    case Repo.update(changeset) do
      {:ok, site} ->
        update_site_in_monitoring(site)

        conn
        |> put_flash(:info, "Site updated successfully.")
        |> redirect(to: site_path(conn, :index))
      {:error, changeset} ->
        render(conn, "edit.html", site: site, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    site = Repo.get!(assoc(user, :sites), id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(site)

    remove_site_from_monitoring(site)

    conn
    |> put_flash(:info, "Site deleted successfully.")
    |> redirect(to: site_path(conn, :index))
  end

  def action(conn, _) do
    apply(__MODULE__, action_name(conn),
      [conn, conn.params, conn.assigns.current_user])
  end

  defp update_site_in_monitoring(site) do
    Uptom.CheckSupervisor.add_or_update_site(site)
  end

  defp remove_site_from_monitoring(site) do
    Uptom.CheckSupervisor.remove_site(site.id)
  end
end
