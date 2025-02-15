defmodule Client.SocketServer do

  @moduledoc """
    THIS MODULE ALLOWS THE Client TO CONNECT TO ANY OTHER WORKER VIA TCP
  """
  use GenServer

  @doc """
    Starts the GenServer
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end


  @doc """
    Initializes the State Server with the initial state
    %{
      "socket_id" => ""
    }
  """
  @impl true
  def init(:ok) do
    init_state = %{
      "socket" => ""
    }
    {:ok, init_state}
  end


  @doc """
    Connects to the TCP socket
  """
  @impl true
  def handle_call({:connect, port, ip}, _from, state) do
    connect = :gen_tcp.connect(ip, port, [active: false])
    case connect do
      {:ok, socket} ->
        state = %{state | "socket" => socket}
        {:reply, {:ok, socket}, state}
      _ ->
        {:reply, {:error, connect}, state}
    end
  end


  @impl true
  def handle_call({:send_tcp, message}, _from, state) do
    reply = :gen_tcp.send(state["socket"], message<>"\n")
    case reply do
      :ok ->
        {:reply, {:ok, :sent}, state}
      _ ->
        IO.puts(IO.ANSI.red() <> "Connection has been terminated. Master seems to be down :(" <> IO.ANSI.reset())
        {:reply, {:error, reply}, state}
    end
  end



  @impl true
  def handle_call({:recv}, _from, state) do
    case :gen_tcp.recv(state["socket"], 0, 5000) do
      {:ok, data} ->
        {:reply, {:ok, data}, state}
      {:error, :closed} ->
        IO.puts(IO.ANSI.red() <> "Connection has been terminated" <> IO.ANSI.reset())
        {:reply, {:error, :closed}, state}
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "There was an error" <> IO.ANSI.reset())
        IO.inspect(reason)
        {:reply, {:error, reason}, state}
    end
  end


  ###########################################################################
  ###########################################################################


  @doc """
    Called whenever there is a new connection
  """
  def connect(port, ip) do
    reply = GenServer.call(Client.SocketServer, {:connect, port, ip})
    IO.inspect(reply)
    case reply do
      {:ok, _socket} ->
        IO.puts(IO.ANSI.green() <> "WORKER CONNECTED TO " <> Enum.join(Tuple.to_list(ip), ".") <> " on port " <> Kernel.inspect(port) <> IO.ANSI.reset())
        IO.puts("")
      {:error, {:error, reason}} ->
        IO.puts(IO.ANSI.red() <> "Error in connecting to desired IP. Error Description: #{reason}" <> IO.ANSI.reset())
        IO.puts(IO.ANSI.red() <> "Try again" <> IO.ANSI.reset())
        {:error, "unable to connect"}
        # :timer.sleep(10000)
        # connect(port, ip)
    end
  end


  @doc """
    SEND MESSAGE OVER TCP
  """
  def send_message(message) do
    GenServer.call(Client.SocketServer, {:send_tcp, message})
  end


  @doc """
    RECEIVE MESSAGES OVER TCP
  """
  def recv_message() do
    GenServer.call(Client.SocketServer, {:recv})
  end


  def receive_message(socket) do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, data} ->
        {:ok, data}
      {:error, :closed} ->
        IO.puts(IO.ANSI.red() <> "Connection has been terminated" <> IO.ANSI.reset())
        {:error, :closed}
      {:error, reason} ->
        IO.puts(IO.ANSI.red() <> "There was an error" <> IO.ANSI.reset())
        IO.inspect(reason)
        {:error, reason}
    end
  end

end
