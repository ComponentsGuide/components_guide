defmodule ComponentsGuideWeb.WebStandards.Live.HttpCaching do
  use ComponentsGuideWeb, :live_view
  alias ComponentsGuideWeb.StylingHelpers
  
  defmodule State do
    defstruct local: nil, remote: nil
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, state: %State{})}
  end

  def render(assigns) do
    ~L"""
    <form phx-change=change>
      <fieldset class="flex flex-row space-x-4">
        <div class="font-bold">Local</div>
        <label><input type=radio name=local value=0 class="form-radio"> Blank</label>
        <label><input type=radio name=local value=1 class="form-radio"> Loaded previously</label>
      </fieldset>
      <fieldset class="flex flex-row space-x-4">
        <div class="font-bold">Remote</div>
        <label><input type=radio name=remote value=a class="form-radio"> ABC</label>
        <label><input type=radio name=remote value=z class="form-radio"> XYZ</label>
      </fieldset>
    </form>
    """
  end
  
  def handle_event("change", %{"local" => local}, socket) do
    state = socket.assigns.state
    state = put_in(state.local, local)
    
    {
      :noreply,
      socket
      |> assign(:state, state)
    }
  end
  
  def handle_event("change", %{"remote" => remote}, socket) do
    state = socket.assigns.state
    state = put_in(state.remote, remote)
    
    {
      :noreply,
      socket
      |> assign(:state, state)
    }
  end
end
