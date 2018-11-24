defmodule Bitcoin.Utilities.ScriptUtil do
  alias Bitcoin.Utilities.{Stack, Keys, Crypto, Base58Check}

  @doc """
  Generates locking script with given 'recipient'
  """
  def generate_locking_script(recipient) do
    "DUP / HASH160 / BASE58CHECK / #{recipient} / EQUALVERIFY / CHECKSIG"
  end

  @doc """
  Generates unlocking script
  """
  def generate_unlocking_script(private_key, public_key) do
    signature = Crypto.sign("true", private_key)
    "#{signature} / #{public_key}"
  end

  @doc """
  Executes the script and validates if unlocking and locking scripts are valid.
  """
  def valid?(script) when is_bitstring(script) do
    script = String.split(script, " / ")
    valid?(script)
  end

  def valid?(script, stack \\ []) when is_list(script) do
    case List.pop_at(script, 0) do
      {"DUP", script} ->
        stack = Stack.push(stack, Stack.peek(stack))
        valid?(script, stack)

      {"HASH160", script} ->
        {element, stack} = Stack.pop(stack)
        element = element |> Crypto.hash(:sha256) |> Crypto.hash(:ripemd160)
        stack = Stack.push(stack, element)
        valid?(script, stack)

      {"BASE58CHECK", script} ->
        {element, stack} = Stack.pop(stack)
        element = element |> Base58Check.encode()
        stack = Stack.push(stack, element)
        valid?(script, stack)

      {"EQUALVERIFY", script} ->
        {[e1, e2], stack} = Stack.pop(stack, 2)

        if e1 == e2 do
          valid?(script, stack)
        else
          false
        end

      {"CHECKSIG", _script} ->
        {[public_key, signature], _stack} = Stack.pop(stack, 2)
        Crypto.verify("true", public_key, signature)

      {element, script} when is_bitstring(element) ->
        stack = Stack.push(stack, element)
        valid?(script, stack)

      _ ->
        false
    end
  end
end
