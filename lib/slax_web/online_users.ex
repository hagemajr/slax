defmodule SlaxWeb.OnlineUsers do
  alias SlaxWeb.Presence

  @topic "online_users"

  def list() do
    l =
      @topic
      |> Presence.list()

    # IO.inspect(l)
  end

  def track(pid, user) do
    {:ok, _} =
      Presence.track(pid, @topic, user.id, %{
        typing: Time.add(Time.utc_now(), -600),
        count: 0,
        phx_ref: nil,
        phx_ref_prev: nil
      })

    :ok
  end

  def online?(online_users, user_id) do
    online =
      Map.get(online_users, Integer.to_string(user_id), %{
        metas: [
          %{count: 0, typing: Time.add(Time.utc_now(), -600), phx_ref: nil, phx_ref_prev: nil}
        ]
      })
      |> get_meta_stats()
      |> elem(0)

    if online > 0 do
      true
    else
      false
    end
  end

  def set_typing_status(pid, user_id) do
    Presence.update(pid, @topic, user_id, %{
      typing: Time.utc_now(),
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
          %{count: 0, typing: Time.add(Time.utc_now(), -600), phx_ref: nil, phx_ref_prev: nil}
        ]
      })
      |> get_meta_stats()
      |> elem(1)

    typing

    # IO.inspect(typing)
    # IO.inspect(Time.utc_now())

    typing
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(Slax.PubSub, @topic)
  end

  def get_meta_stats(%{metas: metas}) do
    Enum.reduce(metas, {0, nil, nil, nil}, fn meta,
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

    list =
      online_users
      |> process_joins(joins)
      |> process_leaves(leaves)

    # IO.inspect(list)
    list
  end

  defp process_joins(online_users, updates) do
    # IO.inspect(online_users)
    # IO.inspect(updates)
    l =
      Enum.reduce(updates, %{}, fn {key, value}, acc ->
        # Do something with key and value
        # Return new accumulator
        Map.put(acc, key, %{
          metas: [
            %{
              count: get_meta_stats(value) |> elem(0),
              typing: get_meta_stats(value) |> elem(1),
              phx_ref: get_meta_stats(value) |> elem(2),
              phx_ref_prev: get_meta_stats(value) |> elem(3)
            }
          ]
        })
      end)

    # Enum.each(l, fn {key, value} ->
    #  IO.inspect(get_meta_stats(value))
    # end
    # IO.puts("Update here\n\n\n")
    # IO.inspect(l)

    out =
      Enum.reduce(online_users, %{}, fn {key, value}, acc ->
        Map.put(acc, key, %{
          metas: [
            %{
              count: (get_meta_stats(value) |> elem(0)) + 1,
              typing: Map.get(l, key).metas |> hd() |> Map.get(:typing),
              phx_ref: get_meta_stats(value) |> elem(2),
              phx_ref_prev: get_meta_stats(value) |> elem(3)
            }
          ]
        })
      end)

    # IO.puts("Output here\n\n\n\n")
    # IO.inspect(out)
    out
  end

  defp process_leaves(online_users, updates) do
    # IO.inspect(updates)
    online_users
  end
end
