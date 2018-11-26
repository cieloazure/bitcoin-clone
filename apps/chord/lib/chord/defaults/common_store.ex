defmodule Chord.Defaults.Store do
  @moduledoc """
  Defaults.Store

  This module takes care of storing and retrieving data
  """
  use GenServer
  require Logger

  ###             ###
  ###             ###
  ### Client API  ###
  ###             ###
  ###             ###

  @doc """
  Defaults.Store.start_link

  Initiate the block storage server with given options
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  ###                      ###
  ###                      ###
  ### GenServer Callbacks  ###
  ###                      ###
  ###                      ###

  @doc """
  Defaults.Store.init
  """
  @impl true
  def init(opts) do
    node = Keyword.get(opts, :node)

    # TODO: Initiailize Database, File storage, etc. 
    # Using a map of items with format {key -> value} temporarily
    # store = Chord.Defaults.Schemas.StringStore
    store = []

    {:ok, {node, store}}
  end

  @doc """
  """
  @impl true
  def handle_info({:handle_message, message, payload}, {node, store}) do
    store =
      case message do
        :store ->
          [payload | store]
      end

    {:noreply, {node, store}}
  end
end
