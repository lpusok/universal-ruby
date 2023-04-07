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
