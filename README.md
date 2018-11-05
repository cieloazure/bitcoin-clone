# Bitcoin

Bitcoin protocol simulation for Project 4 of DOS

## Contribution guidelines

- Install `git-flow` and follow `git-flow` branching guidelines
- Branch off `develop` branch and start working
- Submit pull requests to `develop` branch only
- Write the documentation for any functions or modules. Even a one liner would
  do 
- Write the tests required for the functions in tests folder
- Test the coverage of the code with `mix test --cover`. Try to keep it as high
  as possible
- Make commits in a logical way and avoid making commits which include a huge
  sets of changes 
  soon as possible
- Peer review by pulling the pull requests and running tests on local machine.
  If the tests have suffiecient coverage and the documentation is present only
  then a branch may be merged
- If a urgent Peer review is required, drop all work and work on the peer
  review and getting that branch merged
- Update the project and todo section if any future work needs to be done
  should work on the issue immediately 
- If a pull request is merged, pull the develop branch and start work from the
  new updated state

## Installation on local machine

Follow the steps below for successfully running a local instance of the
simulation

#### Compilation

```elixir
mix compile --force
```

#### Run tests 

```elixir
mix test
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bitcoin](https://hexdocs.pm/bitcoin).

