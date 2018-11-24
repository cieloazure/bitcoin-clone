defmodule Bitcoin.Utilities.ScriptUtilTest do
	use ExUnit.Case
	alias Bitcoin.Utilities.ScriptUtil

	describe "validate script positive case" do
		test "script is valid" do
			wallet = Bitcoin.Wallet.init_wallet()
			locking_script = ScriptUtil.generate_locking_script(wallet[:address])
			unlocking_script = ScriptUtil.generate_unlocking_script(wallet[:private_key], wallet[:public_key])

			script = unlocking_script <> " / " <> locking_script
			assert ScriptUtil.valid?(script)
		end
	end

	describe "validate script negative case" do
		test "script is invalid" do
			wallet1 = Bitcoin.Wallet.init_wallet()
			wallet2 = Bitcoin.Wallet.init_wallet()
			locking_script = ScriptUtil.generate_locking_script(wallet1[:address])
			unlocking_script = ScriptUtil.generate_unlocking_script(wallet2[:private_key], wallet2[:public_key])

			script = unlocking_script <> " / " <> locking_script
			assert !ScriptUtil.valid?(script)
		end
	end
end