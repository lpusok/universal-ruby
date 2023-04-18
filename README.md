# Universal Ruby

This repository contains a [script](./bin/build_ruby.sh) to aid in building
Ruby for universal CPU architectures (arm64 and x86_64) for macOS.

## Pre-requisites

You'll need the following software installed:

* [Homebrew](https://brew.sh)
* [rbenv](https://github.com/rbenv/rbenv)
* [ruby-build](https://github.com/rbenv/ruby-build) (usually installed with
  rbenv)
* GCC-compatible compiler and common build tools (i.e. `make`)

For the compiler, simply downloading Xcode and installing the command line tools
is sufficient.  For the rest, you can install Homebrew first and then install
rbenv and ruby-build.

## Usage

To build Ruby, just run `make` in this directory.  That'll run the 
build_ruby.sh script.  When completed, you should have version 3.2.2 of Ruby
available via `rbenv`.  If you already have it installed, you'll be prompted
whether to replace it.  You can then verify that you are using a Universal
version:

```
➜  git:(main) ✗ make

... wait for completion ...

➜  git:(main) ✗ rbenv local 3.2.2
➜  git:(main) ✗ ruby --version
ruby 3.2.2 (2023-03-30 revision e51014f9c0) [universal.arm64-darwin22]
```

## Choices made to enable a universal Ruby

First things first, ruby-build is a fantastic way to build Ruby.  However, it
adds an indirection to the process of building Ruby.  The build script includes
a function to [build Ruby directly from source][1].  If you run into issues,
you might try to build with it simply by [uncommenting out a line][2].

[1]: https://github.com/Grayson/universal-ruby/blob/e1c168dea5216ab019263708c68d914dfe079c24/bin/build_ruby.sh#L197-L229
[2]: https://github.com/Grayson/universal-ruby/blob/e1c168dea5216ab019263708c68d914dfe079c24/bin/build_ruby.sh#L247

### Building the dependencies

Now, before we can build a universal Ruby, we need to have universal versions of
the dependencies.  Fortunately, libyaml can be readily built by [specifying some
CFLAGS][3] during the standard `configure`/`make`/`make install` dance.

[3]: https://github.com/Grayson/universal-ruby/blob/e1c168dea5216ab019263708c68d914dfe079c24/bin/build_ruby.sh#L65-L67

I couldn't figure out how to build Readline through configuring flags, but found
that I could build an x86_64 version simply by [configuring and making under
Rosetta][4].  We then assemble a universal binary by using `lipo` to [combine
the arm64 and x86_64 builds][5].

[4]: https://github.com/Grayson/universal-ruby/blob/e1c168dea5216ab019263708c68d914dfe079c24/bin/build_ruby.sh#L97
[5]: https://github.com/Grayson/universal-ruby/blob/e1c168dea5216ab019263708c68d914dfe079c24/bin/build_ruby.sh#L104-L111

OpenSSL can be [configured for x86_64 builds][6] and then stitched together
similarly to Readling.

[6]: https://github.com/Grayson/universal-ruby/blob/e1c168dea5216ab019263708c68d914dfe079c24/bin/build_ruby.sh#L145

With all of our dependencies built with symbols for both arm64 and x86_64
architectures, we can [specify their use][7] in ruby-build through the
`RUBY_CONFIGURE_OPTS` environment variable.

[7]: https://github.com/Grayson/universal-ruby/blob/e1c168dea5216ab019263708c68d914dfe079c24/bin/build_ruby.sh#L192

### Fixing the code

There is an issue if you build the Ruby 3.2.2 source.  Ruby will build miniruby
in order to run some files that finish configuring the build.  However, there's
a bug in `tool/mkconfig.rb`.  Specifically, the regex used to match the `arch`
won't match multiple-arch values.  That has [since been fixed][8].

There is also a runtime issue.  Specifically, builds of Ruby created with this
build script would run fine on arm64 but would throw a runtime error (`unmatched
platform`) when running in a Rosetta environment.  That check was [found][9]. At
the time of this writing, a proper fix wasn't found so the solution was just to
comment that check out.

[8]: https://github.com/ruby/ruby/commit/6422fef90c30a9662392a918533851f9ca41405e
[9]: https://github.com/ruby/ruby/blob/2dff1d4fdabd0fafeeac675baaaf7b06bb3150f9/compile.c#L13342-L13344

The only issue was figuring out how to update the source code prior to building.
Ruby-build doesn't provide a mechanism for interjecting between downloading the
code and compiling it but it *does* provide the means to introduce custom
tooling.  In this case, `make` is [being hijacked][10] to provide some
just-in-time replacements.

[10]: https://github.com/Grayson/universal-ruby/blob/e1c168dea5216ab019263708c68d914dfe079c24/bin/build_ruby.sh#L193

The [fake `make`][11] just performs a quick check.  If it finds a `ruby.c` file,
it assumes that it's in the Ruby source directory and will `rsync` the
replacement files.  Then it simply forwards the command to the real `make` to
perform the actual build.

[11]: https://github.com/Grayson/universal-ruby/blob/main/bin/make-shim.sh
[12]: https://github.com/Grayson/universal-ruby/tree/main/bin/replacements/ruby/3.2.2

## Repo history

This repo original contained just a Gemfile and a Makefile with a few commands.
The intent was to have some minimal test cases for evaluating working with Ruby
under Rosetta emulation.

Eventually, some problem solving started and it inherited a handful of different
ideas.  Some ideas, like shim versions of the Ruby binaries that would
de-Rosetta Ruby when run were considered.  Otherwise, most of the work went into
creating the Universal Ruby build.

Some of the tests remain, but this repo has been re-purposed to focus on
building Ruby.
