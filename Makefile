default: install

install: install_mix install_assets

install_mix:
	mix deps.get

install_assets:
	cd apps/components_guide_web/assets/ && npm ci

test_watch:
	watchexec -e ex,exs mix test

dev:
	iex -S mix phx.server

build:
	mix phx.digest

clean:
	rm -rf ./_build

production:
	git pull --rebase
	git push origin master
	git push gigalixir master

deploy: production

status:
	gigalixir ps
