default: install

install: install_mix install_assets

install_mix:
	mix deps.get

install_assets:
	cd assets/ && npm ci

test_watch:
	watchexec -e ex,exs mix test

dev:
	RUST_BACKTRACE=1 iex -S mix phx.server

.PHONY: test
test:
	RUST_BACKTRACE=1 mix test --max-failures 1

.PHONY: e2e
e2e:
	cd e2e && npx playwright test

production_build:
	MIX_ENV=prod mix production_build

cargo_build:
	cd native/componentsguide_rustler_math/ && cargo build --release

clean:
	rm -rf ./_build
	cd native/componentsguide_rustler_math/ && cargo clean

production:
	git pull --rebase
	git push origin master
	git push gigalixir master

deploy: production

status:
	gigalixir ps
