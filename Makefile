default: install

install: install_mix install_assets

install_mix:
	mix deps.get

install_assets:
	cd apps/components_guide_web/assets/ && npm ci

dev:
	iex -S mix phx.server
