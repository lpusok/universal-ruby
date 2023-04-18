build_universal_ruby:
	./bin/build_ruby.sh

clean:
	rm -r .build

test_gem_install_bundler:
	arch -x86_64 zsh -c "bitrise run gem_install_bundler"

test_run_bundler:
	arch -x86_64 zsh -c "bitrise run run_bundler"

clean_gems:
	mv Gemfile _Gemfile
	rm Gemfile.lock || true
	echo "source 'https://rubygems.org'" > Gemfile
	bundle clean --force
	rm Gemfile
	mv _Gemfile Gemfile
