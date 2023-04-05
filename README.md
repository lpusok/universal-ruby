# gem-rosetta-tests
A minimal set of tests to verify using Ruby+Gems+Cocoapods in a Rosetta emulated
environment.

## Usage

To install a specific version of Ruby, update the `.ruby-version` file with the
expected version and run `make setup` to install it using [`rbenv`][].

[`rbenv`]: https://github.com/rbenv/rbenv

There are two major issues that appear to pop up when running Ruby inside a
Rosetta-emulation environment.

### "Bad interpreter"

Sometimes, you'll receive an error that indicates that `gem` failed with a "bad
interpreter" error like so:

```
/opt/homebrew/Cellar/rbenv/1.2.0/libexec/rbenv-exec: /Users/vagrant/.rbenv/versions/3.1.0/bin/gem: /Users/vagrant/ruby31/bin/ruby: bad interpreter: No such file or directory
```

This often occurs when installing `bundler` in the Rosetta environment.  You can
mirror this behavior with `make gem_install_bundler`.

### "symbol(s) not found"

The Ruby installation on macOS is not a Universal binary that contains both
x86_64 and ARM symbols.  As a result, gems that require compilation may find
that they cannot locate the appropriate symbols for a specific architecture.
In those cases, you'll see something like the following in the logs:

```
ld: symbol(s) not found for architecture x86_64
```

You can mimic this behavior by running `make run_bundler` locally.

Note that you might find yourself having a valid `.bundle` folder if you run
bundler outside of Rosetta emulation.  In that case, you can run `make clean`
to remove that folder and start again.
