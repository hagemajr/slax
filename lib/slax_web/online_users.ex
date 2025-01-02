defmodule SlaxWeb.OnlineUsers do
  alias SlaxWeb.Presence

  @topic "online_users"

  def list() do
    @topic
    |> Presence.list()
  end

  def track(pid, user) do
    {:ok, _} =
      Presence.track(pid, @topic, user.id, %{
        typing: 0,
        count: 1,
        phx_ref: nil,
        phx_ref_prev: nil
      })

    :ok
  end

  def online?(online_users, user_id) do
    user_presence =
      Map.get(online_users, Integer.to_string(user_id), false)

    # |> IO.inspect()

    case user_presence do
      false ->
        false

      %{metas: metas} ->
        # IO.inspect(metas)

        sum =
          Enum.map(
            metas,
            fn %{count: count} ->
              count
            end
          )
          |> Enum.sum()

        if sum > 0, do: true, else: false

      _ ->
        true
    end
  end

  def set_typing_status(pid, user_id, status) do
    Presence.update(pid, @topic, user_id, %{
      typing: status,
      count: 1,
      phx_ref: nil,
      phx_ref_prev: nil
    })
  end

  def typing?(online_users, user_id) do
    # IO.inspect(online_users)

    typing =
      Map.get(online_users, Integer.to_string(user_id), %{
        metas: [
          %{count: 0, typing: 0, phx_ref: nil, phx_ref_prev: nil}
        ]
      })
      |> get_meta_stats()
      |> elem(1)

    typing
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(Slax.PubSub, @topic)
  end

  def get_meta_stats(%{metas: metas}) do
    Enum.reduce(metas, {0, 0, nil, nil}, fn meta,
                                            {count_acc, typing_acc, ref_acc, ref_prev_acc} ->
      {
        count_acc + meta.count,
        max(meta.typing, typing_acc),
        max(meta.phx_ref, ref_acc),
        max(meta.phx_ref_prev, ref_prev_acc)
      }
    end)
  end

  def update(online_users, %{joins: joins, leaves: leaves}) do
    # IO.inspect(online_users)
    # IO.inspect(leaves)

    online_users
    |> process_updates(joins, &Kernel.+/2)
    |> process_updates(leaves, &Kernel.-/2)
  end

  defp process_updates(online_users, updates, operation) do
    Enum.reduce(updates, online_users, fn {id,
                                           %{
                                             metas:
                                               [
                                                 %{
                                                   count: count,
                                                   typing: typing,
                                                   phx_ref: phx_ref,
                                                   phx_ref_prev: phx_ref_prev
                                                 }
                                                 | _
                                               ] = metas
                                           }},
                                          acc ->
      case Map.fetch(acc, id) do
        {:ok, existing_metas} ->
          total_count =
            Enum.reduce(existing_metas, 0, fn {:metas, list}, sum ->
              sum + Enum.sum(Enum.map(list, & &1.count))
            end)

          Map.put(acc, id, %{
            metas: [
              %{
                count: operation.(total_count, 1),
                typing: typing,
                phx_ref: phx_ref,
                phx_ref_prev: phx_ref_prev
              }
            ]
          })

        :error ->
          Map.put(acc, id, %{metas: metas})
      end
    end)
  end
end
