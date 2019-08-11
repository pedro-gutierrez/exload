# This module provides with a simple and Elixir friendly wrapper
# around the SQS API provided by Erlcloud. Very basic send/receive
# operations are offered. For instance, in order to keep
# the API dead simpe, Messages, once received, are automatically
# deleted.
#
defmodule F3load.Sqs do
  require Record

  # Use the record from Erlcloud that holds
  # our AWS configuration
  Record.defrecord :aws_config, Record.extract(:aws_config, from_lib: "erlcloud/include/erlcloud_aws.hrl")

  defp sqs_env do
    Application.get_env(:f3load, F3load.Sqs)
  end

  # Build the list of consumers, so that we can
  # add workers under a supervision tree
  def consumers do
    env = sqs_env()
    env[:stacks] |> Enum.reduce([], fn {s, queues}, acc0 ->
      queues |> Enum.reduce(acc0, fn {q, opts}, acc1 ->
        [[name: String.to_atom("#{s}-#{q}"), opts: opts]|acc1]
      end)
    end)
  end


  # Define a default config. TODO: load
  # this from the application environment
  def config do
    env =  sqs_env()

    aws_config(
      access_key_id: env[:access_key] |> to_charlist,
      secret_access_key: env[:secret_key] |> to_charlist,
      sqs_protocol: env[:scheme] |> to_charlist,
      sqs_host: env[:host] |> to_charlist,
      sqs_port: env[:port])
  end

  # List the queues from the SQS endpoint
  # defined by the configuration
  def queues(cfg) do
    cfg
    |> :erlcloud_sqs.list_queues
  end


  # Receive messages from SQS, for the given
  # config, queue and options. Messages returned
  # by this function are automatically deleted
  def receive(cfg, queue,
    max_messages \\ 10,
    visibility_timeout \\ 1,
    wait_time_seconds \\ 1) do

    # Convert the queue name to a charlist
    # so that Erlang is happy
    queue_name = queue |> to_charlist

    # Get a batch of messages
    case queue_name |> :erlcloud_sqs.receive_message(:all, max_messages, visibility_timeout, wait_time_seconds, cfg) do
      {:aws_error, reason} ->
        {:error, reason}
      [messages: batch] ->
        # If no messages were returned
        # then finish
        # Otherwise, delete the batch first, and return it
        case batch |> length do
          0 ->
            :nodata
          _ ->
            ## Extract the id, handle tuple for each message received
            ## and delete them all at once
            receipt_handles = for m <- batch, do: {m[:message_id], m[:receipt_handle]}
            case queue_name |> :erlcloud_sqs.delete_message_batch(receipt_handles, cfg) do
              [_|_] ->
                {:ok, batch}
              other ->
                {:error, other}
            end
        end
    end
  end

  # Send a message to the given queue
  def send(cfg, queue, body) do
    case queue
      |> to_charlist
      |> :erlcloud_sqs.send_message(body, cfg) do
      [message_id: _, md5_of_message_body: _] ->
        :ok
      other ->
        {:error, other}
    end
  end

  # Convenience function that encodes the
  # given doc as json before sending
  # TODO: add message attributes, such as content_type
  # so that we know how to decode it later
  def send_json(cfg, queue, doc) do
    body = doc |> Jason.encode!
    send(cfg, queue, body)
  end


end
