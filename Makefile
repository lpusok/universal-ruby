X86BREW = arch -x86_64 brew

gem_install_bundler:
	arch -x86_64 zsh -c "bitrise run gem_install_bundler"

run_bundler:
	arch -x86_64 zsh -c "bitrise run run_bundler"

setup:
	rbenv install $$(<.ruby-version)

setup_x86_64:
	RBENV_ROOT="$$(rbenv root)/x86_64" arch -x86_64 rbenv install $$(<.ruby-version)

clean:
	.bundle

ruby_install_x86_64:
	arch -x86_64 zsh -c "brew reinstall readline"
	RBENV_ROOT="$$(rbenv root)/x86_64" arch -x86_64 rbenv install $$(<.ruby-version)

run_bundler_with_shim:
	PATH="$(shell pwd)/bin/shims:$$PATH" arch -x86_64 zsh -c "bitrise run run_bundler"

clean_gems:
	mv Gemfile _Gemfile
	rm Gemfile.lock || true
	echo "source 'https://rubygems.org'" > Gemfile
	bundle clean --force
	rm Gemfile
	mv _Gemfile Gemfile
