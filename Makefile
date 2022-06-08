default: install

install: install_mix install_assets

install_mix:
	mix deps.get

install_assets:
	cd assets/ && npm ci

test_watch:
	watchexec -e ex,exs mix test

dev:
	iex -S mix phx.server

build:
	MIX_ENV=prod mix deps.get && MIX_ENV=prod mix production_build

cargo_build:
	cd native/componentsguide_rustler_math/ && cargo build --release

clean:
	rm -rf ./_build

production:
	git pull --rebase
	git push origin master
	git push gigalixir master

deploy: production

status:
	gigalixir ps
