install:
	mix deps.get
	cd apps/components_guide_web/assets/ && npm ci

dev:
	iex -S mix phx.server
