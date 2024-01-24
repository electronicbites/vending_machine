# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     VendingMachine.Repo.insert!(%VendingMachine.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

 VendingMachine.Accounts.register_user(%{username: "seller", password: "secret123", deposit: 42, role: "seller"})
 VendingMachine.Accounts.register_user(%{username: "buyer", password: "secret123", deposit: 42, role: "buyer"})
x
